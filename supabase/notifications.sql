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
  type         text not null,             -- 'like' today; room for 'remix', 'follow', …
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
-- 4) Create / remove a notification when a status is liked / unliked
--
-- Runs inside the same statement as the like itself — no polling, no server.
-- ---------------------------------------------------------------------------
create or replace function public.notify_on_like()
returns trigger language plpgsql security definer as $$
declare
  owner_id uuid;
begin
  if (tg_op = 'INSERT') then
    select user_id into owner_id from public.statuses where id = new.status_id;

    -- Liking your own status notifies nobody.
    if owner_id is null or owner_id = new.user_id then
      return new;
    end if;

    insert into public.notifications (recipient_id, actor_id, status_id, type)
      values (owner_id, new.user_id, new.status_id, 'like');
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
-- 6) NEXT STEP — wire up push (see supabase/functions/notify-on-like/)
--
-- After deploying the Edge Function, add the webhook that calls it:
--   Dashboard → Database → Webhooks → Create a new hook
--     Table:      public.notifications
--     Events:     Insert
--     Type:       Supabase Edge Functions → notify-on-like
--     HTTP header: Authorization: Bearer <YOUR SERVICE_ROLE KEY>
--
-- Until that exists, everything above still works — it just powers the in-app
-- bell only, with no push.
-- ---------------------------------------------------------------------------
