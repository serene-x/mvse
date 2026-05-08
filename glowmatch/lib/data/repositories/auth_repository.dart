import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import '../../env.dart';

class AuthRepository {
  Stream<AuthState> authStateChanges() => sb.auth.onAuthStateChange;

  Session? get currentSession => sb.auth.currentSession;
  User?    get currentUser    => sb.auth.currentUser;
  bool     get isLoggedIn     => sb.auth.currentSession != null;

  Future<void> signInWithEmail(String email, String password) async {
    await sb.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await sb.auth.signUp(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    await sb.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: Env.oauthRedirect,
    );
  }

  Future<void> signInWithApple() async {
    await sb.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: Env.oauthRedirect,
    );
  }

  Future<void> signOut() => sb.auth.signOut();
}
