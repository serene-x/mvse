# MVSE

Beauty discovery, shade matching and a personal product diary. Built with Flutter, React, Electron and Supabase.

## Run

Install Node.js 20+ and Flutter, then:

```bash
npm ci
npm run app
```

Open `http://127.0.0.1:8080`. Product browsing works without an account or backend configuration.

For accounts and saved products, copy `.env.example` to `.env` and add your Supabase URL and anonymous key. Admin credentials stay local.

## Commands

```bash
npm run app:build       # Consumer web build
npm run dev             # Desktop admin
npm test                # Admin tests
cd glowmatch
flutter analyze
flutter test
```

Product images and brand names belong to their respective owners. The bundled font includes its [licence](glowmatch/assets/fonts/OFL.txt).
