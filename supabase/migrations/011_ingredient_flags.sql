-- per-user ingredient profile overrides.
--
-- The app INFERS ingredient sensitivities from logged reactions (computed on
-- the fly from user_product_feedback + product_key_ingredients). This table
-- stores the user's manual corrections and confirmations, which always WIN
-- over inference — the user can confirm a suspected trigger, dismiss a wrong
-- guess, or add a known allergy the app couldn't have inferred.

create table if not exists public.user_ingredient_flags (
  user_id uuid not null references auth.users(id) on delete cascade,
  ingredient_id uuid not null references public.ingredients(id) on delete cascade,
  -- 'trigger'   : user-confirmed personal trigger / known allergy (red)
  -- 'tolerated' : user-confirmed fine for them (green), overrides generic flags
  -- 'dismissed' : "stop suggesting this as a trigger" (mutes inference)
  flag text not null check (flag in ('trigger','tolerated','dismissed')),
  note text,
  created_at timestamptz not null default now(),
  primary key (user_id, ingredient_id)
);
create index if not exists user_ingredient_flags_user_idx
  on public.user_ingredient_flags(user_id);

alter table public.user_ingredient_flags enable row level security;

drop policy if exists "ing flags select self" on public.user_ingredient_flags;
create policy "ing flags select self" on public.user_ingredient_flags
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "ing flags insert self" on public.user_ingredient_flags;
create policy "ing flags insert self" on public.user_ingredient_flags
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "ing flags update self" on public.user_ingredient_flags;
create policy "ing flags update self" on public.user_ingredient_flags
  for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "ing flags delete self" on public.user_ingredient_flags;
create policy "ing flags delete self" on public.user_ingredient_flags
  for delete to authenticated using (auth.uid() = user_id);
