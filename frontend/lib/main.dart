import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/landing/presentation/landing_view.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/developer/presentation/developer_portal_view.dart';
import 'features/shell/app_shell.dart';
import 'features/dashboard/presentation/dashboard_view.dart';
import 'features/tiers/presentation/tiers_view.dart';
import 'features/users/presentation/users_view.dart';
import 'features/telemetry/presentation/telemetry_view.dart';
import 'features/nodes/presentation/nodes_view.dart';
import 'features/certificates/presentation/certificates_view.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    // 1. Public Landing Page & Quickstart Guide
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingView(),
    ),
    // 2. Clear Dedicated Authentication Screen (Developer & Admin)
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    // 3. Developer Personal Workspace (Personal Quotas & VS Code Continue config)
    GoRoute(
      path: '/my-portal',
      builder: (context, state) => const DeveloperPortalView(),
    ),
    // 4. Cluster Administration Shell (Admin Master Control)
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/admin',
          builder: (context, state) => const DashboardView(),
        ),
        GoRoute(
          path: '/tiers',
          builder: (context, state) => const TiersView(),
        ),
        GoRoute(
          path: '/users',
          builder: (context, state) => const UsersView(),
        ),
        GoRoute(
          path: '/telemetry',
          builder: (context, state) => const TelemetryView(),
        ),
        GoRoute(
          path: '/nodes',
          builder: (context, state) => const NodesView(),
        ),
        GoRoute(
          path: '/certificates',
          builder: (context, state) => const CertificatesView(),
        ),
      ],
    ),
  ],
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: SarreraPortalApp(),
    ),
  );
}

class SarreraPortalApp extends StatelessWidget {
  const SarreraPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sarrera - Edge Gateway & Governance Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
