import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/users/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/change_password_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/presentation/pages/dashboard_screen.dart';
import '../../features/editor/presentation/pages/editor_screen.dart';
import '../../features/participants/presentation/pages/participant_list_screen.dart';
import '../../features/analytics/presentation/pages/analytics_screen.dart';
import '../../features/checkin/presentation/pages/qr_scanner_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/store/presentation/pages/store_settings_screen.dart';
import '../../features/store/presentation/pages/store_dashboard_screen.dart';
import '../../features/store/presentation/pages/store_scanner_screen.dart';
import '../../features/store/presentation/pages/store_history_screen.dart';
import '../../features/store/presentation/pages/catalog_screen.dart';
import '../../features/store/presentation/pages/store_pos_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  
  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: _GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final isLoggedIn = authRepository.currentUser != null;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !isLoginRoute) {
        return AppRoutes.login;
      }

      if (isLoggedIn && isLoginRoute) {
        return AppRoutes.dashboard; 
      }

      return null; 
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: AppRoutes.dashboardName,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/editor/:eventId',
        name: AppRoutes.editorName,
        builder: (context, state) => EditorScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/participants/:eventId',
        name: 'participants',
        builder: (context, state) => ParticipantListScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/analytics/:eventId',
        name: AppRoutes.analyticsName,
        builder: (context, state) => AnalyticsScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: AppRoutes.checkin,
        name: AppRoutes.checkinName,
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: AppRoutes.profileName,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        name: AppRoutes.changePasswordName,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/store-settings/:eventId',
        name: AppRoutes.storeSettingsName,
        builder: (context, state) => StoreSettingsScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/store-dashboard/:eventId',
        name: AppRoutes.storeDashboardName,
        builder: (context, state) => StoreDashboardScreen(eventId: state.pathParameters['eventId']!),
      ),

      GoRoute(
        path: '/store-history/:eventId',
        name: AppRoutes.storeHistoryName,
        builder: (context, state) => StoreHistoryScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/store-catalog/:eventId',
        name: 'store-catalog',
        builder: (context, state) => CatalogScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/store-pos/:eventId',
        name: AppRoutes.storePosName,
        builder: (context, state) => StorePosScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/store-pay/:eventId',
        name: 'store-pay',
        builder: (context, state) => StoreScannerScreen(eventId: state.pathParameters['eventId']!),
      ),
    ],
  );
});

// Helper for redirect stream
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
