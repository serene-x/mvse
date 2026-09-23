-- Ingredient library and initial skincare catalogue.
-- Concentrations are recorded only when stated in the product name.
-- Inserts preserve existing rows; sourced full formulas live in the app bundle.

insert into public.ingredients
  (inci_name, common_name, what_it_does, functions, simple_explanation, science_explanation,
   evidence_level, evidence_summary, is_cell_turnover_active, active_family,
   pairs_well, pairs_poorly,
   pregnancy_caution, pregnancy_note, is_fragrance, is_essential_oil, common_allergen,
   comedogenic_rating, comedogenic_note, data_source)
values

('Niacinamide', 'Niacinamide (Vitamin B3)',
 'Calms, strengthens the skin barrier, and helps with oil and uneven tone',
 '["barrier support","brightening","oil regulation","soothing"]'::jsonb,
 'A form of vitamin B3 that''s one of the most reliable all-rounders in skincare. It helps your skin hold onto moisture, calms redness, and over time can soften dark spots and large-looking pores. It''s gentle enough that almost everyone can use it.',
 'Niacinamide is a precursor to NAD+/NADP+, coenzymes involved in skin cell energy metabolism. Clinical studies support its role in increasing ceramide synthesis (barrier repair), reducing transepidermal water loss, and inhibiting melanosome transfer (pigmentation). Most studies use 2–5%; benefits above ~5% are less clearly established and very high concentrations can sting some people.',
 'well_established',
 'One of the better-studied cosmetic ingredients, with multiple randomized controlled trials at 2–5% for barrier function and pigmentation. Claims tied to very high percentages (10%+) outrun the evidence — more is not clearly better.',
 false, 'vitamin_b3',
 '[{"with":"Retinol","note":"Niacinamide can buffer retinoid irritation — a well-liked pairing."},{"with":"Ascorbic Acid","note":"Fine together in modern formulas — the old incompatibility claim is outdated (see claims)."},{"with":"Azelaic Acid","note":"Commonly combined for redness and tone."}]'::jsonb,
 '[]'::jsonb,
 false, null, false, false, false,
 null, null, 'seed'),

('Retinol', 'Retinol (Vitamin A)',
 'Speeds up skin renewal — the best-evidenced over-the-counter anti-aging and acne-prevention active',
 '["cell turnover","anti-aging","acne","texture"]'::jsonb,
 'A form of vitamin A that tells your skin to renew itself faster. It''s the most proven over-the-counter ingredient for smoothing fine lines and keeping pores clear — but it asks for patience: expect an adjustment period of dryness or flaking, and results on a scale of months, not days.',
 'Retinol is converted in skin to retinaldehyde and then retinoic acid, which binds nuclear retinoic-acid receptors and alters gene expression: increased epidermal turnover, increased collagen synthesis, decreased collagen breakdown. It''s less potent than prescription tretinoin (conversion is inefficient) but the same pathway. Efficacy is concentration- and formulation-dependent, and many products don''t disclose their percentage.',
 'well_established',
 'Decades of research on the retinoid pathway, including randomized trials of retinol itself for photoaging. The main honest caveats: over-the-counter strengths vary widely, brands often hide the concentration, and stability/packaging matter a lot.',
 true, 'retinoid',
 '[{"with":"Niacinamide","note":"Helps buffer irritation."},{"with":"Hyaluronic Acid","note":"Hydration support during the adjustment period."},{"with":"Azelaic Acid","note":"Often recommended together — azelaic can help with the redness while both work on texture and marks."}]'::jsonb,
 '[{"with":"Benzoyl Peroxide","note":"BP can deactivate retinol — use in separate routines (e.g. BP in the morning, retinol at night)."},{"with":"Ascorbic Acid","note":"Generally better in separate routines (vitamin C in the morning, retinol at night) — different pH preferences and stacked irritation."},{"with":"Glycolic Acid","note":"Stacking strong exfoliation with a retinoid the same night raises irritation risk — alternate nights instead."}]'::jsonb,
 true, 'Retinoids are commonly avoided during pregnancy and breastfeeding — check with your doctor.',
 false, false, false,
 null, null, 'seed'),

('Ascorbic Acid', 'Vitamin C (L-ascorbic acid)',
 'Antioxidant that brightens and supports collagen — the pure, best-studied form of vitamin C',
 '["antioxidant","brightening","collagen support"]'::jsonb,
 'The pure form of vitamin C. It helps defend skin from everyday environmental stress, gradually brightens dark spots, and supports your skin''s own collagen production. The catch: it''s famously unstable — it degrades with light and air, which is why formulation and packaging matter as much as the ingredient itself.',
 'L-ascorbic acid is a potent antioxidant and a required cofactor for collagen cross-linking enzymes (prolyl and lysyl hydroxylase). It also inhibits tyrosinase, reducing melanin production. Penetration requires a low pH (~3.5 or below) and efficacy is concentration-dependent, with most evidence in the 10–20% range. Oxidized (browned) vitamin C is less effective.',
 'well_established',
 'Strong evidence for photoprotection alongside sunscreen and for brightening, mostly at 10–20% in low-pH formulas. Whether a given product delivers depends heavily on its form, concentration, pH, and packaging — many products don''t disclose enough to judge.',
 true, 'vitamin_c',
 '[{"with":"Ferulic Acid","note":"Stabilizes vitamin C and adds antioxidant effect — a well-studied trio with vitamin E."},{"with":"Tocopherol","note":"Vitamin E regenerates oxidized vitamin C — they reinforce each other."},{"with":"Zinc Oxide","note":"Antioxidants + sunscreen in the morning is a well-supported combination."}]'::jsonb,
 '[{"with":"Benzoyl Peroxide","note":"BP oxidizes vitamin C — separate routines."},{"with":"Retinol","note":"Generally separate (C in the morning, retinol at night) — different pH preferences and stacked irritation."}]'::jsonb,
 false, null, false, false, false,
 null, null, 'seed'),

