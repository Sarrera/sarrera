import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/user_model.dart';

class UserRepository {
  final ApiClient _client = ApiClient();

  Future<List<UserModel>> getUsers() async {
    try {
      final response = await _client.dio.get(ApiConstants.userList);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> users = response.data['users'] as List<dynamic>? ?? [];
        return users.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Failed to load users: ${e.response?.data ?? e.message}');
    }
  }

  Future<bool> createUser({
    required String userId,
    String? email,
    String? alias,
    required String tier,
    String? groupId,
    bool isGroupAccount = false,
    double? maxBudget,
    int? rpmLimit,
    int? tpmLimit,
    String userRole = 'internal_user',
    String? quotaSource,
  }) async {
    try {
      final List<String> userTeams = [];
      if (isGroupAccount && groupId != null && groupId.isNotEmpty) {
        userTeams.add(groupId);
      } else {
        userTeams.add(tier);
      }

      // LiteLLM strictly enforces enum: proxy_admin, proxy_admin_viewer, internal_user, internal_user_viewer
      const validRoles = ['proxy_admin', 'proxy_admin_viewer', 'internal_user', 'internal_user_viewer'];
      final effectiveRole = validRoles.contains(userRole) ? userRole : 'internal_user';

      final payload = {
        'user_id': userId.trim(),
        'user_role': effectiveRole,
        'teams': userTeams,
        if (email != null && email.isNotEmpty) 'user_email': email.trim(),
        if (alias != null && alias.isNotEmpty) 'user_alias': alias.trim(),
        if (maxBudget != null) 'max_budget': maxBudget,
        if (rpmLimit != null) 'rpm_limit': rpmLimit,
        if (tpmLimit != null) 'tpm_limit': tpmLimit,
        'budget_duration': '30d',
        'metadata': {
          'account_type': isGroupAccount ? 'group_member' : 'solo',
          'tier': tier,
          if (isGroupAccount && groupId != null) 'group_id': groupId,
          'quota_source': quotaSource ?? (isGroupAccount ? 'group' : 'personal'),
        },
      };

      final response = await _client.dio.post(
        ApiConstants.userNew,
        data: payload,
      );

      // If user is added to a group, ensure membership record is registered
      if (response.statusCode == 200 && isGroupAccount && groupId != null && groupId.isNotEmpty) {
        try {
          await _client.dio.post(
            ApiConstants.teamMemberAdd,
            data: {
              'team_id': groupId,
              'member': {
                'user_id': userId.trim(),
                'role': 'user',
                if (maxBudget != null) 'max_budget': maxBudget,
              }
            },
          );
        } catch (_) {
          // If already auto-linked, ignore
        }
      }

      return response.statusCode == 200;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw Exception('Failed to create user: $detail');
    }
  }

  Future<GeneratedApiKeyResult> generateKeyForUser({
    required String userId,
    required String tier,
    String? keyAlias,
    String duration = '90d',
    double? maxBudget,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final payload = {
        'user_id': userId.trim(),
        'team_id': tier,
        'key_alias': keyAlias ?? '$userId-$tier-key',
        'duration': duration,
        if (maxBudget != null) 'max_budget': maxBudget,
        if (metadata != null) 'metadata': metadata,
      };

      final response = await _client.dio.post(
        ApiConstants.keyGenerate,
        data: payload,
      );

      if (response.statusCode == 200 && response.data != null) {
        return GeneratedApiKeyResult.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to parse generated key');
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw Exception('Failed to generate key: $detail');
    }
  }

  Future<bool> toggleUserQuotaSource({
    required String userId,
    required bool useGroupQuota,
    Map<String, dynamic>? existingMetadata,
  }) async {
    final meta = Map<String, dynamic>.from(existingMetadata ?? {});
    meta['quota_source'] = useGroupQuota ? 'group' : 'personal';
    return updateUserMetadata(userId: userId, metadata: meta);
  }

  Future<bool> updateUserMetadata({
    required String userId,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.userUpdate,
        data: {
          'user_id': userId.trim(),
          'metadata': metadata,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw Exception('Failed to update user: $detail');
    }
  }

  Future<bool> updateUserMfa({
    required String userId,
    required bool enabled,
    String? secret,
    Map<String, dynamic>? existingMetadata,
  }) async {
    final meta = Map<String, dynamic>.from(existingMetadata ?? {});
    meta['mfa_enabled'] = enabled;
    if (enabled && secret != null) {
      meta['mfa_secret'] = secret;
    } else if (!enabled) {
      meta.remove('mfa_secret');
    }
    return updateUserMetadata(userId: userId, metadata: meta);
  }

  Future<bool> deleteUser(String userId) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.userDelete,
        data: {'user_ids': [userId]},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Failed to delete user: ${e.response?.data ?? e.message}');
    }
  }
}
