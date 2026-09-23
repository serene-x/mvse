-- Additional makeup and skincare products. Missing formulas remain NULL.

insert into public.products (name, brand, category, summary, finish, coverage, region, data_notes, data_source)
values
-- ============ CONCEALER (5) ============
('Radiant Creamy Concealer', 'NARS', 'concealer',
 'The long-running benchmark concealer: creamy, medium-to-buildable coverage that reads like skin. A frequent "shade twin" reference point because the range is wide and well-known.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Shape Tape Concealer', 'Tarte', 'concealer',
 'A thick, high-coverage concealer with serious staying power. Famously opaque — a little goes further than you think, and it can crease if over-applied on dry under-eyes.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Luminous Silk Face and Under-Eye Concealer', 'Armani Beauty', 'concealer',
 'The concealer sibling of Luminous Silk: lightweight, radiant, medium coverage. Popular in shade-twin videos because the numbering lines up with the foundation range.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Hydrating Camo Concealer', 'e.l.f. Cosmetics', 'concealer',
 'A budget concealer with satin finish and honest mid-level coverage — the hydrating counterpart to the fuller-coverage original Camo. Strong value; shade range is decent but not luxury-tier wide.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Liquid Touch Brightening Concealer', 'Rare Beauty', 'concealer',
 'A light-coverage, blendable concealer meant to brighten rather than blank out. Pairs with the Liquid Touch foundation shade system, which makes cross-matching easier.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

-- ============ FOUNDATION (5) ============
('Halo Glow Liquid Filter', 'e.l.f. Cosmetics', 'foundation',
 'Part tint, part highlighter: a glow-first complexion product with light coverage. The much-cited budget alternative to luxury "filter" products — expect sheen, not coverage.',
 'glow', null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Light Reflecting Foundation', 'NARS', 'foundation',
 'A medium-coverage foundation aimed at a lit-from-within finish. Its claim to fame is looking good on camera; its honest caveat is that luminous foundations flatter texture less on very oily skin.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Backstage Face & Body Foundation', 'Dior', 'foundation',
 'A thin, flexible, water-light foundation originally built for editorial use. Light-medium coverage that layers without caking — a favorite for "skin but better" days.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Super Serum Skin Tint SPF 40', 'Ilia', 'foundation',
 'A sheer tint that splits the difference between skincare, light coverage, and SPF 40. Honest framing: SPF in makeup only works at full-face sunscreen doses, which almost nobody applies — treat the SPF as a bonus, not your protection.',
 null, 'sheer',
 'US', 'SPF value appears in the product name; sunscreen actives not yet ingested from a verified source. Formulas can change over time and by market.', 'seed'),

('Triclone Skin Tech Medium Coverage Foundation', 'Haus Labs', 'foundation',
 'A medium-coverage foundation with a large shade range and a skin-care-adjacent pitch. The finish sits between natural and radiant; the shade breadth is the practical headline.',
 null, 'medium',
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

-- ============ BLUSH (3) ============
('Cloud Paint', 'Glossier', 'blush',
 'A sheer gel-cream blush designed to be applied with fingers and to be hard to overdo. Buildable, low-stakes color — the trade-off is modest longevity on oilier skin.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Camo Liquid Blush', 'e.l.f. Cosmetics', 'blush',
 'A pigment-dense liquid blush at a drugstore price — the widely cited budget answer to premium liquid blushes. Start with one dot; it is genuinely concentrated.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('BeachPlease Lip + Cheek Cream Blush', 'Tower 28', 'blush',
 'A balm-textured cream blush from a brand that formulates for sensitive, reactive skin. Sheer-to-medium color with a dewy finish; doubles on lips.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

-- ============ LIP (4) ============
('Lip Sleeping Mask', 'Laneige', 'lip',
 'An occlusive overnight lip balm in a tub — the product that made "lip mask" a category. It works by sealing moisture in while you sleep; the flavors are the fun part, the occlusion is the science part.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Peptide Lip Treatment', 'Rhode', 'lip',
 'A glossy, cushiony lip balm with a peptide story. Honest read: it is a very good balm with great texture; evidence that topical peptides change lips in any lasting way is thin.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Almost Lipstick — Black Honey', 'Clinique', 'lip',
 'The decades-old sheer plum balm that periodically goes viral because it genuinely flatters a wide range of complexions. Sheer, buildable, low-commitment color.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Honey Infused Lip Oil', 'Gisou', 'lip',
 'A honey-based lip oil with high shine and light conditioning. It is a gloss-plus-care hybrid; the honey is a signature texture and scent more than a proven treatment.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

-- ============ CLEANSER (3) ============
('Hydrating Facial Cleanser', 'CeraVe', 'cleanser',
 'The non-foaming sibling of the Foaming Cleanser, aimed at normal-to-dry skin. Cleans gently without the squeaky-stripped feeling; a dermatologist-list staple.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Low pH Good Morning Gel Cleanser', 'COSRX', 'cleanser',
 'A mildly acidic gel cleanser formulated to sit near skin''s own pH — the point being less disruption to the barrier than alkaline cleansers. Light, no-frills, morning-friendly.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Superfood Antioxidant Cleanser', 'Youth To The People', 'cleanser',
 'A gel cleanser with a green-juice ingredient story. The honest core: it is a well-liked, effective gentle cleanser — the antioxidant marketing matters less than the fact that it rinses clean without tightness.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

-- ============ MOISTURIZER (4) ============
('Hydro Boost Water Gel', 'Neutrogena', 'moisturizer',
 'A lightweight gel moisturizer built around hyaluronic acid. A dependable pick for oily or combination skin that wants hydration without heaviness. Note: some versions contain fragrance — check your tub.',
 null, null,
 'US', 'Multiple variants exist (fragranced and fragrance-free, gel and gel-cream). Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Cicaplast Baume B5+', 'La Roche-Posay', 'moisturizer',
 'A thick, panthenol-rich recovery balm for irritated, over-exfoliated, or just-angry skin. Not a daily-glow product — it is the thing you reach for when your barrier needs a weekend off.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Ultra Repair Cream', 'First Aid Beauty', 'moisturizer',
 'A rich cream for dry and easily-irritated skin, built around colloidal oatmeal. The original is positioned as fragrance-free, but the line includes scented variants (e.g. Coconut) — check the specific tub. Unglamorous, reliable comfort cream.',
 null, null,
 'US', 'Multiple variants exist (fragrance-free original and scented editions). Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Ultra Facial Cream', 'Kiehl''s', 'moisturizer',
 'A mid-weight daily moisturizer that suits a wide range of skin types — the definition of a safe default. Does its job without fuss; costs more than functionally similar drugstore creams.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

-- ============ SUNSCREEN (3) ============
('Unseen Sunscreen SPF 40', 'Supergoop!', 'sunscreen',
 'A clear, gel-like chemical sunscreen with a primer-ish velvet finish and no white cast — built to make daily wear painless, which is the single most important sunscreen feature.',
 null, null,
 'US', 'SPF value appears in the product name. US chemical-filter actives appear on the drug-facts label; not yet ingested from a verified source.', 'seed'),

('UV Clear Broad-Spectrum SPF 46', 'EltaMD', 'sunscreen',
 'The dermatologist-office classic for acne-prone and sensitive skin: a light sunscreen with niacinamide that layers politely with actives. Worth knowing: despite the zinc-oxide reputation, the common US formula is a hybrid (zinc oxide plus a chemical filter), not mineral-only. The "Clear" is about how skin tolerates it, not invisibility — deeper skin tones should patch-test for cast.',
 null, null,
 'US', 'SPF value appears in the product name. Filters and percentages appear on the drug-facts label (the US formula pairs zinc oxide with a chemical filter); not yet ingested from a verified source.', 'seed'),

('Relief Sun: Rice + Probiotics SPF 50+', 'Beauty of Joseon', 'sunscreen',
 'A Korean chemical sunscreen beloved for feeling like a light moisturizer rather than sunscreen. Honest note: it uses newer UV filters approved in Korea/EU that are not yet FDA-approved, so US-sold versions may differ — check what you''re actually buying.',
 null, null,
 'KR', 'SPF value appears in the product name. Korean and US-market versions can differ (US filter regulations); full ingredient list not yet ingested from a verified source.', 'seed'),

-- ============ SERUM (4) ============
('Alpha Arbutin 2% + HA', 'The Ordinary', 'serum',
 'A budget serum targeting dark spots and post-blemish marks with alpha arbutin, a gentler relative of hydroquinone. Evidence is decent but not dramatic — expect gradual fading over weeks, and wear sunscreen or it''s pointless.',
 null, null,
 'US', 'Concentration appears in the product name. Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Advanced Snail 96 Mucin Power Essence', 'COSRX', 'serum',
 'The viral snail-mucin essence: a slippy hydrating layer that leaves skin looking plump and glazed. The hydration is real; claims beyond hydration-and-soothing are ahead of the evidence.',
 null, null,
 'KR', 'The 96 in the name refers to the brand''s stated mucin filtrate percentage. Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Watermelon Glow Niacinamide Dew Drops', 'Glow Recipe', 'serum',
 'A hybrid serum-highlighter that gives a glassy sheen with niacinamide along for the ride. Read it as makeup-adjacent glow first, treatment second — the dew is instant, the skincare is a slower background story.',
 null, null,
 'US', 'Niacinamide percentage is not stated in the product name. Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Discoloration Correcting Serum', 'Good Molecules', 'serum',
 'A very affordable serum aimed at dark spots and uneven tone, known for pairing tranexamic acid with niacinamide. A patient-person''s product: results, when they come, take weeks.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

-- ============ EXFOLIANT / TREATMENT / EYE / OIL / MASK (6) ============
('Lactic Acid 10% + HA', 'The Ordinary', 'exfoliant',
 'A leave-on AHA that''s a step gentler than glycolic at the same strength, with hyaluronic acid to soften the blow. Same rules as all acids: start slowly, and sunscreen is non-negotiable.',
 null, null,
 'US', 'Concentration appears in the product name. Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Adapalene Gel 0.1% Acne Treatment', 'Differin', 'treatment',
 'A prescription-strength retinoid that went over-the-counter — one of the best-evidenced acne actives you can buy without a dermatologist. Expect a possible purge in the first weeks; that is the drug working, not failing. It is an actual OTC drug, not a cosmetic.',
 null, null,
 'US', 'Adapalene 0.1% is the labeled drug-facts active (stated in the product name). This is an FDA OTC drug product rather than a cosmetic.', 'seed'),

('Mighty Patch Original', 'Hero Cosmetics', 'treatment',
 'Hydrocolloid stickers that flatten surface-level whiteheads overnight by absorbing fluid — and stop you from picking, which is half the benefit. They do nothing for deep or cystic bumps, and no patch "draws out" a blind pimple.',
 null, null,
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Caffeine Solution 5% + EGCG', 'The Ordinary', 'eye_cream',
 'A watery eye serum with a high caffeine dose aimed at puffiness and dark circles. Honest expectations: caffeine can temporarily de-puff; dark circles from genetics, anatomy, or thin skin will not budge for any topical.',
 null, null,
 'US', 'Concentration appears in the product name. Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('100% Plant-Derived Squalane', 'The Ordinary', 'face_oil',
 'A single-ingredient moisturizing oil that mimics skin''s own sebum — light, stable, and fragrance-free. One of the least likely oils to irritate; also one of the least exciting, which is rather the point.',
 null, null,
 'US', 'The 100% refers to the stated single-ingredient composition (from the product name).', 'seed'),

('Water Sleeping Mask', 'Laneige', 'mask',
 'An overnight gel mask that is functionally a big drink of lightweight hydration you rinse off in the morning. Pleasant, effective-for-a-night glow; it is a moisturizer format, not a treatment.',
 null, null,
 'KR', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed')

on conflict (brand, name) do nothing;

-- Key-ingredient links for the new products.
-- Only ingredients already in the verified catalog; concentration_pct ONLY
-- where the product name states it.
insert into public.product_key_ingredients
  (product_id, ingredient_id, role_in_product, form_note, concentration_pct, concentration_source, display_order, data_source)
select p.id, i.id, v.role_in_product, v.form_note, v.concentration_pct, v.concentration_source, v.display_order, 'seed'
from (values
  ('The Ordinary', 'Lactic Acid 10% + HA', 'Lactic Acid',
   'The exfoliant: a gentler AHA than glycolic at like-for-like strength.', null, 10.0, 'product_name', 0),
  ('The Ordinary', 'Lactic Acid 10% + HA', 'Sodium Hyaluronate',
   'Hydration support to offset exfoliation dryness.', null, null, null, 1),
  ('The Ordinary', 'Alpha Arbutin 2% + HA', 'Sodium Hyaluronate',
   'The HA in the name — hydration support alongside the arbutin.', null, null, null, 1),
  ('The Ordinary', '100% Plant-Derived Squalane', 'Squalane',
   'The entire formula: a skin-identical moisturizing lipid.', 'Single-ingredient product.', 100.0, 'product_name', 0),
  ('Glow Recipe', 'Watermelon Glow Niacinamide Dew Drops', 'Niacinamide',
   'The skincare half of this glow hybrid — percentage not stated in the name.', null, null, null, 0),
  ('Neutrogena', 'Hydro Boost Water Gel', 'Sodium Hyaluronate',
   'The headline humectant this product is built around.', null, null, null, 0),
  ('La Roche-Posay', 'Cicaplast Baume B5+', 'Panthenol',
   'The B5 of the name: the soothing, barrier-recovery centerpiece.', null, null, null, 0),
  ('EltaMD', 'UV Clear Broad-Spectrum SPF 46', 'Zinc Oxide',
   'Mineral UV filter (exact percentage lives on the drug-facts label).', null, null, null, 0),
  ('EltaMD', 'UV Clear Broad-Spectrum SPF 46', 'Niacinamide',
   'The skincare add-in UV Clear is known for.', null, null, null, 1)
) as v(brand, product_name, inci, role_in_product, form_note, concentration_pct, concentration_source, display_order)
join public.products p on p.brand = v.brand and p.name = v.product_name
join public.ingredients i on i.inci_name = v.inci
on conflict (product_id, ingredient_id) do nothing;

-- Representative shades for the new makeup (sampled, not exhaustive).
-- Hex values are editorial approximations, same practice as seed.sql.
with p as (
  select id, name, brand from public.products
)
insert into public.product_shades (product_id, shade_name, hex_color)
select p.id, s.shade_name, s.hex_color
from p
join (values
  ('NARS', 'Radiant Creamy Concealer', 'Chantilly', '#F2DCC4'),
  ('NARS', 'Radiant Creamy Concealer', 'Custard',   '#EBC79C'),
  ('NARS', 'Radiant Creamy Concealer', 'Ginger',    '#D8A87A'),
  ('NARS', 'Radiant Creamy Concealer', 'Caramel',   '#C08B5C'),
  ('NARS', 'Radiant Creamy Concealer', 'Cacao',     '#7A4A2E'),
  ('Tarte', 'Shape Tape Concealer', '12N Fair Neutral',        '#F0D3B2'),
  ('Tarte', 'Shape Tape Concealer', '27H Light-Medium Honey',  '#DDB284'),
  ('Tarte', 'Shape Tape Concealer', '42S Tan Sand',            '#B9855A'),
  ('Tarte', 'Shape Tape Concealer', '57G Rich Golden',         '#6E4326'),
  ('Armani Beauty', 'Luminous Silk Face and Under-Eye Concealer', '2',   '#F3DDC2'),
  ('Armani Beauty', 'Luminous Silk Face and Under-Eye Concealer', '4.5', '#E4BE96'),
  ('Armani Beauty', 'Luminous Silk Face and Under-Eye Concealer', '6',   '#C79A6E'),
  ('Armani Beauty', 'Luminous Silk Face and Under-Eye Concealer', '10',  '#77482B'),
  ('e.l.f. Cosmetics', 'Hydrating Camo Concealer', 'Fair Beige',    '#EFD2B4'),
  ('e.l.f. Cosmetics', 'Hydrating Camo Concealer', 'Light Sand',    '#E4BE94'),
  ('e.l.f. Cosmetics', 'Hydrating Camo Concealer', 'Tan Walnut',    '#B98860'),
  ('e.l.f. Cosmetics', 'Hydrating Camo Concealer', 'Deep Chestnut', '#6B4128'),
  ('Rare Beauty', 'Liquid Touch Brightening Concealer', '120N', '#EFCDB1'),
  ('Rare Beauty', 'Liquid Touch Brightening Concealer', '240W', '#C99672'),
  ('Rare Beauty', 'Liquid Touch Brightening Concealer', '410C', '#5A3320'),
  ('e.l.f. Cosmetics', 'Halo Glow Liquid Filter', 'Fair',   '#EED2B6'),
  ('e.l.f. Cosmetics', 'Halo Glow Liquid Filter', 'Light',  '#E3BC92'),
  ('e.l.f. Cosmetics', 'Halo Glow Liquid Filter', 'Medium', '#C69770'),
  ('e.l.f. Cosmetics', 'Halo Glow Liquid Filter', 'Tan',    '#A97C50'),
  ('e.l.f. Cosmetics', 'Halo Glow Liquid Filter', 'Deep',   '#66401F'),
  ('NARS', 'Light Reflecting Foundation', 'Oslo',       '#F4DCC3'),
  ('NARS', 'Light Reflecting Foundation', 'Stromboli',  '#D9AC7E'),
  ('NARS', 'Light Reflecting Foundation', 'Macao',      '#A5744A'),
  ('NARS', 'Light Reflecting Foundation', 'New Guinea', '#5C3826'),
  ('Dior', 'Backstage Face & Body Foundation', '0N',  '#F4DFC5'),
  ('Dior', 'Backstage Face & Body Foundation', '2N',  '#E2BE97'),
  ('Dior', 'Backstage Face & Body Foundation', '3WP', '#C89C74'),
  ('Dior', 'Backstage Face & Body Foundation', '6N',  '#7B4E2E'),
  ('Ilia', 'Super Serum Skin Tint SPF 40', 'ST2 Tulum',    '#F0D7BA'),
  ('Ilia', 'Super Serum Skin Tint SPF 40', 'ST7 Formosa',  '#DBAE81'),
  ('Ilia', 'Super Serum Skin Tint SPF 40', 'ST12 Kokkini', '#AF7D51'),
  ('Ilia', 'Super Serum Skin Tint SPF 40', 'ST16 Kea',     '#6D4527'),
  ('Haus Labs', 'Triclone Skin Tech Medium Coverage Foundation', '120', '#F1D6B8'),
  ('Haus Labs', 'Triclone Skin Tech Medium Coverage Foundation', '240', '#DFB78B'),
  ('Haus Labs', 'Triclone Skin Tech Medium Coverage Foundation', '360', '#BC8A5C'),
  ('Haus Labs', 'Triclone Skin Tech Medium Coverage Foundation', '480', '#8A5733'),
  ('Glossier', 'Cloud Paint', 'Puff', '#F0A3B2'),
  ('Glossier', 'Cloud Paint', 'Beam', '#E98F77'),
  ('Glossier', 'Cloud Paint', 'Dusk', '#C58A6C'),
  ('Glossier', 'Cloud Paint', 'Haze', '#B25E75'),
  ('e.l.f. Cosmetics', 'Camo Liquid Blush', 'Coral Crush',   '#E77E62'),
  ('e.l.f. Cosmetics', 'Camo Liquid Blush', 'Pinky Promise', '#E68CA0'),
  ('e.l.f. Cosmetics', 'Camo Liquid Blush', 'Berry Bliss',   '#B04A66'),
  ('Tower 28', 'BeachPlease Lip + Cheek Cream Blush', 'Golden Hour', '#DE8E6B'),
  ('Tower 28', 'BeachPlease Lip + Cheek Cream Blush', 'Happy Hour',  '#D96E71'),
  ('Tower 28', 'BeachPlease Lip + Cheek Cream Blush', 'Magic Hour',  '#B26059'),
  ('Laneige', 'Lip Sleeping Mask', 'Berry',      '#C77085'),
  ('Laneige', 'Lip Sleeping Mask', 'Gummy Bear', '#E08D93'),
  ('Laneige', 'Lip Sleeping Mask', 'Vanilla',    '#E7C9A8'),
  ('Rhode', 'Peptide Lip Treatment', 'Unscented',        '#EFE3D8'),
  ('Rhode', 'Peptide Lip Treatment', 'Salted Caramel',   '#C98F63'),
  ('Rhode', 'Peptide Lip Treatment', 'Watermelon Slice', '#E58E96'),
  ('Clinique', 'Almost Lipstick — Black Honey', 'Black Honey', '#6E3B44'),
  ('Gisou', 'Honey Infused Lip Oil', 'Honey',              '#C98F5A'),
  ('Gisou', 'Honey Infused Lip Oil', 'Watermelon Sunrise', '#E2848E')
) as s(brand, name, shade_name, hex_color)
  on s.brand = p.brand and s.name = p.name
on conflict (product_id, shade_name) do nothing;
