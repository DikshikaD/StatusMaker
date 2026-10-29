-- ============================================================================
-- QA hardening — fixes from the pre-release QA audit.
--
-- Run AFTER schema.sql, notifications.sql, 0001, 0002 and 0003, in that order.
-- Safe to re-run. Run in: Supabase dashboard -> SQL Editor -> New query -> Run.
--
-- Nothing here changes what an honest user can do. It closes what a modified
-- client (or a raw API call with the app's public key) could abuse.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Full-size image column
--
-- thumb_url now holds a small WebP preview for the feed (~40 KB instead of a
-- 1–2 MB PNG); image_url holds the full-resolution export used by the detail
-- view and Share. Rows saved before this keep image_url null and the app falls
-- back to thumb_url, which for them is still the full image.
-- ---------------------------------------------------------------------------
alter table public.statuses
  add column if not exists image_url text;

-- ---------------------------------------------------------------------------
-- 2) Server-owned columns
--
-- Same guard as 0002/0003 (counters, remix_of, is_hidden), now also pinning
-- created_at: the feed is ordered and paged by it, so a client that could set
-- it to 2099 would sit at the top of everyone's feed forever.
-- ---------------------------------------------------------------------------
create or replace function public.protect_status_counters()
returns trigger language plpgsql
set search_path = public, pg_temp
as $$
begin
  if current_user in ('anon', 'authenticated') then
    if tg_op = 'INSERT' then
      new.likes_count := 0;
      new.remix_count := 0;
      new.is_hidden   := false;
      new.created_at  := now();
    else
      new.likes_count := old.likes_count;
      new.remix_count := old.remix_count;
      new.remix_of    := old.remix_of;
      new.is_hidden   := old.is_hidden;
      new.created_at  := old.created_at;
    end if;
  end if;
  return new;
end $$;

-- ---------------------------------------------------------------------------
-- 3) Size limits
--
-- The feed downloads every row it shows, so one multi-megabyte design or title
-- would slow or break it for every user. Real designs are ~1–5 KB.
-- NOT VALID: enforced for every new write, without re-checking old rows.
-- ---------------------------------------------------------------------------
alter table public.statuses drop constraint if exists statuses_design_size;
alter table public.statuses
  add constraint statuses_design_size
  check (octet_length(design::text) <= 262144) not valid;

alter table public.statuses drop constraint if exists statuses_title_length;
alter table public.statuses
  add constraint statuses_title_length
  check (title is null or char_length(title) <= 120) not valid;

-- ---------------------------------------------------------------------------
-- 4) Images must live in this project's storage
--
-- thumb_url / image_url / the image URLs inside `design` are written by the
-- client. Without this a modified client could show any external picture in
-- the public feed (and swap it after it was reviewed), skip the bucket size and
-- type limits, and log the IP of everyone who scrolls past it.
--
-- The preview and full image must sit in the poster's own thumbnails folder.
-- URLs inside a design may point to any of this project's public buckets — a
-- remix legitimately keeps the original creator's photos.
--
-- If you ever move projects, update `base` below.
-- ---------------------------------------------------------------------------
create or replace function public.validate_status_urls()
returns trigger language plpgsql
set search_path = public, pg_temp
as $$
declare
  base constant text :=
    'https://soqpzkgribiumftburwy.supabase.co/storage/v1/object/public/';
  own  text;
  u    text;
begin
  if current_user not in ('anon', 'authenticated') then
    return new;
  end if;

  own := base || 'thumbnails/' || coalesce(new.user_id::text, '-') || '/';
  if new.thumb_url is not null and left(new.thumb_url, length(own)) <> own then
    raise exception 'thumb_url must be in your own thumbnails folder'
      using errcode = '22023';
  end if;
  if new.image_url is not null and left(new.image_url, length(own)) <> own then
    raise exception 'image_url must be in your own thumbnails folder'
      using errcode = '22023';
  end if;

  for u in
    select v #>> '{}'
      from jsonb_path_query(new.design, 'strict $.**') as v
     where jsonb_typeof(v) = 'string'
       and (v #>> '{}') ~* '^https?://'
  loop
    if left(u, length(base)) <> base then
      raise exception 'design images must be in this app''s storage'
        using errcode = '22023';
    end if;
  end loop;

  return new;
end $$;

drop trigger if exists statuses_validate_urls on public.statuses;
create trigger statuses_validate_urls
  before insert or update of thumb_url, image_url, design on public.statuses
  for each row execute function public.validate_status_urls();

-- ---------------------------------------------------------------------------
-- 5) Likes are private, and only on posts you can actually see
--
-- likes_select used to be `using (true)` — anyone holding the public key could
-- download who liked what (the privacy policy says "not who liked"). The app
-- only ever reads its own likes; counts come from statuses.likes_count.
--
-- Inserts also had no visibility check (foreign keys bypass RLS), so a user
-- could like a hidden or private post by id and notify its owner. The EXISTS
-- below runs under RLS, so it only sees public-and-not-hidden posts or your own.
-- Same for remix_of on a new status.
-- ---------------------------------------------------------------------------
drop policy if exists likes_select on public.likes;
create policy likes_select on public.likes
  for select using ( user_id = auth.uid() );

