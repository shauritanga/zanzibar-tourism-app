import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zanzibar_tourism/routing/go_router_refresh_stream.dart';
import 'package:zanzibar_tourism/screens/education_screen.dart';
import 'package:zanzibar_tourism/screens/navigation_screen.dart';
import 'package:zanzibar_tourism/screens/places_screen.dart';
import 'package:zanzibar_tourism/screens/profile_screen.dart';
import 'package:zanzibar_tourism/screens/scaffold_with_navigation.dart';
import 'package:zanzibar_tourism/screens/auth_screen.dart';
import 'package:zanzibar_tourism/screens/booking_screen.dart';
import 'package:zanzibar_tourism/screens/home_screen.dart';
import 'package:zanzibar_tourism/screens/marketplace_screen.dart';
import 'package:zanzibar_tourism/services/auth_service.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

enum AppRoute {
  login,
  sites,
  places,
  booking,
  marketplace,
  education,
  profile,
  navigation,
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authServiceProvider).authStateChanges,
    ),
    initialLocation: '/login',
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final path = state.uri.path;
      final isLoggedIn = ref.read(authServiceProvider).currentUser != null;
      print(isLoggedIn);

      if (isLoggedIn) {
        if (path.startsWith('/login')) {
          return '/';
        }
      } else {
        if (path.startsWith('/') ||
            path.startsWith('/places') ||
            path.startsWith('/profile') ||
            path.startsWith('/navigation') ||
            path.startsWith('/marketplace') ||
            path.startsWith('/booking') ||
            path.startsWith('/education')) {
          return '/login';
        }
      }
      return null;
    },

    routes: [
      GoRoute(path: '/login', builder: (context, state) => AuthScreen()),
      GoRoute(
        path: '/education',
        builder: (context, state) => EducationScreen(),
      ),

      GoRoute(
        path: '/navigation',
        builder: (context, state) => NavigationScreen(),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder:
            (context, state, navigationShell) => NoTransitionPage(
              child: ScaffoldWithNestedNavigation(
                navigationShell: navigationShell,
              ),
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/",
                name: AppRoute.sites.name,
                builder: (context, state) => HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/places",
                name: AppRoute.places.name,
                builder: (context, state) => CulturalShowcaseScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/booking",
                name: AppRoute.booking.name,
                builder: (context, state) => BookingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/marketplace",
                name: AppRoute.marketplace.name,

                builder: (context, state) => MarketplaceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: "/profile",
                name: AppRoute.profile.name,
                builder: (context, state) => ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
