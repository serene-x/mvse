const { spawn } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const ffmpegPath = require('ffmpeg-static');

const YTDLP = process.env.YTDLP_PATH || 'yt-dlp';
const TMP_ROOT = path.join(os.tmpdir(), 'mvse');

function run(cmd, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    let stderr = '';
    child.stderr.on('data', (d) => {
      stderr += d.toString();
    });
    child.on('error', reject);
    child.on('close', (code) => {
      if (code === 0) resolve();
      else reject(new Error(`${cmd} exited ${code}: ${stderr.slice(-2000)}`));
    });
  });
}

function workDir(videoId) {
  const dir = path.join(TMP_ROOT, videoId);
  fs.mkdirSync(dir, { recursive: true });
  return dir;
}

async function downloadVideo(videoUrl, videoId) {
  const outPath = path.join(workDir(videoId), 'video.mp4');
  // TikTok's plain "mp4" alias often resolves to a video-only stream, which
  // then breaks Whisper. Demand audio explicitly and let yt-dlp merge.
  await run(YTDLP, [
    '--no-playlist',
    '--ffmpeg-location',
    ffmpegPath,
    '-f',
    'best[acodec!=none][vcodec!=none]/bv*+ba/best',
    '--merge-output-format',
    'mp4',
    '-o',
    outPath,
    videoUrl,
  ]);
  return outPath;
}

async function extractAudio(videoPath) {
  const audioPath = videoPath.replace(/\.mp4$/, '.m4a');
  try {
    await run(ffmpegPath, [
      '-y',
      '-i',
      videoPath,
      '-vn',
      '-ac',
      '1',
      '-ar',
      '16000',
      '-c:a',
      'aac',
      audioPath,
    ]);
    return audioPath;
  } catch {
    return null;
  }
}

async function extractFrames(videoPath, n = 3) {
  const duration = await readDuration(videoPath);
  const dir = path.dirname(videoPath);

  const stamps = [];
  for (let i = 1; i <= n; i++) stamps.push((duration * i) / (n + 1));

  const paths = [];
  for (const [idx, t] of stamps.entries()) {
    const framePath = path.join(dir, `frame_${idx}.jpg`);
    await run(ffmpegPath, [
      '-y',
      '-ss',
      String(t),
      '-i',
      videoPath,
      '-frames:v',
      '1',
      '-q:v',
      '3',
      framePath,
    ]);
    paths.push(framePath);
  }
  return paths;
}

function readDuration(videoPath) {
  return new Promise((resolve, reject) => {
    const child = spawn(ffmpegPath, ['-i', videoPath], {
      stdio: ['ignore', 'ignore', 'pipe'],
    });
    let buf = '';
    child.stderr.on('data', (d) => {
      buf += d.toString();
    });
    child.on('close', () => {
      const m = buf.match(/Duration:\s*(\d+):(\d+):(\d+\.\d+)/);
      if (!m) return resolve(10);
      resolve(+m[1] * 3600 + +m[2] * 60 + +m[3]);
    });
    child.on('error', reject);
  });
}

function cleanup(videoId) {
  fs.rmSync(path.join(TMP_ROOT, videoId), { recursive: true, force: true });
}

module.exports = { downloadVideo, extractAudio, extractFrames, cleanup };
