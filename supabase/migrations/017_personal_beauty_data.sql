-- Owner-only personalisation. Guests continue using device storage.
create table if not exists public.user_beauty_data (
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('book', 'shelf')),
  data jsonb not null default '{}'::jsonb check (jsonb_typeof(data) = 'object'),
  updated_at timestamptz not null default now(),
  primary key (user_id, kind)
);
alter table public.user_beauty_data enable row level security;
revoke all on public.user_beauty_data from anon;
grant select, insert, update, delete on public.user_beauty_data to authenticated;
drop policy if exists own_beauty_data on public.user_beauty_data;
create policy own_beauty_data on public.user_beauty_data for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
