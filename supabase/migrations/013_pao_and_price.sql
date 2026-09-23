-- period-after-opening (PAO) tracking + optional price for a simple
-- cost-per-use readout. Both live on the user's owned-products rows.

alter table public.user_owned_products
  add column if not exists opened_at date,
  add column if not exists pao_months int check (pao_months is null or pao_months between 1 and 60),
  add column if not exists price_paid numeric(8,2),        -- what the user paid (optional)
  add column if not exists uses_count int not null default 0; -- simple cost-per-use tally

-- Default PAO (months) hint per category, so we can suggest a sensible value
-- when the user hasn't set one. Advisory only.
alter table public.products
  add column if not exists default_pao_months int;

update public.products set default_pao_months = case category
  when 'sunscreen'   then 12
  when 'serum'       then 6
  when 'treatment'   then 6
  when 'exfoliant'   then 12
  when 'moisturizer' then 12
  when 'cleanser'    then 12
  when 'toner'       then 12
  when 'mask'        then 12
  when 'eye_cream'   then 6
  when 'face_oil'    then 12
  when 'foundation'  then 12
  when 'concealer'   then 12
  when 'blush'       then 24
  when 'lip'         then 18
  else 12
end
where default_pao_months is null;
