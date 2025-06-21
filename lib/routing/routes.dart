import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zanzibar_tourism/models/cultural_site.dart';
import 'package:zanzibar_tourism/providers/auth_provider.dart';
import 'package:zanzibar_tourism/routing/go_router_refresh_stream.dart';
import 'package:zanzibar_tourism/screens/client/education_screen.dart';
import 'package:zanzibar_tourism/screens/client/navigation_screen.dart';
import 'package:zanzibar_tourism/screens/client/profile_screen.dart';
import 'package:zanzibar_tourism/screens/auth/login_screen.dart';
import 'package:zanzibar_tourism/screens/auth/register_screen.dart';
import 'package:zanzibar_tourism/screens/client/booking_screen.dart';
import 'package:zanzibar_tourism/screens/client/home_screen.dart';
import 'package:zanzibar_tourism/screens/client/marketplace_screen.dart';
import 'package:zanzibar_tourism/screens/client/client_shell.dart';
import 'package:zanzibar_tourism/screens/admin/admin_shell.dart';
import 'package:zanzibar_tourism/screens/admin/admin_dashboard_screen.dart';
import 'package:zanzibar_tourism/screens/admin/admin_content_screen.dart';
import 'package:zanzibar_tourism/screens/admin/admin_business_screen.dart';
import 'package:zanzibar_tourism/screens/admin/admin_analytics_screen.dart';
import 'package:zanzibar_tourism/screens/admin/admin_users_screen.dart';
import 'package:zanzibar_tourism/screens/admin/admin_booking_management_screen.dart';
import 'package:zanzibar_tourism/screens/admin/admin_product_management_screen.dart';
import 'package:zanzibar_tourism/screens/client/site_screen_detail.dart';
import 'package:zanzibar_tourism/screens/client/tour_detail_screen.dart';
import 'package:zanzibar_tourism/screens/client/favorites_screen.dart';
import 'package:zanzibar_tourism/services/auth_service.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

enum AppRoute {
  login,
  client,
  admin,
  adminDashboard,
  adminContent,
  adminBookings,
  adminProducts,
  adminBusiness,
  adminAnalytics,
  adminUsers,
  clientSites,
  clientSiteDetails,
  clientBooking,
  clientMarketplace,
  clientFavorites,
  clientEducation,
  clientProfile,
  clientNavigation,
  clientTourDetails,
  clientProductDetails,
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authService = ref.read(authServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  final isAdmin = currentUser?.isAdmin ?? false;

  return GoRouter(
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    initialLocation: '/',
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = currentUser != null;

      // Redirect to login if not logged in
      if (!isLoggedIn) {
        if (state.uri.toString() != '/login') {
          return '/login';
        }
        return null;
      }

      // Redirect to home if already logged in
      if (state.uri.toString() == '/login') {
        return '/${isAdmin ? 'admin/dashboard' : 'client/sites'}';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/login'),
      GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => RegisterScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ClientShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/sites',
                name: AppRoute.clientSites.name,
                builder: (context, state) => HomeScreen(),

                routes: [
                  GoRoute(
                    path: "sites/:id",
                    name: AppRoute.clientSiteDetails.name,
                    builder: (context, state) {
                      final site = state.extra as CulturalSite;
                      return SiteDetailScreen(site: site);
                    },
                  ),
                  GoRoute(
                    path: "tours/:id",
                    name: AppRoute.clientTourDetails.name,
                    builder: (context, state) {
                      final tourId = state.pathParameters['id']!;
                      return TourDetailScreen(tourId: tourId);
                    },
                  ),
                ],
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/booking',
                name: AppRoute.clientBooking.name,
                builder: (context, state) => const BookingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/marketplace',
                name: AppRoute.clientMarketplace.name,

                builder: (context, state) => const MarketplaceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/favorites',
                name: AppRoute.clientFavorites.name,

                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/education',
                name: AppRoute.clientEducation.name,

                builder: (context, state) => const EducationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/profile',
                name: AppRoute.clientProfile.name,

                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/navigation',
                name: AppRoute.clientNavigation.name,

                builder: (context, state) => const NavigationScreen(),
              ),
            ],
          ),
        ],
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/dashboard',
                name: AppRoute.adminDashboard.name,

                builder: (context, state) => const AdminDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/content',
                name: AppRoute.adminContent.name,

                builder: (context, state) => const AdminContentScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/business',
                name: AppRoute.adminBusiness.name,

                builder: (context, state) => const AdminBusinessScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/analytics',
                name: AppRoute.adminAnalytics.name,

                builder: (context, state) => const AdminAnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/users',
                name: AppRoute.adminUsers.name,

                builder: (context, state) => const AdminUsersScreen(),
              ),
            ],
          ),
        ],
      ),

      // Additional Admin Routes (not in shell)
      GoRoute(
        path: '/admin/bookings',
        name: AppRoute.adminBookings.name,
        builder: (context, state) => const AdminBookingManagementScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        name: AppRoute.adminProducts.name,
        builder: (context, state) => const AdminProductManagementScreen(),
      ),
    ],
  );
});
