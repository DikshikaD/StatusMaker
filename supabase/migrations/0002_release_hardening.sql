-- ============================================================================
-- Release hardening — security fixes found in the pre-release QA pass.
--
-- Nothing here changes what the app does for an honest user: every save, post,
-- like, remix and push keeps working exactly as before. It only closes the
-- doors a modified client (or a raw HTTP call with the app's public key) could
-- walk through.
--
-- Run AFTER schema.sql and notifications.sql. Safe to re-run.
-- Run in: Supabase dashboard -> SQL Editor -> New query -> Run.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Counters are server-owned
--
-- The statuses insert/update policies allow every column, so an owner could
-- PATCH their own row to likes_count = 999999 and float to the top of the
-- feed. The counters are only ever meant to move through the security-definer
-- sync triggers (sync_likes_count / sync_remix_count), which run as the
-- function owner — so any write made directly as an API role keeps the stored
-- value instead. remix_of is pinned the same way after insert: re-pointing it
-- would re-fire remix notifications and skew remix_count.
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
    else
      new.likes_count := old.likes_count;
      new.remix_count := old.remix_count;
      new.remix_of    := old.remix_of;
    end if;
  end if;
  return new;
end $$;

drop trigger if exists statuses_protect_counters on public.statuses;
create trigger statuses_protect_counters
  before insert or update on public.statuses
  for each row execute function public.protect_status_counters();

-- ---------------------------------------------------------------------------
-- 2) Storage: size + type limits, and no listing other users' folders
--
-- Both buckets were created without limits, so any anonymous account could
-- store files of any type and size behind a public URL. The app only ever
-- uploads JPEG/PNG/WebP (StatusRepository._tryUpload / _uploadThumbnail); the
-- thumbnail is the full 3x canvas export, hence the roomier cap.
--
-- Reading files is unaffected: these are public buckets, and public URLs are
-- served without consulting RLS. The select policy is only needed for the
-- client's own upserts, so it is narrowed to the caller's own folder.
-- ---------------------------------------------------------------------------
update storage.buckets
   set file_size_limit = 10485760,  -- 10 MB
       allowed_mime_types = array['image/jpeg','image/png','image/webp']
 where id = 'status-assets';

update storage.buckets
   set file_size_limit = 20971520,  -- 20 MB
       allowed_mime_types = array['image/png','image/jpeg','image/webp']
 where id = 'thumbnails';

drop policy if exists assets_read on storage.objects;
create policy assets_read on storage.objects
  for select to authenticated
  using (
    bucket_id in ('status-assets','thumbnails')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------------------------------------------------------------------------
-- 3) Internal functions are not part of the public API
--
-- (Same statements as section 7 of notifications.sql — repeated here so a
-- database that only ever ran the older notifications.sql gets them too.)
-- ---------------------------------------------------------------------------
revoke execute on function public.push_notification(public.notifications)
  from public, anon, authenticated;
revoke execute on function public.prune_old_notifications()
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4) Pin search_path on every security-definer function
--
-- A security-definer function resolves unqualified names through the caller's
-- search_path; pinning it stops a caller from shadowing a table or function
-- the definer relies on.
-- ---------------------------------------------------------------------------
alter function public.sync_likes_count()          set search_path = public, pg_temp;
alter function public.notify_on_like()            set search_path = public, pg_temp;
alter function public.sync_remix_count()          set search_path = public, pg_temp;
alter function public.notify_on_remix()           set search_path = public, pg_temp;
alter function public.push_notification(public.notifications)
                                                  set search_path = public, pg_temp;
alter function public.prune_old_notifications()   set search_path = public, pg_temp;

-- ---------------------------------------------------------------------------
-- 5) register_device — lets a phone move to its new owner
--
-- device_tokens is keyed by token so a phone that changes hands moves to the
-- new user (see notifications.sql section 2). But a plain client upsert can't
-- do that: the update half of ON CONFLICT runs against the OLD row, whose
-- user_id isn't the caller, so RLS rejects it and the token stays with the
-- previous owner — who keeps getting the new owner's notifications.
--
-- This does the same upsert as the caller-independent owner. It can only ever
-- attach a token to the caller themself (auth.uid()), never to anyone else.
-- PushService calls it and falls back to the plain upsert if it isn't
-- deployed yet.
-- ---------------------------------------------------------------------------
create or replace function public.register_device(
  p_token text, p_platform text, p_lang text
) returns void language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'not signed in';
  end if;
  if p_token is null or length(p_token) = 0 or length(p_token) > 4096 then
    raise exception 'invalid token';
  end if;

  insert into public.device_tokens (token, user_id, platform, lang, updated_at)
    values (
      p_token,
      auth.uid(),
      coalesce(nullif(p_platform, ''), 'android'),
      case when p_lang in ('en', 'hi') then p_lang else 'en' end,
      now()
    )
  on conflict (token) do update
    set user_id    = excluded.user_id,
        platform   = excluded.platform,
        lang       = excluded.lang,
        updated_at = excluded.updated_at;
end $$;

revoke execute on function public.register_device(text, text, text)
  from public, anon;
grant execute on function public.register_device(text, text, text)
  to authenticated;
