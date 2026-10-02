import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../../features/tiers/domain/tier_model.dart';
import '../../features/tiers/data/tier_repository.dart';
import '../../features/users/domain/user_model.dart';
import '../../features/users/data/user_repository.dart';
import '../../features/nodes/domain/node_model.dart';
import '../../features/nodes/data/node_repository.dart';

// --- AUTH STATE ---
class AuthState {
  final bool isAuthenticated;
  final String? token;
  final String? username;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.token,
    this.username,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? token,
    String? username,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      username: username ?? this.username,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final ApiClient _client = ApiClient();

  @override
  AuthState build() {
    return AuthState(
      isAuthenticated: ApiClient().isAuthenticated,
      token: ApiClient().adminToken,
      username: ApiClient().isAuthenticated ? 'Admin' : null,
    );
  }

  Future<bool> login(String username, String password) async {
    // In Sarrera, LiteLLM verifies the Master API Key via Bearer token
    final token = password.trim();
    _client.setToken(token);

    try {
      // Test key by requesting tier list
      await TierRepository().getTiers();
      state = state.copyWith(
        isAuthenticated: true,
        token: token,
        username: username.isEmpty ? 'Admin' : username,
        error: null,
      );
      return true;
    } catch (e) {
      _client.clearToken();
      state = state.copyWith(
        isAuthenticated: false,
        token: null,
        username: null,
        error: 'Invalid credentials or connection error: $e',
      );
      return false;
    }
    return false;
  }

  void logout() {
    _client.clearToken();
    state = const AuthState(isAuthenticated: false);
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
