import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/tier_model.dart';

class TierRepository {
  final ApiClient _client = ApiClient();

  Future<List<TierModel>> getTiers() async {
    try {
      final response = await _client.dio.get(ApiConstants.teamList);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data is List
            ? response.data
            : (response.data['data'] as List<dynamic>? ?? []);
        return list.map((item) => TierModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Failed to load tiers: ${e.response?.data ?? e.message}');
    }
  }

  Future<bool> updateTierQuota({
    required String teamId,
    required double maxBudget,
    required int rpmLimit,
    required int tpmLimit,
    required List<String> models,
  }) async {
    try {
      final payload = {
        'team_id': teamId,
        'max_budget': maxBudget,
        'rpm_limit': rpmLimit,
        'tpm_limit': tpmLimit,
        'models': models,
      };

      final response = await _client.dio.post(
        ApiConstants.teamUpdate,
        data: payload,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Failed to update tier: ${e.response?.data ?? e.message}');
    }
  }
}
