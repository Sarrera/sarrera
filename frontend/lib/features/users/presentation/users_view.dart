import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/user_model.dart';
import '../../auth/presentation/login_dialog.dart';

class UsersView extends ConsumerStatefulWidget {
  const UsersView({super.key});

  @override
  ConsumerState<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends ConsumerState<UsersView> {
  String _searchQuery = '';
  String _selectedTierFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
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
                    'User Identity & Onboarding Directory',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Onboard engineering staff, assign subscription tiers, monitor individual token spend, and issue virtual API keys.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => ref.read(usersProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (!auth.isAuthenticated) {
                        LoginDialog.show(context);
                        return;
                      }
                      _showOnboardUserDialog(context);
                    },
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('+ Onboard User'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Search & Filter Bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search by User ID, Email, or Alias...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTierFilter,
                        dropdownColor: AppTheme.surfaceElevated,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Tiers')),
                          DropdownMenuItem(value: 'tier-basic', child: Text('Basic Tier')),
                          DropdownMenuItem(value: 'tier-standard', child: Text('Standard Tier')),
                          DropdownMenuItem(value: 'tier-premium', child: Text('Premium Tier')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedTierFilter = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // User Table
          usersAsync.when(
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
              child: Text('Error loading users: $err'),
            ),
            data: (users) {
              final filtered = users.where((u) {
                final matchQuery = u.userId.toLowerCase().contains(_searchQuery) ||
                    (u.userEmail?.toLowerCase().contains(_searchQuery) ?? false) ||
                    (u.userAlias?.toLowerCase().contains(_searchQuery) ?? false);
                final matchTier =
                    _selectedTierFilter == 'all' || u.teams.contains(_selectedTierFilter);
                return matchQuery && matchTier;
              }).toList();

              if (filtered.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.people_outline, size: 48, color: AppTheme.textMuted),
                          SizedBox(height: 12),
                          Text('No users matching the current criteria.',
                              style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: DataTable(
                    horizontalMargin: 16,
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('USER IDENTIFIER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('ASSIGNED TIER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('MONTHLY SPEND / BUDGET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('KEYS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    ],
                    rows: filtered.map((u) {
                      final tier = u.primaryTier;
                      final progress = u.budgetProgressPercentage / 100.0;
                      return DataRow(
                        cells: [
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  u.userAlias ?? u.userId,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  u.userEmail ?? u.userId,
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getTierColor(tier).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _getTierColor(tier).withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                tier,
                                style: TextStyle(
                                  color: _getTierColor(tier),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 180,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${u.spend.toStringAsFixed(2)} €',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        u.maxBudget != null ? '${u.maxBudget!.toStringAsFixed(2)} €' : 'Tier Def',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: AppTheme.surfaceElevated,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progress > 0.9 ? AppTheme.error : AppTheme.primary,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    minHeight: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Text('${u.keyCount} active', style: const TextStyle(fontSize: 12)),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.vpn_key_outlined, size: 18, color: AppTheme.primary),
                                  tooltip: 'Issue Virtual Key',
                                  onPressed: () {
                                    if (!auth.isAuthenticated) {
                                      LoginDialog.show(context);
                                      return;
                                    }
                                    _issueKeyForUser(u);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                                  tooltip: 'Delete User',
                                  onPressed: () {
                                    if (!auth.isAuthenticated) {
                                      LoginDialog.show(context);
                                      return;
                                    }
                                    _confirmDeleteUser(u);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'tier-premium':
        return AppTheme.accent;
      case 'tier-standard':
        return AppTheme.primary;
      case 'tier-basic':
      default:
        return AppTheme.secondary;
    }
  }

  void _showOnboardUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _OnboardUserDialog(),
    );
  }

  Future<void> _issueKeyForUser(UserModel user) async {
    try {
      final res = await ref.read(userRepositoryProvider).generateKeyForUser(
            userId: user.userId,
            tier: user.primaryTier,
          );
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => _KeyIssuedDialog(keyResult: res),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _confirmDeleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete user "${user.userId}"? This will invalidate all their virtual keys.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(usersProvider.notifier).deleteUser(user.userId);
    }
  }
}

class _OnboardUserDialog extends ConsumerStatefulWidget {
  const _OnboardUserDialog();

  @override
  ConsumerState<_OnboardUserDialog> createState() => _OnboardUserDialogState();
}

class _OnboardUserDialogState extends ConsumerState<_OnboardUserDialog> {
  final _userIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _aliasController = TextEditingController();
  final _budgetController = TextEditingController();
  String _selectedTier = 'tier-standard';
  bool _isCreating = false;

  @override
  void dispose() {
    _userIdController.dispose();
    _emailController.dispose();
    _aliasController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a User ID'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isCreating = true);
    final budgetVal = double.tryParse(_budgetController.text.trim());

    final success = await ref.read(usersProvider.notifier).createUser(
          userId: userId,
          email: _emailController.text.trim(),
          alias: _aliasController.text.trim(),
          tier: _selectedTier,
          maxBudget: budgetVal,
        );

    if (mounted) {
      setState(() => _isCreating = false);
      if (success) {
        Navigator.of(context).pop();
        // Immediately generate initial key
        final keyRes = await ref.read(userRepositoryProvider).generateKeyForUser(
              userId: userId,
              tier: _selectedTier,
            );
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => _KeyIssuedDialog(keyResult: keyRes),
          );
        }
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
        width: 480,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Onboard New Developer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text('Register engineer and assign default quota tier',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'User Identifier * (e.g. sarah_chen)',
                prefixIcon: Icon(Icons.badge_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Work Email (e.g. sarah@company.com)',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _aliasController,
              decoration: const InputDecoration(
                labelText: 'Full Name / Department (e.g. Sarah Chen - Platform Lead)',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedTier,
                    decoration: const InputDecoration(
                      labelText: 'Subscription Tier',
                      prefixIcon: Icon(Icons.layers_outlined, size: 20),
                    ),
                    dropdownColor: AppTheme.surfaceElevated,
                    items: const [
                      DropdownMenuItem(value: 'tier-basic', child: Text('Basic Tier (15 €)')),
                      DropdownMenuItem(value: 'tier-standard', child: Text('Standard Tier (50 €)')),
                      DropdownMenuItem(value: 'tier-premium', child: Text('Premium Tier (100 €)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTier = val);
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Custom Budget Override (€)',
                      hintText: 'Default: Tier cap',
                      prefixIcon: Icon(Icons.euro_outlined, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isCreating ? null : _submit,
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create & Generate Key'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyIssuedDialog extends StatelessWidget {
  final GeneratedApiKeyResult keyResult;

  const _KeyIssuedDialog({required this.keyResult});

  @override
  Widget build(BuildContext context) {
    final continueJson = '''{
  "models": [
    {
      "title": "Sarrera (${keyResult.teamId})",
      "provider": "openai",
      "model": "basic-coder",
      "apiKey": "${keyResult.key}",
      "apiBase": "https://localhost/v1"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Sarrera Autocomplete",
    "provider": "openai",
    "model": "basic-coder",
    "apiKey": "${keyResult.key}",
    "apiBase": "https://localhost/v1"
  }
}''';

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.surfaceBorder),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Virtual API Key Ready',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('User: ${keyResult.userId} · Tier: ${keyResult.teamId}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Generated API Key (Copy now, it won\'t be shown again):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      keyResult.key,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: keyResult.key));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Key copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('VS Code Continue Configuration (~/.continue/config.json):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              height: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF030712),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: SingleChildScrollView(
                child: Text(
                  continueJson,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy JSON Config'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: continueJson));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Continue config copied to clipboard!')),
                    );
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
