class NodeModel {
  final String id;
  final String modelName;
  final String backendModel;
  final String apiBase;
  final int? rpm;
  final int? weight;
  final bool isDynamic;

  const NodeModel({
    required this.id,
    required this.modelName,
    required this.backendModel,
    required this.apiBase,
    this.rpm,
    this.weight,
    this.isDynamic = true,
  });

  factory NodeModel.fromJson(Map<String, dynamic> json) {
    final params = json['litellm_params'] as Map<String, dynamic>? ?? {};
    final modelInfo = json['model_info'] as Map<String, dynamic>? ?? {};
    final modelId = modelInfo['id'] ?? json['id'] ?? '';

    return NodeModel(
      id: modelId.toString(),
      modelName: json['model_name'] ?? 'Unknown',
      backendModel: params['model'] ?? 'default',
      apiBase: params['api_base'] ?? 'Cluster / Local',
      rpm: params['rpm'] as int?,
      weight: params['weight'] as int?,
      isDynamic: modelId.toString().isNotEmpty,
    );
  }
}
