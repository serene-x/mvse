import React, { useEffect, useMemo, useState } from 'react';
import { supabase } from '../lib/supabase.js';
import { admin } from '../lib/api.js';

export default function CreatorBuilder() {
  const [creators, setCreators] = useState([]);
  const [activeId, setActiveId] = useState(null);
  const [entities, setEntities] = useState([]);
  const [videosById, setVideosById] = useState({});
  const [products, setProducts] = useState([]);
  const [shadesByProductId, setShadesByPid] = useState({});
  const [skinToneDesc, setSkinToneDesc] = useState('');
  const [productPicks, setProductPicks] = useState({});
  const [shadePicks, setShadePicks] = useState({});
  const [shadeInputs, setShadeInputs] = useState({});
  const [savingId, setSavingId] = useState(null);

  useEffect(() => {
    (async () => {
      const [{ data: c }, { data: p }, { data: ps }] = await Promise.all([
        supabase.from('creators').select('id, tiktok_handle, shade_profile, skin_tone_desc').order('tiktok_handle'),
        supabase.from('products').select('id, brand, name').order('brand'),
        supabase.from('product_shades').select('id, product_id, shade_name, hex_color'),
      ]);
      setCreators(c ?? []);
      setProducts(p ?? []);
      setShadesByPid(groupByProduct(ps ?? []));
    })();
  }, []);

  const active = useMemo(() => creators.find(c => c.id === activeId), [creators, activeId]);

  useEffect(() => {
    if (!active) return;
    setSkinToneDesc(active.skin_tone_desc ?? '');
    (async () => {
      const { data: videos } = await supabase
        .from('tiktok_videos')
        .select('id, video_url, view_count, nlp_result, transcript, status')
        .eq('creator_id', active.id);
      const ids = (videos ?? []).map(v => v.id);
      setVideosById(Object.fromEntries((videos ?? []).map(v => [v.id, v])));
      if (ids.length === 0) {
        setEntities([]); setProductPicks({}); setShadePicks({}); setShadeInputs({});
        return;
      }

      const { data } = await supabase
        .from('extracted_entities')
        .select('*')
        .in('video_id', ids)
        .eq('reviewed', false)
        .order('created_at', { ascending: false });
      setEntities(data ?? []);
      setProductPicks({}); setShadePicks({}); setShadeInputs({});
    })();
  }, [active]);

  // Pre-fill product + shade picks from entity guesses.
  useEffect(() => {
    if (!entities.length || !products.length) return;
    const nextProducts = {};
    const nextShades = {};
    const nextInputs = {};
    for (const e of entities) {
      const match = bestProductMatch(products, e.brand_guess, e.product_guess);
      if (match) {
        nextProducts[e.id] = match.id;
        const cleanShade = normalizeShadeName(e.shade_guess);
        nextInputs[e.id] = cleanShade;
        if (cleanShade) {
          const existing = (shadesByProductId[match.id] ?? [])
            .find(s => s.shade_name.toLowerCase() === cleanShade.toLowerCase());
          if (existing) nextShades[e.id] = existing.id;
        }
      }
    }
    setProductPicks(prev => ({ ...nextProducts, ...prev }));
    setShadePicks(prev => ({ ...nextShades, ...prev }));
    setShadeInputs(prev => ({ ...nextInputs, ...prev }));
  }, [entities, products, shadesByProductId]);

  async function resolveShadeId(entityId, productId) {
    if (shadePicks[entityId]) return shadePicks[entityId];

    const typed = (shadeInputs[entityId] ?? '').trim();
    if (!typed) return null;

    const existing = (shadesByProductId[productId] ?? [])
      .find(s => s.shade_name.toLowerCase() === typed.toLowerCase());
    if (existing) return existing.id;

    const created = await admin.addShade({ productId, shadeName: typed, hexColor: null });
    setShadesByPid(prev => ({
      ...prev,
      [productId]: [
        ...(prev[productId] ?? []),
        { id: created.id, product_id: productId, shade_name: typed, hex_color: null },
      ],
    }));
    return created.id;
  }

  async function saveEntity(entity) {
    const productId = productPicks[entity.id];
    if (!productId) return;

    setSavingId(entity.id);
    try {
      const shadeId = await resolveShadeId(entity.id, productId);
      const video = videosById[entity.video_id];
      const shade = (shadesByProductId[productId] ?? []).find(s => s.id === shadeId);
      const product = products.find(p => p.id === productId);
      const shadeName = shade?.shade_name ?? normalizeShadeName(entity.shade_guess);

      await admin.confirmEntity({ id: entity.id, productId, shadeId });

      await admin.linkMention({
        videoId: entity.video_id,
        productId,
        shadeName: shadeId ? shade?.shade_name : null,
        hexColor: null,
        sentimentTags: entity.sentiment_tags ?? [],
        videoUrl: video?.video_url ?? null,
        viewCount: video?.view_count ?? null,
      });

      if (entity.shade_guess || shadeId) {
        const updated = { ...(active.shade_profile ?? {}) };
        const key = product?.brand ?? entity.brand_guess ?? 'unknown';
        updated[key] = updated[key] ?? [];
        const exists = updated[key].some(x => x.product === product?.name && x.shade === shadeName);
        if (!exists) {
          updated[key].push({ product: product?.name ?? entity.product_guess, shade: shadeName });
        }
        await admin.updateCreator({ id: active.id, fields: { shade_profile: updated } });
      }

      setEntities(prev => prev.filter(e => e.id !== entity.id));
    } finally {
      setSavingId(null);
    }
  }

  async function reject(entity) {
    await admin.confirmEntity({ id: entity.id });
    setEntities(prev => prev.filter(e => e.id !== entity.id));
  }

  async function saveSkinTone() {
    if (!active) return;
    await admin.updateCreator({ id: active.id, fields: { skin_tone_desc: skinToneDesc } });
  }

  return (
    <>
      <h2>Creators</h2>
      <select value={activeId ?? ''} onChange={e => setActiveId(e.target.value || null)}>
        <option value="">— pick a creator —</option>
        {creators.map(c => <option key={c.id} value={c.id}>@{c.tiktok_handle}</option>)}
      </select>

      {active && (
        <>
          <label>Skin tone description</label>
          <input value={skinToneDesc} onChange={e => setSkinToneDesc(e.target.value)}
                 placeholder="e.g., medium-tan, warm-neutral" />
          <button className="ghost" style={{ marginTop: 6 }} onClick={saveSkinTone}>Save</button>

          <VideoInsights videos={Object.values(videosById)} />

          <h2 style={{ marginTop: 16 }}>Pending shade extractions ({entities.length})</h2>
          {entities.length === 0 && (
            <div style={{ color: 'var(--muted)', fontSize: 12 }}>Nothing to review.</div>
          )}

          {entities.map(e => (
            <EntityCard
              key={e.id}
              entity={e}
              products={products}
              shadesByProductId={shadesByProductId}
              productId={productPicks[e.id] ?? ''}
              shadeId={shadePicks[e.id] ?? ''}
              shadeInput={shadeInputs[e.id] ?? ''}
              isSaving={savingId === e.id}
              onProductPick={pid => {
                setProductPicks(p => ({ ...p, [e.id]: pid }));
                setShadePicks(p => { const n = { ...p }; delete n[e.id]; return n; });
              }}
              onShadePick={sid => setShadePicks(p => ({ ...p, [e.id]: sid }))}
              onShadeInput={txt => {
                setShadeInputs(p => ({ ...p, [e.id]: txt }));
                setShadePicks(p => { const n = { ...p }; delete n[e.id]; return n; });
              }}
              onSave={() => saveEntity(e)}
              onSkip={() => reject(e)}
            />
          ))}
        </>
      )}
    </>
  );
}

