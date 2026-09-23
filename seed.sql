-- Beauty shopping app — seed data
-- 20 real products across foundation / blush / lip categories.
-- Sephora URLs use the canonical /product/<slug>-P<id> format from sephora.com listings.
-- Note: Sephora rotates product IDs occasionally; verify slugs/IDs against the live site
-- before relying on these in production. Run after schema.sql.

insert into public.products (name, brand, category, sephora_url, ulta_url) values
-- ============ FOUNDATION (8) ============
('Pro Filt''r Soft Matte Longwear Liquid Foundation', 'Fenty Beauty',         'foundation',
  'https://www.sephora.com/product/pro-filt-r-soft-matte-longwear-foundation-P87985432',
  'https://www.ulta.com/p/pro-filtr-soft-matte-longwear-foundation-pimprod2018905'),

('Liquid Touch Weightless Foundation',                'Rare Beauty',          'foundation',
  'https://www.sephora.com/product/rare-beauty-by-selena-gomez-liquid-touch-weightless-foundation-P468090',
  'https://www.ulta.com/p/liquid-touch-weightless-foundation-pimprod2018901'),

('Sheer Glow Foundation',                              'NARS',                 'foundation',
  'https://www.sephora.com/product/sheer-glow-foundation-P78477',
  'https://www.ulta.com/p/sheer-glow-foundation-xlsImpprod6260015'),

('Double Wear Stay-in-Place Foundation',               'Estée Lauder',         'foundation',
  'https://www.sephora.com/product/double-wear-stay-in-place-foundation-P233720',
  'https://www.ulta.com/p/double-wear-stay-in-place-foundation-xlsImpprod3290034'),

('Hollywood Flawless Filter',                          'Charlotte Tilbury',    'foundation',
  'https://www.sephora.com/product/hollywood-flawless-filter-P427417',
  null),

('Luminous Silk Perfect Glow Flawless Foundation',     'Armani Beauty',        'foundation',
  'https://www.sephora.com/product/luminous-silk-foundation-P133900',
  'https://www.ulta.com/p/luminous-silk-foundation-xlsImpprod6620025'),

('HD Skin Undetectable Longwear Foundation',           'Make Up For Ever',     'foundation',
  'https://www.sephora.com/product/hd-skin-undetectable-longwear-foundation-P468001',
  'https://www.ulta.com/p/hd-skin-undetectable-longwear-foundation-pimprod2027044'),

('Shape Tape Radiant Medium Coverage Foundation',      'Tarte',                'foundation',
  'https://www.sephora.com/product/tarte-shape-tape-radiant-medium-coverage-foundation-P462598',
  'https://www.ulta.com/p/shape-tape-radiant-medium-coverage-foundation-pimprod2030075'),

-- ============ BLUSH (6) ============
('Soft Pinch Liquid Blush',                            'Rare Beauty',          'blush',
  'https://www.sephora.com/product/rare-beauty-by-selena-gomez-soft-pinch-liquid-blush-P468309',
  'https://www.ulta.com/p/soft-pinch-liquid-blush-pimprod2018899'),

('Lip + Cheek',                                        'Milk Makeup',          'blush',
  'https://www.sephora.com/product/lip-cheek-P416478',
  'https://www.ulta.com/p/lip-cheek-xlsImpprod15881035'),

('Blush',                                              'NARS',                 'blush',
  'https://www.sephora.com/product/blush-P3622',
  'https://www.ulta.com/p/blush-xlsImpprod6260038'),

('Major Headlines Double-Take Crème & Powder Blush Duo','Patrick Ta',          'blush',
  'https://www.sephora.com/product/patrick-ta-major-headlines-double-take-creme-powder-blush-duo-P467872',
  null),

('Dew Blush Liquid Blush',                             'Saie',                 'blush',
  'https://www.sephora.com/product/saie-dew-blush-P481215',
  null),

('Cheek to Chic Blush',                                'Charlotte Tilbury',    'blush',
  'https://www.sephora.com/product/cheek-to-chic-P396394',
  null),

-- ============ LIP (6) ============
('Gloss Bomb Universal Lip Luminizer',                 'Fenty Beauty',         'lip',
  'https://www.sephora.com/product/gloss-bomb-universal-lip-luminizer-P39833301',
  'https://www.ulta.com/p/gloss-bomb-universal-lip-luminizer-pimprod2018906'),

('Soft Pinch Tinted Lip Oil',                          'Rare Beauty',          'lip',
  'https://www.sephora.com/product/rare-beauty-by-selena-gomez-soft-pinch-tinted-lip-oil-P509677',
  'https://www.ulta.com/p/soft-pinch-tinted-lip-oil-pimprod2034547'),

