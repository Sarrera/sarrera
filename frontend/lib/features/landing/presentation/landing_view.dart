import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class LandingView extends StatefulWidget {
  const LandingView({super.key});

  @override
  State<LandingView> createState() => _LandingViewState();
}

class _LandingViewState extends State<LandingView> {
  int _clientSetupTab = 0; // 0: VS Code, 1: Cursor, 2: Cline, 3: Python

  static const String continueJson = '''{
  "models": [
    {
      "title": "Sarrera (tier-standard)",
      "provider": "openai",
      "model": "premium-coder",
      "apiKey": "sk-your-virtual-key-here",
      "apiBase": "https://localhost/v1"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Sarrera Autocomplete",
    "provider": "openai",
    "model": "basic-coder",
    "apiKey": "sk-your-virtual-key-here",
    "apiBase": "https://localhost/v1"
  }
}''';

  static const String cursorInstructions = '''1. Open Cursor Settings > Models
2. In 'OpenAI API Base URL', enter:
   https://localhost/v1
3. In 'OpenAI API Key', enter your Virtual API Key:
   sk-your-virtual-key-here
4. Model name: basic-coder or premium-coder''';

  static const String clineInstructions = '''1. Open Cline extension settings in VS Code.
2. Select API Provider: 'OpenAI Compatible'.
3. Base URL: https://localhost/v1
4. API Key: sk-your-virtual-key-here
5. Model ID: basic-coder (or premium-coder)''';

  static const String pythonSnippet = '''from openai import OpenAI

client = OpenAI(
    base_url="https://localhost/v1",
    api_key="sk-your-virtual-key-here"
)

response = client.chat.completions.create(
    model="basic-coder",
    messages=[{"role": "user", "content": "Write a binary search in Python"}]
)

print(response.choices[0].message.content)''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/sarrera-icon.png',
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(Icons.hub, size: 24),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sarrera',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                ),
                Row(
                  children: [
                    const Text(
                      'Enterprise Local AI Gateway',
                      style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                    const SizedBox(width: 8),
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
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => html.window.open('/chat', '_blank'),
            child: const Text('Open WebUI (Chat)', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => html.window.open(ApiConstants.docsUrl, '_blank'),
            child: const Text('Documentation', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login, size: 16),
            label: const Text('Sign In / Portal'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [Color(0xFF1E1B4B), Color(0xFF0B0F19)],
                ),
                border: const Border(bottom: BorderSide(color: AppTheme.surfaceBorder)),
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.shield_outlined, size: 14, color: AppTheme.secondary),
                            SizedBox(width: 8),
                            Text(
                              'Air-Gapped Privacy · Multi-Tier Quotas · Zero GPU Saturation',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryLight),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Enterprise Local AI Gateway\n& Token Governance',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.15,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Shield proprietary source code from third-party APIs. Sarrera balances queries across heterogeneous GPUs with weighted least-busy routing, enforces subscription tier budgets, and logs live telemetry to Langfuse.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF94A3B8),
                              fontSize: 16,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 36),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => context.go('/login'),
                            icon: const Icon(Icons.key, size: 18),
                            label: const Text('Access Developer Workspace'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/admin'),
                            icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                            label: const Text('Cluster Administration'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Client IDE Integration Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.laptop_chromebook, color: AppTheme.secondary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Developer Quickstart Guide', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('Connect your IDE to Sarrera in 30 seconds', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Client Selector Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton(0, 'VS Code (Continue)', Icons.code),
                        _buildTabButton(1, 'Cursor IDE', Icons.navigation_outlined),
                        _buildTabButton(2, 'Cline / Roo Code', Icons.smart_toy_outlined),
                        _buildTabButton(3, 'Python & cURL', Icons.terminal),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Code Box
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_getTabSnippetTitle(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.copy, size: 14),
                                label: const Text('Copy Config', style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _getTabSnippetContent()));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Configuration copied to clipboard!')),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF030712),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.surfaceBorder),
                            ),
                            child: Text(
                              _getTabSnippetContent(),
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
            // Subscription Tiers Showcase
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              color: AppTheme.surface.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    children: [
                      const Text('Subscription Tiers & Quota Allocation', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Predefined hardware access tiers for engineering departments', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      const SizedBox(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 800;
                          final cardWidth = isWide ? (constraints.maxWidth - 48) / 3 : constraints.maxWidth;
                          return Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            children: [
                              _buildTierOverviewCard(
                                title: 'tier-basic',
                                alias: 'Junior / Intern Dev',
                                budget: '15 € / month',
                                limits: '60 RPM · 30k TPM',
                                models: ['basic-coder (7B)'],
                                color: AppTheme.secondary,
                                width: cardWidth,
                              ),
                              _buildTierOverviewCard(
                                title: 'tier-standard',
                                alias: 'Fullstack / Senior Dev',
                                budget: '50 € / month',
                                limits: '120 RPM · 60k TPM',
                                models: ['basic-coder (7B)', 'premium-coder (32B)'],
                                color: AppTheme.primary,
                                isPopular: true,
                                width: cardWidth,
                              ),
                              _buildTierOverviewCard(
                                title: 'tier-premium',
                                alias: 'AI Architect / Lead',
                                budget: '100 € / month',
                                limits: '180 RPM · 120k TPM',
                                models: ['basic-coder (7B)', 'premium-coder (32B)', 'premium-reasoning (DeepSeek-R1)'],
                                color: AppTheme.accent,
                                width: cardWidth,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Footer with Version & Docs Links
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.surfaceBorder)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/sarrera-icon.png', width: 20, height: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Sarrera Edge Gateway',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => html.window.open(ApiConstants.changelogUrl, '_blank'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.surfaceBorder),
                              ),
                              child: const Text(
                                ApiConstants.appVersion,
                                style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppTheme.textMuted),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => html.window.open(ApiConstants.docsUrl, '_blank'),
                            child: const Text('GitHub Pages Docs', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => html.window.open(ApiConstants.changelogUrl, '_blank'),
                            child: const Text('Changelog (SemVer)', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => html.window.open('https://github.com/Sarrera/sarrera', '_blank'),
                            child: const Text('GitHub Repo', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = _clientSetupTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _clientSetupTab = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppTheme.primaryLight : AppTheme.textMuted),
              const SizedBox(width: 8),
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

  String _getTabSnippetTitle() {
    switch (_clientSetupTab) {
      case 0:
        return 'VS Code Continue Extension (~/.continue/config.json)';
      case 1:
        return 'Cursor IDE Model Settings';
      case 2:
        return 'Cline / Roo Code (VS Code Extension)';
      case 3:
      default:
        return 'Python OpenAI SDK Integration';
    }
  }

  String _getTabSnippetContent() {
    switch (_clientSetupTab) {
      case 0:
        return continueJson;
      case 1:
        return cursorInstructions;
      case 2:
        return clineInstructions;
      case 3:
      default:
        return pythonSnippet;
    }
  }

  Widget _buildTierOverviewCard({
    required String title,
    required String alias,
    required String budget,
    required String limits,
    required List<String> models,
    required Color color,
    bool isPopular = false,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPopular ? color : AppTheme.surfaceBorder,
              width: isPopular ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      title.toUpperCase(),
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('POPULAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(alias, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(budget, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(limits, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const Divider(color: AppTheme.surfaceBorder, height: 24),
              const Text('Models Whitelist:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: models.map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 14, color: AppTheme.success),
                        const SizedBox(width: 8),
                        Text(m, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.textPrimary)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
