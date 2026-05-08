import React, { useEffect, useState } from 'react';
import QueuePanel from './components/QueuePanel.jsx';
import CreatorBuilder from './components/CreatorBuilder.jsx';
import ProductManager from './components/ProductManager.jsx';
import ShadeTwinCalculator from './components/ShadeTwinCalculator.jsx';
import { admin } from './lib/api.js';

const TABS = [
  { id: 'queue',    label: 'Queue',    Component: QueuePanel },
  { id: 'creator',  label: 'Creator',  Component: CreatorBuilder },
  { id: 'product',  label: 'Products', Component: ProductManager },
  { id: 'twins',    label: 'Twins',    Component: ShadeTwinCalculator }
];

export default function App() {
  const [tab, setTab] = useState('queue');
  const [logs, setLogs] = useState([]);

  useEffect(() => {
    const offLog = admin.on('queue:log', (entry) => {
      setLogs(prev => [...prev.slice(-100), entry]);
    });
    const offErr = admin.on('queue:error', (entry) => {
      setLogs(prev => [...prev.slice(-100), { level: 'error', msg: entry.error, ts: Date.now() }]);
    });
    return () => { offLog?.(); offErr?.(); };
  }, []);

  const Active = TABS.find(t => t.id === tab).Component;

  return (
    <div className="app">
      <div className="tabs">
        {TABS.map(t => (
          <button
            key={t.id}
            className={`tab ${tab === t.id ? 'active' : ''}`}
            onClick={() => setTab(t.id)}
          >{t.label}</button>
        ))}
      </div>
      <div className="panel"><Active /></div>
      <div className="toast-feed">
        {logs.slice(-6).map((l, i) => (
          <div key={i} className={l.level === 'error' ? 'err' : ''}>
            {new Date(l.ts).toLocaleTimeString()} · {l.msg}
          </div>
        ))}
      </div>
    </div>
  );
}
