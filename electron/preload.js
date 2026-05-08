const { contextBridge, ipcRenderer } = require('electron');

const RENDERER_CHANNELS = ['queue:enqueued', 'queue:log', 'queue:error', 'tiktok:apiHit'];

contextBridge.exposeInMainWorld('admin', {
  confirmEntity: args => ipcRenderer.invoke('admin:confirmEntity', args),
  upsertProduct: args => ipcRenderer.invoke('admin:upsertProduct', args),
  updateProduct: args => ipcRenderer.invoke('admin:updateProduct', args),
  addShade: args => ipcRenderer.invoke('admin:addShade', args),
  linkMention: args => ipcRenderer.invoke('admin:linkMention', args),
  saveShadeTwin: args => ipcRenderer.invoke('admin:saveShadeTwin', args),
  updateCreator: args => ipcRenderer.invoke('admin:updateCreator', args),
  captureCurrent: () => ipcRenderer.invoke('admin:captureCurrent'),
  openTikTokDevTools: () => ipcRenderer.invoke('admin:openTikTokDevTools'),

  env: {
    supabaseUrl: process.env.SUPABASE_URL,
    supabaseAnonKey: process.env.SUPABASE_ANON_KEY,
  },

  on: (channel, handler) => {
    if (!RENDERER_CHANNELS.includes(channel)) return () => {};
    const fn = (_evt, payload) => handler(payload);
    ipcRenderer.on(channel, fn);
    return () => ipcRenderer.off(channel, fn);
  },
});