('Matte Revolution Lipstick',                          'Charlotte Tilbury',    'lip',
  'https://www.sephora.com/product/matte-revolution-lipstick-P398153',
  null),

('Addict Lip Glow',                                    'Dior',                 'lip',
  'https://www.sephora.com/product/dior-addict-lip-glow-P376683',
  'https://www.ulta.com/p/dior-addict-lip-glow-pimprod2034245'),

('Retro Matte Lipstick — Ruby Woo',                    'MAC Cosmetics',        'lip',
  'https://www.sephora.com/product/retro-matte-lipstick-P425657',
  'https://www.ulta.com/p/retro-matte-lipstick-xlsImpprod3870107'),

('Lip Butter Balm',                                    'Summer Fridays',       'lip',
  'https://www.sephora.com/product/summer-fridays-lip-butter-balm-P481221',
  'https://www.ulta.com/p/lip-butter-balm-pimprod2030538');

-- A few representative shades per product (sampled, not exhaustive)
with p as (
  select id, name, brand from public.products
)
insert into public.product_shades (product_id, shade_name, hex_color)
select p.id, s.shade_name, s.hex_color
from p
join (values
  -- Fenty Pro Filt'r (50-shade range; sampling fair/light/medium/deep/deepest)
  ('Fenty Beauty',      'Pro Filt''r Soft Matte Longwear Liquid Foundation', '110',  '#F2D6BD'),
  ('Fenty Beauty',      'Pro Filt''r Soft Matte Longwear Liquid Foundation', '230',  '#E2B894'),
  ('Fenty Beauty',      'Pro Filt''r Soft Matte Longwear Liquid Foundation', '345',  '#B8845B'),
  ('Fenty Beauty',      'Pro Filt''r Soft Matte Longwear Liquid Foundation', '440',  '#7B4A2D'),
  ('Fenty Beauty',      'Pro Filt''r Soft Matte Longwear Liquid Foundation', '498',  '#3A1F12'),
  -- Rare Beauty Liquid Touch
  ('Rare Beauty',       'Liquid Touch Weightless Foundation',                '120N',  '#EFCDB1'),
  ('Rare Beauty',       'Liquid Touch Weightless Foundation',                '240W',  '#C99672'),
  ('Rare Beauty',       'Liquid Touch Weightless Foundation',                '410C',  '#5A3320'),
  -- NARS Sheer Glow
  ('NARS',              'Sheer Glow Foundation',                             'Mont Blanc',  '#F5DAC1'),
  ('NARS',              'Sheer Glow Foundation',                             'Deauville',   '#E7C29B'),
  ('NARS',              'Sheer Glow Foundation',                             'Syracuse',    '#8C5A3B'),
  -- Estée Lauder Double Wear
  ('Estée Lauder',      'Double Wear Stay-in-Place Foundation',              '1N1 Ivory Nude', '#EFCDA8'),
  ('Estée Lauder',      'Double Wear Stay-in-Place Foundation',              '3N1 Ivory Beige','#D2A983'),
  ('Estée Lauder',      'Double Wear Stay-in-Place Foundation',              '6W1 Sandalwood', '#9B6940'),
  -- Charlotte Tilbury Hollywood Flawless Filter
  ('Charlotte Tilbury', 'Hollywood Flawless Filter',                         '2 Fair',      '#F1D2B5'),
  ('Charlotte Tilbury', 'Hollywood Flawless Filter',                         '4 Medium',    '#D6A37A'),
  ('Charlotte Tilbury', 'Hollywood Flawless Filter',                         '7 Deep',      '#5A3622'),
  -- Armani Luminous Silk
  ('Armani Beauty',     'Luminous Silk Perfect Glow Flawless Foundation',    '5.5',  '#E9C09C'),
  ('Armani Beauty',     'Luminous Silk Perfect Glow Flawless Foundation',    '7',    '#C99974'),
  ('Armani Beauty',     'Luminous Silk Perfect Glow Flawless Foundation',    '11.5', '#7A4A30'),
  -- MUFE HD Skin
  ('Make Up For Ever',  'HD Skin Undetectable Longwear Foundation',          '1N00', '#F4D9BD'),
  ('Make Up For Ever',  'HD Skin Undetectable Longwear Foundation',          '2Y32', '#D2A075'),
  ('Make Up For Ever',  'HD Skin Undetectable Longwear Foundation',          '4N75', '#5C3520'),
  -- Tarte Shape Tape Radiant
  ('Tarte',             'Shape Tape Radiant Medium Coverage Foundation',     '12N Fair Neutral',  '#EECBA8'),
  ('Tarte',             'Shape Tape Radiant Medium Coverage Foundation',     '34S Medium Sand',   '#C29268'),
  ('Tarte',             'Shape Tape Radiant Medium Coverage Foundation',     '53N Deep Neutral',  '#5F3A24'),
  -- Rare Beauty Soft Pinch Liquid Blush
  ('Rare Beauty',       'Soft Pinch Liquid Blush',                           'Joy',         '#D45B6E'),
  ('Rare Beauty',       'Soft Pinch Liquid Blush',                           'Hope',        '#E47B8A'),
  ('Rare Beauty',       'Soft Pinch Liquid Blush',                           'Bliss',       '#C67269'),
  ('Rare Beauty',       'Soft Pinch Liquid Blush',                           'Happy',       '#A93E54'),
  -- Milk Makeup Lip + Cheek
  ('Milk Makeup',       'Lip + Cheek',                                       'Werk',        '#C66A6E'),
  ('Milk Makeup',       'Lip + Cheek',                                       'Quickie',     '#E5908A'),
  ('Milk Makeup',       'Lip + Cheek',                                       'Rally',       '#9C3D45'),
  -- NARS Blush
  ('NARS',              'Blush',                                             'Orgasm',      '#D88578'),
  ('NARS',              'Blush',                                             'Deep Throat', '#E2A28E'),
  ('NARS',              'Blush',                                             'Dolce Vita',  '#B47368'),
  -- Patrick Ta Major Headlines
  ('Patrick Ta',        'Major Headlines Double-Take Crème & Powder Blush Duo', 'She''s Baby',  '#E89A9C'),
  ('Patrick Ta',        'Major Headlines Double-Take Crème & Powder Blush Duo', 'She''s Iconic','#C25E64'),
  -- Saie Dew Blush
  ('Saie',              'Dew Blush Liquid Blush',                            'Sunkissed',   '#E37B5C'),
  ('Saie',              'Dew Blush Liquid Blush',                            'Poppy',       '#D74A4A'),
  -- Charlotte Tilbury Cheek to Chic
  ('Charlotte Tilbury', 'Cheek to Chic Blush',                               'Pillow Talk', '#D78A8A'),
  ('Charlotte Tilbury', 'Cheek to Chic Blush',                               'Ecstasy',     '#C76068'),
  -- Fenty Gloss Bomb
  ('Fenty Beauty',      'Gloss Bomb Universal Lip Luminizer',                'Fenty Glow',  '#B96E5E'),
  ('Fenty Beauty',      'Gloss Bomb Universal Lip Luminizer',                'Fussy',       '#E090A1'),
  ('Fenty Beauty',      'Gloss Bomb Universal Lip Luminizer',                'Hot Chocolit','#6E3825'),
  -- Rare Beauty Soft Pinch Tinted Lip Oil
  ('Rare Beauty',       'Soft Pinch Tinted Lip Oil',                         'Joy',         '#C95A6A'),
  ('Rare Beauty',       'Soft Pinch Tinted Lip Oil',                         'Hope',        '#E08089'),
  ('Rare Beauty',       'Soft Pinch Tinted Lip Oil',                         'Believe',     '#9B384A'),
  -- Charlotte Tilbury Matte Revolution
  ('Charlotte Tilbury', 'Matte Revolution Lipstick',                         'Pillow Talk', '#B5736B'),
  ('Charlotte Tilbury', 'Matte Revolution Lipstick',                         'Walk of Shame','#A8403C'),
  ('Charlotte Tilbury', 'Matte Revolution Lipstick',                         'Red Carpet Red','#B71C26'),
  -- Dior Addict Lip Glow
  ('Dior',              'Addict Lip Glow',                                   '001 Pink',    '#E089A1'),
  ('Dior',              'Addict Lip Glow',                                   '004 Coral',   '#E8826A'),
  ('Dior',              'Addict Lip Glow',                                   '012 Rosewood','#B86F73'),
  -- MAC Ruby Woo
  ('MAC Cosmetics',     'Retro Matte Lipstick — Ruby Woo',                   'Ruby Woo',    '#B81E2A'),
  -- Summer Fridays Lip Butter Balm
  ('Summer Fridays',    'Lip Butter Balm',                                   'Pink Sugar',  '#D7858E'),
  ('Summer Fridays',    'Lip Butter Balm',                                   'Brown Sugar', '#9B5C4D'),
  ('Summer Fridays',    'Lip Butter Balm',                                   'Vanilla',     '#E1B89A')
) as s(brand, name, shade_name, hex_color)
  on s.brand = p.brand and s.name = p.name
on conflict (product_id, shade_name) do nothing;
