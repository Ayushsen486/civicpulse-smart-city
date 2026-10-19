import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:civicpulse_app/core/theme/app_colors.dart';
import 'package:civicpulse_app/features/auth/application/auth_controller.dart';
import 'package:civicpulse_app/features/issue/application/issue_controller.dart';
import 'package:civicpulse_app/features/issue/domain/issue_model.dart';

class MyIssuesScreen extends ConsumerStatefulWidget {
  const MyIssuesScreen({super.key});

  @override
  ConsumerState<MyIssuesScreen> createState() => _MyIssuesScreenState();
}

class _MyIssuesScreenState extends ConsumerState<MyIssuesScreen> {
  String _selectedTab = 'ALL';
  String _officerViewMode = 'ASSIGNED';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Reports', style: TextStyle(fontWeight: FontWeight.bold))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment_ind_outlined, size: 56, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text('Track Your Reports', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to monitor status updates, officer assignments, and resolution progress on your submitted complaints.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In to View Reports'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isOfficer = user.role.contains('OFFICER') || user.role.contains('ADMIN');
    final myIssuesAsync = (isOfficer && _officerViewMode == 'ASSIGNED')
        ? ref.watch(officerAssignedIssuesProvider(user.id))
        : ref.watch(myIssuesProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isOfficer && _officerViewMode == 'ASSIGNED' ? 'Assigned Complaints' : 'My Reports',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Officer Mode Segmented Switcher (if user is an Officer or Admin)
          if (isOfficer)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'ASSIGNED',
                      icon: Icon(Icons.assignment_ind),
                      label: Text('Assigned to Me'),
                    ),
                    ButtonSegment(
                      value: 'REPORTED',
                      icon: Icon(Icons.edit_note),
                      label: Text('Reported by Me'),
                    ),
                  ],
                  selected: {_officerViewMode},
                  onSelectionChanged: (val) {
                    setState(() => _officerViewMode = val.first);
                  },
                ),
              ),
            ),

          // Filter Tabs Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'ALL'),
                const SizedBox(width: 8),
                _buildFilterChip('In Progress', 'ACTIVE'),
                const SizedBox(width: 8),
                _buildFilterChip('Resolved', 'RESOLVED'),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => (isOfficer && _officerViewMode == 'ASSIGNED')
                  ? ref.refresh(officerAssignedIssuesProvider(user.id).future)
                  : ref.refresh(myIssuesProvider(user.id).future),
              child: myIssuesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.priorityCritical),
                        const SizedBox(height: 12),
                        Text('Error loading reports: $err', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (isOfficer && _officerViewMode == 'ASSIGNED') {
                              ref.invalidate(officerAssignedIssuesProvider(user.id));
                            } else {
                              ref.invalidate(myIssuesProvider(user.id));
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (issues) {
                  // Filter according to selected tab
                  var filtered = issues;
                  if (_selectedTab == 'ACTIVE') {
                    filtered = issues.where((i) => i.status != 'RESOLVED' && i.status != 'CLOSED').toList();
                  } else if (_selectedTab == 'RESOLVED') {
                    filtered = issues.where((i) => i.status == 'RESOLVED' || i.status == 'CLOSED').toList();
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.assignment_outlined, size: 54, color: AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedTab == 'ACTIVE'
                                  ? 'No active issues in progress'
                                  : _selectedTab == 'RESOLVED'
                                      ? 'No resolved issues yet'
                                      : 'You have not reported any issues yet',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'When you report a municipal problem, track its resolution journey right here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/report'),
                              icon: const Icon(Icons.add_a_photo_outlined),
                              label: const Text('Report an Issue'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final issue = filtered[index];
                      return _MyIssueCard(
                        issue: issue,
                        onTap: () => context.push('/issues/${issue.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedTab == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedTab = value);
      },
    );
  }
}

class _MyIssueCard extends StatelessWidget {
  final IssueModel issue;
  final VoidCallback onTap;

  const _MyIssueCard({
    required this.issue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getStatusColor(issue.status);
    final priorityColor = AppColors.getPriorityColor(issue.priority);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      issue.status.replaceAll('_', ' '),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      issue.priority,
                      style: TextStyle(color: priorityColor, fontWeight: FontWeight.w600, fontSize: 11),
                    ),
                  ),
                  const Spacer(),
                  if (issue.issueReference != null)
                    Text(
                      issue.issueReference!,
                      style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                issue.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.category_outlined, size: 14, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 4),
                  Text(
                    issue.categoryName,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const Spacer(),
                  Text(
                    '${issue.createdAt.day}/${issue.createdAt.month}/${issue.createdAt.year}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondaryLight),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
