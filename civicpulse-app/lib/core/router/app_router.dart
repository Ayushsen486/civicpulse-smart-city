import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:civicpulse_app/features/auth/application/auth_controller.dart';
import 'package:civicpulse_app/features/auth/presentation/login_screen.dart';
import 'package:civicpulse_app/features/auth/presentation/register_screen.dart';
import 'package:civicpulse_app/features/home/presentation/home_screen.dart';
import 'package:civicpulse_app/features/issue/presentation/screens/issue_detail_screen.dart';
import 'package:civicpulse_app/features/issue/presentation/screens/report_issue_screen.dart';
import 'package:civicpulse_app/features/issue/presentation/screens/report_success_screen.dart';

import 'package:civicpulse_app/features/splash/presentation/splash_screen.dart';

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (prev, next) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isLoggedIn = authState.asData?.value != null;
      final location = state.matchedLocation;

      // Allow cinematic splash screen to play completely
      if (location == '/splash') {
        return null;
      }

      // Prevent login loops if already authenticated
      if (isLoggedIn && (location == '/login' || location == '/register')) {
        return '/';
      }

      // Intercept issue reporting for unauthenticated guests
      if (!isLoggedIn && location == '/report') {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) => const ReportIssueScreen(),
      ),
      GoRoute(
        path: '/issues/:id',
        builder: (context, state) {
          final issueId = state.pathParameters['id'] ?? '';
          return IssueDetailScreen(issueId: issueId);
        },
      ),
      GoRoute(
        path: '/report-success/:id',
        builder: (context, state) {
          final issueId = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return ReportSuccessScreen(
            issueId: issueId,
            referenceNumber: extra?['referenceNumber'] as String?,
            categoryName: extra?['categoryName'] as String?,
          );
        },
      ),
    ],
  );
});
