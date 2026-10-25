-- ============================================================================
-- Launch blockers: content reporting / hiding (Play UGC policy) and
-- "delete my data" (Play Data safety), plus the indexes the audit flagged.
--
-- Run AFTER schema.sql, notifications.sql and 0002_release_hardening.sql.
-- Safe to re-run. Run in: Supabase dashboard -> SQL Editor -> New query -> Run.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Reports + auto-hide
--
-- Any user can report a public post once. After HIDE_THRESHOLD distinct
-- reporters the post is hidden from everyone but its owner until you review it
-- in the dashboard. Change the threshold in auto_hide_reported() below.
--
-- Review queue (dashboard SQL editor):
--   select s.id, s.title, s.thumb_url, count(*) as reports,
--          array_agg(distinct r.reason) as reasons
--     from reports r join statuses s on s.id = r.status_id
--    group by s.id order by reports desc;
-- Restore a wrongly hidden post:   update statuses set is_hidden = false where id = '<id>';
-- Remove a bad post for good:      delete from statuses where id = '<id>';
-- ---------------------------------------------------------------------------
alter table public.statuses
  add column if not exists is_hidden boolean not null default false;

create table if not exists public.reports (
  id          uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  status_id   uuid not null references public.statuses(id) on delete cascade,
  reason      text not null
              check (reason in ('spam', 'sexual', 'hate', 'violence', 'other')),
  created_at  timestamptz not null default now(),
  unique (reporter_id, status_id)
);

create index if not exists reports_status_idx on public.reports (status_id);

alter table public.reports enable row level security;

-- Reporters can file and see their own reports; nobody can edit or withdraw
-- them from the client, and nobody can read other people's reports.
drop policy if exists reports_insert on public.reports;
create policy reports_insert on public.reports
  for insert to authenticated
  with check (reporter_id = auth.uid());

drop policy if exists reports_select on public.reports;
create policy reports_select on public.reports
  for select to authenticated
  using (reporter_id = auth.uid());

create or replace function public.auto_hide_reported()
returns trigger language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  hide_threshold constant int := 3;
begin
  if (select count(*) from public.reports where status_id = new.status_id)
       >= hide_threshold then
    update public.statuses set is_hidden = true where id = new.status_id;
  end if;
  return new;
end $$;

drop trigger if exists reports_auto_hide on public.reports;
create trigger reports_auto_hide after insert on public.reports
  for each row execute function public.auto_hide_reported();

revoke execute on function public.auto_hide_reported()
  from public, anon, authenticated;

-- is_hidden is moderation state: an owner must not be able to un-hide their own
-- post through the API. Same guard the like/remix counters already use.
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
    else
      new.likes_count := old.likes_count;
      new.remix_count := old.remix_count;
      new.remix_of    := old.remix_of;
      new.is_hidden   := old.is_hidden;
    end if;
  end if;
  return new;
end $$;

-- Hidden posts drop out of the public feed (and out of the detail view a
-- notification tap opens). Owners still see their own.
drop policy if exists statuses_select on public.statuses;
create policy statuses_select on public.statuses
  for select using (
    (is_public and not is_hidden) or user_id = auth.uid()
  );

-- ---------------------------------------------------------------------------
-- 2) Delete my data
--
-- The app first removes the caller's files from the two storage buckets
-- through the Storage API (deleting storage.objects rows from SQL leaves the
-- underlying files behind), then calls this. It deletes the caller's
-- statuses explicitly — statuses.user_id is "on delete set null", so deleting
-- only the auth user would leave their public posts online — and then the auth
-- user itself, which cascades to likes, notifications, device tokens, reports.
-- ---------------------------------------------------------------------------
create or replace function public.delete_my_account()
returns void language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not signed in';
  end if;
  delete from public.statuses where user_id = uid;
  delete from auth.users where id = uid;
end $$;

revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- ---------------------------------------------------------------------------
-- 3) Indexes from the audit
--
-- Foreign keys without an index make every delete/unlike/remix scan the whole
-- child table; the category feed had no index matching its filter + order.
-- ---------------------------------------------------------------------------
create index if not exists statuses_public_category_idx
  on public.statuses (category, created_at desc)
  where is_public and not is_hidden;

create index if not exists likes_status_idx
  on public.likes (status_id);

create index if not exists notifications_status_actor_idx
  on public.notifications (status_id, actor_id);

create index if not exists statuses_remix_of_idx
  on public.statuses (remix_of);
