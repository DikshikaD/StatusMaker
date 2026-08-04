-- ============================================================================
-- status_maker — Supabase schema
-- Run this once in: Supabase dashboard → SQL Editor → New query → Run.
-- Safe to re-run (uses "if not exists" / "on conflict" where possible).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) statuses: one row per saved design (structured, editable — not a PNG)
-- ---------------------------------------------------------------------------
create table if not exists public.statuses (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  title        text,
  category     text,
  design       jsonb not null,          -- full editable composition (bg/text/fonts/images/elements)
  thumb_url    text,                    -- small preview PNG (display only, not source of truth)
  is_public    boolean not null default false,   -- true once the user taps "Share"
  remix_of     uuid references public.statuses(id) on delete set null, -- forked from another
  likes_count  integer not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists statuses_user_idx   on public.statuses (user_id, created_at desc);
create index if not exists statuses_public_idx on public.statuses (is_public, created_at desc);

-- ---------------------------------------------------------------------------
-- 2) likes: many-to-many, powers the "Liked" feed and the likes_count
-- ---------------------------------------------------------------------------
create table if not exists public.likes (
  user_id    uuid not null references auth.users(id) on delete cascade,
  status_id  uuid not null references public.statuses(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, status_id)
);

-- ---------------------------------------------------------------------------
-- 3) Row Level Security — the important part: users only touch their own data
-- ---------------------------------------------------------------------------
alter table public.statuses enable row level security;
alter table public.likes    enable row level security;

-- statuses: readable if public OR mine; writable only by me
drop policy if exists statuses_select on public.statuses;
create policy statuses_select on public.statuses
  for select using ( is_public or user_id = auth.uid() );

drop policy if exists statuses_insert on public.statuses;
create policy statuses_insert on public.statuses
  for insert with check ( user_id = auth.uid() );

drop policy if exists statuses_update on public.statuses;
create policy statuses_update on public.statuses
  for update using ( user_id = auth.uid() ) with check ( user_id = auth.uid() );

drop policy if exists statuses_delete on public.statuses;
create policy statuses_delete on public.statuses
  for delete using ( user_id = auth.uid() );

-- likes: anyone can read counts; you can only like/unlike as yourself
drop policy if exists likes_select on public.likes;
create policy likes_select on public.likes for select using ( true );

drop policy if exists likes_insert on public.likes;
create policy likes_insert on public.likes
  for insert with check ( user_id = auth.uid() );

drop policy if exists likes_delete on public.likes;
create policy likes_delete on public.likes
  for delete using ( user_id = auth.uid() );

-- ---------------------------------------------------------------------------
-- 4) Keep statuses.likes_count in sync automatically
-- ---------------------------------------------------------------------------
create or replace function public.sync_likes_count()
returns trigger language plpgsql security definer as $$
begin
  if (tg_op = 'INSERT') then
    update public.statuses set likes_count = likes_count + 1 where id = new.status_id;
    return new;
  elsif (tg_op = 'DELETE') then
    update public.statuses set likes_count = greatest(likes_count - 1, 0) where id = old.status_id;
    return old;
  end if;
  return null;
end $$;

drop trigger if exists likes_count_ins on public.likes;
create trigger likes_count_ins after insert on public.likes
  for each row execute function public.sync_likes_count();

drop trigger if exists likes_count_del on public.likes;
create trigger likes_count_del after delete on public.likes
  for each row execute function public.sync_likes_count();

-- ---------------------------------------------------------------------------
-- 5) Storage buckets: user photos/backgrounds + preview thumbnails
--    Files are stored under a "<user_id>/..." path so each user owns a folder.
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
  values ('status-assets', 'status-assets', true)
  on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
  values ('thumbnails', 'thumbnails', true)
  on conflict (id) do nothing;

-- App-owned category backgrounds (Bhakti, Morning, Love, …). Read-only for
-- clients: there is no insert/update/delete policy for this bucket, so only
-- the service_role key (admin / CI) can publish to it. Layout:
--   manifest.json          — {version, categories:[{key, files:[...]}]}
--   thumb/<cat>/<file>.jpg — picker grid
--   full/<cat>/<file>.jpg  — applied to the canvas
-- These used to be bundled in the APK (~126 MB); serving them keeps the app
-- small and lets new backgrounds ship without an app release. Upload images
-- with `--cache-control "max-age=31536000, immutable"` and manifest.json with
-- `max-age=300`, so devices fetch each image once but pick up new ones fast.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
  values (
    'category-backgrounds', 'category-backgrounds', true, 5242880,
    array['image/jpeg','image/png','image/webp','application/json']
  )
  on conflict (id) do nothing;

-- Public read (feed images load via URL); writes limited to your own folder.
drop policy if exists assets_read on storage.objects;
create policy assets_read on storage.objects
  for select using ( bucket_id in ('status-assets','thumbnails') );

drop policy if exists assets_insert on storage.objects;
create policy assets_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id in ('status-assets','thumbnails')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists assets_update on storage.objects;
create policy assets_update on storage.objects
  for update to authenticated
  using (
    bucket_id in ('status-assets','thumbnails')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists assets_delete on storage.objects;
create policy assets_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id in ('status-assets','thumbnails')
    and (storage.foldername(name))[1] = auth.uid()::text
  );
