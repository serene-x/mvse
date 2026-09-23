import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import '../../env.dart';

class AuthRepository {
  // Public auth settings prevent offering providers the backend cannot accept.
  Future<Set<OAuthProvider>> enabledSocialProviders() async {
    if (!Env.backendAvailable) return {};
    try {
      final response = await http.get(
        Uri.parse('${Env.supabaseUrl}/auth/v1/settings'),
        headers: {'apikey': Env.supabaseAnonKey},
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return {};
      final settings = jsonDecode(response.body) as Map<String, dynamic>;
      final external = settings['external'] as Map<String, dynamic>? ?? {};
      return {
        if (external['google'] == true) OAuthProvider.google,
        if (external['apple'] == true) OAuthProvider.apple,
      };
    } catch (_) {
      return {};
    }
  }

  Stream<AuthState> authStateChanges() =>
      Env.backendAvailable ? sb.auth.onAuthStateChange : const Stream.empty();

  Session? get currentSession =>
      Env.backendAvailable ? sb.auth.currentSession : null;
  User? get currentUser => Env.backendAvailable ? sb.auth.currentUser : null;
  bool get isLoggedIn => currentSession != null;

  Future<void> signInWithEmail(String email, String password) async {
    if (!Env.backendAvailable) {
      throw StateError(
          'Sign-in is temporarily unavailable. You can still browse and save products.');
    }
    await sb.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    if (!Env.backendAvailable) {
      throw StateError('Accounts are temporarily unavailable.');
    }
    await sb.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: kIsWeb ? '${Uri.base.origin}/' : Env.oauthRedirect);
  }

  Future<void> signInWithGoogle() async {
    await sb.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : Env.oauthRedirect,
    );
  }

  Future<void> signInWithApple() async {
    await sb.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kIsWeb ? Uri.base.origin : Env.oauthRedirect,
    );
  }

  Future<void> signOut() => sb.auth.signOut();
}