('Sodium Ascorbyl Phosphate', 'Vitamin C derivative (SAP)',
 'A gentler, more stable — but less proven — form of vitamin C',
 '["antioxidant","brightening"]'::jsonb,
 'A vitamin C derivative that''s much more stable and gentler than the pure form. Your skin has to convert it to actual vitamin C to use it, and it''s not fully clear how efficiently that happens — so think of it as the milder cousin: easier to live with, but with weaker evidence behind it.',
 'SAP is a salt form that must be enzymatically converted to ascorbic acid in skin. It has some direct evidence for acne (antimicrobial/sebum-oxidation effects at ~5%) but far less evidence than L-ascorbic acid for brightening and photoprotection. Conversion efficiency in vivo is not well characterized.',
 'promising',
 'Reasonable early evidence, especially for acne, but claims that it matches pure vitamin C are not supported — the honest answer is that derivatives are better tolerated and less proven.',
 false, 'vitamin_c',
 '[]'::jsonb, '[]'::jsonb,
 false, null, false, false, false,
 null, null, 'seed'),

('Glycolic Acid', 'Glycolic acid (AHA)',
 'Chemical exfoliant that smooths texture and brightens by dissolving the glue between dead skin cells',
 '["exfoliant","cell turnover","brightening","texture"]'::jsonb,
 'An alpha-hydroxy acid (AHA) that loosens the bonds holding dead cells on your skin''s surface, so they shed instead of building up. Skin looks smoother and brighter. The smallest AHA molecule, so it penetrates deepest — which also makes it the most likely AHA to sting or irritate.',
 'Glycolic acid disrupts corneodesmosome adhesion in the stratum corneum, accelerating desquamation. Effects are strongly pH- and concentration-dependent — free-acid concentration at the formula''s pH, not the labeled percentage, determines strength. Studies also suggest dermal effects (collagen stimulation) with sustained use. Increases photosensitivity: sunscreen is non-negotiable.',
 'well_established',
 'AHAs are among the best-studied exfoliants. The honest caveat: the labeled percentage doesn''t tell you the effective strength without knowing the formula''s pH, which brands rarely publish.',
 true, 'aha',
 '[{"with":"Hyaluronic Acid","note":"Hydration alongside exfoliation."}]'::jsonb,
 '[{"with":"Retinol","note":"Same-night stacking raises irritation risk — alternate nights."},{"with":"Salicylic Acid","note":"Layering multiple exfoliants invites over-exfoliation — pick one per routine."}]'::jsonb,
 false, null, false, false, false,
 null, null, 'seed'),

('Lactic Acid', 'Lactic acid (AHA)',
 'A gentler AHA exfoliant that also hydrates',
 '["exfoliant","cell turnover","hydration","brightening"]'::jsonb,
 'An alpha-hydroxy acid like glycolic, but with a larger molecule — so it works closer to the surface and is noticeably gentler. It also happens to be part of your skin''s own natural moisturizing system, which is why it exfoliates and hydrates at the same time. A good first AHA.',
 'Lactic acid promotes desquamation like other AHAs but penetrates less deeply due to molecular size, and is a component of the skin''s natural moisturizing factor (NMF), contributing humectant effects. Same pH/free-acid caveats as all AHAs; same photosensitivity warning.',
 'well_established',
 'Well-supported as a gentler AHA; most evidence at 5–12%. As with all AHAs, effective strength depends on pH, which is usually undisclosed.',
 true, 'aha',
 '[]'::jsonb,
 '[{"with":"Glycolic Acid","note":"Doubling up on AHAs risks over-exfoliation."}]'::jsonb,
 false, null, false, false, false,
 null, null, 'seed'),

('Salicylic Acid', 'Salicylic acid (BHA)',
 'Oil-soluble exfoliant that gets inside pores — the go-to for blackheads and congestion',
 '["exfoliant","cell turnover","acne","pore care"]'::jsonb,
 'A beta-hydroxy acid (BHA) and the only common exfoliant that''s oil-soluble — meaning it can travel into oily pores and clear them from the inside, not just polish the surface. That''s why it''s the classic pick for blackheads, congestion, and breakout-prone skin. It''s also mildly anti-inflammatory.',
 'Salicylic acid is lipophilic, allowing penetration into the pilosebaceous unit where it exfoliates the follicle lining (comedolytic). It''s also anti-inflammatory (related to aspirin). Most OTC evidence is at 0.5–2%. Unlike AHAs it does not significantly increase photosensitivity, though sunscreen remains wise.',
 'well_established',
 'Decades of use and solid trial evidence at 0.5–2% for acne and congestion. Honest caveat: it treats and prevents clogs; it won''t do much for deep cystic acne on its own.',
 true, 'bha',
 '[{"with":"Niacinamide","note":"Calming support alongside exfoliation."}]'::jsonb,
 '[{"with":"Glycolic Acid","note":"Layering multiple exfoliants invites over-exfoliation."},{"with":"Retinol","note":"Same-night stacking raises irritation risk for many people."}]'::jsonb,
 true, 'Low-strength rinse-off and spot use is generally considered lower-risk, but high-dose or extensive salicylic acid is commonly avoided during pregnancy — check with your doctor.',
 false, false, false,
 null, null, 'seed'),

