import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/sign_in_screen.dart';
import 'features/auth/sign_up_screen.dart';
import 'features/discovery/discovery_screen.dart';
import 'features/ingredients/ingredient_library_screen.dart';
import 'features/ingredients/ingredient_profile_screen.dart';
import 'features/ingredients/ingredient_screen.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/product/product_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/recommendations/recommendations_screen.dart';
import 'features/routine/routine_screen.dart';
import 'features/search/search_screen.dart';
import 'features/colour/colour_screen.dart';
import 'features/colour/season_browser_screen.dart';
import 'providers/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Refresh redirects without rebuilding GoRouter, which would reset navigation.
  final refresh = GoRouterRefreshStream(
      ref.watch(authRepositoryProvider).authStateChanges());
  ref.onDispose(refresh.dispose);

  GoRouter.optionURLReflectsImperativeAPIs = true;
  return GoRouter(
    initialLocation: '/discovery',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(authRepositoryProvider).isLoggedIn;
      final loggingIn = state.matchedLocation.startsWith('/auth');
      final onboarding = state.matchedLocation.startsWith('/onboarding');

      final publicPage = state.matchedLocation == '/discovery' ||
          state.matchedLocation == '/search' ||
          state.matchedLocation == '/seasons' ||
          state.matchedLocation == '/ingredients' ||
          state.matchedLocation.startsWith('/ingredient/') ||
          state.matchedLocation.startsWith('/product/');
      if (!loggedIn) return loggingIn || publicPage ? null : '/auth/sign-in';

      // Check onboarding_complete via cached profile (best-effort).
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      if (profile != null &&
          !profile.onboardingComplete &&
          !onboarding &&
          !publicPage) {
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
      GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/twins', builder: (_, __) => const ColourScreen()),
      GoRoute(path: '/colour', builder: (_, __) => const ColourScreen()),
      GoRoute(
          path: '/seasons', builder: (_, __) => const SeasonBrowserScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(
          path: '/for-you', builder: (_, __) => const RecommendationsScreen()),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) =>
            ProductScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
          path: '/ingredients',
          builder: (_, __) => const IngredientLibraryScreen()),
      GoRoute(
          path: '/skin-profile',
          builder: (_, __) => const IngredientProfileScreen()),
      GoRoute(path: '/routine', builder: (_, __) => const RoutineScreen()),
      GoRoute(
        path: '/ingredient/:id',
        builder: (_, state) =>
            IngredientScreen(ingredientId: state.pathParameters['id']!),
      ),
    ],
  );
});

// Re-evaluate redirects when authentication changes.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