drop policy if exists likes_insert on public.likes;
create policy likes_insert on public.likes
  for insert with check (
    user_id = auth.uid()
    and exists (select 1 from public.statuses s where s.id = status_id)
  );

drop policy if exists statuses_insert on public.statuses;
create policy statuses_insert on public.statuses
  for insert with check (
    user_id = auth.uid()
    and (
      remix_of is null
      or exists (select 1 from public.statuses s where s.id = remix_of)
    )
  );

-- ---------------------------------------------------------------------------
-- 6) Notifications: the only client write is marking as read
--
-- The update policy limits rows to the recipient, but every column was
-- writable. Column privileges narrow it to read_at.
-- ---------------------------------------------------------------------------
revoke update on public.notifications from anon, authenticated;
grant update (read_at) on public.notifications to authenticated;

-- ---------------------------------------------------------------------------
-- 7) Notification cooldown
--
-- like -> unlike -> like (or flipping a remix public/private) used to push the
-- owner every single time, so one account could flood another's phone. Now at
-- most one notification per (actor, post, type) per 24 hours. The throttle row
-- survives the unlike that deletes the bell entry, which is the point.
-- ---------------------------------------------------------------------------
create table if not exists public.notification_throttle (
  actor_id  uuid not null references auth.users(id) on delete cascade,
  status_id uuid not null references public.statuses(id) on delete cascade,
  type      text not null,
  last_at   timestamptz not null default now(),
  primary key (actor_id, status_id, type)
);

-- No policies: only the security-definer triggers below touch it.
alter table public.notification_throttle enable row level security;

create index if not exists notification_throttle_status_idx
  on public.notification_throttle (status_id);

-- True (and records the send) when actor may notify about status/type now.
create or replace function public.notification_allowed(
  p_actor uuid, p_status uuid, p_type text
) returns boolean language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  ok boolean;
begin
  insert into public.notification_throttle (actor_id, status_id, type, last_at)
    values (p_actor, p_status, p_type, now())
  on conflict (actor_id, status_id, type) do update
    set last_at = excluded.last_at
    where public.notification_throttle.last_at < now() - interval '24 hours'
  returning true into ok;
  return coalesce(ok, false);
end $$;

revoke execute on function public.notification_allowed(uuid, uuid, text)
  from public, anon, authenticated;

create or replace function public.notify_on_like()
returns trigger language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  owner_id  uuid;
  new_row   public.notifications%rowtype;
begin
  if (tg_op = 'INSERT') then
    select user_id into owner_id from public.statuses where id = new.status_id;

    -- Liking your own status notifies nobody.
    if owner_id is null or owner_id = new.user_id then
      return new;
    end if;

    if not public.notification_allowed(new.user_id, new.status_id, 'like') then
      return new;
    end if;

    insert into public.notifications (recipient_id, actor_id, status_id, type)
      values (owner_id, new.user_id, new.status_id, 'like')
      returning * into new_row;

    perform public.push_notification(new_row);

    return new;

  elsif (tg_op = 'DELETE') then
    -- Unliking withdraws the bell entry; the throttle row stays.
    delete from public.notifications
      where type = 'like'
        and actor_id = old.user_id
        and status_id = old.status_id;
    return old;
  end if;
  return null;
end $$;

create or replace function public.notify_on_remix()
returns trigger language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  owner_id uuid;
  new_row  public.notifications%rowtype;
begin
  if new.remix_of is null or not new.is_public then
    return new;
  end if;

  -- Only on the way in or the way up, never on later re-saves.
  if tg_op = 'UPDATE' and old.is_public then
    return new;
  end if;

  select user_id into owner_id from public.statuses where id = new.remix_of;

  -- Remixing your own template notifies nobody.
  if owner_id is null or owner_id = new.user_id then
    return new;
  end if;

  if not public.notification_allowed(new.user_id, new.remix_of, 'remix') then
    return new;
  end if;

  insert into public.notifications (recipient_id, actor_id, status_id, type)
    values (owner_id, new.user_id, new.remix_of, 'remix')
    returning * into new_row;

  perform public.push_notification(new_row);

  return new;
end $$;

revoke execute on function public.notify_on_like()  from public, anon, authenticated;
revoke execute on function public.notify_on_remix() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 8) Auto-hide only counts established accounts
--
-- Anonymous accounts are free, so "3 reports hides a post" let anyone hide any
-- post with three throwaway installs. Only reporters whose account is at least
-- 24 hours old (at the time of the report) now count toward auto-hide. Every
-- report is still stored for your review queue (see 0003).
-- ---------------------------------------------------------------------------
create or replace function public.auto_hide_reported()
returns trigger language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  hide_threshold constant int := 3;
begin
  if (select count(*)
        from public.reports r
        join auth.users u on u.id = r.reporter_id
       where r.status_id = new.status_id
         and u.created_at <= r.created_at - interval '24 hours')
       >= hide_threshold then
    update public.statuses set is_hidden = true where id = new.status_id;
  end if;
  return new;
end $$;

revoke execute on function public.auto_hide_reported()
  from public, anon, authenticated;
