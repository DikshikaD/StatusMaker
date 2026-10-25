-- ============================================================================
-- status_maker — like notifications (in-app bell + push)
-- Run this once in: Supabase dashboard → SQL Editor → New query → Run.
-- Safe to re-run. Requires schema.sql to have been run first.
--
-- Design: the `notifications` table is the single source of truth. The in-app
-- bell reads it directly, and the push Edge Function is triggered by inserts
-- into it — so a notification can never exist as a push but not in the bell,
-- or vice versa.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) notifications: one row per thing that happened to you
-- ---------------------------------------------------------------------------
create table if not exists public.notifications (
  id           uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references auth.users(id) on delete cascade,
  actor_id     uuid not null references auth.users(id) on delete cascade,
  status_id    uuid references public.statuses(id) on delete cascade,
  type         text not null,             -- 'like' or 'remix' today; room for 'follow', …
  read_at      timestamptz,               -- null = unread (drives the bell badge)
  created_at   timestamptz not null default now()
);

-- The bell's only query: my notifications, newest first. Also serves the
-- unread-count badge, so it stays fast however many rows pile up.
create index if not exists notifications_recipient_idx
  on public.notifications (recipient_id, created_at desc);

-- ---------------------------------------------------------------------------
-- 2) device_tokens: which phones to push to, per user
--
-- The token is the primary key, not (user_id, token): a phone handed to a
-- different user must not keep receiving the previous user's notifications, so
-- re-registering the same token simply moves it to the new owner.
-- ---------------------------------------------------------------------------
create table if not exists public.device_tokens (
  token      text primary key,
  user_id    uuid not null references auth.users(id) on delete cascade,
  platform   text not null default 'android',
  updated_at timestamptz not null default now()
);

-- Language this device last registered with ('en' | 'hi'). The Edge Function
-- words the tray notification in it, since a closed app can't word anything
-- itself. Defaults to 'en' so rows that predate this column keep working.
--
-- Only used while the app is CLOSED. With the app open the in-app banner
-- re-words from the live setting instead (see PushService._localizedCopy),
-- because this column is only as fresh as the last registration.
alter table public.device_tokens
  add column if not exists lang text not null default 'en';

create index if not exists device_tokens_user_idx on public.device_tokens (user_id);

-- ---------------------------------------------------------------------------
-- 3) Row Level Security
-- ---------------------------------------------------------------------------
alter table public.notifications enable row level security;
alter table public.device_tokens enable row level security;

-- Notifications are readable only by their recipient. There is deliberately NO
-- insert policy: rows are only ever created by the trigger below (which runs as
-- security definer), so no client can forge a notification to someone else.
drop policy if exists notifications_select on public.notifications;
create policy notifications_select on public.notifications
  for select using ( recipient_id = auth.uid() );

-- Marking as read is the only client write, and only on your own rows.
drop policy if exists notifications_update on public.notifications;
create policy notifications_update on public.notifications
  for update using ( recipient_id = auth.uid() )
  with check ( recipient_id = auth.uid() );

drop policy if exists notifications_delete on public.notifications;
create policy notifications_delete on public.notifications
  for delete using ( recipient_id = auth.uid() );

-- Each user manages only their own device tokens.
drop policy if exists device_tokens_select on public.device_tokens;
create policy device_tokens_select on public.device_tokens
  for select using ( user_id = auth.uid() );

drop policy if exists device_tokens_insert on public.device_tokens;
create policy device_tokens_insert on public.device_tokens
  for insert with check ( user_id = auth.uid() );

drop policy if exists device_tokens_update on public.device_tokens;
create policy device_tokens_update on public.device_tokens
  for update using ( user_id = auth.uid() ) with check ( user_id = auth.uid() );

drop policy if exists device_tokens_delete on public.device_tokens;
create policy device_tokens_delete on public.device_tokens
  for delete using ( user_id = auth.uid() );

-- ---------------------------------------------------------------------------
-- 3.5) pg_net + Vault — lets a trigger call the Edge Function directly
--
-- pg_net queues an async HTTP call from inside Postgres (fire-and-forget: it
-- runs in the background, so a slow/dead Edge Function can never block or fail
-- the like insert itself). Vault stores the two values the trigger needs to
-- make that call — the Edge Function's URL and the service-role key it must
-- present — encrypted at rest, so nothing secret sits in this file or in git.
-- ---------------------------------------------------------------------------
create extension if not exists pg_net with schema extensions;

