import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase.js';
import { admin } from '../lib/api.js';

const TERMINAL = new Set(['ready', 'failed']);

export default function QueuePanel() {
  const [videos, setVideos] = useState([]);
  const [captureMsg, setCaptureMsg] = useState(null);

  async function handleCapture() {
    setCaptureMsg('capturing…');
    try {
      const result = await admin.captureCurrent();
      if (!result) setCaptureMsg('no video on screen — scroll to one and try again');
      else setCaptureMsg(`sent: ${result.video_url}`);
    } catch (e) {
      setCaptureMsg(`failed: ${e.message ?? e}`);
    }
    setTimeout(() => setCaptureMsg(null), 4000);
  }

  useEffect(() => {
    let mounted = true;
    (async () => {
      const { data } = await supabase
        .from('tiktok_videos')
        .select('id, video_url, creator_handle, caption, status, error, captured_at, nlp_result')
        .order('captured_at', { ascending: false })
        .limit(50);
      if (mounted && data) setVideos(data);
    })();

    const channel = supabase
      .channel('tiktok_videos-feed')
      .on('postgres_changes',
          { event: '*', schema: 'public', table: 'tiktok_videos' },
          (payload) => {
            setVideos(prev => {
              const next = [...prev];
              const idx = next.findIndex(v => v.id === payload.new?.id || v.id === payload.old?.id);
              if (payload.eventType === 'DELETE') {
                if (idx >= 0) next.splice(idx, 1);
              } else if (idx >= 0) {
                next[idx] = { ...next[idx], ...payload.new };
              } else if (payload.new) {
                next.unshift(payload.new);
              }
              return next.slice(0, 50);
            });
          })
      .subscribe();

    return () => { mounted = false; supabase.removeChannel(channel); };
  }, []);

  const active = videos.filter(v => !TERMINAL.has(v.status));
  const done = videos.filter(v => TERMINAL.has(v.status));

  return (
    <>
      <div style={{ display: 'flex', gap: 6, marginBottom: 10 }}>
        <button className="primary" onClick={handleCapture}>Capture this video</button>
        <button className="ghost" onClick={() => admin.openTikTokDevTools?.()}>TikTok DevTools</button>
      </div>
      {captureMsg && (
        <div style={{ fontSize: 11, color: 'var(--muted)', marginBottom: 8 }}>{captureMsg}</div>
      )}

      <h2>Active ({active.length})</h2>
      {active.length === 0 && <div style={{ color: 'var(--muted)', fontSize: 12 }}>Browse TikTok in the left panel — captured videos will appear here.</div>}
      {active.map(v => <VideoRow key={v.id} v={v} />)}

      <h2 style={{ marginTop: 16 }}>Recent ({done.length})</h2>
      {done.map(v => <VideoRow key={v.id} v={v} />)}
    </>
  );
}

function VideoRow({ v }) {
  const isShadeMatch = v.nlp_result?.is_shade_match_video === true;
  const audienceCount = (v.nlp_result?.audience_signals ?? []).length;
  return (
    <div className="row">
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 12, marginBottom: 2, display: 'flex', gap: 6, alignItems: 'center', flexWrap: 'wrap' }}>
          <span>@{v.creator_handle ?? '?'}</span>
          {isShadeMatch && (
            <span style={{
              fontSize: 10, padding: '2px 6px', borderRadius: 999,
              background: '#3a2c4a', color: '#e8c5ff',
              border: '1px solid #5a3e7a',
            }}>★ shade match</span>
          )}
          {audienceCount > 0 && (
            <span style={{ fontSize: 10, color: 'var(--muted)' }}>{audienceCount} audience signals</span>
          )}
        </div>
        <small className="url">{v.video_url}</small>
        {v.error && <div style={{ color: 'var(--bad)', fontSize: 11, marginTop: 4 }}>{v.error}</div>}
      </div>
      <span className={`status ${v.status}`}>{v.status}</span>
    </div>
  );
}
