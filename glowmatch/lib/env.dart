// Compile-time env. Provide via --dart-define on flutter run/build:
//   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Deep-link redirect for OAuth (Google/Apple). Configure URL scheme in
  // ios/Info.plist and android/app/build.gradle accordingly.
  static const oauthRedirect = 'app.mvse://login-callback';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
