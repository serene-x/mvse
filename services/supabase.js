const { createClient } = require('@supabase/supabase-js');
const ws = require('ws');

let cached;
function admin() {
  if (cached) return cached;
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key)
    throw new Error('SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing');
  cached = createClient(url, key, {
    auth: { persistSession: false },
    realtime: { transport: ws },
  });
  return cached;
}

async function upsertVideo(payload) {
  const { data, error } = await admin()
    .from('tiktok_videos')
    .upsert(
      {
        video_url: payload.video_url,
        creator_handle: payload.creator_handle ?? null,
        caption: payload.caption ?? null,
        posted_at: payload.posted_at ?? null,
        view_count: payload.view_count ?? null,
        top_comments: payload.top_comments ?? [],
        status: payload.status ?? 'queued',
      },
      { onConflict: 'video_url' },
    )
    .select()
    .single();
  if (error) throw error;
  return data;
}

async function setVideoStatus(id, status, extra = {}) {
  const patch = { status, ...extra };
  if (status === 'ready' || status === 'failed') {
    patch.processed_at = new Date().toISOString();
  }
  const { error } = await admin()
    .from('tiktok_videos')
    .update(patch)
    .eq('id', id);
  if (error) throw error;
}

async function setVideoFields(id, fields) {
  const { error } = await admin()
    .from('tiktok_videos')
    .update(fields)
    .eq('id', id);
  if (error) throw error;
}

async function insertExtractedEntities(rows) {
  if (!rows?.length) return;
  // supabase-js unions keys across batch inserts and writes explicit nulls
  // for any field a row omits, which overrides column defaults. Coerce
  // every row so the NOT NULL constraints don't reject the batch.
  const safe = rows.map((r) => ({
    ...r,
    sentiment_tags: Array.isArray(r.sentiment_tags) ? r.sentiment_tags : [],
    reviewed: r.reviewed ?? false,
  }));
  const { error } = await admin().from('extracted_entities').insert(safe);
  if (error) throw error;
}

async function deleteUnreviewedEntities(videoId) {
  const { error } = await admin()
    .from('extracted_entities')
    .delete()
    .eq('video_id', videoId)
    .eq('reviewed', false);
  if (error) throw error;
}

async function upsertCreatorByHandle(handle, fields = {}) {
  const { data, error } = await admin()
    .from('creators')
    .upsert(
      { tiktok_handle: handle, ...fields },
      { onConflict: 'tiktok_handle' },
    )
    .select()
    .single();
  if (error) throw error;
  return data;
}

async function upsertProduct(fields) {
  const { data, error } = await admin()
    .from('products')
    .upsert(fields, { onConflict: 'brand,name' })
    .select()
    .single();
  if (error) throw error;
  return data;
}

async function findProduct({ brand, name }) {
  if (!brand || !name) return null;
  const { data, error } = await admin()
    .from('products')
    .select('id, brand, name, category')
    .ilike('brand', brand)
    .ilike('name', name)
    .limit(1);
  if (error) throw error;
  return data?.[0] ?? null;
}

async function updateProduct(id, fields) {
  const { data, error } = await admin()
    .from('products')
    .update(fields)
    .eq('id', id)
    .select()
    .single();
  if (error) throw error;
  return data;
}

async function addShade(productId, shadeName, hexColor) {
  const { data, error } = await admin()
    .from('product_shades')
    .upsert(
      { product_id: productId, shade_name: shadeName, hex_color: hexColor },
      { onConflict: 'product_id,shade_name' },
    )
    .select()
    .single();
  if (error) throw error;
  return data;
}

async function saveShadeTwin(
  creatorAId,
  creatorBId,
  confidence,
  confirmed = true,
) {
  const [a, b] = [creatorAId, creatorBId].sort();
  const { error } = await admin().from('shade_twins').upsert(
    {
      creator_a_id: a,
      creator_b_id: b,
      confidence_score: confidence,
      confirmed,
    },
    { onConflict: 'creator_a_id,creator_b_id' },
  );
  if (error) throw error;
}

module.exports = {
  admin,
  upsertVideo,
  setVideoStatus,
  setVideoFields,
  insertExtractedEntities,
  deleteUnreviewedEntities,
  upsertCreatorByHandle,
  upsertProduct,
  findProduct,
  updateProduct,
  addShade,
  saveShadeTwin,
};
