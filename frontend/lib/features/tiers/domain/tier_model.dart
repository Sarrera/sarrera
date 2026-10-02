class TierModel {
  final String teamId;
  final String teamAlias;
  final double? maxBudget;
  final String budgetDuration;
  final int? rpmLimit;
  final int? tpmLimit;
  final List<String> models;
  final double spend;
  final DateTime? budgetResetAt;
  final int activeKeysCount;

  const TierModel({
    required this.teamId,
    required this.teamAlias,
    this.maxBudget,
    this.budgetDuration = '30d',
    this.rpmLimit,
    this.tpmLimit,
    this.models = const [],
    this.spend = 0.0,
    this.budgetResetAt,
    this.activeKeysCount = 0,
  });

  factory TierModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      try {
        return DateTime.parse(date.toString());
      } catch (_) {
        return null;
      }
    }

    final rawKeys = json['keys'] as List<dynamic>? ?? [];

    return TierModel(
      teamId: json['team_id'] ?? '',
      teamAlias: json['team_alias'] ?? json['team_id'] ?? '',
      maxBudget: json['max_budget'] != null ? (json['max_budget'] as num).toDouble() : null,
      budgetDuration: json['budget_duration'] ?? '30d',
      rpmLimit: json['rpm_limit'] as int?,
      tpmLimit: json['tpm_limit'] as int?,
      models: (json['models'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      spend: json['spend'] != null ? (json['spend'] as num).toDouble() : 0.0,
      budgetResetAt: parseDate(json['budget_reset_at']),
      activeKeysCount: rawKeys.length,
    );
  }

  Map<String, dynamic> toJson() => {
        'team_id': teamId,
        'team_alias': teamAlias,
        'max_budget': maxBudget,
        'budget_duration': budgetDuration,
        'rpm_limit': rpmLimit,
        'tpm_limit': tpmLimit,
        'models': models,
      };

  double get budgetProgressPercentage {
    if (maxBudget == null || maxBudget! <= 0) return 0.0;
    final pct = (spend / maxBudget!) * 100.0;
    return pct.clamp(0.0, 100.0);
  }
}
