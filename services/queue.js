const ai = require('./ai');
const whisper = require('./whisper');
const media = require('./media');
const sb = require('./supabase');

const MIN_PRODUCT_CONFIDENCE = 0.6;

const queue = [];
let running = false;
let seenUrls = new Set();
let logFn = () => {};

function setLogger(fn) {
  logFn = typeof fn === 'function' ? fn : () => {};
}

function log(level, videoId, msg) {
  logFn({ level, videoId, msg, ts: Date.now() });
}

async function enqueue(payload) {
  if (!payload?.video_url) return null;
  if (seenUrls.has(payload.video_url)) return null;
  seenUrls.add(payload.video_url);

  const video = await sb.upsertVideo({ ...payload, status: 'queued' });

  if (payload.creator_handle) {
    const creator = await sb.upsertCreatorByHandle(payload.creator_handle);
    await sb.setVideoFields(video.id, { creator_id: creator.id });
    video.creator_id = creator.id;
  }

  queue.push(video);
  log('info', video.id, `queued ${video.video_url}`);
  if (!running) tick();
  return video;
}

async function tick() {
  if (running) return;
  running = true;
  try {
    while (queue.length) {
      const video = queue.shift();
      try {
        await processVideo(video);
      } catch (err) {
        log('error', video.id, err.message);
        await sb.setVideoStatus(video.id, 'failed', {
          error: err.message?.slice(0, 2000),
        });
      } finally {
        try {
          media.cleanup(video.id);
        } catch {}
      }
    }
  } finally {
    running = false;
  }
}

async function processVideo(video) {
  const { id, video_url, caption, top_comments } = video;

  const needsTranscribe = video.transcript == null;
  const needsVision = video.vision_result == null;
  const needsNlp = video.nlp_result == null;
  const needsDownload = needsTranscribe || needsVision;

  let videoPath = null;
  if (needsDownload) {
    await sb.setVideoStatus(id, 'downloading');
    log('info', id, 'downloading…');
    videoPath = await media.downloadVideo(video_url, id);
  }

  let transcript = video.transcript;
  if (needsTranscribe) {
    await sb.setVideoStatus(id, 'transcribing');
    const audioPath = await media.extractAudio(videoPath);
    if (audioPath) {
      transcript = await whisper.transcribe(audioPath);
    } else {
      // sentinel '' = "we tried, no audio"; null = "haven't tried yet"
      transcript = '';
    }
    await sb.setVideoFields(id, { transcript });
  }

  let visionResult = video.vision_result;
  if (needsVision) {
    await sb.setVideoStatus(id, 'vision');
    const framePaths = await media.extractFrames(videoPath, 3);
    visionResult =
      (await ai.extractFromFrames(framePaths, { videoUrl: video_url })) || {};
    await sb.setVideoFields(id, {
      vision_result: visionResult,
      frames: framePaths.map((p) => ({ path: p })),
    });
  }

  let nlpResult = video.nlp_result;
  if (needsNlp) {
    await sb.setVideoStatus(id, 'nlp');
    nlpResult =
      (await ai.extractFromTextSignals({
        transcript: transcript || null,
        caption: caption ?? '',
        comments: top_comments ?? [],
      })) || {};
    await sb.setVideoFields(id, { nlp_result: nlpResult });
  }

  await autoDiscoverProducts(id, visionResult, nlpResult);

  await sb.deleteUnreviewedEntities(id);
  await sb.insertExtractedEntities(
    buildEntityRows(id, transcript, visionResult, nlpResult),
  );
  await sb.setVideoStatus(id, 'ready');
}

function buildEntityRows(videoId, transcript, vision, nlp) {
  const rows = [];
  const sentiments = nlp?.sentiment_descriptors ?? [];

  if (transcript) {
    rows.push({
      video_id: videoId,
      source: 'whisper',
      raw_text: transcript,
      sentiment_tags: [],
    });
  }

  for (const p of vision?.products ?? []) {
    rows.push({
      video_id: videoId,
      source: 'vision',
      brand_guess: p.brand ?? null,
      product_guess: p.product_name ?? null,
      shade_guess: p.shade ?? null,
      raw_text: (vision.packaging_text ?? []).join(' | ').slice(0, 4000),
      sentiment_tags: [],
    });
  }

  for (const p of nlp?.products ?? []) {
    rows.push({
      video_id: videoId,
      source: 'caption_nlp',
      brand_guess: p.brand ?? null,
      product_guess: p.product_name ?? null,
      sentiment_tags: sentiments,
      skin_tone_language:
        (nlp.skin_tone_language ?? []).join(' | ').slice(0, 1000) || null,
    });
  }

  for (const s of nlp?.shades ?? []) {
    rows.push({
      video_id: videoId,
      source: 'caption_nlp',
      brand_guess: s.brand ?? null,
      product_guess: s.product_name ?? null,
      shade_guess: s.shade ?? null,
      sentiment_tags: [],
    });
  }

  return rows;
}

async function autoDiscoverProducts(videoId, vision, nlp) {
  const candidates = new Map();
  const collect = (p) => {
    const brand = (p?.brand ?? '').trim();
    const name = (p?.product_name ?? '').trim();
    if (!brand || !name) return;
    const key = `${brand}|${name}`.toLowerCase();
    if (!candidates.has(key)) candidates.set(key, { brand, name });
  };

  for (const p of vision?.products ?? []) collect(p);
  for (const p of nlp?.products ?? []) collect(p);
  for (const p of nlp?.shades ?? []) collect(p);
  if (candidates.size === 0) return;

  for (const [, { brand, name }] of candidates) {
    try {
      const existing = await sb.findProduct({ brand, name });
      if (existing) continue;

      const result = await ai.findProductOnline(brand, name);
      if (!result?.found || (result.confidence ?? 0) < MIN_PRODUCT_CONFIDENCE) {
        continue;
      }

      await sb.upsertProduct({
        brand: result.brand || brand,
        name: result.name || name,
        category: result.category || 'other',
        sephora_url: result.sephora_url ?? null,
        ulta_url: result.ulta_url ?? null,
      });
      log('info', videoId, `+ ${result.brand} · ${result.name}`);
    } catch (err) {
      log('warn', videoId, `lookup failed: ${brand} · ${name}: ${err.message}`);
    }
  }
}

async function rehydrate() {
  const stuck = ['downloading', 'transcribing', 'vision', 'nlp', 'queued'];
  const { data, error } = await sb
    .admin()
    .from('tiktok_videos')
    .select('*')
    .in('status', stuck)
    .order('captured_at', { ascending: true });
  if (error) throw error;

  let count = 0;
  for (const video of data ?? []) {
    if (seenUrls.has(video.video_url)) continue;
    seenUrls.add(video.video_url);
    if (video.status !== 'queued') {
      try {
        await sb.setVideoStatus(video.id, 'queued', { error: null });
      } catch {}
    }
    queue.push(video);
    count++;
  }

  if (count > 0 && !running) tick();
  return count;
}

module.exports = { enqueue, setLogger, rehydrate };
