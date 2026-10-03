class GroupMember {
  final String userId;
  final String? userEmail;
  final String? userAlias;
  final String role;
  final double spend;
  final double? maxBudget;

  const GroupMember({
    required this.userId,
    this.userEmail,
    this.userAlias,
    this.role = 'user',
    this.spend = 0.0,
    this.maxBudget,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user_id']?.toString() ?? '',
      userEmail: json['user_email'] as String?,
      userAlias: json['user_alias'] as String?,
      role: json['role']?.toString() ?? 'user',
      spend: json['spend'] != null ? (json['spend'] as num).toDouble() : 0.0,
      maxBudget: json['max_budget'] != null ? (json['max_budget'] as num).toDouble() : null,
    );
  }
}

class GroupModel {
  final String groupId;
  final String groupAlias;
  final String tier;
  final double? maxBudget;
  final String budgetDuration;
  final int? rpmLimit;
  final int? tpmLimit;
  final List<String> models;
  final double spend;
  final DateTime? budgetResetAt;
  final List<GroupMember> members;
  final int activeKeysCount;
  final String? clientEmail;
  final DateTime? createdAt;

  const GroupModel({
    required this.groupId,
    required this.groupAlias,
    this.tier = 'tier-standard',
    this.maxBudget,
    this.budgetDuration = '30d',
    this.rpmLimit,
    this.tpmLimit,
    this.models = const [],
    this.spend = 0.0,
    this.budgetResetAt,
    this.members = const [],
    this.activeKeysCount = 0,
    this.clientEmail,
    this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      try {
        return DateTime.parse(date.toString());
      } catch (_) {
        return null;
      }
    }

    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};
    final tier = metadata['tier']?.toString() ?? 'tier-standard';
    final clientEmail = metadata['contact_email']?.toString() ?? metadata['client_email']?.toString();

    // Parse members from members_with_roles or team_memberships
    final rawRoles = json['members_with_roles'] as List<dynamic>? ?? [];
    final rawMemberships = json['team_memberships'] as List<dynamic>? ?? [];

    final Map<String, double> memberSpends = {};
    for (var m in rawMemberships) {
      if (m is Map<String, dynamic> && m['user_id'] != null) {
        memberSpends[m['user_id'].toString()] =
            m['spend'] != null ? (m['spend'] as num).toDouble() : 0.0;
      }
    }

    final List<GroupMember> parsedMembers = [];
    for (var r in rawRoles) {
      if (r is Map<String, dynamic>) {
        final uid = r['user_id']?.toString() ?? '';
        if (uid.isEmpty || uid == 'default_user_id') continue;
        parsedMembers.add(GroupMember(
          userId: uid,
          userEmail: r['user_email'] as String?,
          userAlias: r['user_alias'] as String?,
          role: r['role']?.toString() ?? 'user',
          spend: memberSpends[uid] ?? 0.0,
          maxBudget: r['max_budget'] != null ? (r['max_budget'] as num).toDouble() : null,
        ));
      }
    }

    final rawKeys = json['keys'] as List<dynamic>? ?? [];

    return GroupModel(
      groupId: json['team_id'] ?? '',
      groupAlias: json['team_alias'] ?? json['team_id'] ?? 'Client Group',
      tier: tier,
      maxBudget: json['max_budget'] != null ? (json['max_budget'] as num).toDouble() : null,
      budgetDuration: json['budget_duration'] ?? '30d',
      rpmLimit: json['rpm_limit'] as int?,
      tpmLimit: json['tpm_limit'] as int?,
      models: (json['models'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      spend: json['spend'] != null ? (json['spend'] as num).toDouble() : 0.0,
      budgetResetAt: parseDate(json['budget_reset_at']),
      members: parsedMembers,
      activeKeysCount: rawKeys.length,
      clientEmail: clientEmail,
      createdAt: parseDate(json['created_at']),
    );
  }

  double get budgetProgressPercentage {
    if (maxBudget == null || maxBudget! <= 0) return 0.0;
    final pct = (spend / maxBudget!) * 100.0;
    return pct.clamp(0.0, 100.0);
  }

  int get memberCount => members.length;
}
