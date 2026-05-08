# mvse (Flutter app)

The consumer-facing app: discovery feed, shade twins, search, owned-products
onboarding. Talks to the same Supabase project as the Electron admin tool in `..`.

The folder is named `glowmatch/` for legacy reasons; the package and product
name is `mvse`.

## Stack

Flutter 3.22+ / Dart 3.4+. supabase_flutter, flutter_riverpod, go_router,
google_fonts, url_launcher, sign_in_with_apple, google_sign_in, cached_network_image.

## Layout

```
lib/
├── main.dart, app.dart, theme.dart, env.dart, router.dart
├── core/supabase_client.dart
├── data/
│   ├── models/models.dart
│   └── repositories/         all Supabase calls live here
├── providers/providers.dart  Riverpod
├── features/
│   ├── auth/
│   ├── onboarding/
│   ├── discovery/
│   ├── product/
│   ├── shade_twin/
│   ├── search/
│   └── profile/
└── widgets/
```

## Architecture rules

- Repositories own every Supabase call. Widgets and providers do not import
  `supabase_flutter` directly.
- Providers are the boundary between repositories and UI.

## Run

```bash
cd glowmatch
flutter pub get

flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

Swap `chrome` for `ios` or `android` when those are set up.

## Database setup

Run `node ../apply_migrations.js` from the project root — it applies everything
including this app's views and RPCs.

What `003_glowmatch_views.sql` adds:

- `product_with_mention_count` view (discovery sort key)
- `product_top_sentiments` view (top 5 sentiment tags per product)
- `match_user_to_creators(user_id)` RPC (Jaccard-ish creator similarity)
- `recommended_products_for_user(user_id)` RPC (For You feed)
- `your_shade_for_product(user_id, product_id)` RPC (the "your shade" pill)

`006_shade_twins_from_videos.sql` adds two more RPCs that derive shade-twin
relationships from the admin tool's confirmed `extracted_entities`:
`shade_equivalences_for(...)` and `shade_twins_for_user(...)`.

## Auth

Email/password works out of the box. Google + Apple use
`Supabase.auth.signInWithOAuth` with the deep link `app.mvse://login-callback`,
which means you need:

- URL scheme in `ios/Runner/Info.plist` (`CFBundleURLTypes`)
- Intent-filter in `android/app/src/main/AndroidManifest.xml`
- Google + Apple configured as providers in Supabase with that redirect

For web, drop the `redirectTo` and let Supabase handle the popup.

## Onboarding + profile

Onboarding writes `users.skin_tone_desc`, `users.undertone`, and bulk-inserts
into `user_owned_products`. The router redirects logged-in users with
`onboarding_complete = false` to `/onboarding`.

`/profile` (person icon in the discovery app bar) lets users edit skin tone,
undertone, and owned products. Mutations invalidate the relevant providers so
the For You feed and shade twins refresh.

## Known limitations

- Shade-twin scoring is a SQL Jaccard heuristic. Tune `match_user_to_creators`
  once you have real volume.
- Search is `ilike` on name + brand. Move to a `tsvector` index past a few
  thousand catalog rows.
- OAuth native config (Info.plist, AndroidManifest) isn't included.

## Color palette

```
warmWhite #FAF6F2     surface  #FFFFFF
beige     #F1E5DA     beigeDeep #E3D1C1
rose      #C4928E     roseDeep  #9F6E6A
text      #3A2E2A     textMuted #8A7C76
stroke    #EADFD5     positive  #7FA37A
```
