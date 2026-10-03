-- ============================================================================
-- Keep public content alive forever, even if its author's auth row disappears.
--
-- Before: statuses.user_id was `not null ... on delete cascade`, so deleting an
-- auth user (anonymous-user cleanup, a GDPR delete, a manual purge in the
-- dashboard) silently deleted every status they had ever posted — public ones
-- included. That is almost certainly how a batch of seeded templates vanished
-- from the Home feed.
--
-- After: the status survives and becomes unowned (user_id = null).
--
-- Safe to re-run. Run in: Supabase dashboard -> SQL Editor -> New query -> Run.
-- ============================================================================

-- 1) A status no longer requires an owner.
alter table public.statuses
  alter column user_id drop not null;

-- 2) Swap cascade for "set null". The constraint name is Postgres's default for
--    this column; look it up rather than assuming, so this works on a database
--    whose constraint was named differently.
do $$
declare
  fk_name text;
begin
  select conname into fk_name
    from pg_constraint
   where conrelid = 'public.statuses'::regclass
     and contype  = 'f'
     and conkey   = array[
           (select attnum from pg_attribute
             where attrelid = 'public.statuses'::regclass and attname = 'user_id')
         ]::smallint[];

  if fk_name is not null then
    execute format('alter table public.statuses drop constraint %I', fk_name);
  end if;

  alter table public.statuses
    add constraint statuses_user_id_fkey
    foreign key (user_id) references auth.users(id) on delete set null;
end $$;

-- 3) RLS is unchanged and still correct:
--      select: ( is_public or user_id = auth.uid() )
--    An orphaned PUBLIC row stays visible to everyone (what we want). An
--    orphaned PRIVATE row matches nobody, since `null = auth.uid()` is null,
--    so it is retained but invisible — it cannot leak to another user.
--
--    Trade-off worth knowing: an orphaned row can no longer be edited or
--    deleted from the app either, because update/delete also key off
--    `user_id = auth.uid()`. Moderate those from the dashboard.

-- 4) Likes intentionally keep `on delete cascade` on user_id: a like from a
--    deleted account should disappear, and the likes_count trigger keeps the
--    displayed total honest when it does.
