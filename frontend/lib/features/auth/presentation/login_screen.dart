import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  int _selectedTab = 0; // 0: Developer, 1: Administrator

  final _devKeyController = TextEditingController();
  final _adminKeyController = TextEditingController(text: 'sk-master-platform-key-change-me');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _devKeyController.dispose();
    _adminKeyController.dispose();
    super.dispose();
  }

  Future<void> _submitDeveloper() async {
    final key = _devKeyController.text.trim();
    if (key.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Virtual API Key (sk-...)');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authProvider.notifier).loginDeveloper(key);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go('/my-portal');
      } else {
        setState(() => _errorMessage = ref.read(authProvider).error ?? 'Invalid Virtual API Key');
      }
    }
  }

  Future<void> _submitAdmin() async {
    final key = _adminKeyController.text.trim();
    if (key.isEmpty) {
      setState(() => _errorMessage = 'Please enter the Admin Master Key');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authProvider.notifier).loginAdmin(key);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go('/admin');
      } else {
        setState(() => _errorMessage = ref.read(authProvider).error ?? 'Authentication failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: () => context.go('/'),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/sarrera-icon.png',
              width: 24,
              height: 24,
              errorBuilder: (_, __, ___) => const Icon(Icons.hub, size: 20),
            ),
            const SizedBox(width: 8),
            const Text('Sarrera AI Platform', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Logo
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Image.asset(
                          'assets/sarrera-icon.png',
                          width: 52,
                          height: 52,
                          errorBuilder: (_, __, ___) => const Icon(Icons.lock_open, size: 36, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Authenticate with Sarrera',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Select your role to access your workspace',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Role Toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            _selectedTab = 0;
                            _errorMessage = null;
                          }),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.code,
                                  size: 16,
                                  color: _selectedTab == 0 ? Colors.white : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Developer',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTab == 0 ? Colors.white : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() {
                            _selectedTab = 1;
                            _errorMessage = null;
                          }),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.admin_panel_settings_outlined,
                                  size: 16,
                                  color: _selectedTab == 1 ? Colors.white : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Administrator',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTab == 1 ? Colors.white : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.error, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Tab Content
                if (_selectedTab == 0) ...[
                  // Developer Form
                  const Text('Virtual API Key', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _devKeyController,
                    decoration: const InputDecoration(
                      hintText: 'sk-... (Issued by your Admin)',
                      prefixIcon: Icon(Icons.key_outlined, size: 20),
                    ),
                    onSubmitted: (_) => _submitDeveloper(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your virtual API key authenticates your personal quota, whitelisted models, and logs all telemetry to Langfuse.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  // Quick Test Button
                  OutlinedButton.icon(
                    onPressed: () {
                      _devKeyController.text = 'sk-iXFFH3MsmXgAs1I4TBvSiw';
                    },
                    icon: const Icon(Icons.flash_on, size: 14, color: AppTheme.secondary),
                    label: const Text('Fill Test Key (Sarah Chen / Standard)', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitDeveloper,
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Access Developer Workspace'),
                    ),
                  ),
                ] else ...[
                  // Administrator Form
                  const Text('Admin Master Key / Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _adminKeyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'sk-master-platform-key...',
                      prefixIcon: Icon(Icons.security, size: 20),
                    ),
                    onSubmitted: (_) => _submitAdmin(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Full platform control: Tune subscription tiers, onboard engineering staff, and register dynamic GPU/CPU nodes.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitAdmin,
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Sign In as Administrator'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
