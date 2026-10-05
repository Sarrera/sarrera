import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/group_model.dart';

class GroupRepository {
  final ApiClient _client = ApiClient();

  /// Retrieve all B2B client organizations / groups with consolidated telemetry
  Future<List<GroupModel>> getGroups() async {
    try {
      final response = await _client.dio.get(ApiConstants.teamList);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> list = response.data is List
            ? response.data
            : (response.data['data'] as List<dynamic>? ?? []);

        // Filter groups: team_id starts with 'group-' or metadata['account_type'] == 'group'
        final groupTeams = list.where((item) {
          if (item is! Map<String, dynamic>) return false;
          final tid = item['team_id']?.toString() ?? '';
          final meta = item['metadata'] as Map<String, dynamic>? ?? {};
          return tid.startsWith('group-') || meta['account_type'] == 'group';
        }).toList();

        // For each group, query team/info to obtain full member breakdown and spends
        final List<GroupModel> groups = [];
        for (var item in groupTeams) {
          final tid = item['team_id']?.toString() ?? '';
          try {
            final infoRes = await _client.dio.get(
              ApiConstants.teamInfo,
              queryParameters: {'team_id': tid},
            );
            if (infoRes.statusCode == 200 && infoRes.data != null) {
              final teamInfo = infoRes.data['team_info'] as Map<String, dynamic>? ?? {};
              // Merge root team_memberships and keys into teamInfo if present
              if (infoRes.data['team_memberships'] != null) {
                teamInfo['team_memberships'] = infoRes.data['team_memberships'];
              }
              if (infoRes.data['keys'] != null) {
                teamInfo['keys'] = infoRes.data['keys'];
              }
              groups.add(GroupModel.fromJson(teamInfo));
              continue;
            }
          } catch (_) {
            // Fallback to basic team item if team/info fails
          }
          groups.add(GroupModel.fromJson(item as Map<String, dynamic>));
        }

        return groups;
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Failed to load client groups: ${e.response?.data ?? e.message}');
    }
  }

  /// Create a new corporate Client Group with pooled budget and inherited tier models
  Future<bool> createGroup({
    required String groupId,
    required String groupAlias,
    required String tier,
    required double maxBudget,
    int? rpmLimit,
    int? tpmLimit,
    String? contactEmail,
    List<String>? customModels,
  }) async {
    try {
      final slugId = groupId.trim().startsWith('group-')
          ? groupId.trim()
          : 'group-${groupId.trim().replaceAll(' ', '-').toLowerCase()}';

      List<String> models = customModels ?? [];
      if (models.isEmpty) {
        switch (tier) {
          case 'tier-premium':
            models = ['basic-coder', 'premium-coder', 'premium-reasoning'];
            break;
          case 'tier-basic':
            models = ['basic-coder'];
            break;
          case 'tier-standard':
          default:
            models = ['basic-coder', 'premium-coder'];
            break;
        }
      }

      final payload = {
        'team_id': slugId,
        'team_alias': groupAlias.trim(),
        'models': models,
        'max_budget': maxBudget,
        'budget_duration': '30d',
        'rpm_limit': rpmLimit ?? (tier == 'tier-premium' ? 240 : 120),
        'tpm_limit': tpmLimit ?? (tier == 'tier-premium' ? 180000 : 60000),
        'metadata': {
          'account_type': 'group',
          'tier': tier,
          'client_name': groupAlias.trim(),
          if (contactEmail != null && contactEmail.isNotEmpty)
            'contact_email': contactEmail.trim(),
        },
      };

      final response = await _client.dio.post(
        ApiConstants.teamNew,
        data: payload,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw Exception('Failed to create client group: $detail');
    }
  }

  /// Delete a corporate client group by ID
  Future<bool> deleteGroup(String groupId) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.teamDelete,
        data: {
          'team_ids': [groupId]
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw Exception('Failed to delete group: $detail');
    }
  }

  /// Enroll an existing user into a corporate Client Group
  Future<bool> addMemberToGroup({
    required String groupId,
    required String userId,
    String role = 'user',
    double? maxBudget,
  }) async {
    try {
      final payload = {
        'team_id': groupId,
        'member': {
          'user_id': userId.trim(),
          'role': role,
          if (maxBudget != null) 'max_budget': maxBudget,
        },
      };

      final response = await _client.dio.post(
        ApiConstants.teamMemberAdd,
        data: payload,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw Exception('Failed to add member to group: $detail');
    }
  }

  /// Remove a user membership from a corporate Client Group
  Future<bool> removeMemberFromGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      final payload = {
        'team_id': groupId,
        'user_id': userId.trim(),
      };

      final response = await _client.dio.post(
        ApiConstants.teamMemberDelete,
        data: payload,
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw Exception('Failed to remove member from group: $detail');
    }
  }
}
