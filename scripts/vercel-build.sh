#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  flutter_dir="${TMPDIR:-/tmp}/mvse-flutter-3.44.5"
  if [[ ! -x "$flutter_dir/bin/flutter" ]]; then
    git clone --depth 1 --branch 3.44.5 https://github.com/flutter/flutter.git "$flutter_dir"
  fi
  export PATH="$flutter_dir/bin:$PATH"
fi

flutter config --no-analytics
public_config="$(mktemp)"
trap 'rm -f "$public_config"' EXIT

node - "$public_config" <<'NODE'
const { writeFileSync } = require('node:fs');
writeFileSync(process.argv[2], JSON.stringify({
  SUPABASE_URL: process.env.SUPABASE_URL || '',
  SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY || '',
}), { mode: 0o600 });
NODE

cd glowmatch
flutter build web --release --dart-define-from-file="$public_config"
