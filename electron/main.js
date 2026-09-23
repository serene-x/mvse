const { app, BrowserWindow, BrowserView, ipcMain, shell } = require('electron');
const path = require('node:path');
const fs = require('node:fs');

require('dotenv').config({
  path: app.isPackaged
    ? path.join(app.getPath('userData'), '.env')
    : path.join(__dirname, '..', '.env'),
});

const queue = require('../services/queue');
const sb = require('../services/supabase');
const { attachInterceptors } = require('./interceptor');

const RENDERER_DEV_URL = 'http://localhost:5173';
const RIGHT_PANEL_WIDTH = 480;
const TIKTOK_URL = 'https://www.tiktok.com/foryou';
const isDev = () => process.env.NODE_ENV === 'development';

let mainWindow = null;
let tiktokView = null;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1440,
    height: 900,
    title: 'mvse Admin',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      sandbox: false,
      nodeIntegration: false,
    },
  });

  if (isDev()) {
    mainWindow.loadURL(RENDERER_DEV_URL);
    mainWindow.webContents.openDevTools({ mode: 'detach' });
  } else {
    mainWindow.loadFile(path.join(__dirname, '..', 'dist', 'index.html'));
  }

  attachTikTokView();
  mainWindow.on('resize', layoutViews);
  mainWindow.on('closed', () => {
    mainWindow = null;
    tiktokView = null;
  });
}

function attachTikTokView() {
  tiktokView = new BrowserView({
    webPreferences: {
      preload: path.join(__dirname, 'tiktokPreload.js'),
      contextIsolation: true,
      sandbox: false,
      partition: 'persist:tiktok',
    },
  });
  mainWindow.addBrowserView(tiktokView);
  layoutViews();
  tiktokView.webContents.loadURL(TIKTOK_URL);

  const contentScript = fs.readFileSync(
    path.join(__dirname, 'contentScript.js'),
    'utf8',
  );
  const inject = () =>
    tiktokView.webContents.executeJavaScript(contentScript).catch(() => {});
  tiktokView.webContents.on('did-finish-load', inject);
  tiktokView.webContents.on('did-navigate-in-page', inject);

  attachInterceptors(tiktokView.webContents, ({ kind, payload }) => {
    if (kind === 'apiHit' && mainWindow) {
      mainWindow.webContents.send('tiktok:apiHit', payload);
    }
  });

  tiktokView.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });
}

function layoutViews() {
  if (!mainWindow || !tiktokView) return;
  const { width, height } = mainWindow.getContentBounds();
  const tiktokWidth = Math.max(400, width - RIGHT_PANEL_WIDTH);
  tiktokView.setBounds({ x: 0, y: 0, width: tiktokWidth, height });
  tiktokView.setAutoResize({ width: false, height: true });
}

ipcMain.on('tiktok:videoCaptured', async (_evt, payload) => {
  try {
    const video = await queue.enqueue(payload);
    if (video && mainWindow) {
      mainWindow.webContents.send('queue:enqueued', {
        id: video.id,
        url: video.video_url,
      });
    }
  } catch (err) {
    console.error('enqueue failed', err);
    if (mainWindow)
      mainWindow.webContents.send('queue:error', { error: err.message });
  }
});

ipcMain.handle('admin:captureCurrent', async () => {
  if (!tiktokView) throw new Error('TikTok view not ready');
  return tiktokView.webContents.executeJavaScript(
    'window.__mvseCapture && window.__mvseCapture()',
  );
});

ipcMain.handle('admin:openTikTokDevTools', () => {
  if (!tiktokView) return;
  tiktokView.webContents.openDevTools({ mode: 'detach' });
});

ipcMain.handle(
  'admin:confirmEntity',
  async (_evt, { id, productId, shadeId }) => {
    const { error } = await sb
      .admin()
      .from('extracted_entities')
      .update({
        reviewed: true,
        product_id: productId ?? null,
        shade_id: shadeId ?? null,
      })
      .eq('id', id);
    if (error) throw error;
    return { ok: true };
  },
);

ipcMain.handle('admin:upsertProduct', (_evt, fields) =>
  sb.upsertProduct(fields),
);
ipcMain.handle('admin:updateProduct', (_evt, { id, fields }) =>
  sb.updateProduct(id, fields),
);
ipcMain.handle('admin:addShade', (_evt, { productId, shadeName, hexColor }) =>
  sb.addShade(productId, shadeName, hexColor),
);

ipcMain.handle('admin:linkMention', async (_evt, args) => {
  const { videoId, productId, shadeName, hexColor, sentimentTags } = args;
  let { videoUrl, viewCount } = args;

  // tiktok_mentions.video_url is NOT NULL; fall back to the video's URL.
  if ((!videoUrl || viewCount == null) && videoId) {
    const { data: vid } = await sb
      .admin()
      .from('tiktok_videos')
      .select('video_url, view_count')
      .eq('id', videoId)
      .single();
    if (vid) {
      videoUrl = videoUrl ?? vid.video_url;
      viewCount = viewCount ?? vid.view_count;
    }
  }
  if (!videoUrl) throw new Error('linkMention requires a video_url');

  const { data, error } = await sb
    .admin()
    .from('tiktok_mentions')
    .insert({
      product_id: productId,
      video_id: videoId,
      video_url: videoUrl,
      view_count: viewCount ?? 0,
      sentiment_tags: sentimentTags ?? [],
      confirmed: true,
    })
    .select()
    .single();
  if (error) throw error;
  if (shadeName) await sb.addShade(productId, shadeName, hexColor ?? null);
  return data;
});

ipcMain.handle(
  'admin:saveShadeTwin',
  async (_evt, { creatorAId, creatorBId, confidence }) => {
    await sb.saveShadeTwin(creatorAId, creatorBId, confidence, true);
    return { ok: true };
  },
);

ipcMain.handle('admin:updateCreator', async (_evt, { id, fields }) => {
  const { data, error } = await sb
    .admin()
    .from('creators')
    .update(fields)
    .eq('id', id)
    .select()
    .single();
  if (error) throw error;
  return data;
});

queue.setLogger((entry) => {
  if (mainWindow) mainWindow.webContents.send('queue:log', entry);
});

app.whenReady().then(async () => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
  try {
    await queue.rehydrate();
  } catch (err) {
    console.error('rehydrate failed', err);
  }
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

ipcMain.handle('admin:saveManualShadeReport', (_evt, input) =>
  require('../services/manualShadeReports').saveManualReport(input),
);
