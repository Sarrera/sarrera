import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/node_model.dart';

class NodeRepository {
  final ApiClient _client = ApiClient();

  Map<String, double> _parsePrometheusVector(dynamic rawData) {
    final Map<String, double> results = {};
    try {
      dynamic data = rawData;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }

      if (data is Map && data['status'] == 'success') {
        final dataObj = data['data'];
        final List<dynamic> list = (dataObj is Map ? dataObj['result'] : null) as List<dynamic>? ?? [];
        for (final item in list) {
          if (item is! Map) continue;
          final metric = item['metric'];
          String instance = '';
          String nodeName = '';
          if (metric is Map) {
            instance = metric['instance']?.toString() ?? '';
            nodeName = metric['node_name']?.toString() ?? '';
          }
          final valueList = item['value'];
          if (valueList is List && valueList.length >= 2) {
            final valStr = valueList[1]?.toString() ?? '';
            final val = double.tryParse(valStr);
            if (val != null) {
              if (instance.isNotEmpty) {
                results[instance] = val;
                if (instance.contains(':')) {
                  results[instance.split(':').first] = val;
                }
              }
              if (nodeName.isNotEmpty) {
                results[nodeName] = val;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing Prometheus vector: $e');
    }
    return results;
  }

  String _extractHost(String apiBase) {
    try {
      final uri = Uri.tryParse(apiBase);
      if (uri != null && uri.host.isNotEmpty) {
        return uri.host;
      }
    } catch (_) {}
    return apiBase;
  }

  Future<dynamic> _safePromQuery(String query) async {
    try {
      final res = await _client.dio.get(
        ApiConstants.prometheusQuery,
        queryParameters: {'query': query},
      );
      return res.data;
    } catch (e) {
      debugPrint('Prometheus query error for [$query]: $e');
      return null;
    }
  }

  Future<Map<String, NodeHardwareMetrics>> fetchPrometheusMetrics() async {
    final Map<String, NodeHardwareMetrics> metricsMap = {};
    try {
      final futures = await Future.wait([
        _safePromQuery('100-(avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m]))*100)'),
        _safePromQuery('((node_memory_MemTotal_bytes-node_memory_MemAvailable_bytes)/node_memory_MemTotal_bytes)*100'),
        _safePromQuery('((node_filesystem_size_bytes{mountpoint="/"}-node_filesystem_avail_bytes{mountpoint="/"})/node_filesystem_size_bytes{mountpoint="/"})*100'),
        _safePromQuery('DCGM_FI_DEV_GPU_UTIL or (container_gpu_utilization * 100) or (nvidia_smi_utilization_gpu_ratio * 100)'),
      ]);

      final cpuMap = _parsePrometheusVector(futures[0]);
      final memMap = _parsePrometheusVector(futures[1]);
      final diskMap = _parsePrometheusVector(futures[2]);
      final gpuMap = _parsePrometheusVector(futures[3]);

      final allKeys = {...cpuMap.keys, ...memMap.keys, ...diskMap.keys, ...gpuMap.keys};
      for (final key in allKeys) {
        final gpuVal = gpuMap[key];
        metricsMap[key] = NodeHardwareMetrics(
          cpuPercent: (cpuMap[key] ?? 0.0).clamp(0.0, 100.0),
          memoryPercent: (memMap[key] ?? 0.0).clamp(0.0, 100.0),
          diskPercent: (diskMap[key] ?? 0.0).clamp(0.0, 100.0),
          gpuPercent: gpuVal,
          gpuLabel: gpuVal != null ? 'NVIDIA GPU (${gpuVal.toStringAsFixed(0)}%)' : 'CPU Mode',
          isLive: true,
        );
      }
    } catch (e) {
      debugPrint('Error in fetchPrometheusMetrics: $e');
    }
    return metricsMap;
  }

  NodeHardwareMetrics? _findMetricsForNode(NodeModel model, Map<String, NodeHardwareMetrics> metricsMap) {
    if (metricsMap.isEmpty) return null;

    final host = _extractHost(model.apiBase);
    if (metricsMap.containsKey(host)) return metricsMap[host];
    if (metricsMap.containsKey('$host:9100')) return metricsMap['$host:9100'];
    if (metricsMap.containsKey(model.modelName)) return metricsMap[model.modelName];

    // Substring match on IP in apiBase (e.g. 192.168.252.46)
    for (final entry in metricsMap.entries) {
      if (entry.key.isNotEmpty && (model.apiBase.contains(entry.key) || entry.key.contains(host))) {
        return entry.value;
      }
    }

    // Match by node suffix (e.g. node-1 / node-2)
    final lowerModel = model.modelName.toLowerCase();
    for (final entry in metricsMap.entries) {
      final lowerKey = entry.key.toLowerCase();
      if (lowerModel.contains('node-1') && lowerKey.contains('node-1')) return entry.value;
      if (lowerModel.contains('node-2') && lowerKey.contains('node-2')) return entry.value;
      if (lowerModel.contains('node-1') && lowerKey.contains('.46')) return entry.value;
      if (lowerModel.contains('node-2') && lowerKey.contains('.47')) return entry.value;
    }

    return null;
  }

  Future<List<NodeModel>> getNodes() async {
    try {
      final responseFuture = _client.dio.get(ApiConstants.modelInfo);
      final metricsFuture = fetchPrometheusMetrics();

      final results = await Future.wait([responseFuture, metricsFuture]);
      final response = results[0] as Response;
      final metricsMap = results[1] as Map<String, NodeHardwareMetrics>;

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'] as List<dynamic>? ?? [];
        return data.map((item) {
          final model = NodeModel.fromJson(item as Map<String, dynamic>);
          final metrics = _findMetricsForNode(model, metricsMap);
          return model.copyWith(metrics: metrics);
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Failed to load compute nodes: ${e.response?.data ?? e.message}');
    }
  }

  Future<bool> registerNode({
    required String modelAlias,
    required String backendModel,
    required String apiBase,
    int rpm = 60,
    int? weight,
  }) async {
    try {
      final payload = {
        'model_name': modelAlias.trim(),
        'litellm_params': {
          'model': backendModel.trim(),
          'api_base': apiBase.trim(),
          'rpm': rpm,
          if (weight != null) 'weight': weight,
        }
      };

      final response = await _client.dio.post(
        ApiConstants.modelNew,
        data: payload,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw Exception('Failed to register node: $detail');
    }
  }

  Future<bool> deleteNode(String nodeId) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.modelDelete,
        data: {'id': nodeId},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Failed to delete node: ${e.response?.data ?? e.message}');
    }
  }

  Future<bool> toggleBlockNode(String nodeId, bool blocked) async {
    try {
      final response = await _client.dio.patch(
        ApiConstants.modelUpdate(nodeId),
        data: {'blocked': blocked},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Failed to update node maintenance state: ${e.response?.data ?? e.message}');
    }
  }

  Future<int?> pingNode(String apiBase) async {
    try {
      final stopwatch = Stopwatch()..start();
      await _client.dio.get(
        '$apiBase/api/version',
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }
}
