import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase.js';
import { admin } from '../lib/api.js';

function ProductShade({ products, value, onChange }) {
  const [shades, setShades] = useState([]);
  useEffect(() => {
    let active = true;
    setShades([]);
    if (value.productId)
      supabase
        .from('product_shades')
        .select('shade_name')
        .eq('product_id', value.productId)
        .order('shade_name')
        .then(({ data }) => {
          if (active) setShades(data ?? []);
        });
    return () => {
      active = false;
    };
  }, [value.productId]);
  return (
    <div className="row">
      <select
        aria-label="Product"
        value={value.productId}
        onChange={(e) => onChange({ productId: e.target.value, shade: '' })}
      >
        <option value="">Choose product</option>
        {products.map((p) => (
          <option key={p.id} value={p.id}>
            {p.brand} / {p.name}
          </option>
        ))}
      </select>
      <select
        aria-label="Shade"
        value={value.shade}
        onChange={(e) => onChange({ ...value, shade: e.target.value })}
      >
        <option value="">Choose shade</option>
        {shades.map((s) => (
          <option key={s.shade_name}>{s.shade_name}</option>
        ))}
      </select>
    </div>
  );
}
export default function ManualShadeReport() {
  const [products, setProducts] = useState([]),
    [sourceUrl, setUrl] = useState(''),
    [evidence, setEvidence] = useState('');
  const [pairs, setPairs] = useState([
    { productId: '', shade: '' },
    { productId: '', shade: '' },
  ]);
  const [confirmed, setConfirmed] = useState(false),
    [busy, setBusy] = useState(false),
    [message, setMessage] = useState('');
  useEffect(() => {
    supabase
      .from('products')
      .select('id,brand,name')
      .in('category', ['foundation', 'concealer'])
      .order('brand')
      .then(({ data, error }) => {
        if (error) setMessage('Could not load products.');
        else setProducts(data ?? []);
      });
  }, []);
  async function save(e) {
    e.preventDefault();
    setBusy(true);
    setMessage('');
    try {
      await admin.saveManualShadeReport({
        sourceUrl,
        evidence,
        pairs,
        confirmed,
      });
      setMessage('Report published. It can now inform shade suggestions.');
      setUrl('');
      setEvidence('');
      setConfirmed(false);
    } catch (e) {
      setMessage(e.message ?? 'Could not save the report.');
    } finally {
      setBusy(false);
    }
  }
  return (
    <form onSubmit={save}>
      <h2>Record a shade twin</h2>
      <p>
        Watch the clip, then record the exact products the same creator says
        match their skin.
      </p>
      <label>
        TikTok video URL
        <input
          type="url"
          required
          value={sourceUrl}
          onChange={(e) => setUrl(e.target.value)}
          placeholder="https://www.tiktok.com/@creator/video/…"
        />
      </label>
      {pairs.map((pair, i) => (
        <ProductShade
          key={i}
          products={products}
          value={pair}
          onChange={(v) => setPairs(pairs.map((p, j) => (i === j ? v : p)))}
        />
      ))}
      <button
        type="button"
        onClick={() => setPairs([...pairs, { productId: '', shade: '' }])}
      >
        Add another product
      </button>
      <label>
        What you checked
        <textarea
          required
          value={evidence}
          onChange={(e) => setEvidence(e.target.value)}
          placeholder="Timestamp and a short note about the creator’s match statement"
        />
      </label>
      <label className="row">
        <input
          type="checkbox"
          checked={confirmed}
          onChange={(e) => setConfirmed(e.target.checked)}
        />
        The same person explicitly reports these as skin matches, not just
        products they own.
      </label>
      <button className="primary" disabled={busy || !confirmed}>
        {busy ? 'Saving…' : 'Publish reviewed report'}
      </button>
      <p role="status">{message}</p>
    </form>
  );
}
