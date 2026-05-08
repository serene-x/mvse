import React, { useEffect, useMemo, useState } from 'react';
import { supabase } from '../lib/supabase.js';
import { admin } from '../lib/api.js';

// Simple Jaccard-like similarity over (brand, product, shade) tuples in
// each creator's shade_profile JSONB. Surfaces top suggestions for the
// active creator and lets the admin confirm pairs.

function tuplesFromProfile(profile) {
  const out = new Set();
  if (!profile || typeof profile !== 'object') return out;
  for (const [brand, items] of Object.entries(profile)) {
    if (!Array.isArray(items)) continue;
    for (const it of items) {
      const key = `${brand}::${(it.product ?? '').toLowerCase()}::${(it.shade ?? '').toLowerCase()}`;
      out.add(key);
    }
  }
  return out;
}

function jaccard(a, b) {
  if (!a.size || !b.size) return 0;
  let inter = 0;
  for (const x of a) if (b.has(x)) inter++;
  const union = a.size + b.size - inter;
  return inter / union;
}

export default function ShadeTwinCalculator() {
  const [creators, setCreators] = useState([]);
  const [activeId, setActiveId] = useState(null);
  const [confirmedPairs, setConfirmedPairs] = useState(new Set());

  useEffect(() => {
    (async () => {
      const { data } = await supabase
        .from('creators').select('id, tiktok_handle, shade_profile, skin_tone_desc');
      setCreators(data ?? []);
      const { data: pairs } = await supabase
        .from('shade_twins').select('creator_a_id, creator_b_id, confirmed').eq('confirmed', true);
      setConfirmedPairs(new Set((pairs ?? []).map(p => `${p.creator_a_id}|${p.creator_b_id}`)));
    })();
  }, []);

  const active = creators.find(c => c.id === activeId);

  const suggestions = useMemo(() => {
    if (!active) return [];
    const a = tuplesFromProfile(active.shade_profile);
    return creators
      .filter(c => c.id !== active.id)
      .map(c => ({ creator: c, score: jaccard(a, tuplesFromProfile(c.shade_profile)) }))
      .filter(s => s.score > 0)
      .sort((x, y) => y.score - x.score)
      .slice(0, 20);
  }, [creators, active]);

  async function confirmPair(other, score) {
    if (!active) return;
    const [aId, bId] = [active.id, other.id].sort();
    await admin.saveShadeTwin({ creatorAId: aId, creatorBId: bId, confidence: Number(score.toFixed(3)) });
    setConfirmedPairs(prev => new Set(prev).add(`${aId}|${bId}`));
  }

  return (
    <>
      <h2>Shade Twins</h2>
      <select value={activeId ?? ''} onChange={e => setActiveId(e.target.value || null)}>
        <option value="">— pick a creator —</option>
        {creators.map(c => <option key={c.id} value={c.id}>@{c.tiktok_handle}</option>)}
      </select>

      {active && (
        <>
          <div style={{ fontSize: 12, color: 'var(--muted)', margin: '8px 0' }}>
            {active.skin_tone_desc ? `Tone: ${active.skin_tone_desc}` : 'No tone description set'}
          </div>

          <h2>Suggestions ({suggestions.length})</h2>
          {suggestions.length === 0 && (
            <div style={{ color: 'var(--muted)', fontSize: 12 }}>
              No overlapping tuples. Confirm more shades on creator profiles first.
            </div>
          )}
          {suggestions.map(({ creator, score }) => {
            const [aId, bId] = [active.id, creator.id].sort();
            const isConfirmed = confirmedPairs.has(`${aId}|${bId}`);
            return (
              <div key={creator.id} className="row">
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13 }}>@{creator.tiktok_handle}</div>
                  <small className="url">{creator.skin_tone_desc ?? '—'}</small>
                </div>
                <div style={{ fontSize: 12, color: 'var(--muted)', marginRight: 6 }}>
                  {(score * 100).toFixed(0)}%
                </div>
                <button className={isConfirmed ? 'ghost' : 'primary'}
                        disabled={isConfirmed}
                        onClick={() => confirmPair(creator, score)}>
                  {isConfirmed ? 'Confirmed' : 'Confirm pair'}
                </button>
              </div>
            );
          })}
        </>
      )}
    </>
  );
}
