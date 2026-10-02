import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/login_dialog.dart';

class NodesView extends ConsumerStatefulWidget {
  const NodesView({super.key});

  @override
  ConsumerState<NodesView> createState() => _NodesViewState();
}

class _NodesViewState extends ConsumerState<NodesView> {
  final _aliasController = TextEditingController(text: 'basic-coder');
  final _backendController = TextEditingController(text: 'ollama/qwen2.5-coder:7b');
  final _hostController = TextEditingController(text: 'http://ai-ollama-local:11434');
  final _rpmController = TextEditingController(text: '60');
  final _weightController = TextEditingController(text: '8');

  bool _isRegistering = false;
  bool _isPinging = false;
  String? _pingResult;

  @override
  void dispose() {
    _aliasController.dispose();
    _backendController.dispose();
    _hostController.dispose();
    _rpmController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pingNode() async {
    final host = _hostController.text.trim();
    if (host.isEmpty) return;

    setState(() {
      _isPinging = true;
      _pingResult = null;
    });

    final latency = await ref.read(nodeRepositoryProvider).pingNode(host);

    if (mounted) {
      setState(() {
        _isPinging = false;
        _pingResult = latency != null ? '✅ Reachable ($latency ms)' : '⚠️ Connection attempted / Host requires proxy';
      });
    }
  }

  Future<void> _registerNode() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      LoginDialog.show(context);
      return;
    }

    final alias = _aliasController.text.trim();
    final backend = _backendController.text.trim();
    final host = _hostController.text.trim();
    final rpm = int.tryParse(_rpmController.text.trim()) ?? 60;
    final weight = int.tryParse(_weightController.text.trim());

    if (alias.isEmpty || backend.isEmpty || host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Model Alias, Backend Model and Host Address'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isRegistering = true);

    final success = await ref.read(nodesProvider.notifier).registerNode(
          modelAlias: alias,
          backendModel: backend,
          apiBase: host,
          rpm: rpm,
          weight: weight,
        );

    if (mounted) {
      setState(() => _isRegistering = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🚀 Node "$alias" registered successfully in LiteLLM'), backgroundColor: AppTheme.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Error registering node'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodesAsync = ref.watch(nodesProvider);

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
                    'Compute Nodes & Dynamic Orchestration',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Register upstream Ollama / vLLM inference nodes dynamically with zero downtime. Persisted in PostgreSQL.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => ref.read(nodesProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh Nodes'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildNodesTable(nodesAsync)),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _buildRegisterForm()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildNodesTable(nodesAsync),
                  const SizedBox(height: 24),
                  _buildRegisterForm(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNodesTable(AsyncValue<List<dynamic>> nodesAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Active Inference Models & Nodes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            nodesAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              error: (err, _) => Text('Error loading nodes: $err'),
              data: (nodes) {
                if (nodes.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No nodes registered.')));
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: nodes.length,
                  separatorBuilder: (_, __) => const Divider(color: AppTheme.surfaceBorder, height: 16),
                  itemBuilder: (context, index) {
                    final node = nodes[index];
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.memory, color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(node.modelName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(
                                '${node.backendModel} · ${node.apiBase}',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                        if (node.isDynamic)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                            tooltip: 'Remove Dynamic Node',
                            onPressed: () => ref.read(nodesProvider.notifier).deleteNode(node.id),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Static (yaml)', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
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
    );
  }

  Widget _buildRegisterForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('+ Dynamic Node Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Registers upstream model without container restart',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 20),
            TextField(
              controller: _aliasController,
              decoration: const InputDecoration(labelText: 'Exposed Model Alias (e.g. basic-coder)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _backendController,
              decoration: const InputDecoration(labelText: 'Backend Engine / Model (e.g. ollama/qwen2.5-coder:7b)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hostController,
              decoration: InputDecoration(
                labelText: 'Node API Host Address',
                suffixIcon: IconButton(
                  icon: _isPinging
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.network_ping, size: 18),
                  tooltip: 'Ping Node Connectivity',
                  onPressed: _isPinging ? null : _pingNode,
                ),
              ),
            ),
            if (_pingResult != null) ...[
              const SizedBox(height: 6),
              Text(_pingResult!, style: const TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rpmController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'RPM Limit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Load Weight'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRegistering ? null : _registerNode,
                child: _isRegistering
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Node to Cluster'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
