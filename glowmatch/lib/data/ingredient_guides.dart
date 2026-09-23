import '../logic/ingredient_identity.dart';

class IngredientGuide {
  final String name, benefit, use, pairs, caution, source;
  final List<String> inci;
  const IngredientGuide(this.name, this.inci, this.benefit, this.use,
      this.pairs, this.caution, this.source);
}

const _aad =
    'https://www.aad.org/public/everyday-care/skin-care-basics/care/skin-care-in-your-20s';
const _moisture =
    'https://www.aad.org/public/everyday-care/skin-care-basics/dry/pick-moisturizer';
const _ha = 'https://www.theinkeylist.com/products/hyaluronic-acid-serum-60ml';
const _cerave =
    'https://www.cerave.com/skincare/moisturizers/moisturizing-cream';

// General ingredient guidance. Product directions always take priority: a
// rinse-off cleanser or strong peel is not used like a serum containing the same ingredient.
const ingredientGuides = <IngredientGuide>[
  IngredientGuide(
      'Hyaluronic acid',
      [
        'hyaluronic acid',
        'sodium hyaluronate',
        'hydrolyzed hyaluronic acid',
        'hydrolyzed sodium hyaluronate',
        'sodium hyaluronate crosspolymer'
      ],
      'A humectant that holds water at the skin surface. Helps dehydrated skin feel more comfortable and temporarily softens the look of fine dry lines. It is a hydrator, not an exfoliating acid.',
      'For a hydrating serum, apply to slightly damp skin after cleansing, then follow with moisturizer. Morning or evening. Damp skin is helpful, not a requirement for every formula.',
      'Works alongside glycerin, ceramides and most actives. Let skin dry before a retinoid or a product whose directions require dry skin.',
      'Do not apply an acid peel to wet skin just because it also contains hyaluronic acid. Follow the finished product’s directions.',
      _ha),
  IngredientGuide(
      'Retinol',
      ['retinol', 'retinal', 'retinaldehyde'],
      'A vitamin A ingredient that can improve uneven texture, fine lines and discoloration with consistent use. Results develop over weeks to months; more frequent application is not always better.',
      'Use at night on dry skin. Start with a few nights a week and increase only if comfortable. Follow the label’s amount and moisturize to reduce dryness. Use daytime sunscreen.',
      'Pair with a simple moisturizer. Vitamin C in the morning and retinol at night is an easy way to use both without layering them.',
      'Exfoliating acids and other retinoids can add irritation. Separate them at first. Avoid retinoids during pregnancy; discuss use while breastfeeding with your clinician.',
      _aad),
  IngredientGuide(
      'Adapalene',
      ['adapalene'],
      'An acne-treatment retinoid that helps prevent clogged pores and treats existing acne. It is used over the acne-prone area, rather than just on individual spots.',
      'For Differin 0.1%, apply a thin layer once daily to clean, dry skin, avoiding eyes, lips and damaged skin. Moisturize and use sunscreen. Improvement may take up to 12 weeks.',
      'Use a gentle cleanser and plain moisturizer. Benzoyl peroxide is compatible with adapalene in designed combination treatments, but can add dryness.',
      'Avoid stacking with other retinoids or exfoliating acids. Do not use during pregnancy. Persistent or severe irritation means stop and seek advice. Follow the medicine label.',
      'https://differin.com/learn/faqs'),
  IngredientGuide(
      'Vitamin C',
      [
        'ascorbic acid',
        'sodium ascorbyl phosphate',
        'ascorbyl glucoside',
        '3-o-ethyl ascorbic acid',
        'magnesium ascorbyl phosphate',
        'tetrahexyldecyl ascorbate'
      ],
      'An antioxidant used for uneven tone and signs of sun damage. Pure ascorbic acid and vitamin C derivatives are different forms; their strength and stability depend on the finished formula.',
      'A vitamin C serum fits well after morning cleansing and before moisturizer and sunscreen. Follow its label for dry or damp application. Vitamin C does not replace sunscreen.',
      'Often formulated with vitamin E and ferulic acid. Retinol can be used in the same routine, commonly vitamin C in the morning and retinol at night.',
      'There is no universal ban on vitamin C with retinol. Acidic vitamin C, exfoliating acids and retinoids can sting when layered. Separate applications if sensitive and follow brand-specific instructions.',
      _aad),
  IngredientGuide(
      'Niacinamide',
      ['niacinamide'],
      'Vitamin B3 supports the moisture barrier and can improve the appearance of uneven tone and excess shine. A higher percentage is not automatically more effective or more comfortable.',
      'Use a serum after cleansing and before moisturizer, morning or evening. When it is already in a moisturizer, use that product normally; a separate serum is optional.',
      'Pairs well with hydrating ingredients. It can support a routine containing retinoids; introduce new products one at a time so reactions are easier to interpret.',
      'Concentrated serums can sting or cause redness. Some brands advise separating their specific niacinamide and pure vitamin C formulas, so check both labels rather than assuming a universal conflict.',
      'https://theordinary.com/en-us/niacinamide-10-zinc-1-serum-100436.html'),
  IngredientGuide(
      'Glycolic acid',
      ['glycolic acid'],
      'An alpha hydroxy acid (AHA) that helps remove dead surface cells for smoother texture and more even-looking tone. Strength, pH and contact time affect how exfoliating it is.',
      'Use a leave-on exfoliant after cleansing, usually in the evening. Begin infrequently and follow with moisturizer. A rinse-off peel has a strict contact time: never leave it on overnight.',
      'Keep the rest of that application simple: gentle cleansing and a barrier-supporting moisturizer. Use broad-spectrum sunscreen during the day.',
      'Avoid adding other exfoliants or retinoids in the same session when starting. Do not use on broken, peeling or irritated skin. AHAs can increase sun sensitivity during use and for a week afterwards.',
      'https://theordinary.com/en-us/glycolic-acid-7-exfoliating-toner-100418.html'),
  IngredientGuide(
      'Lactic acid',
      ['lactic acid'],
      'An AHA that exfoliates the surface and also helps skin retain water. A low amount in a moisturizer may serve a different purpose from a 10% exfoliating serum.',
      'Use an exfoliating serum in the evening as directed, before moisturizer. Start slowly. Do not assume every formula containing lactic acid needs daily exfoliation.',
      'Pair with a simple moisturizer containing glycerin or ceramides and daytime sunscreen.',
      'Separate from other exfoliants and retinoids if irritation occurs. Avoid broken or sensitive, peeling skin. AHAs increase sun sensitivity; keep using sun protection for a week after stopping.',
      'https://theordinary.com/en-us/lactic-acid-10-ha-exfoliator-100426.html'),
  IngredientGuide(
      'Salicylic acid',
      ['salicylic acid', 'betaine salicylate'],
      'Salicylic acid is a BHA used to exfoliate within oily pores and help with blackheads. Betaine salicylate is related, but its percentage is not interchangeable with salicylic acid.',
      'Follow the product type: rinse a cleanser off, but leave a designated leave-on exfoliant on. Start infrequently and moisturize. Small amounts in other products may not provide an exfoliating treatment.',
      'A gentle cleanser, moisturizer and sunscreen are useful companions.',
      'Other exfoliating acids, benzoyl peroxide and retinoids can increase dryness when layered. Introduce separately and reduce frequency if skin becomes sore or flaky.',
      'https://www.paulaschoice.com/skin-perfecting-2pct-bha-liquid-exfoliant/201.html'),
  IngredientGuide(
      'Azelaic acid',
      ['azelaic acid'],
      'Used for blemishes, uneven tone and the appearance of redness. Cosmetic 10% products and prescription strengths are different; benefits and tolerability depend on the formulation.',
      'Use a small amount on clean skin as directed, avoiding eyes and lips. Begin once daily or less often if sensitive and moisturize. Some silicone suspensions work best after watery serums.',
      'Keep it with gentle hydration while introducing it. It can be part of a routine with other actives when tolerated.',
      'Can sting or itch, especially on irritated skin. For The Ordinary’s suspension, follow its advice to separate from strong acids, retinoids and direct vitamin C; this is product-specific advice.',
      'https://theordinary.com/en-us/azelaic-acid-suspension-10-exfoliator-100407.html'),
  IngredientGuide(
      'Ceramides',
      [
        'ceramide np',
        'ceramide ap',
        'ceramide eop',
        'ceramide ns',
        'ceramide eos'
      ],
      'Lipids similar to those in the skin barrier. In moisturizers they help reduce moisture loss, supporting dry, tight or easily irritated skin. They do not exfoliate.',
      'Apply a ceramide moisturizer after cleansing and water-based serums. Slightly damp skin can help trap moisture. Use morning or evening as needed.',
      'Useful with glycerin, hyaluronic acid, cholesterol and fatty acids, and as moisturizing support around retinoid or acid use.',
      'No routine ingredient conflict is expected from ceramides themselves. The rest of the formula still matters for reactions.',
      _cerave),
  IngredientGuide(
      'Glycerin',
      ['glycerin'],
      'A humectant that attracts water and helps keep the outer skin layer hydrated. It can reduce a tight, dry feeling and is useful in both cleansers and moisturizers.',
      'Use the finished cleanser, serum or moisturizer as directed. For leave-on hydration, apply after cleansing and finish with moisturizer if using a serum.',
      'Works with ceramides, hyaluronic acid, emollients and most treatment ingredients.',
      'No usual pairing restriction. Do not apply raw cosmetic ingredients directly to skin; concentration and the whole formula matter.',
      _moisture),
  IngredientGuide(
      'Panthenol',
      ['panthenol'],
      'Pro-vitamin B5 helps hold moisture and supports comfortable, softer-feeling skin. Often used in formulas for dry or stressed skin.',
      'Use as part of a hydrating serum or moisturizer, morning or evening, following the product’s directions.',
      'Pairs with glycerin, ceramides and other barrier-supporting ingredients. Useful alongside drying treatments.',
      'It does not cancel out irritation from a strong acid or retinoid in the same product. Stop using a formula that causes persistent burning.',
      'https://www.laroche-posay.us/our-products/body/body-lotion/cicaplast-balm-b5-for-dry-skin-irritations-cicaplastbalmb5.html'),
  IngredientGuide(
      'Squalane',
      ['squalane'],
      'An emollient that smooths dry, rough patches and helps reduce moisture loss. It adds softness rather than exfoliation or acne treatment.',
      'A standalone squalane oil can be pressed over water-based products or moisturizer. Use a few drops as needed. In a cream, follow the cream’s directions.',
      'Complements humectants such as glycerin and hyaluronic acid. Can soften a routine containing drying treatments.',
      'No usual ingredient conflict. Squalane and squalene are different ingredients; neither a familiar name nor an oil-free label guarantees a formula will suit you.',
      'https://theordinary.com/en-us/100-plant-derived-squalane-face-oil-100398.html'),
  IngredientGuide(
      'Vitamin E',
      ['tocopherol', 'tocopheryl acetate'],
      'An antioxidant that helps protect oils in the formula and conditions the skin. Often combined with vitamin C. Tocopherol and tocopheryl acetate are distinct forms.',
      'Use the finished serum or moisturizer as directed. A product containing vitamin E is not a reason to add undiluted vitamin E oil.',
      'Commonly paired with vitamin C and ferulic acid in antioxidant serums.',
      'Can cause contact reactions in some people. Historical pore-clogging results vary by form and raw material, so the app keeps the two forms separate.',
      'https://www.skinceuticals.com/skincare/vitamin-c-serums/c-e-ferulic-with-15-l-ascorbic-acid/S17.html'),
  IngredientGuide(
      'Ferulic acid',
      ['ferulic acid'],
      'An antioxidant often used to help stabilize and complement vitamins C and E. Despite its name, it is not used like an exfoliating AHA peel.',
      'Follow the serum directions. In C E Ferulic, apply 4–5 drops to dry skin in the morning before other skincare and finish with sunscreen.',
      'Vitamin C and vitamin E are common formulated companions.',
      'The acidity and other actives in the serum may sting sensitive skin. Avoid adding several strong treatments at once.',
      'https://www.skinceuticals.com/skincare/vitamin-c-serums/c-e-ferulic-with-15-l-ascorbic-acid/S17.html'),
  IngredientGuide(
      'Zinc PCA',
      ['zinc pca'],
      'A zinc salt used in products for excess shine, with PCA providing moisture-binding properties. It is not the sunscreen filter zinc oxide.',
      'Use the finished serum after cleansing and before moisturizer as directed.',
      'Often formulated with niacinamide and humectants for oily skin.',
      'No standard blanket pairing ban for zinc PCA. Follow restrictions for other actives in the product, and reduce use if the serum stings.',
      'https://theordinary.com/en-us/niacinamide-10-zinc-1-serum-100436.html'),
  IngredientGuide(
      'Sunscreen filters',
      [
        'zinc oxide',
        'titanium dioxide',
        'avobenzone',
        'homosalate',
        'octisalate',
        'octocrylene',
        'octinoxate',
        'ethylhexyl triazone',
        'diethylamino hydroxybenzoyl hexyl benzoate',
        'diethylhexyl butamido triazone',
        'methylene bis-benzotriazolyl tetramethylbutylphenol (nano)'
      ],
      'UV filters protect against sun damage only as part of a tested, labelled sunscreen. Finding one in makeup does not establish its SPF or level of protection.',
      'Apply sunscreen as the final skincare step before makeup, 15 minutes before going outdoors. Reapply at least every two hours outdoors and after swimming, sweating or towelling, following its water-resistance label.',
      'Use over moisturizer and alongside vitamin C or a nighttime retinoid routine. Let the sunscreen form an even layer.',
      'Do not dilute sunscreen by mixing it into moisturizer, foundation or oils. No sunscreen blocks all UV: shade and protective clothing also help.',
      _aad),
  IngredientGuide(
      'Alpha arbutin',
      ['alpha-arbutin'],
      'Used to reduce the appearance of dark spots and uneven tone by affecting pigment production. It does not change your natural skin colour everywhere or replace sun protection.',
      'Apply the serum after cleansing and before moisturizer, morning or evening as directed. Use sunscreen during the day to help prevent further darkening.',
      'Often combined with hydrating ingredients. Introduce one tone-focused product at a time.',
      'Avoid layering multiple treatments if they cause stinging. Follow the product’s directions; results depend on formulation and consistent use.',
      'https://theordinary.com/en-us/alpha-arbutin-2-ha-serum-100401.html'),
  IngredientGuide(
      'Caffeine',
      ['caffeine'],
      'May temporarily reduce the look of under-eye puffiness. It cannot remove structural hollows or every cause of dark circles.',
      'Use a small amount around the eye contour as directed, keeping it out of the eyes. Follow with moisturizer if the area feels dry.',
      'Hydrating ingredients can keep the delicate eye area comfortable.',
      'Avoid bringing exfoliating acids or irritating retinoids close to the eyes to boost results. Stop if the eye area becomes irritated.',
      'https://theordinary.com/en-us/caffeine-solution-5-egcg-eye-serum-100412.html'),
  IngredientGuide(
      'Snail mucin',
      ['snail secretion filtrate'],
      'A mixture used to hydrate and condition skin. It can improve a dry, tight feeling, but is not a substitute for an acne medicine or scar treatment.',
      'For an essence, apply after cleansing and gently pat in, then use moisturizer. Follow the product label for frequency.',
      'Works as a hydrating step alongside a simple moisturizer.',
      'Stop if you develop itching, a rash or swelling. Animal-derived and botanical ingredients can cause reactions too.',
      'https://www.cosrx.com/products/advanced-snail-96-mucin-power-essence'),
  IngredientGuide(
      'Dimethicone',
      ['dimethicone'],
      'A silicone that smooths the surface and helps reduce water loss. It can improve slip and comfort in moisturizers and makeup.',
      'Use the finished product normally. A moisturizer containing dimethicone fits after water-based serums.',
      'Pairs with humectants such as glycerin and hyaluronic acid to help retain hydration.',
      'Silicones are not automatically pore-clogging. Pilling when layering is a texture issue, not evidence that pores are clogged.',
      _cerave),
  IngredientGuide(
      'Petrolatum',
      ['petrolatum'],
      'An occlusive that forms a protective layer to reduce water loss. Useful for very dry, flaky areas; it does not add water by itself.',
      'Use a thin layer of the finished balm on dry areas after hydration, following the label. A cream that includes it can be used as a normal moisturizer.',
      'Helps seal in moisture from glycerin or hyaluronic acid products.',
      'Avoid heavily sealing over irritating treatments unless directed, since occlusion can change tolerability. Purified petrolatum is not automatically a pore-clogger.',
      _cerave),
  IngredientGuide(
      'Fragrance',
      [
        'fragrance',
        'limonene',
        'linalool',
        'eucalyptus globulus leaf oil',
        'melaleuca alternifolia (tea tree) leaf oil'
      ],
      'Adds scent. Fragrance compounds and fragrant essential oils can irritate or trigger contact allergy in some people; this is different from clogged pores.',
      'Use the product as directed. If skin is easily irritated, a fragrance-free option may be more comfortable.',
      'No benefit comes from combining several fragranced products. Keep a reactive-skin routine simple.',
      'Itching, burning or an eczema-like rash belongs under Irritation in your notes, not automatically Breakout. Stop using a product that causes a reaction.',
      'https://www.aad.org/public/everyday-care/skin-care-basics/dry/dermatologists-tips-relieve-dry-skin'),
];

List<IngredientGuide> guidesForIngredients(Set<String> tokens) => [
      for (final guide in ingredientGuides)
        if (guide.inci.any((name) => tokens.contains(ingredientIdentity(name))))
          guide
    ];
IngredientGuide? guideForName(String inci) {
  final name = ingredientIdentity(inci);
  for (final guide in ingredientGuides) {
    if (guide.inci.any((i) => ingredientIdentity(i) == name)) return guide;
  }
  return null;
}