function EntityCard({
  entity, products, shadesByProductId,
  productId, shadeId, shadeInput,
  isSaving,
  onProductPick, onShadePick, onShadeInput, onSave, onSkip,
}) {
  const productShades = shadesByProductId[productId] ?? [];
  const trimmedInput = (shadeInput ?? '').trim();
  const matchesExistingShade = productShades.find(
    s => s.shade_name.toLowerCase() === trimmedInput.toLowerCase()
  );
  const willCreateNew = !matchesExistingShade && !!trimmedInput;
  const canSave = !!productId && (!!shadeId || !!trimmedInput);

  return (
    <div className="entity-card">
      <div className="source">{entity.source}</div>
      <div className="kv">
        <div className="k">brand</div><div>{entity.brand_guess ?? '—'}</div>
        <div className="k">product</div><div>{entity.product_guess ?? '—'}</div>
        <div className="k">shade</div><div>{entity.shade_guess ?? '—'}</div>
        {Array.isArray(entity.sentiment_tags) && entity.sentiment_tags.length > 0 && (
          <>
            <div className="k">sentiment</div>
            <div>{entity.sentiment_tags.join(', ')}</div>
          </>
        )}
      </div>
      {entity.raw_text && (
        <div style={{ color: 'var(--muted)', fontSize: 11, marginTop: 6, whiteSpace: 'pre-wrap' }}>
          {entity.raw_text.slice(0, 300)}{entity.raw_text.length > 300 ? '…' : ''}
        </div>
      )}

      <label style={{ marginTop: 8 }}>Link to product</label>
      <select value={productId} onChange={ev => onProductPick(ev.target.value)}>
        <option value="">— pick a product —</option>
        {products.map(p => (
          <option key={p.id} value={p.id}>{p.brand} · {p.name}</option>
        ))}
      </select>

      {productId && (
        <>
          <label style={{ marginTop: 8 }}>Shade in this product</label>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 6 }}>
            {productShades.length === 0 && (
              <span style={{ fontSize: 11, color: 'var(--muted)' }}>
                No shades yet for this product — type one below.
              </span>
            )}
            {productShades.map(s => {
              const on = shadeId === s.id;
              return (
                <button
                  key={s.id}
                  onClick={() => { onShadePick(s.id); onShadeInput(s.shade_name); }}
                  style={{
                    fontSize: 11,
                    padding: '4px 10px',
                    borderRadius: 999,
                    border: `1px solid ${on ? 'var(--accent)' : 'var(--border)'}`,
                    background: on ? 'var(--accent)' : 'var(--panel)',
                    color: on ? '#fff' : 'var(--text)',
                    cursor: 'pointer',
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: 6,
                  }}
                >
                  {s.hex_color && (
                    <span style={{
                      width: 10, height: 10, borderRadius: '50%',
                      background: s.hex_color,
                      border: '1px solid rgba(255,255,255,.2)',
                    }} />
                  )}
                  {s.shade_name}
                </button>
              );
            })}
          </div>

          <input
            placeholder="Shade name (e.g. 2N, NC44, Pillow Talk)"
            value={shadeInput}
            onChange={ev => onShadeInput(ev.target.value)}
          />
          {willCreateNew && (
            <div style={{ fontSize: 10, color: 'var(--accent)', marginTop: 4 }}>
              Will create new shade "{trimmedInput}" on Save.
            </div>
          )}
          {matchesExistingShade && shadeId !== matchesExistingShade.id && (
            <div style={{ fontSize: 10, color: 'var(--muted)', marginTop: 4 }}>
              Matches existing shade — will link to it.
            </div>
          )}
        </>
      )}

      <div style={{ marginTop: 10, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
        <button
          className="primary"
          disabled={!canSave || isSaving}
          onClick={onSave}
          title={!productId ? 'Pick a product' : !canSave ? 'Pick or type a shade' : ''}
        >
          {isSaving ? 'Saving…' : 'Save (link product + shade)'}
        </button>
        <button className="ghost" disabled={isSaving} onClick={onSkip}>
          Skip
        </button>
      </div>
    </div>
  );
}