('Azelaic Acid', 'Azelaic acid',
 'Multi-tasker for redness, breakouts, and dark marks — unusually gentle for how much it does',
 '["acne","rosacea","brightening","anti-inflammatory","cell turnover"]'::jsonb,
 'A gentle multi-tasker made by yeast that lives on everyone''s skin. It calms redness, fights breakout-causing bacteria, helps keep pores clear, and fades the dark marks breakouts leave behind — all while being one of the least irritating actives. Chronically underrated.',
 'Azelaic acid is a dicarboxylic acid with antimicrobial activity against C. acnes, normalizes keratinization (mildly comedolytic), inhibits tyrosinase (post-inflammatory pigmentation), and has anti-inflammatory effects via reduced reactive oxygen species. Prescription strengths are 15–20%; over-the-counter products are typically 10% and have less direct trial evidence (see the claims on specific products).',
 'well_established',
 'Prescription-strength azelaic acid (15–20%) has strong evidence for acne and rosacea. Over-the-counter 10% versions rely mostly on extrapolation — probably helpful, but the direct evidence is thinner. Effects also depend on the formulation''s delivery.',
 true, 'azelaic',
 '[{"with":"Retinol","note":"A commonly recommended pair — azelaic can calm the redness while both target texture and post-blemish marks."},{"with":"Niacinamide","note":"Complementary for redness and tone."}]'::jsonb,
 '[]'::jsonb,
 false, null, false, false, false,
 null, null, 'seed'),

('Sodium Hyaluronate', 'Hyaluronic acid',
 'Water-binding hydrator that temporarily plumps the skin''s surface',
 '["humectant","hydration"]'::jsonb,
 'A molecule your body already makes that can hold many times its weight in water — like a sponge for your skin''s surface. It gives an immediate hydrated, plumper look. What it doesn''t do: permanently change your skin or "fill" wrinkles from a jar. The effect lasts as long as the hydration does.',
 'Hyaluronic acid is a glycosaminoglycan humectant. Topically, most of it (especially high-molecular-weight forms) stays in the stratum corneum, binding water and improving surface hydration and the appearance of fine lines. Lower-molecular-weight fractions penetrate somewhat better; claims of deep dermal effects from topical application are weakly supported. In very dry air it can theoretically draw water from skin — pairing with an occlusive moisturizer helps.',
 'well_established',
 'Extremely well-established as a surface hydrator. The marketing often overshoots: the plumping is real but temporary, and "1000x its weight in water" varies by molecular weight.',
 false, 'humectant',
 '[{"with":"Retinol","note":"Hydration support during retinoid adjustment."},{"with":"Glycerin","note":"Humectants stack well."}]'::jsonb,
 '[]'::jsonb,
 false, null, false, false, false,
 0, null, 'seed'),

('Glycerin', 'Glycerin',
 'The unglamorous workhorse of hydration',
 '["humectant","hydration","barrier support"]'::jsonb,
 'The least trendy, most dependable hydrator in skincare — it''s in almost everything for a reason. It pulls water into the top layer of your skin and helps it stay there. If a moisturizer works, glycerin is often quietly doing a lot of the heavy lifting.',
 'Glycerin (glycerol) is a small-molecule humectant that mimics the skin''s natural moisturizing factor, improves stratum corneum hydration, and supports barrier recovery. It''s one of the most consistently supported moisturizing ingredients in the literature, often outperforming trendier humectants in head-to-head measurements.',
 'well_established',
 'About as solid as cosmetic evidence gets. No real controversy.',
 false, 'humectant',
 '[]'::jsonb, '[]'::jsonb,
 false, null, false, false, false,
 0, null, 'seed'),

('Ceramide NP', 'Ceramides',
 'Skin-identical lipids that patch the mortar of your skin barrier',
 '["barrier support","moisturizing"]'::jsonb,
 'If your skin barrier is a brick wall, ceramides are the mortar between the bricks. Your skin makes them naturally, but dryness, over-exfoliation, and age deplete them. Adding them back in a moisturizer helps the wall hold water in and keep irritants out. Great for dry or sensitive skin.',
 'Ceramides are the dominant lipid class of the stratum corneum''s intercellular matrix. Topical ceramide-containing moisturizers (usually combined with cholesterol and fatty acids) improve barrier function and reduce transepidermal water loss in studies, including in eczema-prone skin. The specific ratio matters more than any single ceramide.',
 'well_established',
 'Good evidence that ceramide-containing moisturizers help barrier function. Which specific ceramide blend is "best" is less settled.',
 false, 'lipid',
 '[]'::jsonb, '[]'::jsonb,
 false, null, false, false, false,
 null, null, 'seed'),

('Panthenol', 'Panthenol (Pro-Vitamin B5)',
 'Soothing hydrator that helps irritated skin recover',
 '["soothing","humectant","barrier support"]'::jsonb,
 'A form of vitamin B5 that hydrates and genuinely calms. It''s a favorite supporting ingredient for irritated, freshly-exfoliated, or just-cranky skin — think of it as a glass of water and a blanket for your skin barrier.',
 'Panthenol converts to pantothenic acid in skin, acts as a humectant, and has documented effects on barrier repair and reduction of irritation and redness in clinical studies. Often used post-procedure in dermatology.',
 'well_established',
 'Well-supported for soothing and barrier recovery. Modest in effect — a helper, not a hero.',
 false, 'humectant',
 '[]'::jsonb, '[]'::jsonb,
 false, null, false, false, false,
 null, null, 'seed'),

('Palmitoyl Pentapeptide-4', 'Peptides (Matrixyl)',
 'Messenger molecules that may nudge skin to build collagen — promising, less proven than retinoids',
 '["anti-aging","collagen support"]'::jsonb,
 'Peptides are tiny protein fragments that act like text messages to your skin cells — this one is meant to say "make more collagen." Early research is encouraging, and they''re very gentle. But if retinoids are a proven prescription, peptides are still a promising rookie: worth trying, especially if retinoids are too harsh for you, but don''t expect retinoid-level evidence.',
 'Palmitoyl pentapeptide-4 is a matrikine — a collagen fragment analog hypothesized to signal fibroblast collagen synthesis. Some controlled studies show improvement in photoaged skin, but the body of independent, well-powered trials is much smaller than for retinoids, and penetration of peptides through the stratum corneum is an open question.',
 'promising',
 'Genuinely promising, genuinely under-proven. Most supporting studies are small or industry-funded. A reasonable choice for retinoid-intolerant skin, with honest expectations.',
 false, 'peptide',
 '[{"with":"Niacinamide","note":"Gentle, compatible pairing."}]'::jsonb,
 '[]'::jsonb,
 false, null, false, false, false,
 null, null, 'seed'),

