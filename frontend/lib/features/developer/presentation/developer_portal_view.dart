import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class DeveloperPortalView extends ConsumerWidget {
  const DeveloperPortalView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // If not authenticated or not developer, redirect to login
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const SizedBox();
    }

    final userId = auth.userId ?? 'Developer';
    final userAlias = auth.userAlias ?? userId;
    final teamId = auth.teamId ?? 'tier-standard';
    final apiKey = auth.token ?? 'sk-sample-key';
    final spend = auth.spend;
    final maxBudget = auth.maxBudget ?? 50.0;
    final progress = auth.budgetProgressPercentage / 100.0;
    final allowedModels = auth.allowedModels;

    final continueJson = '''{
  "models": [
    {
      "title": "Sarrera ($teamId)",
      "provider": "openai",
      "model": "${allowedModels.isNotEmpty ? allowedModels.last : 'basic-coder'}",
      "apiKey": "$apiKey",
      "apiBase": "https://localhost/v1"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Sarrera Autocomplete",
    "provider": "openai",
    "model": "basic-coder",
    "apiKey": "$apiKey",
    "apiBase": "https://localhost/v1"
  }
}''';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            'assets/sarrera-icon.png',
            errorBuilder: (_, __, ___) => const Icon(Icons.hub),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Developer Workspace · $userId',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const Text(
                  'Personal Quotas & Virtual Key Hub',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => html.window.open(ApiConstants.changelogUrl, '_blank'),
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
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => html.window.open(ApiConstants.docsUrl, '_blank'),
            icon: const Icon(Icons.menu_book_outlined, size: 16),
            label: const Text('Documentation'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => html.window.open('/chat', '_blank'),
            icon: const Icon(Icons.chat_bubble_outline, size: 16),
            label: const Text('Launch Chat WebUI'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Sign Out',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/');
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Welcome Card
                Card(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E1B4B), Color(0xFF111827)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                          child: const Icon(Icons.person, size: 32, color: AppTheme.primaryLight),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    userAlias,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: auth.isGroupMember
                                          ? AppTheme.secondary.withValues(alpha: 0.15)
                                          : AppTheme.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: auth.isGroupMember
                                            ? AppTheme.secondary.withValues(alpha: 0.4)
                                            : AppTheme.primary.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          auth.isGroupMember ? Icons.corporate_fare : Icons.person_outline,
                                          size: 14,
                                          color: auth.isGroupMember ? AppTheme.secondary : AppTheme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          auth.isGroupMember
                                              ? (auth.groupAlias ?? teamId).toUpperCase()
                                              : teamId.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: auth.isGroupMember ? AppTheme.secondary : AppTheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                auth.isGroupMember
                                    ? 'Account: B2B Group Member (${auth.groupAlias ?? teamId}) · Quota cycle: 30 days rolling'
                                    : 'Account: B2C Solo Developer · Quota cycle: 30 days rolling',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Quota & Rate Limit Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        auth.isGroupMember ? 'INDIVIDUAL TOKEN SPEND' : 'MONTHLY TOKEN SPEND',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                                      ),
                                      const Icon(Icons.euro, size: 18, color: AppTheme.primary),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${spend.toStringAsFixed(2)} € / ${maxBudget.toStringAsFixed(2)} €',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: AppTheme.surfaceElevated,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progress > 0.9 ? AppTheme.error : AppTheme.primary,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    minHeight: 6,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${((1 - progress) * 100).toStringAsFixed(0)}% remaining of personal quota',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (isWide && auth.isGroupMember && auth.groupMaxBudget != null) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('GROUP POOLED BUDGET',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                                        const Icon(Icons.corporate_fare, size: 18, color: AppTheme.secondary),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${(auth.groupSpend ?? 0.0).toStringAsFixed(2)} € / ${(auth.groupMaxBudget ?? 0.0).toStringAsFixed(2)} €',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: auth.groupBudgetProgressPercentage / 100.0,
                                      backgroundColor: AppTheme.surfaceElevated,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        auth.groupBudgetProgressPercentage > 90 ? AppTheme.error : AppTheme.secondary,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      minHeight: 6,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${((1 - (auth.groupBudgetProgressPercentage / 100.0)) * 100).toStringAsFixed(0)}% remaining in corporate pool',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (isWide) const SizedBox(width: 16),
                        if (isWide)
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Text('ACTIVE RATE LIMITS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                                        Icon(Icons.speed, size: 18, color: AppTheme.secondary),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Request Throttle', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                              const SizedBox(height: 2),
                                              Text('${auth.rpmLimit} RPM', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Token Velocity', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                              const SizedBox(height: 2),
                                              Text('${(auth.tpmLimit / 1000).round()}k TPM', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    const Text('LiteLLM enforces sub-millisecond throttle to protect shared GPUs',
                                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Virtual API Key Box
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Your Active Virtual API Key', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            Icon(Icons.key, size: 18, color: AppTheme.secondary),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF030712),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  apiKey,
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
                                tooltip: 'Copy API Key',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: apiKey));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('API Key copied to clipboard!')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Allowed Models Whitelist
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Authorized Models ($teamId)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Models whitelisted for your engineering subscription tier', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _ModelBadge(
                              model: 'basic-coder',
                              desc: 'Qwen 2.5 Coder 7B (Fast Autocomplete)',
                              isAllowed: allowedModels.contains('basic-coder'),
                            ),
                            _ModelBadge(
                              model: 'premium-coder',
                              desc: 'Qwen 2.5 Coder 32B (Refactoring & Architecture)',
                              isAllowed: allowedModels.contains('premium-coder'),
                            ),
                            _ModelBadge(
                              model: 'premium-reasoning',
                              desc: 'DeepSeek-R1 (Complex Chain-of-Thought)',
                              isAllowed: allowedModels.contains('premium-reasoning'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Personalized VS Code Continue Config
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Personalized VS Code Continue Config', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                SizedBox(height: 2),
                                Text('Ready to paste into ~/.continue/config.json with your key prefilled', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              ],
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy Config'),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: continueJson));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Continue config copied to clipboard!')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF030712),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.surfaceBorder),
                          ),
                          child: Text(
                            continueJson,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Color(0xFFCBD5E1),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModelBadge extends StatelessWidget {
  final String model;
  final String desc;
  final bool isAllowed;

  const _ModelBadge({
    required this.model,
    required this.desc,
    required this.isAllowed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAllowed ? AppTheme.surfaceElevated : AppTheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isAllowed ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAllowed ? Icons.check_circle : Icons.lock_outline,
                size: 16,
                color: isAllowed ? AppTheme.success : AppTheme.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                model,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isAllowed ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
