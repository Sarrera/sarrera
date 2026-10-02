import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../../features/tiers/domain/tier_model.dart';
import '../../features/tiers/data/tier_repository.dart';
import '../../features/users/domain/user_model.dart';
import '../../features/users/data/user_repository.dart';
import '../../features/nodes/domain/node_model.dart';
import '../../features/nodes/data/node_repository.dart';

enum UserRole { guest, developer, admin }

// --- AUTH STATE ---
class AuthState {
  final bool isAuthenticated;
  final UserRole role;
  final String? token;
  final String? userId;
  final String? userAlias;
  final String? userEmail;
  final String? teamId;
  final double spend;
  final double? maxBudget;
  final List<String> allowedModels;
  final int rpmLimit;
  final int tpmLimit;
  final String? keyAlias;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.role = UserRole.guest,
    this.token,
    this.userId,
    this.userAlias,
    this.userEmail,
    this.teamId,
    this.spend = 0.0,
    this.maxBudget,
    this.allowedModels = const [],
    this.rpmLimit = 60,
    this.tpmLimit = 30000,
    this.keyAlias,
    this.error,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isDeveloper => role == UserRole.developer;
  bool get isGuest => role == UserRole.guest;

  String? get username => userId ?? (isAdmin ? 'Administrator' : null);

  double get budgetProgressPercentage {
    if (maxBudget == null || maxBudget! <= 0) return 0.0;
    return ((spend / maxBudget!) * 100.0).clamp(0.0, 100.0);
  }

