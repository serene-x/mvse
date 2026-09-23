require('dotenv').config({ quiet: true });
const fs = require('node:fs');
const { createClient } = require('@supabase/supabase-js');
(async () => {
  const db = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    { auth: { persistSession: false } },
  );
  const { data: products, error } = await db
    .from('products')
    .select('id,brand,name');
  if (error) throw error;
  const patches = JSON.parse(
    fs.readFileSync('glowmatch/assets/catalog/details_overrides.json'),
  );
  let count = 0;
  for (const [key, patch] of Object.entries(patches)) {
    const p = products.find(
      (p) => p.brand.toLowerCase() + '|' + p.name.toLowerCase() === key,
    );
    if (!p) throw Error('Product missing: ' + key);
    if (patch.sephora_url) {
      const update = await db
        .from('products')
        .update({ sephora_url: patch.sephora_url })
        .eq('id', p.id);
      if (update.error) throw update.error;
    }
    const { error } = await db.from('product_shades').upsert(
      patch.shades.map((shade_name) => ({ product_id: p.id, shade_name })),
      { onConflict: 'product_id,shade_name' },
    );
    if (error) throw error;
    count += patch.shades.length;
  }
  console.log(
    `Synced ${count} shade names across ${Object.keys(patches).length} corrected products.`,
  );
})().catch(() => {
  console.error('Shade correction sync failed.');
  process.exit(1);
});