-- Run these two once, filling in your real project ref and service-role key
-- (Dashboard → Project Settings → API). Safe to re-run: each call replaces the
-- previous value for that name.
--   select vault.create_secret(
--     'https://<project-ref>.functions.supabase.co/notify-on-like',
--     'notify_on_like_url'
--   );
--   select vault.create_secret(
--     '<service-role-key>',
--     'notify_on_like_key'
--   );

-- ---------------------------------------------------------------------------
-- 3.6) push_notification — shared by every "insert a notification" trigger
--
-- Pulled out of notify_on_like() so notify_on_remix() (and any future event)
-- calls the exact same, exception-safe path instead of copy-pasting it.
-- ---------------------------------------------------------------------------
create or replace function public.push_notification(n public.notifications)
returns void language plpgsql security definer as $$
declare
  fn_url text;
  fn_key text;
begin
  -- Best-effort: if the Vault secrets haven't been set yet, the notification
  -- row (and the in-app bell) still exists — only the push is skipped.
  select decrypted_secret into fn_url
    from vault.decrypted_secrets where name = 'notify_on_like_url';
  select decrypted_secret into fn_key
    from vault.decrypted_secrets where name = 'notify_on_like_key';

  if fn_url is null or fn_key is null then
    return;
  end if;

  -- Wrapped on its own: pg_net's function/table names have moved across
  -- versions, and this call must never be able to take the triggering write
  -- down with it if pg_net is missing, misconfigured, or errors for any reason.
  begin
    perform net.http_post(
      url     := fn_url,
      headers := jsonb_build_object(
                   'Content-Type', 'application/json',
                   'Authorization', 'Bearer ' || fn_key
                 ),
      body    := jsonb_build_object(
                   'type', 'INSERT',
                   'table', 'notifications',
                   'record', jsonb_build_object(
                     'id', n.id,
                     'recipient_id', n.recipient_id,
                     'actor_id', n.actor_id,
                     'status_id', n.status_id,
                     'type', n.type
                   )
                 )
    );
  exception when others then
    raise warning 'push_notification: push call failed: %', sqlerrm;
  end;
end $$;

-- ---------------------------------------------------------------------------
-- 4) Create / remove a notification when a status is liked / unliked, and push
--    the Edge Function directly on insert — no manual Dashboard webhook needed.
--
-- Runs inside the same statement as the like itself — no polling, no server.
-- ---------------------------------------------------------------------------
create or replace function public.notify_on_like()
returns trigger language plpgsql security definer as $$
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

    insert into public.notifications (recipient_id, actor_id, status_id, type)
      values (owner_id, new.user_id, new.status_id, 'like')
      returning * into new_row;

    perform public.push_notification(new_row);

    return new;

  elsif (tg_op = 'DELETE') then
    -- Unliking withdraws the notification, so like → unlike → like doesn't
    -- leave a trail of duplicates in the bell.
    delete from public.notifications
      where type = 'like'
        and actor_id = old.user_id
        and status_id = old.status_id;
    return old;
  end if;
  return null;
end $$;

-- Separate from the existing likes_count triggers on purpose: a failure here
-- must not be able to break the like itself.
drop trigger if exists notify_like_ins on public.likes;
create trigger notify_like_ins after insert on public.likes
  for each row execute function public.notify_on_like();

drop trigger if exists notify_like_del on public.likes;
create trigger notify_like_del after delete on public.likes
  for each row execute function public.notify_on_like();

-- ---------------------------------------------------------------------------
-- 4.5) Remixes: count + notify the original creator when someone uses their
--      template.
--
-- `remix_of` is set exactly once, at insert (see StatusRepository.saveDesign —
-- it's only ever passed on the very first save of a new row, never on later
-- updates to that same row), so this can't double-count a status being edited
-- further after its first save.
-- ---------------------------------------------------------------------------
alter table public.statuses
  add column if not exists remix_count integer not null default 0;

create or replace function public.sync_remix_count()
returns trigger language plpgsql security definer as $$
begin
  if (tg_op = 'INSERT') then
    if new.remix_of is not null then
      update public.statuses set remix_count = remix_count + 1 where id = new.remix_of;
    end if;
    return new;
  elsif (tg_op = 'DELETE') then
    if old.remix_of is not null then
      update public.statuses set remix_count = greatest(remix_count - 1, 0) where id = old.remix_of;
    end if;
    return old;
  end if;
  return null;
