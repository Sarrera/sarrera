import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class TelemetryView extends ConsumerWidget {
  const TelemetryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiersAsync = ref.watch(tiersProvider);
    final usersAsync = ref.watch(usersProvider);
    final summary = ref.watch(telemetrySummaryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Telemetry & Consumption Observability',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Real-time token metering, cost attribution, and trace performance aggregated from LiteLLM & Langfuse.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  html.window.open('/admin/audit/', '_blank');
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open Langfuse Audit Suite'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Top KPI Summary Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final cardWidth = isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _KpiCard(
                    title: 'TOTAL MONTHLY SPEND',
                    value: '${summary.totalSpend.toStringAsFixed(2)} €',
                    subtitle: 'Cap: ${summary.totalAllocatedBudget.toStringAsFixed(0)} €',
                    icon: Icons.euro,
                    color: AppTheme.primary,
                    width: cardWidth,
                  ),
                  _KpiCard(
                    title: 'QUOTA UTILIZATION',
                    value: '${summary.quotaUtilizationPercentage.toStringAsFixed(1)}%',
                    subtitle: 'Pooled quota capacity',
                    icon: Icons.pie_chart_outline,
                    color: summary.quotaUtilizationPercentage > 85 ? AppTheme.error : AppTheme.secondary,
                    width: cardWidth,
                  ),
                  _KpiCard(
                    title: 'ONBOARDED DEVELOPERS',
                    value: '${summary.totalUsers}',
                    subtitle: 'Active user accounts',
                    icon: Icons.people_alt_outlined,
                    color: AppTheme.success,
                    width: cardWidth,
                  ),
                  _KpiCard(
                    title: 'VIRTUAL API KEYS',
                    value: '${summary.totalKeys}',
                    subtitle: 'Bound to subscription tiers',
                    icon: Icons.key_outlined,
                    color: AppTheme.warning,
                    width: cardWidth,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          // Middle Row: Chart & Tier Breakdown
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 850;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _TierSpendChartCard(tiersAsync: tiersAsync)),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _HardwareLatencyCard()),
                  ],
                );
              }
              return Column(
                children: [
                  _TierSpendChartCard(tiersAsync: tiersAsync),
                  const SizedBox(height: 24),
                  _HardwareLatencyCard(),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          // User Spend Leaderboard
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Developer Token Consumption Leaderboard',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () => ref.read(usersProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Update'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  usersAsync.when(
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                    error: (err, _) => Text('Error loading leaderboard: $err'),
                    data: (users) {
                      if (users.isEmpty) {
                        return const Center(child: Text('No users recorded.'));
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: users.length,
                        separatorBuilder: (_, __) => const Divider(color: AppTheme.surfaceBorder, height: 16),
                        itemBuilder: (context, index) {
                          final u = users[index];
                          final maxB = u.maxBudget ?? 50.0;
                          final progress = (u.spend / (maxB > 0 ? maxB : 1.0)).clamp(0.0, 1.0);
                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.surfaceElevated,
                                child: Text('${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u.userAlias ?? u.userId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text(u.primaryTier, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${u.spend.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        Text('${maxB.toStringAsFixed(0)} € Cap', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: AppTheme.surfaceElevated,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        progress > 0.9 ? AppTheme.error : AppTheme.primary,
                                      ),
                                      minHeight: 4,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double width;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
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
                  Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.05)),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierSpendChartCard extends StatelessWidget {
  final AsyncValue<List<dynamic>> tiersAsync;

  const _TierSpendChartCard({required this.tiersAsync});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Allocation by Subscription Tier',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Relative distribution of monthly token limits across tiers',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 120,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          switch (val.toInt()) {
                            case 0:
                              return const Text('Basic', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary));
                            case 1:
                              return const Text('Standard', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary));
                            case 2:
                              return const Text('Premium', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary));
                            default:
                              return const SizedBox();
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (val, _) => Text('${val.toInt()}€', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 15, color: AppTheme.secondary, width: 28, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 50, color: AppTheme.primary, width: 28, borderRadius: BorderRadius.circular(4))]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 100, color: AppTheme.accent, width: 28, borderRadius: BorderRadius.circular(4))]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HardwareLatencyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hardware & Latency Metrics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Average inference performance across nodes',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 20),
            _MetricRow(label: 'Avg Time-To-First-Token (TTFT)', value: '~180 ms', color: AppTheme.success),
            const Divider(color: AppTheme.surfaceBorder, height: 20),
            _MetricRow(label: 'Autocomplete Completion Latency', value: '~420 ms', color: AppTheme.primary),
            const Divider(color: AppTheme.surfaceBorder, height: 20),
            _MetricRow(label: 'Routing Policy Latency Overhead', value: '< 10 ms', color: AppTheme.secondary),
            const Divider(color: AppTheme.surfaceBorder, height: 20),
            _MetricRow(label: 'Least-Busy Queue Balancing', value: 'Active (least-busy)', color: AppTheme.accent),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }
}
