-- Makeup observations and persisted undertone/season estimates.

alter table public.user_product_feedback
  add column if not exists shade_notes jsonb not null default '[]'::jsonb;

alter table public.users
  add column if not exists inferred_undertone text
    check (inferred_undertone in ('warm','cool','neutral','olive') or inferred_undertone is null),
  add column if not exists inferred_undertone_confidence text
    check (inferred_undertone_confidence in ('low','medium','high') or inferred_undertone_confidence is null),
  add column if not exists inferred_season text,
  add column if not exists undertone_reasoning text,
  -- learned finish preferences: {"liked":["matte"],"disliked":["dewy"]}
  add column if not exists finish_prefs jsonb not null default '{}'::jsonb;
