class UserModel {
  final String userId;
  final String? userEmail;
  final String? userAlias;
  final String userRole;
  final List<String> teams;
  final double? maxBudget;
  final double spend;
  final int? tpmLimit;
  final int? rpmLimit;
  final List<String> models;
  final DateTime? createdAt;
  final int keyCount;

  const UserModel({
    required this.userId,
    this.userEmail,
    this.userAlias,
    this.userRole = 'app_user',
    this.teams = const [],
    this.maxBudget,
    this.spend = 0.0,
    this.tpmLimit,
    this.rpmLimit,
    this.models = const [],
    this.createdAt,
    this.keyCount = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      try {
        return DateTime.parse(date.toString());
      } catch (_) {
        return null;
      }
    }

    final rawTeams = json['teams'] as List<dynamic>? ?? [];

    return UserModel(
      userId: json['user_id'] ?? '',
      userEmail: json['user_email'] as String?,
      userAlias: json['user_alias'] as String?,
      userRole: json['user_role'] ?? 'app_user',
      teams: rawTeams.map((e) => e.toString()).toList(),
      maxBudget: json['max_budget'] != null ? (json['max_budget'] as num).toDouble() : null,
      spend: json['spend'] != null ? (json['spend'] as num).toDouble() : 0.0,
      tpmLimit: json['tpm_limit'] as int?,
      rpmLimit: json['rpm_limit'] as int?,
      models: (json['models'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: parseDate(json['created_at']),
      keyCount: json['key_count'] as int? ?? 0,
    );
  }

  String get primaryTier => teams.isNotEmpty ? teams.first : 'Unassigned';

  double get budgetProgressPercentage {
    if (maxBudget == null || maxBudget! <= 0) return 0.0;
    final pct = (spend / maxBudget!) * 100.0;
    return pct.clamp(0.0, 100.0);
  }
}

class GeneratedApiKeyResult {
  final String key;
  final String keyName;
  final String? expires;
  final String userId;
  final String teamId;

  const GeneratedApiKeyResult({
    required this.key,
    required this.keyName,
    this.expires,
    required this.userId,
    required this.teamId,
  });

  factory GeneratedApiKeyResult.fromJson(Map<String, dynamic> json) {
    return GeneratedApiKeyResult(
      key: json['key'] ?? '',
      keyName: json['key_name'] ?? '',
      expires: json['expires']?.toString(),
      userId: json['user_id'] ?? '',
      teamId: json['team_id'] ?? '',
    );
  }
}