end $$;

drop trigger if exists remix_count_ins on public.statuses;
create trigger remix_count_ins after insert on public.statuses
  for each row execute function public.sync_remix_count();

drop trigger if exists remix_count_del on public.statuses;
create trigger remix_count_del after delete on public.statuses
  for each row execute function public.sync_remix_count();

create or replace function public.notify_on_remix()
returns trigger language plpgsql security definer as $$
declare
  owner_id uuid;
  new_row  public.notifications%rowtype;
begin
  if new.remix_of is null then
    return new;
  end if;

  -- Only a *published* remix is news. Keeping a private copy of someone's
  -- status is between that user and their own gallery, so a Save (is_public
  -- false) must stay silent — the creator hears about it when, and only when,
  -- the remix goes public.
  if not new.is_public then
    return new;
  end if;

  -- ...and only on the way in or the way up. Without this, every later
  -- edit-and-resave of an already-public remix would notify again.
  if tg_op = 'UPDATE' and old.is_public then
    return new;
  end if;

  select user_id into owner_id from public.statuses where id = new.remix_of;

  -- Remixing your own template notifies nobody.
  if owner_id is null or owner_id = new.user_id then
    return new;
  end if;

  insert into public.notifications (recipient_id, actor_id, status_id, type)
    values (owner_id, new.user_id, new.remix_of, 'remix')
    returning * into new_row;

  perform public.push_notification(new_row);

  return new;
end $$;

-- Separate trigger from sync_remix_count for the same reason notify_on_like
-- is separate from likes_count: a notification failure must never be able to
-- break the save.
drop trigger if exists notify_remix_ins on public.statuses;
create trigger notify_remix_ins after insert on public.statuses
  for each row execute function public.notify_on_remix();

-- Post straight from the editor inserts an already-public row (the INSERT
-- trigger above catches that), but Save-then-Post inserts privately first and
-- flips the flag later — so the private -> public transition needs its own
-- trigger or that notification is lost. notify_on_remix() is written to be
-- safe under both, and `after update of is_public` keeps it off the hot path
-- of ordinary design re-saves.
drop trigger if exists notify_remix_pub on public.statuses;
create trigger notify_remix_pub after update of is_public on public.statuses
  for each row execute function public.notify_on_remix();

-- ---------------------------------------------------------------------------
-- 5) Housekeeping: drop read notifications older than 30 days
--
-- This table grows fastest of any in the schema. Call this from a scheduled
-- job (Supabase dashboard → Database → Cron, e.g. daily) — or ignore it until
-- volume makes it worth setting up.
-- ---------------------------------------------------------------------------
create or replace function public.prune_old_notifications()
returns void language sql security definer as $$
  delete from public.notifications
    where read_at is not null
      and created_at < now() - interval '30 days';
$$;

-- ---------------------------------------------------------------------------
-- 6) NEXT STEP — deploy the Edge Function and set the two Vault secrets above
--    (see supabase/functions/notify-on-like/ for the deploy commands).
--
-- Once both secrets exist, the trigger in step 4 calls the function directly
-- on every like — no Dashboard webhook to configure or forget. Until the
-- secrets are set, everything above still works, it just powers the in-app
-- bell only, with no push (see the "best-effort" note in notify_on_like()).
--
-- Alternative: if you'd rather manage this from the Dashboard instead of
-- Vault, you can still skip step 3.5/4's pg_net call and wire a
-- Database Webhook (Dashboard → Database → Webhooks) on public.notifications
-- INSERT → Edge Function notify-on-like instead. Pick one path, not both, or
-- every like will push twice.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 7) Lock down internal functions
--
-- Postgres grants EXECUTE to PUBLIC on new functions, and PostgREST exposes
-- every public-schema function to the API. Without this, anyone holding the app's
-- public key could call push_notification() to push to any user, or
-- prune_old_notifications() to delete everyone's read notifications. The
-- triggers still work: they run as the function owner, not as the caller.
-- ---------------------------------------------------------------------------
revoke execute on function public.push_notification(public.notifications)
  from public, anon, authenticated;
revoke execute on function public.prune_old_notifications()
  from public, anon, authenticated;
