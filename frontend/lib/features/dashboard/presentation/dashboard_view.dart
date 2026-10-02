import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(telemetrySummaryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
                            ),
                            child: InkWell(
                              onTap: () => html.window.open(ApiConstants.changelogUrl, '_blank'),
                              child: const Text(
                                'SARRERA EDGE GATEWAY ${ApiConstants.appVersion}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryLight,
                                  letterSpacing: 0.05,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'All Microservices Healthy',
                            style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Enterprise Local AI Inference & Governance Hub',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Decoupling engineering client IDEs from heterogeneous physical GPUs. Multi-tier token quotas, dynamic load balancing, and compliance telemetry.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFFCBD5E1)),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => context.go('/users'),
                            icon: const Icon(Icons.person_add, size: 16),
                            label: const Text('Onboard Developer'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/tiers'),
                            icon: const Icon(Icons.tune, size: 16),
                            label: const Text('Manage Tiers & Quotas'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/telemetry'),
                            icon: const Icon(Icons.insights, size: 16),
                            label: const Text('View Telemetry'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/sarrera-icon.png',
                    width: 76,
                    height: 76,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // KPI Metric Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final cardWidth = isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _SummaryCard(
                    title: 'TOTAL MONTHLY SPEND',
                    value: '${summary.totalSpend.toStringAsFixed(2)} €',
                    caption: 'Budget Pool: ${summary.totalAllocatedBudget.toStringAsFixed(0)} €',
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppTheme.primary,
                    width: cardWidth,
                  ),
                  _SummaryCard(
                    title: 'SUBSCRIPTION TIERS',
                    value: '3 Tiers Active',
                    caption: 'Basic, Standard, Premium',
                    icon: Icons.layers_outlined,
                    color: AppTheme.secondary,
                    width: cardWidth,
                  ),
                  _SummaryCard(
                    title: 'ACTIVE DEVELOPERS',
                    value: '${summary.totalUsers}',
                    caption: '${summary.totalKeys} Virtual API Keys',
                    icon: Icons.groups_outlined,
                    color: AppTheme.success,
                    width: cardWidth,
                  ),
                  _SummaryCard(
                    title: 'COMPUTE NODES',
                    value: '${summary.activeNodes}',
                    caption: 'Ollama & vLLM Clusters',
                    icon: Icons.memory,
                    color: AppTheme.warning,
                    width: cardWidth,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          // Service Hub Links
          Text('Integrated Microservices & Applications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          const Text('Direct access to underlying cluster services proxied by Caddy',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final width = isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _ServiceCard(
                    title: 'Open WebUI',
                    subtitle: 'Chat & Model Playground',
                    icon: Icons.chat_bubble_outline,
                    color: const Color(0xFF10B981),
                    url: '/chat',
                    width: width,
                  ),
                  _ServiceCard(
                    title: 'Langfuse v2',
                    subtitle: 'Audit & Telemetry Traces',
                    icon: Icons.analytics_outlined,
                    color: const Color(0xFF6366F1),
                    url: '/admin/audit/',
                    width: width,
                  ),
                  _ServiceCard(
                    title: 'MinIO Console',
                    subtitle: 'S3 Trace Storage Bucket',
                    icon: Icons.cloud_queue_outlined,
                    color: const Color(0xFFEC4899),
                    url: '/admin/storage/',
                    width: width,
                  ),
                  _ServiceCard(
                    title: 'Documentation',
                    subtitle: 'GitHub Pages Runbooks',
                    icon: Icons.menu_book_outlined,
                    color: const Color(0xFF06B6D4),
                    url: ApiConstants.docsUrl,
                    width: width,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
  final double width;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  Icon(icon, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(caption, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String url;
  final double width;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.url,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          onTap: () => html.window.open(url, '_blank'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