('Soluble Collagen', 'Collagen (topical)',
 'A surface moisturizer — cannot rebuild the collagen in your skin',
 '["moisturizing","film former"]'::jsonb,
 'Collagen molecules are huge — roughly 600 times too big to fit through your skin, like pushing a basketball through the eye of a needle. So collagen in a cream mostly sits on the surface, holding water and softening skin. That''s a fine thing for a moisturizer to do — it just can''t rebuild the collagen inside your skin. Ingredients that actually signal your skin to make its own collagen: retinoids, vitamin C, and (more tentatively) peptides.',
 'Native collagen (~300 kDa) cannot penetrate the stratum corneum, whose practical cutoff is around 500 Da. Topical collagen and hydrolyzed collagen act as humectants and film formers, improving surface hydration and temporarily smoothing appearance. There is no credible mechanism or clinical evidence for topical collagen incorporating into dermal collagen.',
 'limited',
 'Well-established as a moisturizing agent; unsupported for "rebuilding" or "replenishing" your skin''s collagen. The size problem is basic physiology.',
 false, 'moisturizer',
 '[]'::jsonb, '[]'::jsonb,
 false, null, false, false, false,
 null, null, 'seed'),

('Ferulic Acid', 'Ferulic acid',
 'Plant antioxidant that famously makes vitamin C formulas stronger and more stable',
 '["antioxidant","stabilizer"]'::jsonb,
 'A plant-derived antioxidant that''s rarely the star but often the best supporting actor: added to vitamin C serums, it stabilizes the formula and boosts the overall antioxidant effect. The famous C + E + ferulic trio exists because these three genuinely reinforce each other.',
 'Ferulic acid is a phenolic antioxidant. Research (notably on the 15% L-ascorbic acid + 1% alpha-tocopherol + 0.5% ferulic acid combination) found it stabilizes both vitamins and roughly doubles the measured photoprotection of the combination versus vitamin C alone.',
 'promising',
 'Good supporting evidence in combination formulas; less studied as a solo active.',
 false, 'antioxidant',
 '[{"with":"Ascorbic Acid","note":"Stabilizes it and increases the combined antioxidant effect."},{"with":"Tocopherol","note":"Part of the well-studied C+E+ferulic trio."}]'::jsonb,
 '[]'::jsonb,
 false, null, false, false, false,
 null, null, 'seed'),

('Tocopherol', 'Vitamin E',
 'Oil-soluble antioxidant and skin conditioner',
 '["antioxidant","moisturizing"]'::jsonb,
 'An oil-soluble antioxidant your skin naturally stocks in its outer layers. In products it defends oils (and your skin) from oxidation and adds a moisturizing touch. It works best in a team — especially with vitamin C, which recharges it after it neutralizes a free radical.',
 'Alpha-tocopherol is the predominant antioxidant of the stratum corneum, protecting lipids from peroxidation. Topically it''s photoprotective in combination with vitamin C (they regenerate each other). Evidence for vitamin E alone reducing scars is weak, despite the folk reputation.',
 'well_established',
 'Solid as an antioxidant and moisturizer, especially in combinations. The scar-healing reputation is not well supported.',
 false, 'antioxidant',
 '[{"with":"Ascorbic Acid","note":"They regenerate each other — a true synergy."}]'::jsonb,
 '[]'::jsonb,
 false, null, false, false, false,
 2, 'Old comedogenicity scales rate tocopherol around 2/5, but those rabbit-ear assays are contested and formula context matters more. Your own experience wins.', 'seed'),

('Zinc Oxide', 'Zinc oxide (mineral UV filter)',
 'Broad-spectrum mineral sunscreen filter',
 '["uv filter","soothing"]'::jsonb,
 'A mineral that sits on your skin and absorbs UV light across both UVA and UVB — one of the most complete single sun filters we have, and gentle enough that it''s the classic pick for sensitive skin and babies. Its one honest drawback: it can leave a white cast, especially on deeper skin tones.',
 'Zinc oxide attenuates UV primarily by absorption (not, as commonly repeated, mostly reflection), covering UVB through UVA1. It''s photostable and has a strong safety record. Particle size determines the trade-off between white cast and transparency; "sheer" formulas use smaller or coated particles.',
 'well_established',
 'One of the best-validated UV filters. White cast on medium-deep and deep skin tones is a real, common frustration worth checking reviews for.',
 false, 'uv_filter',
 '[{"with":"Ascorbic Acid","note":"Morning antioxidant + sunscreen is a well-supported combination."}]'::jsonb,
 '[]'::jsonb,
 false, null, false, false, false,
 null, null, 'seed'),

('Parfum', 'Fragrance',
 'Makes products smell nice; the most common cause of cosmetic skin allergies',
 '["fragrance"]'::jsonb,
 '"Parfum" or "fragrance" on a label is an umbrella term for a blend that can contain dozens of scent chemicals. Most people tolerate fragrance fine — but it''s the most common cause of allergic reactions to cosmetics. If your skin is sensitive or you''re playing detective about a reaction, fragrance is one of the usual suspects. Personal experience matters most: tolerating it elsewhere is real evidence in your favor.',
 'Fragrance mixtures are the leading cause of allergic contact dermatitis from cosmetics; specific sensitizers (e.g. linalool and limonene oxidation products, eugenol, geraniol) are patch-tested individually in dermatology. Reactions are individual-specific sensitizations — population statistics say little about any one person.',
 'well_established',
 'That fragrance is the top cosmetic allergen is well documented. That it will bother YOU is not a given — most fragrance users never react.',
 false, null,
 '[]'::jsonb, '[]'::jsonb,
 false, null, true, false, true,
 null, null, 'seed'),

