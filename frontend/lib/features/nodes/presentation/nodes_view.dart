import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/node_model.dart';
import '../../auth/presentation/login_dialog.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class NodesView extends ConsumerStatefulWidget {
  const NodesView({super.key});

  @override
  ConsumerState<NodesView> createState() => _NodesViewState();
}

class _NodesViewState extends ConsumerState<NodesView> {
  final _aliasController = TextEditingController(text: 'multipass-node');
  final _backendController = TextEditingController(text: 'ollama/qwen2.5-coder:0.5b');
  final _hostController = TextEditingController(text: 'http://192.168.252.46:11434');
  final _rpmController = TextEditingController(text: '60');
  final _weightController = TextEditingController(text: '5');

  bool _isRegistering = false;
  bool _isPinging = false;
  String? _pingResult;

  final Map<String, int?> _nodePings = {};
  final Map<String, bool> _nodePinging = {};

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

  Future<void> _pingSpecificNode(NodeModel node) async {
    setState(() {
      _nodePinging[node.id] = true;
    });

    final latency = await ref.read(nodeRepositoryProvider).pingNode(node.apiBase);

    if (mounted) {
      setState(() {
        _nodePinging[node.id] = false;
        _nodePings[node.id] = latency;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            latency != null
                ? '⚡ Node "${node.modelName}" reachable (${latency}ms)'
                : '⚠️ Node "${node.modelName}" ping timed out / host unreachable',
          ),
          backgroundColor: latency != null ? AppTheme.success : AppTheme.warning,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleNodeMaintenance(NodeModel node) async {
    final nextBlocked = !node.isBlocked;
    final actionName = nextBlocked ? 'Drain / Pause' : 'Resume';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              nextBlocked ? Icons.pause_circle_outline : Icons.play_circle_outline,
              color: nextBlocked ? AppTheme.warning : AppTheme.success,
            ),
            const SizedBox(width: 10),
            Text('$actionName Node Traffic'),
          ],
        ),
        content: Text(
          nextBlocked
              ? 'Are you sure you want to drain traffic from "${node.modelName}"? LiteLLM will immediately stop routing requests to this node so you can safely perform maintenance or reboots.'
              : 'Restore traffic to "${node.modelName}"? LiteLLM will resume load-balancing active inference requests to this node.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: nextBlocked ? AppTheme.warning : AppTheme.success,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(actionName),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(nodesProvider.notifier).toggleBlockNode(node.id, nextBlocked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (nextBlocked ? '⏸️ Node "${node.modelName}" is now DRAINED (Maintenance mode)' : '▶️ Node "${node.modelName}" restored to active routing')
                  : '❌ Failed to update node maintenance state',
            ),
            backgroundColor: success ? (nextBlocked ? AppTheme.warning : AppTheme.success) : AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteNode(NodeModel node) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unregister Compute Node'),
        content: Text('Are you sure you want to remove "${node.modelName}" (${node.backendModel}) from the cluster?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove Node'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(nodesProvider.notifier).deleteNode(node.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Node "${node.modelName}" removed from cluster' : '❌ Failed to delete node'),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }

  void _showTerminalModal(BuildContext context, NodeModel node) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.terminal, color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Terminal & SSH: ${node.vmName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Host IP: ${node.hostIp} · Port 22 / Multipass CLI', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildCliSnippet(
                title: '⚡ Fast Interactive Shell (Multipass CLI)',
                description: 'Direct console access to the VM operating system without SSH keys',
                command: 'multipass shell ${node.vmName}',
              ),
              const SizedBox(height: 12),
              _buildCliSnippet(
                title: '🔑 Direct SSH Network Access',
                description: 'Standard SSH connection using system terminal',
                command: 'ssh ubuntu@${node.hostIp}',
              ),
              const SizedBox(height: 12),
              _buildCliSnippet(
                title: '🐳 Docker Container Status Check',
                description: 'Inspect Ollama, cAdvisor, and Node Exporter container states',
                command: 'multipass exec ${node.vmName} -- sudo docker ps',
              ),
              const SizedBox(height: 12),
              _buildCliSnippet(
                title: '🤖 Ollama Local Models Inspection',
                description: 'Verify downloaded models inside the node engine',
                command: 'multipass exec ${node.vmName} -- sudo docker exec ollama ollama list',
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOperationsModal(BuildContext context, NodeModel node) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.surfaceBorder),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.restart_alt, color: AppTheme.warning, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Node Operations & Reboot: ${node.vmName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Manage container lifecycle and VM restart for ${node.hostIp}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (node.isBlocked ? AppTheme.success : AppTheme.warning).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: (node.isBlocked ? AppTheme.success : AppTheme.warning).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(node.isBlocked ? Icons.check_circle_outline : Icons.shield_outlined,
                        color: node.isBlocked ? AppTheme.success : AppTheme.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        node.isBlocked
                            ? '✅ Node is DRAINED. Safe to restart services or reboot without dropping active user inference.'
                            : '⚠️ Pro Tip: Drain this node first before restarting so LiteLLM stops forwarding active traffic.',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCliSnippet(
                title: '🔄 Restart Ollama Inference Service',
                description: 'Restarts the Ollama daemon container (~2 seconds)',
                command: 'multipass exec ${node.vmName} -- sudo docker restart ollama',
              ),
              const SizedBox(height: 12),
              _buildCliSnippet(
                title: '📦 Restart Entire Docker Compose Stack',
                description: 'Restarts Ollama, cAdvisor, and Node Exporter services cleanly',
                command: 'multipass exec ${node.vmName} -- sudo docker compose -f /home/ubuntu/docker-compose.yml restart',
              ),
              const SizedBox(height: 12),
              _buildCliSnippet(
                title: '⚡ Reboot Virtual Machine Instance',
                description: 'Reboots the entire Ubuntu 24.04 instance via Multipass hypervisor',
                command: 'multipass restart ${node.vmName}',
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _toggleNodeMaintenance(node);
                    },
                    icon: Icon(node.isBlocked ? Icons.play_arrow : Icons.pause, size: 18),
                    label: Text(node.isBlocked ? 'Restore Traffic' : 'Drain Traffic First'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCliSnippet({
    required String title,
    required String description,
    required String command,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                tooltip: 'Copy Command',
                icon: const Icon(Icons.copy, color: AppTheme.primary),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: command));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📋 Copied: $command'),
                      backgroundColor: AppTheme.primary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(description, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.surfaceBorder.withValues(alpha: 0.4)),
            ),
            child: SelectableText(
              command,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppTheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
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
                    'Real-time CPU, RAM, Disk & GPU telemetry aggregated from Prometheus, Node Exporter & cAdvisor.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      html.window.open(ApiConstants.getPrometheusUrl(), '_blank');
                    },
                    icon: const Icon(Icons.show_chart, size: 18),
                    label: const Text('Open Prometheus Telemetry'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => ref.read(nodesProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh Nodes'),
                  ),
                ],
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

  Widget _buildNodesTable(AsyncValue<List<NodeModel>> nodesAsync) {
    final auth = ref.watch(authProvider);

    if (!auth.isAuthenticated) {
      return _buildAuthRequiredCard();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Inference Models & Nodes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.circle, color: AppTheme.success, size: 8),
                      SizedBox(width: 6),
                      Text('Prometheus Scraper Active', style: TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            nodesAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              error: (err, _) => _buildErrorCard(err.toString()),
              data: (nodes) {
                if (nodes.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No nodes registered.')));
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: nodes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final node = nodes[index];
                    return _buildNodeCard(node);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthRequiredCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, size: 42, color: AppTheme.primary),
              ),
              const SizedBox(height: 18),
              const Text(
                'Administrator Authentication Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'To inspect compute nodes, monitor hardware utilization (CPU, RAM, Disk, GPU),\nor register new upstream models, please sign in with your Administrator Master Key.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => LoginDialog.show(context),
                icon: const Icon(Icons.vpn_key_outlined, size: 18),
                label: const Text('Sign in as Administrator'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String errorMsg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 24),
              const SizedBox(width: 10),
              const Text('Failed to load compute nodes', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error)),
            ],
          ),
          const SizedBox(height: 8),
          Text(errorMsg, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => LoginDialog.show(context),
                icon: const Icon(Icons.login, size: 16),
                label: const Text('Sign in with Master Key'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => ref.read(nodesProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNodeCard(NodeModel node) {
    final metrics = node.metrics;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: node.isBlocked ? AppTheme.warning.withValues(alpha: 0.5) : AppTheme.surfaceBorder,
          width: node.isBlocked ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (node.isBlocked ? AppTheme.warning : AppTheme.primary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  node.isBlocked ? Icons.pause_circle_outline : Icons.dns_rounded,
                  color: node.isBlocked ? AppTheme.warning : AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(node.modelName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        if (node.isBlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.35)),
                            ),
                            child: const Text('DRAINED / PAUSED', style: TextStyle(fontSize: 10, color: AppTheme.warning, fontWeight: FontWeight.bold)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                            ),
                            child: const Text('ROUTING ACTIVE', style: TextStyle(fontSize: 10, color: AppTheme.success, fontWeight: FontWeight.bold)),
                          ),
                        if (node.isDynamic)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Dynamic Node', style: TextStyle(fontSize: 10, color: AppTheme.secondary, fontWeight: FontWeight.w600)),
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
                        if (_nodePings.containsKey(node.id))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (_nodePings[node.id] != null ? AppTheme.success : AppTheme.error).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _nodePings[node.id] != null ? '⚡ ${_nodePings[node.id]}ms' : '⚠️ Offline',
                              style: TextStyle(
                                fontSize: 10,
                                color: _nodePings[node.id] != null ? AppTheme.success : AppTheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${node.backendModel} · ${node.apiBase}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              if (node.weight != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBorder.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Weight: ${node.weight}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ),
              if (node.rpm != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBorder.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${node.rpm} RPM', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: _nodePinging[node.id] == true
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.network_ping, size: 18, color: AppTheme.secondary),
                    tooltip: 'Probe Ping Latency',
                    onPressed: _nodePinging[node.id] == true ? null : () => _pingSpecificNode(node),
                  ),
                  if (node.cadvisorUrl != null)
                    IconButton(
                      icon: const Icon(Icons.insights_outlined, size: 18, color: AppTheme.primary),
                      tooltip: 'Open cAdvisor Live Dashboard (${node.hostIp}:8080)',
                      onPressed: () => html.window.open(node.cadvisorUrl!, '_blank'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.terminal, size: 18, color: AppTheme.textPrimary),
                    tooltip: 'Terminal & SSH Access (${node.vmName})',
                    onPressed: () => _showTerminalModal(context, node),
                  ),
                  IconButton(
                    icon: Icon(
                      node.isBlocked ? Icons.play_arrow_rounded : Icons.pause_circle_outline,
                      size: 19,
                      color: node.isBlocked ? AppTheme.success : AppTheme.warning,
                    ),
                    tooltip: node.isBlocked ? 'Resume Routing (Unblock)' : 'Drain Traffic (Maintenance)',
                    onPressed: () => _toggleNodeMaintenance(node),
                  ),
                  IconButton(
                    icon: const Icon(Icons.restart_alt, size: 19, color: AppTheme.secondary),
                    tooltip: 'Node Operations & Service Reboot',
                    onPressed: () => _showOperationsModal(context, node),
                  ),
                  if (node.isDynamic)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                      tooltip: 'Remove Node from Cluster',
                      onPressed: () => _confirmDeleteNode(node),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (metrics != null && metrics.isLive) ...[
            Row(
              children: [
                _buildMetricBar('CPU', metrics.cpuPercent, Icons.memory, _getLoadColor(metrics.cpuPercent)),
                const SizedBox(width: 8),
                _buildMetricBar('RAM', metrics.memoryPercent, Icons.storage, _getLoadColor(metrics.memoryPercent)),
                const SizedBox(width: 8),
                _buildMetricBar('DISK', metrics.diskPercent, Icons.pie_chart_outline, _getLoadColor(metrics.diskPercent)),
                const SizedBox(width: 8),
                _buildGpuBadge(metrics),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.surfaceBorder.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.info_outline, size: 13, color: AppTheme.textMuted),
                  SizedBox(width: 6),
                  Text('Telemetry: Host metrics pending Prometheus scrape or mock alias', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getLoadColor(double percent) {
    if (percent > 85) return AppTheme.error;
    if (percent > 65) return AppTheme.warning;
    return AppTheme.success;
  }

  Widget _buildMetricBar(String label, double percent, IconData icon, Color color) {
    final clamped = (percent / 100.0).clamp(0.0, 1.0);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.surfaceBorder.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 13, color: color),
                    const SizedBox(width: 4),
                    Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                  ],
                ),
                Text(
                  '${percent.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: clamped,
                minHeight: 4,
                backgroundColor: AppTheme.surfaceBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpuBadge(NodeHardwareMetrics metrics) {
    final hasGpu = metrics.gpuPercent != null;
    final color = hasGpu ? AppTheme.secondary : AppTheme.primary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.surfaceBorder.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.speed, size: 13, color: color),
                    const SizedBox(width: 4),
                    const Text('ACCEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                  ],
                ),
                Flexible(
                  child: Text(
                    metrics.gpuLabel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: hasGpu ? ((metrics.gpuPercent! / 100.0).clamp(0.0, 1.0)) : 0.05,
                minHeight: 4,
                backgroundColor: AppTheme.surfaceBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
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
              decoration: const InputDecoration(labelText: 'Exposed Model Alias (e.g. multipass-node)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _backendController,
              decoration: const InputDecoration(labelText: 'Backend Engine / Model (e.g. ollama/qwen2.5-coder:0.5b)'),
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
