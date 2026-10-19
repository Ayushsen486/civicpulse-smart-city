import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:civicpulse_app/core/theme/app_colors.dart';
import 'package:civicpulse_app/core/theme/theme_provider.dart';
import 'package:civicpulse_app/features/auth/application/auth_controller.dart';
import 'package:civicpulse_app/features/issue/application/issue_controller.dart';
import 'package:civicpulse_app/features/issue/presentation/screens/feed_screen.dart';
import 'package:civicpulse_app/features/issue/presentation/screens/my_issues_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const [
    FeedScreen(),
    MyIssuesScreen(),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        floatingActionButton: _currentIndex == 0 || _currentIndex == 1
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/report'),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Report Issue'),
                tooltip: 'Report a new civic issue with photo and GPS location',
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Explore',
              tooltip: 'Browse public civic feed',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'My Reports',
              tooltip: 'View your submitted issues',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
              tooltip: 'User profile and settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  void _showThemeModeDialog(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Theme Mode',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Auto-Sync', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.brightness_auto, color: AppColors.primary),
                  title: const Text('Auto (System Default)'),
                  subtitle: const Text('Matches device system light / dark setting'),
                  trailing: currentMode == ThemeMode.system
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.light_mode, color: Colors.amber),
                  title: const Text('Light Mode'),
                  subtitle: const Text('Clean white background with refined accent highlights'),
                  trailing: currentMode == ThemeMode.light
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode, color: Colors.indigo),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Modern dark aesthetics easy on the eyes in low light'),
                  trailing: currentMode == ThemeMode.dark
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of CivicPulse?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.priorityCritical,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Citizen Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: user == null
          ? Center(
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
                      child: const Icon(Icons.account_circle_outlined, size: 64, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text('Welcome to CivicPulse', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to report issues, track resolutions, and participate in civic decisions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/login'),
                      icon: const Icon(Icons.login),
                      label: const Text('Sign In or Register'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Identity Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                            backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                                ? Text(
                                    user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    user.role.replaceAll('ROLE_', ''),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Statistics Cards
                  Consumer(
                    builder: (context, ref, _) {
                      final myIssuesAsync = ref.watch(myIssuesProvider(user.id));
                      return myIssuesAsync.maybeWhen(
                        data: (issues) {
                          final total = issues.length;
                          final resolved = issues.where((i) => i.status == 'RESOLVED' || i.status == 'CLOSED').length;
                          final inProgress = issues.where((i) => i.status == 'IN_PROGRESS' || i.status == 'ASSIGNED').length;

                          return Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Total Reports',
                                  value: '$total',
                                  icon: Icons.assignment_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatCard(
                                  title: 'In Progress',
                                  value: '$inProgress',
                                  icon: Icons.pending_actions,
                                  color: AppColors.statusInProgress,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatCard(
                                  title: 'Resolved',
                                  value: '$resolved',
                                  icon: Icons.check_circle_outline,
                                  color: AppColors.statusResolved,
                                ),
                              ),
                            ],
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // App Settings & Preferences
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            ref.watch(themeModeProvider) == ThemeMode.dark
                                ? Icons.dark_mode
                                : ref.watch(themeModeProvider) == ThemeMode.light
                                    ? Icons.light_mode
                                    : Icons.brightness_auto,
                            color: AppColors.primary,
                          ),
                          title: const Text('Theme Mode / थीम मोड'),
                          subtitle: Text(
                            ref.watch(themeModeProvider) == ThemeMode.dark
                                ? 'Dark Mode (Active)'
                                : ref.watch(themeModeProvider) == ThemeMode.light
                                    ? 'Light Mode (Active)'
                                    : 'Auto / System (Active)',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showThemeModeDialog(context, ref, ref.read(themeModeProvider)),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.language, color: AppColors.primary),
                          title: const Text('Language / भाषा'),
                          subtitle: const Text('English & हिंदी supported'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Language automatically reflects device settings (EN / HI).'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                          title: const Text('Push Notifications'),
                          subtitle: const Text('Updates on assigned and resolved issues'),
                          trailing: const Icon(Icons.check_circle, color: AppColors.statusResolved, size: 20),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.security, color: AppColors.primary),
                          title: const Text('Security & Privacy'),
                          subtitle: const Text('JWT 15m/7d encrypted token storage'),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.info_outline, color: AppColors.primary),
                          title: const Text('CivicPulse Version'),
                          subtitle: const Text('v1.0.0 (Production Release Build)'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.priorityCritical,
                      side: const BorderSide(color: AppColors.priorityCritical),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _showLogoutDialog(context, ref),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }
}
