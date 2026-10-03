import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_providers.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../auth/presentation/login_dialog.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(right: BorderSide(color: AppTheme.surfaceBorder)),
            ),
            child: Column(
              children: [
                // Brand Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/sarrera-icon.png',
                          width: 38,
                          height: 38,
                          errorBuilder: (_, __, ___) => Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.hub, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Sarrera',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => html.window.open(ApiConstants.changelogUrl, '_blank'),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: const Text(
                                    ApiConstants.appVersion,
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accent),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'AI Inference Gateway',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppTheme.surfaceBorder, height: 1),
                const SizedBox(height: 16),
                // Navigation Links
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _NavItem(
                        title: 'Overview',
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard,
                        isSelected: location == '/admin' || location == '/admin/',
                        onTap: () => context.go('/admin'),
                      ),
                      _NavItem(
                        title: 'Tiers & Quotas',
                        icon: Icons.layers_outlined,
                        activeIcon: Icons.layers,
                        isSelected: location.startsWith('/tiers'),
                        onTap: () => context.go('/tiers'),
                      ),
                      _NavItem(
                        title: 'Users & Keys',
                        icon: Icons.people_outline,
                        activeIcon: Icons.people,
                        isSelected: location.startsWith('/users'),
                        onTap: () => context.go('/users'),
                      ),
                      _NavItem(
                        title: 'Telemetry & Spend',
                        icon: Icons.insights_outlined,
                        activeIcon: Icons.insights,
                        isSelected: location.startsWith('/telemetry'),
                        onTap: () => context.go('/telemetry'),
                      ),
                      _NavItem(
                        title: 'Compute Nodes',
                        icon: Icons.memory_outlined,
                        activeIcon: Icons.memory,
                        isSelected: location.startsWith('/nodes'),
                        onTap: () => context.go('/nodes'),
                      ),
                      _NavItem(
                        title: 'TLS & Certificates',
                        icon: Icons.lock_outline,
                        activeIcon: Icons.lock,
                        isSelected: location.startsWith('/certificates'),
                        onTap: () => context.go('/certificates'),
                      ),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text(
                          'PLATFORM SERVICES',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.05,
                          ),
                        ),
                      ),
                      _ExternalLinkItem(
                        title: 'Open WebUI (Chat)',
                        icon: Icons.chat_outlined,
                        url: ApiConstants.getChatUrl(),
                      ),
                      _ExternalLinkItem(
                        title: 'Langfuse Audit Suite',
                        icon: Icons.analytics_outlined,
                        url: ApiConstants.getAuditUrl(),
                      ),
                      _ExternalLinkItem(
                        title: 'Documentation',
                        icon: Icons.menu_book_outlined,
                        url: ApiConstants.docsUrl,
                      ),
                    ],
                  ),
                ),
                // Footer / Admin Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    border: Border(top: BorderSide(color: AppTheme.surfaceBorder)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: auth.isAuthenticated ? AppTheme.success : AppTheme.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          auth.isAuthenticated ? 'Admin Authenticated' : 'Guest / Read-Only',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          auth.isAuthenticated ? Icons.logout : Icons.login,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                        tooltip: auth.isAuthenticated ? 'Sign Out' : 'Sign In as Admin',
                        onPressed: () {
                          if (auth.isAuthenticated) {
                            ref.read(authProvider.notifier).logout();
                          } else {
                            LoginDialog.show(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main Content View
          Expanded(
            child: Scaffold(
              backgroundColor: AppTheme.background,
              appBar: AppBar(
                backgroundColor: AppTheme.surface,
                elevation: 0,
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.lock, size: 12, color: AppTheme.success),
                          SizedBox(width: 6),
                          Text(
                            'HTTPS · Caddy Reverse Proxy Active',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home_outlined, size: 16, color: AppTheme.textSecondary),
                    label: const Text('Landing Page', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  if (!auth.isAuthenticated)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.security, size: 16),
                        label: const Text('Admin Sign In'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                          context.go('/');
                        },
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.help_outline, size: 20),
                    tooltip: 'Open GitHub Pages Documentation',
                    onPressed: () => html.window.open(ApiConstants.docsUrl, '_blank'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primary.withValues(alpha: 0.4) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 20,
                color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExternalLinkItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final String url;

  const _ExternalLinkItem({
    required this.title,
    required this.icon,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => html.window.open(url, '_blank'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
              const Icon(Icons.north_east, size: 12, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
