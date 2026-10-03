import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/user_model.dart';
import '../domain/group_model.dart';
import '../../auth/presentation/login_dialog.dart';

class UsersView extends ConsumerStatefulWidget {
  const UsersView({super.key});

  @override
  ConsumerState<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends ConsumerState<UsersView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedTierFilter = 'all';
  String _selectedAccountTypeFilter = 'all'; // 'all', 'solo', 'group'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final groupsAsync = ref.watch(groupsProvider);
    final auth = ref.watch(authProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tenancy, Groups & User Directory',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage B2B corporate client groups with pooled quotas, onboard solo developers, and audit dual-level consumption.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(usersProvider.notifier).refresh();
                      ref.read(groupsProvider.notifier).refresh();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (!auth.isAuthenticated) {
                        LoginDialog.show(context);
                        return;
                      }
                      _showCreateGroupDialog(context);
                    },
                    icon: const Icon(Icons.corporate_fare, size: 18, color: AppTheme.secondary),
                    label: const Text('+ Create Client Group'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (!auth.isAuthenticated) {
                        LoginDialog.show(context);
                        return;
                      }
                      _showOnboardUserDialog(context);
                    },
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('+ Onboard User'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Segmented Tabs
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              labelColor: AppTheme.textPrimary,
              unselectedLabelColor: AppTheme.textMuted,
              tabs: const [
                Tab(icon: Icon(Icons.corporate_fare, size: 18), text: 'Client Groups (B2B)'),
                Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Solo Developers (B2C)'),
                Tab(icon: Icon(Icons.badge_outlined, size: 18), text: 'All Users Directory'),
                Tab(icon: Icon(Icons.receipt_long_outlined, size: 18), text: 'Billing & Rollup'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tab Content
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              switch (_tabController.index) {
                case 0:
                  return _buildGroupsTab(groupsAsync, usersAsync, auth);
                case 1:
                  return _buildSoloUsersTab(usersAsync, auth);
                case 2:
                  return _buildAllUsersTab(usersAsync, auth);
                case 3:
                  return _buildBillingRollupTab(groupsAsync, usersAsync);
                default:
                  return const SizedBox();
              }
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: CLIENT GROUPS (B2B)
  // ===========================================================================
  Widget _buildGroupsTab(
    AsyncValue<List<GroupModel>> groupsAsync,
    AsyncValue<List<UserModel>> usersAsync,
    AuthState auth,
  ) {
    return groupsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => _buildErrorCard('Error loading client groups: $err'),
      data: (groups) {
        if (groups.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.corporate_fare, size: 56, color: AppTheme.textMuted),
                    const SizedBox(height: 16),
                    const Text(
                      'No Client Groups Provisioned Yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Client groups allow you to sell to enterprise accounts with pooled monthly token budgets and multi-seat access.',
                      style: TextStyle(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (!auth.isAuthenticated) {
                          LoginDialog.show(context);
                          return;
                        }
                        _showCreateGroupDialog(context);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create First Client Group'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Summary KPI Row for Groups
        double totalPooledBudget = 0.0;
        double totalPooledSpend = 0.0;
        int totalMembers = 0;
        for (var g in groups) {
          totalPooledBudget += g.maxBudget ?? 0.0;
          totalPooledSpend += g.spend;
          totalMembers += g.members.length;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Row
            Row(
              children: [
                _buildKpiCard(
                  title: 'CORPORATE CLIENT GROUPS',
                  value: '${groups.length}',
                  subtitle: 'Active B2B accounts',
                  icon: Icons.business,
                  color: AppTheme.secondary,
                ),
                const SizedBox(width: 16),
                _buildKpiCard(
                  title: 'POOLED ALLOCATED BUDGET',
                  value: '${totalPooledBudget.toStringAsFixed(2)} €',
                  subtitle: 'Monthly subscription cap',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 16),
                _buildKpiCard(
                  title: 'CONSOLIDATED GROUP SPEND',
                  value: '${totalPooledSpend.toStringAsFixed(2)} €',
                  subtitle: totalPooledBudget > 0
                      ? '${((totalPooledSpend / totalPooledBudget) * 100).toStringAsFixed(1)}% quota consumed'
                      : 'No budget set',
                  icon: Icons.trending_up,
                  color: totalPooledSpend > totalPooledBudget * 0.9 ? AppTheme.error : AppTheme.success,
                ),
                const SizedBox(width: 16),
                _buildKpiCard(
                  title: 'ENROLLED SEATS',
                  value: '$totalMembers',
                  subtitle: 'Engineers across groups',
                  icon: Icons.people_outline,
                  color: AppTheme.accent,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Group Cards List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final group = groups[index];
                return _buildGroupCard(group, usersAsync, auth);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupCard(
    GroupModel group,
    AsyncValue<List<UserModel>> usersAsync,
    AuthState auth,
  ) {
    final progress = group.budgetProgressPercentage / 100.0;
    final maxBudget = group.maxBudget ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.business, color: AppTheme.secondary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              group.groupAlias,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            _buildTierBadge(group.tier),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.surfaceBorder),
                              ),
                              child: Text(
                                group.groupId,
                                style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppTheme.textMuted),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contact: ${group.clientEmail ?? "Not specified"} · Pooled Throughput: ${group.rpmLimit ?? 120} RPM / ${(group.tpmLimit ?? 60000) ~/ 1000}k TPM',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.person_add_outlined, size: 16),
                      label: const Text('Add Member'),
                      onPressed: () {
                        if (!auth.isAuthenticated) {
                          LoginDialog.show(context);
                          return;
                        }
                        _showAddMemberDialog(context, group, usersAsync);
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.vpn_key_outlined, size: 16, color: AppTheme.primary),
                      label: const Text('Issue Group Key'),
                      onPressed: () {
                        if (!auth.isAuthenticated) {
                          LoginDialog.show(context);
                          return;
                        }
                        _issueKeyForGroup(group);
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                      tooltip: 'Delete Client Group',
                      onPressed: () {
                        if (!auth.isAuthenticated) {
                          LoginDialog.show(context);
                          return;
                        }
                        _confirmDeleteGroup(group);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Consolidated Budget Progress Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'CONSOLIDATED GROUP BUDGET CONSUMPTION',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${group.budgetProgressPercentage.toStringAsFixed(1)}% used)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: progress > 0.9 ? AppTheme.error : AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${group.spend.toStringAsFixed(2)} € / ${maxBudget > 0 ? "${maxBudget.toStringAsFixed(2)} €" : "Unlimited"}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.background,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 0.9 ? AppTheme.error : AppTheme.secondary,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Enrolled Members Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enrolled Seats (${group.members.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Individual spends roll up into the consolidated monthly invoice above',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (group.members.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No users currently assigned to this group. Click "+ Add Member" or onboard a new user with this group.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              )
            else
              DataTable(
                horizontalMargin: 8,
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('MEMBER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('ROLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('INDIVIDUAL SPEND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
                rows: group.members.map((member) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              member.userAlias ?? member.userId,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              member.userEmail ?? member.userId,
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: member.role == 'admin'
                                ? AppTheme.accent.withValues(alpha: 0.2)
                                : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            member.role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: member.role == 'admin' ? AppTheme.accent : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${member.spend.toStringAsFixed(2)} €',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.vpn_key_outlined, size: 16, color: AppTheme.primary),
                              tooltip: 'Issue Key for this Member',
                              onPressed: () {
                                if (!auth.isAuthenticated) {
                                  LoginDialog.show(context);
                                  return;
                                }
                                _issueKeyForGroupMember(group, member);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.person_remove_outlined, size: 16, color: AppTheme.error),
                              tooltip: 'Remove Member from Group',
                              onPressed: () {
                                if (!auth.isAuthenticated) {
                                  LoginDialog.show(context);
                                  return;
                                }
                                _confirmRemoveMember(group, member);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: SOLO DEVELOPERS (B2C)
  // ===========================================================================
  Widget _buildSoloUsersTab(AsyncValue<List<UserModel>> usersAsync, AuthState auth) {
    return usersAsync.when(
      loading: () => const Center(
        child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()),
      ),
      error: (err, _) => _buildErrorCard('Error loading solo users: $err'),
      data: (users) {
        final soloUsers = users.where((u) => u.isSolo && u.userId != 'default_user_id').toList();

        if (soloUsers.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.person_outline, size: 56, color: AppTheme.textMuted),
                    const SizedBox(height: 16),
                    const Text('No Solo Developers Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Solo developers have personal subscription tiers without corporate group pooling.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: DataTable(
              horizontalMargin: 16,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('DEVELOPER IDENTIFIER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('SUBSCRIPTION TIER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('PERSONAL MONTHLY SPEND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ACTIVE KEYS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              ],
              rows: soloUsers.map((u) {
                final tier = u.primaryTier;
                final progress = u.budgetProgressPercentage / 100.0;
                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            u.userAlias ?? u.userId,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            u.userEmail ?? u.userId,
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    DataCell(_buildTierBadge(tier)),
                    DataCell(
                      SizedBox(
                        width: 180,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${u.spend.toStringAsFixed(2)} €',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(
                                  u.maxBudget != null ? '${u.maxBudget!.toStringAsFixed(2)} €' : 'Tier Def',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppTheme.surfaceElevated,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress > 0.9 ? AppTheme.error : AppTheme.primary,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              minHeight: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text('${u.keyCount} active', style: const TextStyle(fontSize: 12))),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.vpn_key_outlined, size: 18, color: AppTheme.primary),
                            tooltip: 'Issue Virtual Key',
                            onPressed: () {
                              if (!auth.isAuthenticated) {
                                LoginDialog.show(context);
                                return;
                              }
                              _issueKeyForUser(u);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                            tooltip: 'Delete User',
                            onPressed: () {
                              if (!auth.isAuthenticated) {
                                LoginDialog.show(context);
                                return;
                              }
                              _confirmDeleteUser(u);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // TAB 3: ALL USERS DIRECTORY
  // ===========================================================================
  Widget _buildAllUsersTab(AsyncValue<List<UserModel>> usersAsync, AuthState auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search & Filter Bar
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by User ID, Email, or Alias...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAccountTypeFilter,
                      dropdownColor: AppTheme.surfaceElevated,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Accounts')),
                        DropdownMenuItem(value: 'solo', child: Text('👤 Solo Developers')),
                        DropdownMenuItem(value: 'group', child: Text('🏢 Group Members')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedAccountTypeFilter = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTierFilter,
                      dropdownColor: AppTheme.surfaceElevated,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Tiers')),
                        DropdownMenuItem(value: 'tier-basic', child: Text('Basic Tier')),
                        DropdownMenuItem(value: 'tier-standard', child: Text('Standard Tier')),
                        DropdownMenuItem(value: 'tier-premium', child: Text('Premium Tier')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTierFilter = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // User Table
        usersAsync.when(
          loading: () => const Center(
            child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()),
          ),
          error: (err, _) => _buildErrorCard('Error loading users: $err'),
          data: (users) {
            final filtered = users.where((u) {
              if (u.userId == 'default_user_id') return false;
              final matchQuery = u.userId.toLowerCase().contains(_searchQuery) ||
                  (u.userEmail?.toLowerCase().contains(_searchQuery) ?? false) ||
                  (u.userAlias?.toLowerCase().contains(_searchQuery) ?? false);

              final matchTier =
                  _selectedTierFilter == 'all' || u.teams.contains(_selectedTierFilter);

              final matchAccountType = _selectedAccountTypeFilter == 'all' ||
                  (_selectedAccountTypeFilter == 'solo' && u.isSolo) ||
                  (_selectedAccountTypeFilter == 'group' && u.isGroupMember);

              return matchQuery && matchTier && matchAccountType;
            }).toList();

            if (filtered.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(Icons.people_outline, size: 48, color: AppTheme.textMuted),
                        SizedBox(height: 12),
                        Text('No users matching the current criteria.',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: DataTable(
                  horizontalMargin: 16,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('USER IDENTIFIER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ACCOUNT CLASSIFICATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ASSIGNED TIER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('MONTHLY SPEND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('KEYS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  ],
                  rows: filtered.map((u) {
                    final tier = u.primaryTier;
                    return DataRow(
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                u.userAlias ?? u.userId,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                u.userEmail ?? u.userId,
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          u.isGroupMember
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.corporate_fare, size: 14, color: AppTheme.secondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        u.assignedGroupId ?? 'Group Member',
                                        style: const TextStyle(
                                          color: AppTheme.secondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.surfaceBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
                                      SizedBox(width: 6),
                                      Text(
                                        'Solo Developer',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        DataCell(_buildTierBadge(tier)),
                        DataCell(
                          Text(
                            '${u.spend.toStringAsFixed(2)} €',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(Text('${u.keyCount} active', style: const TextStyle(fontSize: 12))),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.vpn_key_outlined, size: 18, color: AppTheme.primary),
                                tooltip: 'Issue Virtual Key',
                                onPressed: () {
                                  if (!auth.isAuthenticated) {
                                    LoginDialog.show(context);
                                    return;
                                  }
                                  _issueKeyForUser(u);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                                tooltip: 'Delete User',
                                onPressed: () {
                                  if (!auth.isAuthenticated) {
                                    LoginDialog.show(context);
                                    return;
                                  }
                                  _confirmDeleteUser(u);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 4: BILLING & CONSUMPTION ROLLUP
  // ===========================================================================
  Widget _buildBillingRollupTab(
    AsyncValue<List<GroupModel>> groupsAsync,
    AsyncValue<List<UserModel>> usersAsync,
  ) {
    final groups = groupsAsync.value ?? [];
    final users = (usersAsync.value ?? []).where((u) => u.userId != 'default_user_id').toList();

    double b2bSpend = 0.0;
    double b2bBudget = 0.0;
    for (var g in groups) {
      b2bSpend += g.spend;
      b2bBudget += g.maxBudget ?? 0.0;
    }

    final soloUsers = users.where((u) => u.isSolo).toList();
    double b2cSpend = 0.0;
    double b2cBudget = 0.0;
    for (var u in soloUsers) {
      b2cSpend += u.spend;
      b2cBudget += u.maxBudget ?? 0.0;
    }

    final totalPlatformSpend = b2bSpend + b2cSpend;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Financial Overview Cards
        Row(
          children: [
            _buildKpiCard(
              title: 'B2B CORPORATE INVOICED',
              value: '${b2bSpend.toStringAsFixed(2)} €',
              subtitle: 'Across ${groups.length} client groups (${b2bBudget.toStringAsFixed(0)} € cap)',
              icon: Icons.corporate_fare,
              color: AppTheme.secondary,
            ),
            const SizedBox(width: 16),
            _buildKpiCard(
              title: 'B2C SOLO INVOICED',
              value: '${b2cSpend.toStringAsFixed(2)} €',
              subtitle: 'Across ${soloUsers.length} developers (${b2cBudget.toStringAsFixed(0)} € cap)',
              icon: Icons.person_outline,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 16),
            _buildKpiCard(
              title: 'TOTAL PLATFORM REVENUE / SPEND',
              value: '${totalPlatformSpend.toStringAsFixed(2)} €',
              subtitle: 'Consolidated billing volume',
              icon: Icons.receipt_long,
              color: AppTheme.accent,
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Section A: B2B Group Accounts Table
        Text(
          'B2B Corporate Client Accounts Invoicing Breakdown',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Consolidated monthly charges billed to the parent organization entity based on pooled token consumption.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: DataTable(
              horizontalMargin: 16,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('CLIENT ORGANIZATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('TIER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('SEATS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('CONSUMED / CAP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('UTILIZATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              ],
              rows: groups.map((g) {
                final pct = g.budgetProgressPercentage;
                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(g.groupAlias, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(g.groupId, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    DataCell(_buildTierBadge(g.tier)),
                    DataCell(Text('${g.members.length} members', style: const TextStyle(fontSize: 12))),
                    DataCell(Text('${g.spend.toStringAsFixed(2)} € / ${(g.maxBudget ?? 0).toStringAsFixed(2)} €',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11)),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: pct / 100.0,
                              backgroundColor: AppTheme.surfaceElevated,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                pct > 90 ? AppTheme.error : AppTheme.secondary,
                              ),
                              minHeight: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: pct > 90
                              ? AppTheme.error.withValues(alpha: 0.15)
                              : AppTheme.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          pct > 90 ? 'CAP REACHED' : 'HEALTHY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: pct > 90 ? AppTheme.error : AppTheme.success,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Section B: B2C Solo Developers Table
        Text(
          'B2C Solo Developers Invoicing Breakdown',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          'Individual monthly subscriptions billed directly per developer seat.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: DataTable(
              horizontalMargin: 16,
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('DEVELOPER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('TIER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('CONSUMED / CAP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('UTILIZATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              ],
              rows: soloUsers.map((u) {
                final pct = u.budgetProgressPercentage;
                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(u.userAlias ?? u.userId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(u.userEmail ?? u.userId, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    DataCell(_buildTierBadge(u.primaryTier)),
                    DataCell(Text('${u.spend.toStringAsFixed(2)} € / ${(u.maxBudget ?? 0).toStringAsFixed(2)} €',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11)),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: pct / 100.0,
                              backgroundColor: AppTheme.surfaceElevated,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                pct > 90 ? AppTheme.error : AppTheme.primary,
                              ),
                              minHeight: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: pct > 90
                              ? AppTheme.error.withValues(alpha: 0.15)
                              : AppTheme.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          pct > 90 ? 'CAP REACHED' : 'HEALTHY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: pct > 90 ? AppTheme.error : AppTheme.success,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // HELPER WIDGETS
  // ===========================================================================
  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                  ),
                  Icon(icon, size: 20, color: color),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierBadge(String tier) {
    Color color = AppTheme.secondary;
    if (tier.contains('premium')) color = AppTheme.accent;
    if (tier.contains('standard')) color = AppTheme.primary;
    if (tier.contains('basic')) color = AppTheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        tier,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Text(error, style: const TextStyle(color: AppTheme.error)),
    );
  }

  // ===========================================================================
  // ACTION HANDLERS & MODALS
  // ===========================================================================
  void _showCreateGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _CreateGroupDialog(),
    );
  }

  void _showOnboardUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _OnboardUserDialog(),
    );
  }

  void _showAddMemberDialog(BuildContext context, GroupModel group, AsyncValue<List<UserModel>> usersAsync) {
    showDialog(
      context: context,
      builder: (_) => _AddMemberToGroupDialog(group: group, users: usersAsync.value ?? []),
    );
  }

  Future<void> _issueKeyForUser(UserModel user) async {
    try {
      final res = await ref.read(userRepositoryProvider).generateKeyForUser(
            userId: user.userId,
            tier: user.assignedGroupId ?? user.primaryTier,
          );
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => _KeyIssuedDialog(keyResult: res),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _issueKeyForGroup(GroupModel group) async {
    try {
      final res = await ref.read(userRepositoryProvider).generateKeyForUser(
            userId: '${group.groupId}_lead',
            tier: group.groupId,
            keyAlias: '${group.groupAlias} Master Key',
          );
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => _KeyIssuedDialog(keyResult: res),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _issueKeyForGroupMember(GroupModel group, GroupMember member) async {
    try {
      final res = await ref.read(userRepositoryProvider).generateKeyForUser(
            userId: member.userId,
            tier: group.groupId,
            keyAlias: '${member.userAlias ?? member.userId} (${group.groupAlias})',
          );
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => _KeyIssuedDialog(keyResult: res),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _confirmDeleteGroup(GroupModel group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Client Group'),
        content: Text(
          'Are you sure you want to delete corporate group "${group.groupAlias}" (${group.groupId})? '
          'This will disconnect all ${group.members.length} enrolled members and invalidate group pooled keys.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete Group'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(groupsProvider.notifier).deleteGroup(group.groupId);
    }
  }

  Future<void> _confirmRemoveMember(GroupModel group, GroupMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Remove Group Member'),
        content: Text('Remove "${member.userId}" from "${group.groupAlias}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(groupsProvider.notifier).removeMember(
            groupId: group.groupId,
            userId: member.userId,
          );
    }
  }

  Future<void> _confirmDeleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete user "${user.userId}"? This will invalidate all their virtual keys.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(usersProvider.notifier).deleteUser(user.userId);
    }
  }
}

// =============================================================================
// DIALOG: CREATE CLIENT GROUP (B2B)
// =============================================================================
class _CreateGroupDialog extends ConsumerStatefulWidget {
  const _CreateGroupDialog();

  @override
  ConsumerState<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<_CreateGroupDialog> {
  final _idController = TextEditingController();
  final _aliasController = TextEditingController();
  final _budgetController = TextEditingController(text: '500.00');
  final _emailController = TextEditingController();
  String _selectedTier = 'tier-standard';
  bool _isCreating = false;

  @override
  void dispose() {
    _idController.dispose();
    _aliasController.dispose();
    _budgetController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final rawId = _idController.text.trim();
    final alias = _aliasController.text.trim();
    if (rawId.isEmpty || alias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both Group ID and Company Name'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final budget = double.tryParse(_budgetController.text.trim()) ?? 500.0;

    setState(() => _isCreating = true);
    final success = await ref.read(groupsProvider.notifier).createGroup(
          groupId: rawId,
          groupAlias: alias,
          tier: _selectedTier,
          maxBudget: budget,
          contactEmail: _emailController.text.trim(),
        );

    if (mounted) {
      setState(() => _isCreating = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Client Group "$alias" created successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.surfaceBorder),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.corporate_fare, color: AppTheme.secondary, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create Client Group (B2B)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Provision a corporate client with pooled monthly token quota', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Group Slug / Identifier *',
                hintText: 'e.g. acme-corp (auto-prefixed with group-)',
                prefixIcon: Icon(Icons.tag, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _aliasController,
              decoration: const InputDecoration(
                labelText: 'Client Company / Organization Name *',
                hintText: 'e.g. Acme Corporation Enterprise',
                prefixIcon: Icon(Icons.business, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Corporate Billing Contact Email',
                hintText: 'e.g. billing@acme.com',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedTier,
                    decoration: const InputDecoration(
                      labelText: 'Base Tier (Model Whitelist)',
                      prefixIcon: Icon(Icons.layers_outlined, size: 20),
                    ),
                    dropdownColor: AppTheme.surfaceElevated,
                    items: const [
                      DropdownMenuItem(value: 'tier-basic', child: Text('Basic (7B)')),
                      DropdownMenuItem(value: 'tier-standard', child: Text('Standard (7B + 32B)')),
                      DropdownMenuItem(value: 'tier-premium', child: Text('Premium (+ R1 Reasoning)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTier = val);
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pooled Budget Cap (€)',
                      hintText: 'e.g. 500.00',
                      prefixIcon: Icon(Icons.euro, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isCreating ? null : _submit,
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create Group'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DIALOG: ONBOARD USER (Solo or Group Member)
// =============================================================================
class _OnboardUserDialog extends ConsumerStatefulWidget {
  const _OnboardUserDialog();

  @override
  ConsumerState<_OnboardUserDialog> createState() => _OnboardUserDialogState();
}

class _OnboardUserDialogState extends ConsumerState<_OnboardUserDialog> {
  final _userIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _aliasController = TextEditingController();
  final _budgetController = TextEditingController();

  bool _isGroupMember = false;
  String? _selectedGroupId;
  String _selectedTier = 'tier-standard';
  bool _isCreating = false;

  @override
  void dispose() {
    _userIdController.dispose();
    _emailController.dispose();
    _aliasController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a User ID'), backgroundColor: AppTheme.error),
      );
      return;
    }

    if (_isGroupMember && (_selectedGroupId == null || _selectedGroupId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an existing Client Group'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isCreating = true);
    final budgetVal = double.tryParse(_budgetController.text.trim());

    final success = await ref.read(usersProvider.notifier).createUser(
          userId: userId,
          email: _emailController.text.trim(),
          alias: _aliasController.text.trim(),
          tier: _selectedTier,
          groupId: _isGroupMember ? _selectedGroupId : null,
          isGroupAccount: _isGroupMember,
          maxBudget: budgetVal,
        );

    if (mounted) {
      setState(() => _isCreating = false);
      if (success) {
        Navigator.of(context).pop();
        // Automatically issue initial key
        final keyRes = await ref.read(userRepositoryProvider).generateKeyForUser(
              userId: userId,
              tier: _isGroupMember ? _selectedGroupId! : _selectedTier,
            );
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => _KeyIssuedDialog(keyResult: keyRes),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);
    final availableGroups = groupsAsync.value ?? [];

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.surfaceBorder),
      ),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Onboard Engineering User',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text('Register an engineer as a Solo Developer or assign to a Client Group',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 18),

            // Account Classification Selector
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isGroupMember = false),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: !_isGroupMember
                            ? AppTheme.primary.withValues(alpha: 0.15)
                            : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !_isGroupMember ? AppTheme.primary : AppTheme.surfaceBorder,
                          width: !_isGroupMember ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 18, color: !_isGroupMember ? AppTheme.primary : AppTheme.textMuted),
                          const SizedBox(width: 8),
                          const Text('Solo Developer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isGroupMember = true;
                        if (_selectedGroupId == null && availableGroups.isNotEmpty) {
                          _selectedGroupId = availableGroups.first.groupId;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: _isGroupMember
                            ? AppTheme.secondary.withValues(alpha: 0.15)
                            : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isGroupMember ? AppTheme.secondary : AppTheme.surfaceBorder,
                          width: _isGroupMember ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.corporate_fare,
                              size: 18, color: _isGroupMember ? AppTheme.secondary : AppTheme.textMuted),
                          const SizedBox(width: 8),
                          const Text('Group Member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'User Identifier * (e.g. sarah_chen)',
                prefixIcon: Icon(Icons.badge_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Work Email (e.g. sarah@company.com)',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _aliasController,
              decoration: const InputDecoration(
                labelText: 'Full Name / Department (e.g. Sarah Chen - Platform Lead)',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
            ),
            const SizedBox(height: 14),

            if (_isGroupMember) ...[
              if (availableGroups.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'No client groups exist yet. Create a client group first or register as a solo developer.',
                    style: TextStyle(color: AppTheme.warning, fontSize: 12),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedGroupId ?? (availableGroups.isNotEmpty ? availableGroups.first.groupId : null),
                  decoration: const InputDecoration(
                    labelText: 'Assign to Client Group',
                    prefixIcon: Icon(Icons.corporate_fare, size: 20),
                  ),
                  dropdownColor: AppTheme.surfaceElevated,
                  items: availableGroups.map((g) {
                    return DropdownMenuItem(
                      value: g.groupId,
                      child: Text('${g.groupAlias} (${g.tier})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedGroupId = val);
                  },
                ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedTier,
                      decoration: const InputDecoration(
                        labelText: 'Subscription Tier',
                        prefixIcon: Icon(Icons.layers_outlined, size: 20),
                      ),
                      dropdownColor: AppTheme.surfaceElevated,
                      items: const [
                        DropdownMenuItem(value: 'tier-basic', child: Text('Basic Tier (15 €)')),
                        DropdownMenuItem(value: 'tier-standard', child: Text('Standard Tier (50 €)')),
                        DropdownMenuItem(value: 'tier-premium', child: Text('Premium Tier (100 €)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTier = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Individual Cap (€)',
                        hintText: 'Default: Tier cap',
                        prefixIcon: Icon(Icons.euro_outlined, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isCreating ? null : _submit,
                  child: _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create & Generate Key'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DIALOG: ADD MEMBER TO EXISTING GROUP
// =============================================================================
class _AddMemberToGroupDialog extends ConsumerStatefulWidget {
  final GroupModel group;
  final List<UserModel> users;

  const _AddMemberToGroupDialog({required this.group, required this.users});

  @override
  ConsumerState<_AddMemberToGroupDialog> createState() => _AddMemberToGroupDialogState();
}

class _AddMemberToGroupDialogState extends ConsumerState<_AddMemberToGroupDialog> {
  String? _selectedUserId;
  String _selectedRole = 'user';
  final _budgetController = TextEditingController();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    final available = _getAvailableUsers();
    if (available.isNotEmpty) {
      _selectedUserId = available.first.userId;
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  List<UserModel> _getAvailableUsers() {
    final enrolledIds = widget.group.members.map((m) => m.userId).toSet();
    return widget.users
        .where((u) => u.userId != 'default_user_id' && !enrolledIds.contains(u.userId))
        .toList();
  }

  Future<void> _submit() async {
    if (_selectedUserId == null) return;

    setState(() => _isAdding = true);
    final maxB = double.tryParse(_budgetController.text.trim());

    final success = await ref.read(groupsProvider.notifier).addMember(
          groupId: widget.group.groupId,
          userId: _selectedUserId!,
          role: _selectedRole,
          maxBudget: maxB,
        );

    if (mounted) {
      setState(() => _isAdding = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User "$_selectedUserId" added to group!'), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableUsers = _getAvailableUsers();

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.surfaceBorder),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enroll Member into ${widget.group.groupAlias}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Enrolled members share the pooled monthly budget of ${widget.group.maxBudget?.toStringAsFixed(2) ?? "unlimited"} €.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),

            if (availableUsers.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('All existing registered users are already members of this group.'),
              )
            else ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedUserId,
                decoration: const InputDecoration(
                  labelText: 'Select Registered User',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
                dropdownColor: AppTheme.surfaceElevated,
                items: availableUsers.map((u) {
                  return DropdownMenuItem(
                    value: u.userId,
                    child: Text('${u.userAlias ?? u.userId} (${u.userId})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedUserId = val);
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Group Role',
                        prefixIcon: Icon(Icons.shield_outlined, size: 20),
                      ),
                      dropdownColor: AppTheme.surfaceElevated,
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('Member (User)')),
                        DropdownMenuItem(value: 'admin', child: Text('Group Admin')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sub-Cap (€, optional)',
                        hintText: 'Inherit pooled',
                        prefixIcon: Icon(Icons.euro, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isAdding || availableUsers.isEmpty ? null : _submit,
                  child: _isAdding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Enroll Member'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DIALOG: KEY ISSUED (Continue config)
// =============================================================================
class _KeyIssuedDialog extends StatelessWidget {
  final GeneratedApiKeyResult keyResult;

  const _KeyIssuedDialog({required this.keyResult});

  @override
  Widget build(BuildContext context) {
    final continueJson = '''{
  "models": [
    {
      "title": "Sarrera (${keyResult.teamId})",
      "provider": "openai",
      "model": "basic-coder",
      "apiKey": "${keyResult.key}",
      "apiBase": "https://localhost/v1"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Sarrera Autocomplete",
    "provider": "openai",
    "model": "basic-coder",
    "apiKey": "${keyResult.key}",
    "apiBase": "https://localhost/v1"
  }
}''';

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.surfaceBorder),
      ),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Virtual API Key Ready',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('User: ${keyResult.userId} · Entity: ${keyResult.teamId}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Generated Virtual Key (Copy now, it won\'t be shown again):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      keyResult.key,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: keyResult.key));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Key copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('VS Code Continue Configuration (~/.continue/config.json):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              height: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF030712),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: SingleChildScrollView(
                child: Text(
                  continueJson,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy JSON Config'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: continueJson));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Continue config copied to clipboard!')),
                    );
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
