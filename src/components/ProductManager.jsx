import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase.js';
import { admin } from '../lib/api.js';

const CATEGORIES = ['foundation', 'blush', 'lip'];

export default function ProductManager() {
  const [products, setProducts] = useState([]);
  const [filter, setFilter] = useState('');
  const [editing, setEditing] = useState(null);

  async function reload() {
    const { data } = await supabase
      .from('products')
      .select('id, name, brand, category, sephora_url, ulta_url')
      .order('brand');
    setProducts(data ?? []);
  }
  useEffect(() => {
    reload();
  }, []);

  async function save(form) {
    if (form.id) await admin.updateProduct({ id: form.id, fields: form });
    else await admin.upsertProduct(form);
    setEditing(null);
    reload();
  }

  const filtered = products.filter(
    (p) =>
      !filter ||
      `${p.brand} ${p.name}`.toLowerCase().includes(filter.toLowerCase()),
  );

  return (
    <>
      <h2>Products</h2>
      <input
        placeholder="Filter…"
        value={filter}
        onChange={(e) => setFilter(e.target.value)}
      />
      <button
        className="primary"
        style={{ marginTop: 6 }}
        onClick={() =>
          setEditing({ name: '', brand: '', category: 'foundation' })
        }
      >
        + New product
      </button>

      <div style={{ marginTop: 12 }}>
        {filtered.map((p) => (
          <div key={p.id} className="row">
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 12 }}>{p.brand}</div>
              <div style={{ fontSize: 13 }}>{p.name}</div>
              <small className="url">{p.category}</small>
            </div>
            <button className="ghost" onClick={() => setEditing(p)}>
              Edit
            </button>
          </div>
        ))}
      </div>

      {editing && (
        <ProductForm
          product={editing}
          onSave={save}
          onCancel={() => setEditing(null)}
        />
      )}
    </>
  );
}

function ProductForm({ product, onSave, onCancel }) {
  const [form, setForm] = useState(product);
  const [shadeName, setShadeName] = useState('');
  const [hex, setHex] = useState('#');

  function set(k, v) {
    setForm((f) => ({ ...f, [k]: v }));
  }

  async function addShade() {
    if (!form.id) return;
    if (!shadeName) return;
    await admin.addShade({
      productId: form.id,
      shadeName,
      hexColor: hex.match(/^#[0-9A-Fa-f]{6}$/) ? hex : null,
    });
    setShadeName('');
    setHex('#');
  }

  return (
    <div className="entity-card" style={{ marginTop: 12 }}>
      <h2>{form.id ? 'Edit' : 'New'} product</h2>
      <label>Brand</label>
      <input
        value={form.brand ?? ''}
        onChange={(e) => set('brand', e.target.value)}
      />
      <label>Name</label>
      <input
        value={form.name ?? ''}
        onChange={(e) => set('name', e.target.value)}
      />
      <label>Category</label>
      <select
        value={form.category}
        onChange={(e) => set('category', e.target.value)}
      >
        {CATEGORIES.map((c) => (
          <option key={c}>{c}</option>
        ))}
      </select>
      <label>Sephora URL</label>
      <input
        value={form.sephora_url ?? ''}
        onChange={(e) => set('sephora_url', e.target.value)}
      />
      <label>Ulta URL</label>
      <input
        value={form.ulta_url ?? ''}
        onChange={(e) => set('ulta_url', e.target.value)}
      />

      {form.id && (
        <>
          <h2 style={{ marginTop: 12 }}>Add shade</h2>
          <input
            placeholder="Shade name"
            value={shadeName}
            onChange={(e) => setShadeName(e.target.value)}
          />
          <input
            placeholder="#RRGGBB"
            value={hex}
            onChange={(e) => setHex(e.target.value)}
            style={{ marginTop: 4 }}
          />
          <button className="ghost" style={{ marginTop: 6 }} onClick={addShade}>
            Add shade
          </button>
        </>
      )}

      <div style={{ marginTop: 12, display: 'flex', gap: 6 }}>
        <button className="primary" onClick={() => onSave(form)}>
          Save
        </button>
        <button className="ghost" onClick={onCancel}>
          Cancel
        </button>
      </div>
    </div>
  );
}
