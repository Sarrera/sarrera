class NodeHardwareMetrics {
  final double cpuPercent;
  final double memoryPercent;
  final double diskPercent;
  final double? gpuPercent;
  final String gpuLabel;
  final bool isLive;

  const NodeHardwareMetrics({
    this.cpuPercent = 0.0,
    this.memoryPercent = 0.0,
    this.diskPercent = 0.0,
    this.gpuPercent,
    this.gpuLabel = 'CPU Mode',
    this.isLive = false,
  });

  NodeHardwareMetrics copyWith({
    double? cpuPercent,
    double? memoryPercent,
    double? diskPercent,
    double? gpuPercent,
    String? gpuLabel,
    bool? isLive,
  }) {
    return NodeHardwareMetrics(
      cpuPercent: cpuPercent ?? this.cpuPercent,
      memoryPercent: memoryPercent ?? this.memoryPercent,
      diskPercent: diskPercent ?? this.diskPercent,
      gpuPercent: gpuPercent ?? this.gpuPercent,
      gpuLabel: gpuLabel ?? this.gpuLabel,
      isLive: isLive ?? this.isLive,
    );
  }
}

class NodeModel {
  final String id;
  final String modelName;
  final String backendModel;
  final String apiBase;
  final int? rpm;
  final int? weight;
  final bool isDynamic;
  final bool isBlocked;
  final NodeHardwareMetrics? metrics;

  const NodeModel({
    required this.id,
    required this.modelName,
    required this.backendModel,
    required this.apiBase,
    this.rpm,
    this.weight,
    this.isDynamic = true,
    this.isBlocked = false,
    this.metrics,
  });

  String get hostIp {
    try {
      final uri = Uri.tryParse(apiBase);
      if (uri != null && uri.host.isNotEmpty) return uri.host;
    } catch (_) {}
    return apiBase;
  }

  String get vmName {
    final lower = modelName.toLowerCase();
    final ip = hostIp;
    if (lower.contains('node-1') || ip.endsWith('.46')) return 'sarrera-node-1';
    if (lower.contains('node-2') || ip.endsWith('.47')) return 'sarrera-node-2';
    if (lower.startsWith('multipass-')) {
      return 'sarrera-${lower.replaceAll('multipass-', '')}';
    }
    return modelName;
  }

  String? get cadvisorUrl {
    final ip = hostIp;
    if (ip.isNotEmpty && ip.contains('.')) {
      return 'http://$ip:8080/containers/';
    }
    return null;
  }

  NodeModel copyWith({
    String? id,
    String? modelName,
    String? backendModel,
    String? apiBase,
    int? rpm,
    int? weight,
    bool? isDynamic,
    bool? isBlocked,
    NodeHardwareMetrics? metrics,
  }) {
    return NodeModel(
      id: id ?? this.id,
      modelName: modelName ?? this.modelName,
      backendModel: backendModel ?? this.backendModel,
      apiBase: apiBase ?? this.apiBase,
      rpm: rpm ?? this.rpm,
      weight: weight ?? this.weight,
      isDynamic: isDynamic ?? this.isDynamic,
      isBlocked: isBlocked ?? this.isBlocked,
      metrics: metrics ?? this.metrics,
    );
  }

  factory NodeModel.fromJson(Map<String, dynamic> json, [NodeHardwareMetrics? metrics]) {
    final params = json['litellm_params'] as Map<String, dynamic>? ?? {};
    final modelInfo = json['model_info'] as Map<String, dynamic>? ?? {};
    final modelId = modelInfo['id'] ?? json['id'] ?? '';
    final blocked = (modelInfo['blocked'] == true) || (json['blocked'] == true);

    return NodeModel(
      id: modelId.toString(),
      modelName: json['model_name'] ?? 'Unknown',
      backendModel: params['model'] ?? 'default',
      apiBase: params['api_base'] ?? 'Cluster / Local',
      rpm: params['rpm'] as int?,
      weight: params['weight'] as int?,
      isDynamic: modelId.toString().isNotEmpty,
      isBlocked: blocked,
      metrics: metrics,
    );
  }
}