('Linalool', 'Linalool (fragrance component)',
 'Floral scent molecule found in lavender; can sensitize when oxidized',
 '["fragrance"]'::jsonb,
 'A naturally occurring scent molecule — it''s a big part of why lavender smells like lavender. Fresh linalool is fairly benign; the trouble is that it oxidizes with air exposure, and oxidized linalool is a known skin sensitizer. It''s listed separately on labels because enough people react to it.',
 'Linalool itself is a weak sensitizer, but its air-oxidation products (hydroperoxides) are common patch-test positives. EU regulation requires it to be declared when above threshold concentrations. Reaction rates in patch-tested populations are meaningful but the tested population skews toward people with existing dermatitis.',
 'well_established',
 'The oxidation-sensitization mechanism is well documented. As always, personal tolerance data beats the population statistic.',
 false, null,
 '[]'::jsonb, '[]'::jsonb,
 false, null, true, false, true,
 null, null, 'seed'),

('Limonene', 'Limonene (fragrance component)',
 'Citrus scent molecule; can sensitize when oxidized',
 '["fragrance"]'::jsonb,
 'The molecule that makes citrus peel smell like citrus. Like its cousin linalool, it''s mostly harmless when fresh but forms sensitizing compounds as it oxidizes in air — which is why it gets its own line on ingredient labels and why old, long-opened products are more likely to bother sensitive skin.',
 'D-limonene''s oxidation products (notably limonene hydroperoxides) are established contact allergens and standard patch-test allergens in dermatology. Declared separately under EU rules above threshold concentrations.',
 'well_established',
 'Well-documented sensitizer in oxidized form. Most people never react.',
 false, null,
 '[]'::jsonb, '[]'::jsonb,
 false, null, true, false, true,
 null, null, 'seed'),

('Cocos Nucifera (Coconut) Oil', 'Coconut oil',
 'Rich occlusive oil — great for very dry skin and hair, a gamble for clog-prone faces',
 '["occlusive","emollient"]'::jsonb,
 'A rich plant oil that''s excellent at sealing moisture into very dry skin and hair. Its reputation for clogging pores comes from old lab tests, and real faces vary a lot: some breakout-prone people react badly to it, others use it happily for years. If you''re acne-prone, treat it as "worth caution," not "banned" — and let your own track record decide.',
 'Coconut oil is predominantly medium-chain saturated triglycerides (lauric acid-rich). It scores high (4/5) on classic rabbit-ear comedogenicity assays, but those assays poorly predict human facial response, and human data is sparse. Ironically, lauric acid has some evidence of activity against C. acnes. Individual response genuinely varies.',
 'well_established',
 'Well-established as an emollient/occlusive. The comedogenicity question is honestly unsettled — the rating comes from contested older assays.',
 false, null,
 '[]'::jsonb, '[]'::jsonb,
 false, null, false, false, false,
 4, 'The 4/5 rating comes from older animal-model assays that are contested and don''t reliably predict human faces. If you personally tolerate it, your data overrides this number.', 'seed'),

('Dimethicone', 'Dimethicone (silicone)',
 'Silky-feel protectant that smooths texture and locks in moisture — much maligned, well tolerated',
 '["occlusive","emollient","texture"]'::jsonb,
 'The silicone that gives primers and moisturizers their silky glide. It forms a light, breathable mesh on the skin that smooths texture and slows water loss. Despite its scary online reputation, it''s one of the least likely ingredients to irritate or clog — it''s even used in scar treatment sheets.',
 'Dimethicone is a large, inert polymer that cannot penetrate skin. It''s non-comedogenic in testing, hypoallergenic, FDA-monographed as a skin protectant, and silicone sheeting is a first-line dermatology option for scar management. The "suffocates skin" claim is mechanistically wrong — the film is permeable to water vapor and oxygen.',
 'well_established',
 'The safety and tolerability data is strong; the online fear is not evidence-based (see claims).',
 false, null,
 '[]'::jsonb, '[]'::jsonb,
 false, null, false, false, false,
 0, null, 'seed'),

('Benzoyl Peroxide', 'Benzoyl peroxide',
 'The bacteria-killer for inflamed breakouts — effective, bleaches fabric, plays badly with some actives',
 '["acne","antimicrobial"]'::jsonb,
 'The most effective over-the-counter ingredient for red, angry breakouts. It releases oxygen inside pores, which kills acne bacteria — and unlike antibiotics, bacteria can''t become resistant to it. Honest downsides: it''s drying, it bleaches towels and pillowcases, and it deactivates some other actives if layered together.',
 'Benzoyl peroxide is oxidizing and bactericidal against C. acnes with no documented resistance, plus mildly keratolytic. Strong trial evidence at 2.5–10%; 2.5% is nearly as effective as 10% with less irritation. It oxidizes tretinoin/retinol and vitamin C on contact — separate applications by routine.',
 'well_established',
 'First-line in acne guidelines. The 2.5%-is-enough finding is one of skincare''s best-kept secrets.',
 false, 'benzoyl_peroxide',
 '[{"with":"Niacinamide","note":"Can help offset dryness and irritation."}]'::jsonb,
 '[{"with":"Retinol","note":"Oxidizes/deactivates it — use BP in the morning and retinol at night, or alternate days."},{"with":"Ascorbic Acid","note":"Oxidizes vitamin C — separate routines."}]'::jsonb,
 false, null, false, false, false,
 null, null, 'seed'),

