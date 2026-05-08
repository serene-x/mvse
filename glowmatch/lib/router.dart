import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/sign_in_screen.dart';
import 'features/auth/sign_up_screen.dart';
import 'features/discovery/discovery_screen.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/product/product_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/search/search_screen.dart';
import 'features/shade_twin/shade_twin_screen.dart';
import 'providers/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Listen to auth state so go_router redirects when sign-in/out happens.
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/discovery',
    refreshListenable: GoRouterRefreshStream(authState),
    redirect: (context, state) {
      final loggedIn = ref.read(authRepositoryProvider).isLoggedIn;
      final loggingIn = state.matchedLocation.startsWith('/auth');
      final onboarding = state.matchedLocation.startsWith('/onboarding');

      if (!loggedIn) return loggingIn ? null : '/auth/sign-in';

      // Check onboarding_complete via cached profile (best-effort).
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      if (profile != null && !profile.onboardingComplete && !onboarding) {
        return '/onboarding';
      }

      if (loggingIn) return '/discovery';
      return null;
    },
    routes: [
      GoRoute(path: '/auth/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/auth/sign-up', builder: (_, __) => const SignUpScreen()),

      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingFlow()),

      GoRoute(path: '/discovery', builder: (_, __) => const DiscoveryScreen()),
      GoRoute(path: '/search',    builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/twins',     builder: (_, __) => const ShadeTwinScreen()),
      GoRoute(path: '/profile',   builder: (_, __) => const ProfileScreen()),

      GoRoute(
        path: '/product/:id',
        builder: (_, state) => ProductScreen(productId: state.pathParameters['id']!),
      ),
    ],
  );
});

// Bridges a Riverpod AsyncValue snapshot into a Listenable so GoRouter
// re-evaluates redirects whenever auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(AsyncValue<dynamic> async) {
    notifyListeners();
  }
}
