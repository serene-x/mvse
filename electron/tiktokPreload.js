const { contextBridge, ipcRenderer } = require('electron');

const ALLOWED = new Set(['tiktok:videoCaptured']);

contextBridge.exposeInMainWorld('__admin', {
  send: (channel, payload) => {
    if (!ALLOWED.has(channel)) return;
    ipcRenderer.send(channel, payload);
  },
});
