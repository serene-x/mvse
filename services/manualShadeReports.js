const sb = require('./supabase');

function validateReport(input) {
  const url = new URL(input.sourceUrl);
  if (
    url.protocol !== 'https:' ||
    url.hostname !== 'www.tiktok.com' ||
    !/^\/@[^/]+\/video\/\d+$/.test(url.pathname)
  ) {
    throw Error(
      'Use the full TikTok video link, including the creator and video number.',
    );
  }
  if (input.confirmed !== true)
    throw Error('Confirm that both shades were reported as skin matches.');
  if (!input.evidence?.trim())
    throw Error('Record the timestamp or statement you checked.');
  const pairs = input.pairs ?? [];
  if (
    pairs.length < 2 ||
    new Set(pairs.map((p) => p.productId)).size !== pairs.length ||
    pairs.some((p) => !p.productId || !p.shade?.trim())
  ) {
    throw Error(
      'Choose at least two different products and their exact shades.',
    );
  }
  return {
    source: url.origin + url.pathname,
    person: url.pathname.split('/')[1],
    pairs,
  };
}
async function saveManualReport(input) {
  const report = validateReport(input);
  const db = sb.admin();
  const { data: products, error } = await db
    .from('products')
    .select('id,brand,name,category')
    .in(
      'id',
      report.pairs.map((p) => p.productId),
    );
  if (error) throw error;
  const shades = {};
  for (const pair of report.pairs) {
    const product = products.find((p) => p.id === pair.productId);
    if (!product || !['foundation', 'concealer'].includes(product.category))
      throw Error(
        'Shade-twin reports require exact foundation or concealer products.',
      );
    const { data: shade, error: shadeError } = await db
      .from('product_shades')
      .select('shade_name')
      .eq('product_id', product.id)
      .eq('shade_name', pair.shade.trim())
      .maybeSingle();
    if (shadeError) throw shadeError;
    if (!shade)
      throw Error(
        'That shade is not in the product catalogue. Add it in Products first.',
      );
    shades[product.brand.toLowerCase() + '|' + product.name.toLowerCase()] =
      shade.shade_name;
  }
  const { error: writeError } = await db.from('reviewed_shade_reports').upsert({
    source_url: report.source,
    person: report.person,
    shades,
    evidence_note: input.evidence.trim(),
    reviewed_at: new Date().toISOString(),
  });
  if (writeError) throw writeError;
  return { ok: true };
}
module.exports = { validateReport, saveManualReport };
