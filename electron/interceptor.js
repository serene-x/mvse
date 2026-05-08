// Pulls structured metadata out of TikTok's internal JSON API by attaching
// a CDP debugger and parsing the response bodies for /api/post/item_list,
// /api/recommend/item_list, /api/item/detail, and /api/comment/list. The DOM
// scraper is a fallback; this is the primary signal source.

const TIKTOK_API_FRAGMENTS = [
  '/api/post/item_list',
  '/api/recommend/item_list',
  '/api/item/detail',
  '/api/comment/list',
];

const itemsByAweme = new Map();
const commentsByAweme = new Map();

function isTikTokApi(url) {
  return TIKTOK_API_FRAGMENTS.some(f => url.includes(f));
}

function parseItem(it) {
  if (!it) return null;
  const id = String(it.aweme_id ?? it.id ?? '');
  if (!id) return null;
  const handle = it.author?.unique_id ?? it.author?.uniqueId ?? null;
  return {
    aweme_id: id,
    video_url: handle ? `https://www.tiktok.com/@${handle}/video/${id}` : null,
    creator_handle: handle,
    caption: it.desc ?? null,
    view_count: it.statistics?.play_count ?? it.stats?.playCount ?? null,
    posted_at: it.create_time ? new Date(it.create_time * 1000).toISOString() : null,
  };
}

function parseComments(json) {
  const arr = json?.comments ?? json?.comment_list ?? [];
  return arr.map(c => ({
    text: c.text ?? c.share_info?.desc ?? '',
    author: c.user?.unique_id ?? c.user?.uniqueId ?? null,
    like_count: c.digg_count ?? c.diggCount ?? 0,
  })).filter(c => c.text);
}

function awemeIdFromCommentsUrl(url) {
  try {
    const u = new URL(url);
    return u.searchParams.get('aweme_id') ?? u.searchParams.get('item_id') ?? null;
  } catch { return null; }
}

function flush(awemeId, webContents) {
  const item = itemsByAweme.get(awemeId);
  if (!item || !item.video_url) return;
  webContents.send('tiktok:videoCaptured', {
    video_url: item.video_url,
    creator_handle: item.creator_handle,
    caption: item.caption,
    view_count: item.view_count,
    top_comments: (commentsByAweme.get(awemeId) ?? []).slice(0, 50),
    posted_at: item.posted_at,
    captured_at: new Date().toISOString(),
    _source: 'cdp',
  });
}

function attachInterceptors(webContents, emit) {
  webContents.session.webRequest.onCompleted(
    { urls: ['https://*.tiktok.com/*', 'https://*.tiktokv.com/*'] },
    details => {
      if (!isTikTokApi(details.url)) return;
      emit({ kind: 'apiHit', payload: { url: details.url, status: details.statusCode } });
    },
  );

  try {
    if (!webContents.debugger.isAttached()) webContents.debugger.attach('1.3');
  } catch (err) {
    if (!String(err).includes('already attached')) {
      console.warn('debugger.attach failed:', err);
      return;
    }
  }
  webContents.debugger.sendCommand('Network.enable').catch(() => {});

  webContents.debugger.on('message', async (_evt, method, params) => {
    if (method !== 'Network.responseReceived') return;
    const { requestId, response } = params;
    if (!isTikTokApi(response.url)) return;

    let raw;
    try {
      const r = await webContents.debugger.sendCommand(
        'Network.getResponseBody', { requestId },
      );
      raw = r.base64Encoded ? Buffer.from(r.body, 'base64').toString('utf8') : r.body;
    } catch {
      return;
    }

    let json;
    try { json = JSON.parse(raw); } catch { return; }

    const items = json?.aweme_list
      ?? json?.itemList
      ?? (json?.aweme_detail ? [json.aweme_detail] : null);

    if (Array.isArray(items)) {
      for (const it of items) {
        const parsed = parseItem(it);
        if (!parsed?.video_url) continue;
        itemsByAweme.set(parsed.aweme_id, parsed);
        flush(parsed.aweme_id, webContents);
      }
    }

    if (response.url.includes('/api/comment/list')) {
      const aid = awemeIdFromCommentsUrl(response.url);
      if (!aid) return;
      const incoming = parseComments(json);
      const existing = commentsByAweme.get(aid) ?? [];
      const merged = [...existing];
      for (const c of incoming) {
        if (!merged.some(m => m.text === c.text && m.author === c.author)) merged.push(c);
      }
      merged.sort((a, b) => (b.like_count ?? 0) - (a.like_count ?? 0));
      commentsByAweme.set(aid, merged.slice(0, 50));
      flush(aid, webContents);
    }
  });
}

module.exports = { attachInterceptors };