function groupByProduct(rows) {
  const out = {};
  for (const r of rows) {
    (out[r.product_id] ??= []).push(r);
  }
  for (const k of Object.keys(out)) {
    out[k].sort((a, b) => a.shade_name.localeCompare(b.shade_name));
  }
  return out;
}

function normalizeShadeName(s) {
  if (!s) return '';
  return s
    .replace(/\s*\((?:winter|summer|spring|fall|autumn|w|s)\)\s*/gi, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function VideoInsights({ videos }) {
  const ready = (videos ?? []).filter(v => v.nlp_result);
  if (ready.length === 0) return null;

  const shadeMatchVideos = ready.filter(v => v.nlp_result.is_shade_match_video === true);
  const audience = new Map();
  const sentiment = new Map();
  const skinToneLang = new Map();
  const selfDescriptions = new Set();

  for (const v of ready) {
    for (const a of (v.nlp_result.audience_signals ?? []))      audience.set(a, (audience.get(a) ?? 0) + 1);
    for (const s of (v.nlp_result.sentiment_descriptors ?? [])) sentiment.set(s, (sentiment.get(s) ?? 0) + 1);
    for (const t of (v.nlp_result.skin_tone_language ?? []))    skinToneLang.set(t, (skinToneLang.get(t) ?? 0) + 1);
    if (v.nlp_result.creator_self_description) selfDescriptions.add(v.nlp_result.creator_self_description);
  }

  const sortByCount = (m) => [...m.entries()].sort((a, b) => b[1] - a[1]);

  return (
    <div style={{
      marginTop: 14, padding: 12,
      border: '1px solid var(--border)', borderRadius: 8,
      background: 'var(--panel-2)',
    }}>
      <h2 style={{ marginTop: 0 }}>Video insights ({ready.length} processed)</h2>

      {selfDescriptions.size > 0 && (
        <div style={{ fontSize: 12, marginBottom: 10 }}>
          <strong style={{ color: 'var(--muted)' }}>Creator self-described as:</strong>{' '}
          {[...selfDescriptions].join(' · ')}
        </div>
      )}

      {shadeMatchVideos.length > 0 && (
        <div style={{ marginBottom: 12 }}>
          <div style={{ fontSize: 11, color: '#e8c5ff', marginBottom: 6, fontWeight: 600 }}>
            ★ Shade match videos ({shadeMatchVideos.length})
          </div>
          {shadeMatchVideos.map(v => (
            <div key={v.id} style={{ fontSize: 11, color: 'var(--muted)', wordBreak: 'break-all', marginBottom: 4 }}>
              {v.video_url}
            </div>
          ))}
        </div>
      )}

      {audience.size > 0 && (
        <Section label="Audience signals (who they're targeting)">
          {sortByCount(audience).map(([phrase, n]) => <Tag key={phrase} text={phrase} count={n} highlight />)}
        </Section>
      )}
      {skinToneLang.size > 0 && (
        <Section label="Skin tone language">
          {sortByCount(skinToneLang).map(([phrase, n]) => <Tag key={phrase} text={phrase} count={n} />)}
        </Section>
      )}
      {sentiment.size > 0 && (
        <Section label="Performance phrases">
          {sortByCount(sentiment).slice(0, 12).map(([phrase, n]) => <Tag key={phrase} text={phrase} count={n} />)}
        </Section>
      )}
    </div>
  );
}

function Section({ label, children }) {
  return (
    <div style={{ marginBottom: 10 }}>
      <div style={{
        fontSize: 10, textTransform: 'uppercase', letterSpacing: 0.5,
        color: 'var(--muted)', fontWeight: 600, marginBottom: 6,
      }}>{label}</div>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>{children}</div>
    </div>
  );
}

function Tag({ text, count, highlight }) {
  return (
    <span style={{
      fontSize: 11, padding: '3px 8px', borderRadius: 999,
      background: highlight ? '#3a2c4a' : 'var(--panel)',
      color: highlight ? '#e8c5ff' : 'var(--text)',
      border: '1px solid var(--border)',
    }}>
      {text}{count > 1 ? ` ×${count}` : ''}
    </span>
  );
}

function bestProductMatch(products, brandGuess, productGuess) {
  if (!brandGuess && !productGuess) return null;
  const bg = (brandGuess ?? '').trim().toLowerCase();
  const pg = (productGuess ?? '').trim().toLowerCase();
  let best = null, bestScore = 0;
  for (const p of products) {
    const pb = p.brand.toLowerCase();
    const pn = p.name.toLowerCase();
    let score = 0;
    if (bg) {
      if (pb === bg) score += 3;
      else if (pb.includes(bg) || bg.includes(pb)) score += 2;
    }
    if (pg) {
      if (pn === pg) score += 4;
      else {
        const tokens = pg.split(/\W+/).filter(t => t.length >= 3);
        const hits = tokens.filter(t => pn.includes(t)).length;
        score += Math.min(hits, 3);
      }
    }
    if (score > bestScore) { bestScore = score; best = p; }
  }
  return bestScore >= 2 ? best : null;
}