('Bakuchiol', 'Bakuchiol',
 'Plant-derived "retinol alternative" — genuinely interesting, still lightly proven',
 '["anti-aging","antioxidant"]'::jsonb,
 'A plant extract marketed as "natural retinol." It''s not a retinoid at all — different molecule, different pathway — but a few small studies found retinol-like improvements with less irritation, which made it famous. The honest read: promising early results, far less total evidence than retinoids, worth a look if retinoids are off the table for you (including possibly during pregnancy — but ask your doctor, the safety data is thin too).',
 'Bakuchiol is a meroterpene from Psoralea corylifolia. In vitro it modulates some retinoid-adjacent gene expression without binding retinoic acid receptors. A small randomized double-blind trial found comparable photoaging improvement to 0.5% retinol at 12 weeks with less flaking, but the trial count and sizes remain small.',
 'promising',
 'A handful of small studies versus decades of retinoid research. "Comparable to retinol" is an overreach of the current data; "encouraging" is fair.',
 false, null,
 '[]'::jsonb, '[]'::jsonb,
 false, 'Often suggested as a pregnancy-safe retinoid alternative, but its own pregnancy safety data is minimal — check with your doctor.',
 false, false, false,
 null, null, 'seed'),

('Squalane', 'Squalane',
 'Feather-light moisturizing oil that mimics skin''s own sebum',
 '["emollient","moisturizing"]'::jsonb,
 'A lightweight, odorless oil that''s the shelf-stable cousin of squalene, a moisturizer your skin produces naturally. Because it''s so similar to what skin already makes, it absorbs easily and suits almost everyone, including many oily and sensitive skins. One of the safest "just add moisture" picks.',
 'Squalane is hydrogenated squalene (originally shark-derived, now typically from sugarcane or olives), a stable, non-polar emollient. It''s biocompatible with sebum, non-sensitizing, and generally regarded as low-comedogenic, though formal human comedogenicity data is limited.',
 'well_established',
 'Uncontroversial emollient with a strong tolerability record.',
 false, 'emollient',
 '[]'::jsonb, '[]'::jsonb,
 false, null, false, false, false,
 0, null, 'seed'),

('Centella Asiatica Extract', 'Centella (cica)',
 'Soothing plant extract beloved for calming stressed skin',
 '["soothing","barrier support","antioxidant"]'::jsonb,
 'An herb (also called cica or tiger grass) that K-beauty made famous for calming irritated skin. Its active compounds have real research behind wound-healing and soothing effects, though "how much is in this product" is usually a mystery. A gentle, reasonable pick for reactive skin.',
 'Centella''s triterpenes (asiaticoside, madecassoside, asiatic and madecassic acids) have documented effects on collagen synthesis and inflammation in wound-healing research. Cosmetic evidence is decent for soothing/barrier support, but extract standardization varies wildly between products and is rarely disclosed.',
 'promising',
 'The isolated compounds are reasonably studied; whole-extract cosmetic products vary too much to generalize. Concentration is almost never disclosed.',
 false, null,
 '[]'::jsonb, '[]'::jsonb,
 false, null, false, false, false,
 null, null, 'seed'),

('Zinc PCA', 'Zinc PCA',
 'Zinc salt aimed at oil control — modest evidence',
 '["oil regulation","soothing"]'::jsonb,
 'A combination of zinc and a natural moisturizing molecule (PCA), usually added to help with oiliness and shine. There''s some lab support for zinc calming oil production, but the topical human evidence is thin — treat "controls sebum" as a plausible maybe, not a promise.',
 'Zinc PCA pairs zinc''s in-vitro 5-alpha-reductase inhibition (sebum pathway) and antimicrobial properties with the humectant PCA. Direct clinical trials of topical zinc PCA for sebum reduction are sparse; most support is extrapolated from in-vitro work or oral zinc studies.',
 'limited',
 'Plausible mechanism, thin direct evidence. It won''t hurt; whether it visibly helps oiliness is uncertain.',
 false, null,
 '[]'::jsonb, '[]'::jsonb,
 false, null, false, false, false,
 null, null, 'seed')

on conflict (inci_name) do nothing;

-- Skincare catalog starter set (real products; INCI lists intentionally
-- NULL until ingested from a verifiable source)
insert into public.products (name, brand, category, summary, region, data_notes, data_source)
values
('Niacinamide 10% + Zinc 1%', 'The Ordinary', 'serum',
 'A budget serum built around two oil-and-blemish helpers: a high dose of niacinamide with a little zinc. Good for visible pores, shine, and post-blemish marks — though 10% is more niacinamide than most of the supporting research used, so "stronger" isn''t necessarily "better" here.',
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Hyaluronic Acid 2% + B5', 'The Ordinary', 'serum',
 'A simple hydration serum: multiple weights of hyaluronic acid plus soothing panthenol (B5). It makes skin look plumper and feel more comfortable while the hydration lasts — it does not permanently change skin. Works best sealed in with a moisturizer.',
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Glycolic Acid 7% Exfoliating Toner', 'The Ordinary', 'toner',
 'A leave-on exfoliating toner using glycolic acid to smooth texture and add glow over time. Effective strength depends on the formula''s pH, not just the 7% on the label. Start once or twice a week, not nightly — and be serious about sunscreen while using it.',
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Azelaic Acid Suspension 10%', 'The Ordinary', 'treatment',
 'A 10% azelaic acid cream-gel for redness, breakouts, and the marks they leave. Azelaic itself is well-proven — but note the prescription studies used 15–20%, so expectations for a 10% version should be a notch humbler. Texture is famously… silicone-y.',
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Skin Perfecting 2% BHA Liquid Exfoliant', 'Paula''s Choice', 'exfoliant',
 'The cult-classic leave-on salicylic acid exfoliant for blackheads, clogged pores, and uneven texture. 2% is the well-studied over-the-counter strength. Gentle enough for regular use for most, but ease in — daily use from day one is a common way to over-exfoliate.',
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Foaming Facial Cleanser', 'CeraVe', 'cleanser',
 'A gel cleanser for normal-to-oily skin that cleans without stripping, with ceramides and niacinamide along for the ride. Honest note: rinse-off products spend seconds on your skin, so treat the ceramides here as a gentle bonus, not a treatment.',
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Moisturizing Cream', 'CeraVe', 'moisturizer',
 'The big-tub barrier moisturizer built on ceramides, cholesterol, and hyaluronic acid. Unfussy, fragrance-free, and one of the most dermatologist-recommended basics for dry or sensitive skin. Not exciting. Extremely dependable.',
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Resurfacing Retinol Serum', 'CeraVe', 'serum',
 'An entry-level retinol serum cushioned with ceramides and niacinamide, aimed at post-acne marks and texture. CeraVe doesn''t disclose the retinol percentage — so we honestly can''t tell you how strong it is, only that it''s positioned as gentle. A reasonable first retinol.',
 'US', 'Retinol concentration is not disclosed by the brand. Formulas can change over time and by market; full ingredient list not yet ingested from a verified source.', 'seed'),

