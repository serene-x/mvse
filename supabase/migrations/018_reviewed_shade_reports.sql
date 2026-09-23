-- Public evidence contains only reviewed public creator reports, never wear notes.
create table if not exists public.reviewed_shade_reports (
  source_url text primary key check (source_url ~ '^https://www[.]tiktok[.]com/@[^/]+/video/[0-9]+$'),
  person text not null,
  shades jsonb not null check (jsonb_typeof(shades) = 'object'),
  evidence_note text not null,
  reviewed_at timestamptz not null default now()
);
alter table public.reviewed_shade_reports enable row level security;
revoke all on public.reviewed_shade_reports from anon, authenticated;
grant select on public.reviewed_shade_reports to anon, authenticated;
drop policy if exists read_reviewed_shade_reports on public.reviewed_shade_reports;
create policy read_reviewed_shade_reports on public.reviewed_shade_reports
  for select to anon, authenticated using (true);