  AuthState copyWith({
    bool? isAuthenticated,
    UserRole? role,
    String? token,
    String? userId,
    String? userAlias,
    String? userEmail,
    String? teamId,
    double? spend,
    double? maxBudget,
    List<String>? allowedModels,
    int? rpmLimit,
    int? tpmLimit,
    String? keyAlias,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      userAlias: userAlias ?? this.userAlias,
      userEmail: userEmail ?? this.userEmail,
      teamId: teamId ?? this.teamId,
      spend: spend ?? this.spend,
      maxBudget: maxBudget ?? this.maxBudget,
      allowedModels: allowedModels ?? this.allowedModels,
      rpmLimit: rpmLimit ?? this.rpmLimit,
      tpmLimit: tpmLimit ?? this.tpmLimit,
      keyAlias: keyAlias ?? this.keyAlias,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final ApiClient _client = ApiClient();

  @override
  AuthState build() {
    final hasToken = ApiClient().isAuthenticated;
    return AuthState(
      isAuthenticated: hasToken,
      role: hasToken ? UserRole.admin : UserRole.guest,
      token: ApiClient().adminToken,
      userId: hasToken ? 'Admin' : null,
    );
  }

  Future<bool> login(String username, String password) async {
    return loginAdmin(password.trim());
  }

  Future<bool> loginAdmin(String masterKey) async {
    final token = masterKey.trim();
    _client.setToken(token);

    try {
      // Test master key by querying tier list
      await TierRepository().getTiers();
      state = state.copyWith(
        isAuthenticated: true,
        role: UserRole.admin,
        token: token,
        userId: 'admin',
        userAlias: 'Platform Administrator',
        error: null,
      );
      return true;
    } catch (e) {
      _client.clearToken();
      state = state.copyWith(
        isAuthenticated: false,
        role: UserRole.guest,
        token: null,
        error: 'Invalid Administrator Master Key: $e',
      );
      return false;
    }
  }

  Future<bool> loginDeveloper(String apiKey) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      state = state.copyWith(error: 'Please enter your Virtual API Key');
      return false;
    }

    try {
      // Validate virtual key via /key/info
      final response = await _client.dio.get(
        '/admin/litellm/key/info',
        options: Options(
          headers: {'Authorization': 'Bearer $key'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final info = response.data['info'] as Map<String, dynamic>? ?? {};
        final userId = info['user_id']?.toString() ?? 'developer';
        final teamId = info['team_id']?.toString() ?? 'tier-standard';
        final spend = (info['spend'] as num?)?.toDouble() ?? 0.0;
        final keyAlias = info['key_alias']?.toString() ?? 'Developer Key';

        // Load models & limits for this team
        List<String> models = ['basic-coder'];
        double maxBudget = 50.0;
        int rpm = 60;
        int tpm = 30000;

        if (teamId == 'tier-premium') {
          models = ['basic-coder', 'premium-coder', 'premium-reasoning'];
          maxBudget = 100.0;
          rpm = 180;
          tpm = 120000;
        } else if (teamId == 'tier-standard') {
          models = ['basic-coder', 'premium-coder'];
          maxBudget = 50.0;
          rpm = 120;
          tpm = 60000;
        } else if (teamId == 'tier-basic') {
          models = ['basic-coder'];
          maxBudget = 15.0;
          rpm = 60;
          tpm = 30000;
        }

        _client.setToken(key);

        state = AuthState(
          isAuthenticated: true,
          role: UserRole.developer,
          token: key,
          userId: userId,
          userAlias: keyAlias,
          teamId: teamId,
          spend: spend,
          maxBudget: maxBudget,
          allowedModels: models,
          rpmLimit: rpm,
          tpmLimit: tpm,
          keyAlias: keyAlias,
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Virtual API key not found or expired. Please check with your administrator.',
      );
      return false;
    }
    return false;
  }

  void logout() {
    _client.clearToken();
    state = const AuthState(isAuthenticated: false, role: UserRole.guest);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// --- REPOSITORIES ---
final tierRepositoryProvider = Provider((ref) => TierRepository());
final userRepositoryProvider = Provider((ref) => UserRepository());
final nodeRepositoryProvider = Provider((ref) => NodeRepository());

// --- TIERS STATE ---
final tiersProvider = AsyncNotifierProvider<TiersNotifier, List<TierModel>>(() {
  return TiersNotifier();
});

class TiersNotifier extends AsyncNotifier<List<TierModel>> {
  @override
  Future<List<TierModel>> build() async {
    final repo = ref.watch(tierRepositoryProvider);
    return repo.getTiers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(tierRepositoryProvider).getTiers());
  }

  Future<bool> updateTier({
    required String teamId,
    required double maxBudget,
    required int rpmLimit,
    required int tpmLimit,
    required List<String> models,
  }) async {
    final success = await ref.read(tierRepositoryProvider).updateTierQuota(
          teamId: teamId,
          maxBudget: maxBudget,
          rpmLimit: rpmLimit,
          tpmLimit: tpmLimit,
          models: models,
        );
    if (success) {
      await refresh();
    }
    return success;
  }
}

// --- USERS STATE ---
final usersProvider = AsyncNotifierProvider<UsersNotifier, List<UserModel>>(() {
  return UsersNotifier();
});

class UsersNotifier extends AsyncNotifier<List<UserModel>> {
  @override
  Future<List<UserModel>> build() async {
    final repo = ref.watch(userRepositoryProvider);
    return repo.getUsers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(userRepositoryProvider).getUsers());
  }

  Future<bool> createUser({
    required String userId,
    String? email,
    String? alias,
    required String tier,
    double? maxBudget,
    int? rpmLimit,
    int? tpmLimit,
  }) async {
    final success = await ref.read(userRepositoryProvider).createUser(
          userId: userId,
          email: email,
          alias: alias,
          tier: tier,
          maxBudget: maxBudget,
          rpmLimit: rpmLimit,
          tpmLimit: tpmLimit,
        );
    if (success) {
      await refresh();
    }
    return success;
  }

  Future<bool> deleteUser(String userId) async {
    final success = await ref.read(userRepositoryProvider).deleteUser(userId);
    if (success) {
      await refresh();
    }
    return success;
  }
}

// --- NODES STATE ---
final nodesProvider = AsyncNotifierProvider<NodesNotifier, List<NodeModel>>(() {
  return NodesNotifier();
});

class NodesNotifier extends AsyncNotifier<List<NodeModel>> {
  @override
  Future<List<NodeModel>> build() async {
    final repo = ref.watch(nodeRepositoryProvider);
    return repo.getNodes();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(nodeRepositoryProvider).getNodes());
  }

  Future<bool> registerNode({
    required String modelAlias,
    required String backendModel,
    required String apiBase,
    int rpm = 60,
    int? weight,
  }) async {
    final success = await ref.read(nodeRepositoryProvider).registerNode(
          modelAlias: modelAlias,
          backendModel: backendModel,
          apiBase: apiBase,
          rpm: rpm,
          weight: weight,
        );
    if (success) {
      await refresh();
    }
    return success;
  }

  Future<bool> deleteNode(String nodeId) async {
    final success = await ref.read(nodeRepositoryProvider).deleteNode(nodeId);
    if (success) {
      await refresh();
    }
    return success;
  }
}

// --- TELEMETRY SUMMARY PROVIDER ---
class TelemetrySummary {
  final double totalSpend;
  final double totalAllocatedBudget;
  final int totalUsers;
  final int totalKeys;
  final int activeNodes;

  const TelemetrySummary({
    this.totalSpend = 0.0,
    this.totalAllocatedBudget = 0.0,
    this.totalUsers = 0,
    this.totalKeys = 0,
    this.activeNodes = 0,
  });

  double get quotaUtilizationPercentage {
    if (totalAllocatedBudget <= 0) return 0.0;
    return ((totalSpend / totalAllocatedBudget) * 100).clamp(0.0, 100.0);
  }
}

final telemetrySummaryProvider = Provider<TelemetrySummary>((ref) {
  final tiersAsync = ref.watch(tiersProvider);
  final usersAsync = ref.watch(usersProvider);
  final nodesAsync = ref.watch(nodesProvider);

  double spend = 0.0;
  double budget = 0.0;
  int keys = 0;

  tiersAsync.whenData((tiers) {
    for (var t in tiers) {
      spend += t.spend;
      budget += t.maxBudget ?? 0.0;
      keys += t.activeKeysCount;
    }
  });

  int userCount = 0;
  usersAsync.whenData((users) {
    userCount = users.length;
  });

  int nodeCount = 0;
  nodesAsync.whenData((nodes) {
    nodeCount = nodes.length;
  });

  return TelemetrySummary(
    totalSpend: spend,
    totalAllocatedBudget: budget,
    totalUsers: userCount,
    totalKeys: keys,
    activeNodes: nodeCount,
  );
});