('Anthelios Melt-In Milk Sunscreen SPF 60', 'La Roche-Posay', 'sunscreen',
 'A high-SPF chemical sunscreen lotion with a milky, blendable texture that''s easy to actually wear daily — which matters more than any other sunscreen spec. US chemical-filter formulas differ from the European version of Anthelios.',
 'US', 'The US and EU Anthelios lines use different UV filters (regional regulation). Active percentages appear on the US drug-facts label; not yet ingested from a verified source.', 'seed'),

('C E Ferulic', 'SkinCeuticals', 'serum',
 'The benchmark vitamin C serum: L-ascorbic acid with vitamin E and ferulic acid, the combination much of the vitamin C research is built on. Priced like a luxury handbag — the honest question isn''t whether it works (the combo is well-studied) but whether cheaper takes on the same trio are close enough for you.',
 'US', 'Formulas can change over time and by market; full ingredient list not yet ingested from a verified source. Vitamin C products also degrade with air and light — freshness matters.', 'seed')

on conflict (brand, name) do nothing;

-- Key-ingredient links (the tappable buttons)
-- concentration_pct ONLY where the product name itself states it.
insert into public.product_key_ingredients
  (product_id, ingredient_id, role_in_product, form_note, concentration_pct, concentration_source, display_order, data_source)
select p.id, i.id, v.role_in_product, v.form_note, v.concentration_pct, v.concentration_source, v.display_order, 'seed'
from (values
  -- The Ordinary Niacinamide 10% + Zinc 1%
  ('The Ordinary', 'Niacinamide 10% + Zinc 1%', 'Niacinamide',
   'The headline act: oil regulation, pores, and post-blemish marks.', null, 10.0, 'product_name', 0),
  ('The Ordinary', 'Niacinamide 10% + Zinc 1%', 'Zinc PCA',
   'Supporting oil-control role — evidence for topical zinc here is modest.', null, 1.0, 'product_name', 1),
  -- The Ordinary Hyaluronic Acid 2% + B5
  ('The Ordinary', 'Hyaluronic Acid 2% + B5', 'Sodium Hyaluronate',
   'The hydrator: binds water at multiple skin depths.', 'Blend of molecular weights (as sodium hyaluronate).', 2.0, 'product_name', 0),
  ('The Ordinary', 'Hyaluronic Acid 2% + B5', 'Panthenol',
   'Soothing, hydrating support.', null, null, null, 1),
  -- The Ordinary Glycolic Acid 7% Exfoliating Toner
  ('The Ordinary', 'Glycolic Acid 7% Exfoliating Toner', 'Glycolic Acid',
   'The exfoliant: dissolves the bonds holding dead surface cells.', 'Effective strength depends on the formula''s pH, which isn''t disclosed — the 7% alone doesn''t tell the whole story.', 7.0, 'product_name', 0),
  -- The Ordinary Azelaic Acid Suspension 10%
  ('The Ordinary', 'Azelaic Acid Suspension 10%', 'Azelaic Acid',
   'The everything-helper: redness, breakouts, and dark marks.', 'Prescription azelaic acid is 15–20%; direct evidence at 10% is thinner.', 10.0, 'product_name', 0),
  -- Paula's Choice 2% BHA
  ('Paula''s Choice', 'Skin Perfecting 2% BHA Liquid Exfoliant', 'Salicylic Acid',
   'The pore-clearer: oil-soluble exfoliation inside the pore.', null, 2.0, 'product_name', 0),
  -- CeraVe Foaming Facial Cleanser
  ('CeraVe', 'Foaming Facial Cleanser', 'Ceramide NP',
   'Barrier-support gesture — limited contact time in a rinse-off product.', 'One of three ceramides in CeraVe''s blend.', null, null, 0),
  ('CeraVe', 'Foaming Facial Cleanser', 'Niacinamide',
   'Soothing support — again, brief contact time in a cleanser.', null, null, null, 1),
  -- CeraVe Moisturizing Cream
  ('CeraVe', 'Moisturizing Cream', 'Ceramide NP',
   'The core of the formula: replenishes barrier lipids.', 'One of three ceramides in CeraVe''s blend.', null, null, 0),
  ('CeraVe', 'Moisturizing Cream', 'Sodium Hyaluronate',
   'Humectant hydration alongside the barrier lipids.', null, null, null, 1),
  ('CeraVe', 'Moisturizing Cream', 'Glycerin',
   'The dependable workhorse humectant.', null, null, null, 2),
  -- CeraVe Resurfacing Retinol Serum
  ('CeraVe', 'Resurfacing Retinol Serum', 'Retinol',
   'The active: texture and post-blemish marks over months.', 'Encapsulated retinol; percentage not disclosed by the brand, so strength is honestly unknowable from the label.', null, null, 0),
  ('CeraVe', 'Resurfacing Retinol Serum', 'Niacinamide',
   'Irritation-buffering support.', null, null, null, 1),
  ('CeraVe', 'Resurfacing Retinol Serum', 'Ceramide NP',
   'Barrier support during retinol adjustment.', null, null, null, 2),
  -- SkinCeuticals C E Ferulic
  ('SkinCeuticals', 'C E Ferulic', 'Ascorbic Acid',
   'The star: pure vitamin C for antioxidant defense and brightening.', 'Pure L-ascorbic acid — the best-studied but least stable form.', null, null, 0),
  ('SkinCeuticals', 'C E Ferulic', 'Tocopherol',
   'Recharges the vitamin C and protects skin lipids.', null, null, null, 1),
  ('SkinCeuticals', 'C E Ferulic', 'Ferulic Acid',
   'Stabilizes the formula and roughly doubles its measured photoprotection.', null, null, null, 2)
) as v(brand, product_name, inci, role_in_product, form_note, concentration_pct, concentration_source, display_order)
join public.products p on p.brand = v.brand and p.name = v.product_name
join public.ingredients i on i.inci_name = v.inci
on conflict (product_id, ingredient_id) do nothing;

