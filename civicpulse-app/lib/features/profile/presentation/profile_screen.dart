import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:civicpulse_app/core/theme/app_colors.dart';
import 'package:civicpulse_app/core/theme/locale_provider.dart';
import 'package:civicpulse_app/core/theme/theme_provider.dart';
import 'package:civicpulse_app/features/auth/application/auth_controller.dart';
import 'package:civicpulse_app/features/auth/domain/user_model.dart';
import 'package:civicpulse_app/features/issue/application/issue_controller.dart';
import 'package:civicpulse_app/features/issue/domain/issue_model.dart';
import 'package:civicpulse_app/l10n/app_localizations.dart';

/// Premium, production-grade Profile screen with full civic-tech design
/// language. Connects to real Riverpod providers for user data and statistics.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (user == null) {
      return _UnauthenticatedView(l10n: l10n, theme: theme, isDark: isDark);
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium profile header
          _ProfileSliverAppBar(user: user, isDark: isDark, l10n: l10n),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Activity Dashboard ──
                _SectionHeader(
                  title: l10n.myActivity,
                  icon: Icons.insights_outlined,
                ),
                const SizedBox(height: 12),
                _ActivityDashboard(userId: user.id, l10n: l10n),
                const SizedBox(height: 24),

                // ── Quick Actions ──
                _SectionHeader(
                  title: l10n.myComplaintsShortcut,
                  icon: Icons.assignment_outlined,
                ),
                const SizedBox(height: 12),
                _ComplaintShortcutCard(userId: user.id, l10n: l10n),
                const SizedBox(height: 24),

                // ── Appearance ──
                _SectionHeader(
                  title: l10n.appearance,
                  icon: Icons.palette_outlined,
                ),
                const SizedBox(height: 12),
                _AppearanceSection(l10n: l10n, isDark: isDark),
                const SizedBox(height: 24),

                // ── Account ──
                _SectionHeader(
                  title: l10n.account,
                  icon: Icons.manage_accounts_outlined,
                ),
                const SizedBox(height: 12),
                _AccountSection(l10n: l10n, user: user),
                const SizedBox(height: 24),

                // ── Support ──
                _SectionHeader(
                  title: l10n.support,
                  icon: Icons.support_agent_outlined,
                ),
                const SizedBox(height: 12),
                _SupportSection(l10n: l10n),
                const SizedBox(height: 24),

                // ── General ──
                _SectionHeader(title: l10n.general, icon: Icons.info_outline),
                const SizedBox(height: 12),
                _GeneralSection(l10n: l10n),
                const SizedBox(height: 32),

                // ── Sign Out ──
                _SignOutButton(l10n: l10n),
                const SizedBox(height: 16),

                // ── Delete Account ──
                _DeleteAccountButton(l10n: l10n),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// UNAUTHENTICATED VIEW
// ═══════════════════════════════════════════════════════════════════════════════

