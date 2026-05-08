(() => {
  if (window.__mvseInstalled) return;
  window.__mvseInstalled = true;

  const send = data => {
    try { window.__admin?.send('tiktok:videoCaptured', data); } catch {}
  };

  window.__mvseCapture = () => {
    const data = harvest();
    if (data) send(data);
    return data;
  };

  function currentVideoMeta() {
    const m = location.pathname.match(/^\/@([^/]+)\/video\/(\d+)/);
    if (!m) return null;
    return { url: `https://www.tiktok.com${location.pathname}`, handle: m[1], videoId: m[2] };
  }

  function pickText(selectors) {
    for (const sel of selectors) {
      const t = document.querySelector(sel)?.textContent?.trim();
      if (t) return t;
    }
    return null;
  }

  function readWithin(el, selectors) {
    for (const sel of selectors) {
      const t = el.querySelector(sel)?.textContent?.trim();
      if (t) return t;
    }
    return null;
  }

  // TikTok rotates these data-e2e attributes regularly. Newest first; if one
  // breaks the others usually still resolve.
  const SEL = {
    caption: [
      '[data-e2e="browse-video-desc"]',
      '[data-e2e="video-desc"]',
      '[data-e2e="new-desc-span"]',
      'div[class*="DivVideoInfoContainer"] [data-e2e*="desc"]',
      'h1[data-e2e*="desc"]',
    ],
    commentItem: [
      '[data-e2e="comment-level-1"]',
      '[data-e2e^="comment-level"]',
      'div[class*="DivCommentItemContainer"]',
    ],
    commentText: [
      '[data-e2e="comment-level-1"]',
      'p[data-e2e="comment-level-1"]',
      'span[data-e2e*="comment"]',
    ],
    commentAuthor: ['[data-e2e="comment-username-1"]', 'a[data-e2e*="username"]'],
    commentLikes: ['[data-e2e="comment-like-count"]', 'span[data-e2e*="like"]'],
    viewCount: [
      '[data-e2e="video-views"]',
      'strong[data-e2e="like-count"]',
      'strong[data-e2e*="view"]',
    ],
  };

  function harvest() {
    const meta = currentVideoMeta();
    if (!meta) return null;

    let items = [];
    for (const sel of SEL.commentItem) {
      const found = Array.from(document.querySelectorAll(sel));
      if (found.length > 0) { items = found.slice(0, 50); break; }
    }

    const top_comments = items.map(el => ({
      text: readWithin(el, SEL.commentText) ?? el.textContent?.trim() ?? '',
      author: readWithin(el, SEL.commentAuthor),
      like_count: parseCount(readWithin(el, SEL.commentLikes)) ?? 0,
    })).filter(c => c.text);

    return {
      video_url: meta.url,
      creator_handle: meta.handle,
      caption: pickText(SEL.caption),
      top_comments,
      view_count: parseCount(pickText(SEL.viewCount)),
      posted_at: null,
      captured_at: new Date().toISOString(),
      _source: 'dom',
    };
  }

  function parseCount(s) {
    if (!s) return null;
    const m = String(s).trim().match(/([\d.,]+)\s*([KMB]?)/i);
    if (!m) return null;
    const n = parseFloat(m[1].replace(/,/g, ''));
    const mult = { K: 1e3, M: 1e6, B: 1e9 }[(m[2] || '').toUpperCase()] ?? 1;
    return Math.round(n * mult);
  }

  let lastSentUrl = null;
  let lastSentAt = 0;
  let timer = null;
  function maybeCapture() {
    if (!currentVideoMeta()) return;
    if (timer) clearTimeout(timer);
    timer = setTimeout(() => {
      const data = harvest();
      if (!data) return;
      const sameUrl = data.video_url === lastSentUrl;
      const recent = Date.now() - lastSentAt < 30_000;
      if (sameUrl && recent && !data.top_comments?.length) return;
      lastSentUrl = data.video_url;
      lastSentAt = Date.now();
      send(data);
    }, 1800);
  }

  new MutationObserver(maybeCapture).observe(document.documentElement, {
    childList: true,
    subtree: true,
  });
  maybeCapture();
})();