-- Name-derived attributes for the existing makeup catalog.
-- Only what the product's own name states (finish/coverage words in the
-- name). Everything else stays NULL until ingested from a real source.
update public.products set finish = 'matte'
  where brand = 'Fenty Beauty' and name like 'Pro Filt''r Soft Matte%' and finish is null;
update public.products set coverage = 'medium'
  where brand = 'Tarte' and name like '%Medium Coverage%' and coverage is null;
update public.products set finish = 'radiant'
  where brand = 'Tarte' and name like 'Shape Tape Radiant%' and finish is null;
update public.products set finish = 'sheer glow'
  where brand = 'NARS' and name = 'Sheer Glow Foundation' and finish is null;
update public.products set coverage = 'sheer'
  where brand = 'NARS' and name = 'Sheer Glow Foundation' and coverage is null;

-- Contested-claim seed (honest framing; sources added in source verification after
-- URL verification)
insert into public.claims (product_id, ingredient_id, claim, reality, confidence, data_source)
select null, i.id, v.claim, v.reality, v.confidence, 'seed'
from (values
  ('Soluble Collagen',
   'Collagen creams rebuild the collagen in your skin.',
   'Collagen molecules are far too large to pass through skin — hundreds of times over the size limit. Topical collagen hydrates the surface, which is nice but temporary. Ingredients with actual evidence for stimulating your own collagen: retinoids, vitamin C, and (more tentatively) peptides.',
   'unsupported'),
  ('Sodium Hyaluronate',
   'Hyaluronic acid fills in and erases wrinkles.',
   'It temporarily plumps the skin surface by binding water, which softens the look of fine lines while the product is on. It does not change skin structure, and the effect ends when the hydration does. Injectable HA fillers are a completely different thing.',
   'mixed'),
  ('Dimethicone',
   'Silicones clog pores and suffocate the skin.',
   'Dimethicone molecules are large, inert, and form a permeable film — water vapor and oxygen pass through. Testing consistently finds it non-comedogenic and very low-irritation; medical-grade silicone is even used on healing scars. The fear is popular, not evidence-based.',
   'unsupported'),
  ('Niacinamide',
   'Niacinamide and vitamin C cancel each other out and shouldn''t be layered.',
   'This comes from 1960s experiments on unstabilized ingredients under high heat — conditions modern formulas don''t experience. Current formulations are generally fine together, and some products deliberately combine them. This one is folklore that outlived its data.',
   'unsupported'),
  ('Bakuchiol',
   'Bakuchiol is a natural retinol with the same results.',
   'It''s not a retinoid — different molecule, different pathway. One small head-to-head trial found comparable photoaging results to 0.5% retinol over 12 weeks with less irritation, which is genuinely encouraging, but that''s a fraction of the evidence behind retinoids. "Promising alternative" is fair; "the same" is not.',
   'mixed'),
  ('Cocos Nucifera (Coconut) Oil',
   'Coconut oil clogs pores — acne-prone people must avoid it.',
   'Its high comedogenicity rating comes from decades-old animal assays that don''t reliably predict human faces. Some acne-prone people do break out from it; others never do. If you''ve used it without trouble, your own experience outranks the rating. If you''re acne-prone and haven''t tried it, patch-testing on the face first is fair caution.',
   'contested')
) as v(inci, claim, reality, confidence)
join public.ingredients i on i.inci_name = v.inci
where not exists (select 1 from public.claims c where c.claim = v.claim);

-- Product-level claim: the azelaic 10% case.
insert into public.claims (product_id, ingredient_id, claim, reality, confidence, data_source)
select p.id, null,
  'This 10% azelaic acid works just like prescription azelaic acid.',
  'The strong azelaic acid evidence (acne, rosacea) mostly comes from prescription 15–20% formulations with different delivery systems. A 10% cosmetic suspension plausibly helps — azelaic acid itself is well-proven — but the direct evidence at this strength and in this vehicle is thinner, and effects depend on formulation, not just the percentage. This can be genuinely hard to predict from the label.',
  'depends_on_formula', 'seed'
from public.products p
where p.brand = 'The Ordinary' and p.name = 'Azelaic Acid Suspension 10%'
  and not exists (
    select 1 from public.claims c
    where c.product_id = p.id and c.claim like 'This 10% azelaic acid works just like%'
  );