class _UnauthenticatedView extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final bool isDark;

  const _UnauthenticatedView({
    required this.l10n,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.2 : 0.08,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_circle_outlined,
                  size: 72,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.welcomeToCivicPulse,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.signInPrompt,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(l10n.signInOrRegister),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SLIVER APP BAR — PROFILE HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _ProfileSliverAppBar extends StatelessWidget {
  final UserModel user;
  final bool isDark;
  final AppLocalizations l10n;

  const _ProfileSliverAppBar({
    required this.user,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isOfficer = user.role.toUpperCase().contains('OFFICER');
    final roleBadge = isOfficer ? l10n.officerProfile : l10n.citizenProfile;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      title: Text(
        l10n.profile,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.primary.withValues(alpha: 0.25),
                      AppColors.surfaceDark,
                    ]
                  : [
                      AppColors.primary.withValues(alpha: 0.06),
                      AppColors.surfaceLight,
                    ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              child: Row(
                children: [
                  // Avatar
                  Hero(
                    tag: 'profile_avatar',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: isDark
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : AppColors.primary.withValues(alpha: 0.12),
                        backgroundImage:
                            user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child:
                            (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                            ? Text(
                                user.firstName.isNotEmpty
                                    ? user.firstName[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.primaryLight
                                      : AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Name + Email + Role badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.fullName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.phone != null && user.phone!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            user.phone!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Role badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isOfficer
                                            ? AppColors.secondary
                                            : AppColors.primary)
                                        .withValues(alpha: isDark ? 0.25 : 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                roleBadge,
                                style: TextStyle(
                                  color: isOfficer
                                      ? AppColors.secondary
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Verified badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.statusResolved.withValues(
                                  alpha: isDark ? 0.25 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    size: 12,
                                    color: AppColors.statusResolved,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.verified,
                                    style: const TextStyle(
                                      color: AppColors.statusResolved,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.primaryLight : AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ACTIVITY DASHBOARD — REAL DATA FROM RIVERPOD
// ═══════════════════════════════════════════════════════════════════════════════

class _ActivityDashboard extends ConsumerWidget {
  final String userId;
  final AppLocalizations l10n;

  const _ActivityDashboard({required this.userId, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myIssuesAsync = ref.watch(myIssuesProvider(userId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return myIssuesAsync.when(
      loading: () => _buildShimmerRow(isDark),
      error: (_, _) => _buildStatRow(isDark, 0, 0, 0, 0, 0),
      data: (issues) {
        final total = issues.length;
        final pending = issues
            .where((i) => i.status == 'REPORTED' || i.status == 'ACKNOWLEDGED')
            .length;
        final inProg = issues
            .where((i) => i.status == 'IN_PROGRESS' || i.status == 'ASSIGNED')
            .length;
        final resolved = issues
            .where((i) => i.status == 'RESOLVED' || i.status == 'CLOSED')
            .length;
        final rejected = issues.where((i) => i.status == 'REOPENED').length;
        return _buildStatRow(
          isDark,
          total,
          pending,
          inProg,
          resolved,
          rejected,
        );
      },
    );
  }

  Widget _buildShimmerRow(bool isDark) {
    return SizedBox(
      height: 90,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(
    bool isDark,
    int total,
    int pending,
    int inProg,
    int resolved,
    int rejected,
  ) {
    final items = [
      _StatData(
        l10n.totalComplaints,
        total,
        isDark ? AppColors.primaryLight : AppColors.primary,
        Icons.assignment_outlined,
      ),
      _StatData(
        l10n.pending,
        pending,
        AppColors.statusAssigned,
        Icons.schedule_outlined,
      ),
      _StatData(
        l10n.inProgress,
        inProg,
        AppColors.statusInProgress,
        Icons.pending_actions_outlined,
      ),
      _StatData(
        l10n.resolved,
        resolved,
        AppColors.statusResolved,
        Icons.check_circle_outline,
      ),
      _StatData(
        l10n.rejected,
        rejected,
        AppColors.statusReopened,
        Icons.cancel_outlined,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _MiniStatCard(data: item, isDark: isDark),
          );
        }).toList(),
      ),
    );
  }
}

class _StatData {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _StatData(this.label, this.value, this.color, this.icon);
}

class _MiniStatCard extends StatelessWidget {
  final _StatData data;
  final bool isDark;

  const _MiniStatCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, color: data.color, size: 20),
          const SizedBox(height: 6),
          Text(
            '${data.value}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: data.color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMPLAINT SHORTCUT CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _ComplaintShortcutCard extends ConsumerWidget {
  final String userId;
  final AppLocalizations l10n;

  const _ComplaintShortcutCard({required this.userId, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myIssuesAsync = ref.watch(myIssuesProvider(userId));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.assignment_outlined,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
            title: Text(
              l10n.myComplaintsShortcut,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.myComplaintsSubtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            onTap: () {
              // Navigate to My Reports tab (index 2 in home screen)
              // Using GoRouter to push to home and switch to tab 2
              final homeState = context.findAncestorStateOfType<State>();
              if (homeState != null) {
                // fallback: just show snackbar
              }
            },
          ),
          myIssuesAsync.maybeWhen(
            data: (issues) {
              if (issues.isEmpty) return const SizedBox.shrink();
              // Show last 3 issues as preview
              final preview = issues.take(3).toList();
              return Column(
                children: [
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  ...preview.map(
                    (issue) => _MiniIssueRow(issue: issue, isDark: isDark),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _MiniIssueRow extends StatelessWidget {
  final IssueModel issue;
  final bool isDark;

  const _MiniIssueRow({required this.issue, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getStatusColor(issue.status);
    return InkWell(
      onTap: () => context.push('/issues/${issue.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                issue.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                issue.status.replaceAll('_', ' '),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// APPEARANCE SECTION — Theme + Language
// ═══════════════════════════════════════════════════════════════════════════════

class _AppearanceSection extends ConsumerWidget {
  final AppLocalizations l10n;
  final bool isDark;

  const _AppearanceSection({required this.l10n, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);

    return _SettingsCard(
      isDark: isDark,
      children: [
        // Theme mode
        _SettingsTile(
          icon: currentTheme == ThemeMode.dark
              ? Icons.dark_mode_outlined
              : currentTheme == ThemeMode.light
              ? Icons.light_mode_outlined
              : Icons.brightness_auto_outlined,
          iconColor: Colors.amber,
          title: l10n.themeMode,
          subtitle: currentTheme == ThemeMode.dark
              ? l10n.themeDark
              : currentTheme == ThemeMode.light
              ? l10n.themeLight
              : l10n.themeAuto,
          isDark: isDark,
          onTap: () => _showThemePicker(context, ref, currentTheme),
        ),
        _SettingsDivider(isDark: isDark),
        // Language
        _SettingsTile(
          icon: Icons.translate_outlined,
          iconColor: AppColors.aiBadge,
          title: l10n.languageSettings,
          subtitle: currentLocale == null
              ? l10n.systemDefault
              : currentLocale.languageCode == 'hi'
              ? l10n.hindi
              : l10n.english,
          isDark: isDark,
          onTap: () => _showLanguagePicker(context, ref, currentLocale),
        ),
      ],
    );
  }

  void _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  l10n.selectThemeMode,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ThemeOption(
                icon: Icons.brightness_auto,
                iconColor: AppColors.primary,
                title: l10n.themeAuto,
                subtitle: l10n.themeAutoSubtitle,
                isSelected: currentMode == ThemeMode.system,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.system);
                  Navigator.of(ctx).pop();
                },
              ),
              _ThemeOption(
                icon: Icons.light_mode,
                iconColor: Colors.amber,
                title: l10n.themeLight,
                subtitle: l10n.themeLightSubtitle,
                isSelected: currentMode == ThemeMode.light,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.light);
                  Navigator.of(ctx).pop();
                },
              ),
              _ThemeOption(
                icon: Icons.dark_mode,
                iconColor: Colors.indigo,
                title: l10n.themeDark,
                subtitle: l10n.themeDarkSubtitle,
                isSelected: currentMode == ThemeMode.dark,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.dark);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    Locale? currentLocale,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  l10n.languageSettings,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  l10n.languageSubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _LanguageOption(
                flag: '🌐',
                title: l10n.systemDefault,
                subtitle: 'Auto-detect from device',
                isSelected: currentLocale == null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(null);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.languageChanged),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _LanguageOption(
                flag: '🇬🇧',
                title: l10n.english,
                subtitle: 'English',
                isSelected: currentLocale?.languageCode == 'en',
                onTap: () {
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('en'));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.languageChanged),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _LanguageOption(
                flag: '🇮🇳',
                title: l10n.hindi,
                subtitle: 'हिंदी',
                isSelected: currentLocale?.languageCode == 'hi',
                onTap: () {
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('hi'));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.languageChanged),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ACCOUNT SECTION
// ═══════════════════════════════════════════════════════════════════════════════

class _AccountSection extends StatelessWidget {
  final AppLocalizations l10n;
  final UserModel user;

  const _AccountSection({required this.l10n, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _SettingsCard(
      isDark: isDark,
      children: [
        _SettingsTile(
          icon: Icons.edit_outlined,
          iconColor: AppColors.primary,
          title: l10n.editProfile,
          subtitle: l10n.editProfileSubtitle,
          isDark: isDark,
          badge: l10n.backendRequired,
          onTap: () => _showComingSoon(context, l10n),
        ),
        _SettingsDivider(isDark: isDark),
        _SettingsTile(
          icon: Icons.notifications_outlined,
          iconColor: AppColors.statusInProgress,
          title: l10n.notificationPreferences,
          subtitle: l10n.notificationPreferencesSubtitle,
          isDark: isDark,
          onTap: () => _showNotificationPreferences(context, l10n, isDark),
        ),
        _SettingsDivider(isDark: isDark),
        _SettingsTile(
          icon: Icons.lock_outline,
          iconColor: AppColors.statusAcknowledged,
          title: l10n.privacyAndSecurity,
          subtitle: l10n.privacySubtitle,
          isDark: isDark,
          onTap: () => _showPrivacySecurity(context, l10n, isDark),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.featureComingSoonMessage),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showNotificationPreferences(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  l10n.notificationPreferences,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _NotifToggle(
                title: l10n.complaintUpdates,
                subtitle: 'Get notified when your complaint status changes',
                value: true,
              ),
              _NotifToggle(
                title: l10n.officerResponses,
                subtitle: 'Get notified when an officer responds',
                value: true,
              ),
              _NotifToggle(
                title: l10n.communityAlerts,
                subtitle: 'Get alerts about issues in your area',
                value: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacySecurity(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  l10n.privacyAndSecurity,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.password_outlined,
                  color: AppColors.primary,
                ),
                title: Text(l10n.changePassword),
                subtitle: Text(
                  l10n.changePasswordSubtitle,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: _BadgeChip(text: l10n.backendRequired),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.featureComingSoonMessage)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.security_outlined,
                  color: AppColors.secondary,
                ),
                title: const Text('JWT Token Security'),
                subtitle: const Text(
                  'Access: 15min • Refresh: 7 days • Encrypted',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(
                  Icons.check_circle,
                  color: AppColors.statusResolved,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifToggle extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool value;

  const _NotifToggle({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  State<_NotifToggle> createState() => _NotifToggleState();
}

class _NotifToggleState extends State<_NotifToggle> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(widget.subtitle, style: const TextStyle(fontSize: 12)),
      value: _value,
      activeThumbColor: AppColors.primary,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUPPORT SECTION
// ═══════════════════════════════════════════════════════════════════════════════

class _SupportSection extends StatelessWidget {
  final AppLocalizations l10n;

  const _SupportSection({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _SettingsCard(
      isDark: isDark,
      children: [
        _SettingsTile(
          icon: Icons.help_outline,
          iconColor: AppColors.statusAssigned,
          title: l10n.faqs,
          subtitle: 'Common questions about CivicPulse',
          isDark: isDark,
          onTap: () => _showFAQ(context, isDark),
        ),
        _SettingsDivider(isDark: isDark),
        _SettingsTile(
          icon: Icons.mail_outline,
          iconColor: AppColors.statusInProgress,
          title: l10n.contactSupport,
          subtitle: 'support@civicpulse.city',
          isDark: isDark,
          onTap: () {
            Clipboard.setData(
              const ClipboardData(text: 'support@civicpulse.city'),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email copied to clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        _SettingsDivider(isDark: isDark),
        _SettingsTile(
          icon: Icons.bug_report_outlined,
          iconColor: AppColors.priorityCritical,
          title: l10n.reportAppProblem,
          subtitle: 'Help us improve the app',
          isDark: isDark,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.featureComingSoonMessage)),
            );
          },
        ),
      ],
    );
  }

  void _showFAQ(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => SafeArea(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _faqItem(
                'How do I report a civic issue?',
                'Tap the "Report Issue" button on the home screen. Add a title, description, select a category, attach photos, and your GPS location will be automatically captured.',
              ),
              _faqItem(
                'Can I track my complaint status?',
                'Yes! Go to "My Reports" tab to see all your submitted complaints with real-time status updates from reporting to resolution.',
              ),
              _faqItem(
                'What does upvoting do?',
                'Upvoting increases the priority of a complaint, helping officers identify the most impactful issues in the community.',
              ),
              _faqItem(
                'How does the AI analysis work?',
                'Our AI system automatically analyzes your complaint, suggests the appropriate department, and helps prioritize based on severity and impact.',
              ),
              _faqItem(
                'Is my data secure?',
                'Yes. We use JWT-based authentication with encrypted token storage. Access tokens expire every 15 minutes with automatic refresh.',
              ),
              _faqItem(
                'Can I use the app in Hindi?',
                'Yes! Go to Profile → Language and select हिंदी. The entire interface will switch to Hindi.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _faqItem(String question, String answer) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            answer,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GENERAL SECTION — About
// ═══════════════════════════════════════════════════════════════════════════════

class _GeneralSection extends StatelessWidget {
  final AppLocalizations l10n;

  const _GeneralSection({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _SettingsCard(
      isDark: isDark,
      children: [
        _SettingsTile(
          icon: Icons.info_outline,
          iconColor: AppColors.primary,
          title: l10n.aboutCivicPulse,
          subtitle: 'v1.0.0 • Smart City Citizen Portal',
          isDark: isDark,
          onTap: () => _showAbout(context, isDark),
        ),
        _SettingsDivider(isDark: isDark),
        _SettingsTile(
          icon: Icons.article_outlined,
          iconColor: AppColors.textSecondaryLight,
          title: l10n.termsOfService,
          subtitle: '',
          isDark: isDark,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.featureComingSoonMessage)),
            );
          },
        ),
        _SettingsDivider(isDark: isDark),
        _SettingsTile(
          icon: Icons.privacy_tip_outlined,
          iconColor: AppColors.textSecondaryLight,
          title: l10n.privacyPolicy,
          subtitle: '',
          isDark: isDark,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.featureComingSoonMessage)),
            );
          },
        ),
        _SettingsDivider(isDark: isDark),
        _SettingsTile(
          icon: Icons.code_outlined,
          iconColor: AppColors.secondary,
          title: l10n.openSourceLicenses,
          subtitle: '',
          isDark: isDark,
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'CivicPulse',
            applicationVersion: 'v1.0.0',
            applicationIcon: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            applicationLegalese: '© 2026 CivicPulse Smart City Portal',
          ),
        ),
      ],
    );
  }

  void _showAbout(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            const Text('CivicPulse'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'CivicPulse is a smart city citizen engagement platform that empowers residents to report civic issues, track resolutions, and collaborate with municipal officers for a better city.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'Built with ❤️ using Flutter, Spring Boot & PostGIS',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIGN OUT BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _SignOutButton extends ConsumerWidget {
  final AppLocalizations l10n;

  const _SignOutButton({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.priorityCritical,
          side: const BorderSide(color: AppColors.priorityCritical),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () => _showLogoutDialog(context, ref),
        icon: const Icon(Icons.logout_rounded),
        label: Text(l10n.signOut),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.signOutConfirmTitle),
        content: Text(l10n.signOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
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
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DELETE ACCOUNT BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _DeleteAccountButton extends StatelessWidget {
  final AppLocalizations l10n;

  const _DeleteAccountButton({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () => _showDeleteDialog(context),
        icon: const Icon(Icons.delete_outline, size: 18),
        label: Text(l10n.deleteAccount, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.deleteAccountConfirmMessage,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusAssigned.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.statusAssigned,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.deleteAccountRequiresBackend,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.statusAssigned,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.priorityCritical),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _SettingsCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback? onTap;
  final String? badge;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) _BadgeChip(text: badge!),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  final bool isDark;
  const _SettingsDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String text;
  const _BadgeChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.statusAssigned.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.statusAssigned,
        ),
      ),
    );
  }
}
