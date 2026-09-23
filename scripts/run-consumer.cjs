// Pass only public Supabase configuration to Flutter; never bundle .env secrets.
const { spawn } = require('node:child_process');
const { mkdtempSync, writeFileSync, rmSync } = require('node:fs');
const { tmpdir } = require('node:os');
const { join, resolve } = require('node:path');
require('dotenv').config({ path: resolve(__dirname, '../.env') });
const dir = mkdtempSync(join(tmpdir(), 'mvse-config-'));
const file = join(dir, 'public.json');
writeFileSync(
  file,
  JSON.stringify({
    SUPABASE_URL: process.env.SUPABASE_URL || '',
    SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY || '',
  }),
  { mode: 0o600 },
);
const build = process.argv.includes('--build');
const args = build
  ? ['build', 'web']
  : ['run', '-d', 'web-server', '--web-hostname=127.0.0.1', '--web-port=8080'];
args.push(`--dart-define-from-file=${file}`);
const child = spawn('flutter', args, {
  cwd: resolve(__dirname, '../glowmatch'),
  stdio: 'inherit',
});
const cleanup = () => rmSync(dir, { recursive: true, force: true });
child.on('error', (e) => {
  cleanup();
  console.error(e.message);
  process.exitCode = 1;
});
child.on('exit', (code) => {
  cleanup();
  process.exitCode = code ?? 1;
});
for (const signal of ['SIGINT', 'SIGTERM'])
  process.on(signal, () => child.kill(signal));
