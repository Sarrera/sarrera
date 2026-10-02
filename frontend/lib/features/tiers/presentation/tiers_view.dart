import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/tier_model.dart';
import '../../auth/presentation/login_dialog.dart';

class TiersView extends ConsumerWidget {
  const TiersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiersAsync = ref.watch(tiersProvider);
    final auth = ref.watch(authProvider);

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
                    'Subscription Tiers & Quota Governance',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Configure token quotas, model access whitelists, and monthly budget limits per engineering tier.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => ref.read(tiersProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh Tiers'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          tiersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Failed to load tiers',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error),
                        ),
                        const SizedBox(height: 4),
                        Text(err.toString(), style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  if (!auth.isAuthenticated)
                    ElevatedButton(
                      onPressed: () => LoginDialog.show(context),
                      child: const Text('Sign in as Admin'),
                    ),
                ],
              ),
            ),
            data: (tiers) {
              if (tiers.isEmpty) {
                return const Center(child: Text('No tiers provisioned yet.'));
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 900;
                  return Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: tiers.map((tier) {
                      final cardWidth = isWide ? (constraints.maxWidth - 48) / 3 : constraints.maxWidth;
                      return SizedBox(
                        width: cardWidth,
                        child: _TierCard(tier: tier),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 36),
          // Policy Notice
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppTheme.primary, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Sub-Millisecond Policy Enforcement Active',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'When an IDE client queries a model outside their assigned tier whitelist, LiteLLM rejects the call with HTTP 403 Forbidden in <10ms without routing to GPU clusters.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierCard extends ConsumerWidget {
  final TierModel tier;

  const _TierCard({required this.tier});

  Color _getTierColor() {
    switch (tier.teamId) {
      case 'tier-premium':
        return AppTheme.accent;
      case 'tier-standard':
        return AppTheme.primary;
      case 'tier-basic':
      default:
        return AppTheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierColor = _getTierColor();
    final progress = tier.budgetProgressPercentage / 100.0;
    final auth = ref.watch(authProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tierColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: tierColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    tier.teamId.toUpperCase(),
                    style: TextStyle(
                      color: tierColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.05,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.key, size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${tier.activeKeysCount} Keys',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              tier.teamAlias,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Spend & Budget
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Monthly Spend', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                Text(
                  '${tier.spend.toStringAsFixed(2)} € / ${tier.maxBudget != null ? "${tier.maxBudget!.toStringAsFixed(2)} €" : "∞"}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.9
                    ? AppTheme.error
                    : (progress > 0.7 ? AppTheme.warning : tierColor),
              ),
              borderRadius: BorderRadius.circular(4),
              minHeight: 6,
            ),
            const SizedBox(height: 20),
            // Limits Grid
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rate Limit', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('${tier.rpmLimit ?? 60} RPM',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Token Limit', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          '${((tier.tpmLimit ?? 30000) / 1000).round()}k TPM',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Allowed Whitelist Models',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tier.models.isEmpty
                  ? [
                      const Chip(
                        label: Text('All Models Allowed', style: TextStyle(fontSize: 11)),
                        backgroundColor: AppTheme.surfaceElevated,
                      )
                    ]
                  : tier.models.map((m) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.surfaceBorder),
                        ),
                        child: Text(
                          m,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (!auth.isAuthenticated) {
                    LoginDialog.show(context);
                    return;
                  }
                  _showEditQuotaDialog(context, ref, tier);
                },
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Adjust Quotas & Models'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditQuotaDialog(BuildContext context, WidgetRef ref, TierModel tier) {
    showDialog(
      context: context,
      builder: (_) => _EditTierQuotaDialog(tier: tier),
    );
  }
}

class _EditTierQuotaDialog extends ConsumerStatefulWidget {
  final TierModel tier;

  const _EditTierQuotaDialog({required this.tier});

  @override
  ConsumerState<_EditTierQuotaDialog> createState() => _EditTierQuotaDialogState();
}

class _EditTierQuotaDialogState extends ConsumerState<_EditTierQuotaDialog> {
  late double _budget;
  late double _rpm;
  late double _tpmThousands;
  late List<String> _selectedModels;
  bool _isSaving = false;

  static const List<String> availableModels = [
    'basic-coder',
    'premium-coder',
    'premium-reasoning',
  ];

  @override
  void initState() {
    super.initState();
    _budget = widget.tier.maxBudget ?? 50.0;
    _rpm = (widget.tier.rpmLimit ?? 60).toDouble();
    _tpmThousands = ((widget.tier.tpmLimit ?? 30000) / 1000).toDouble();
    _selectedModels = List.from(widget.tier.models);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final success = await ref.read(tiersProvider.notifier).updateTier(
          teamId: widget.tier.teamId,
          maxBudget: _budget,
          rpmLimit: _rpm.round(),
          tpmLimit: (_tpmThousands * 1000).round(),
          models: _selectedModels,
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Quotas updated for ${widget.tier.teamAlias}'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to update tier quota in LiteLLM'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.surfaceBorder),
      ),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tune Tier Quotas: ${widget.tier.teamId}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text('Adjust limits for all users bound to this tier',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Monthly Budget Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Monthly Budget Cap (EUR)', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${_budget.round()} € / month',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ],
            ),
            Slider(
              value: _budget,
              min: 5,
              max: 500,
              divisions: 99,
              activeColor: AppTheme.primary,
              onChanged: (val) => setState(() => _budget = val),
            ),
            const SizedBox(height: 14),
            // RPM Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Rate Limit (RPM)', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${_rpm.round()} Requests/min',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondary)),
              ],
            ),
            Slider(
              value: _rpm,
              min: 10,
              max: 300,
              divisions: 29,
              activeColor: AppTheme.secondary,
              onChanged: (val) => setState(() => _rpm = val),
            ),
            const SizedBox(height: 14),
            // TPM Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Token Limit (TPM)', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${_tpmThousands.round()}k Tokens/min',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent)),
              ],
            ),
            Slider(
              value: _tpmThousands,
              min: 10,
              max: 300,
              divisions: 29,
              activeColor: AppTheme.accent,
              onChanged: (val) => setState(() => _tpmThousands = val),
            ),
            const SizedBox(height: 18),
            const Text('Authorized Models Whitelist', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: availableModels.map((m) {
                final isSelected = _selectedModels.contains(m);
                return FilterChip(
                  label: Text(m, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  selected: isSelected,
                  selectedColor: AppTheme.primary.withValues(alpha: 0.25),
                  checkmarkColor: AppTheme.primary,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedModels.add(m);
                      } else {
                        _selectedModels.remove(m);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save & Apply Limits'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
