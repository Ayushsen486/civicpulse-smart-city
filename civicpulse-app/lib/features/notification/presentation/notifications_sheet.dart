import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../issue/application/issue_controller.dart';
import '../../issue/data/issue_repository.dart';

class NotificationsSheet extends ConsumerWidget {
  const NotificationsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.72,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modal drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Notifications',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        await ref.read(issueRepositoryProvider).markAllNotificationsAsRead();
                        ref.invalidate(notificationsProvider);
                        ref.invalidate(unreadNotificationsCountProvider);
                      } catch (_) {}
                    },
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              Expanded(
                child: notifsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 40, color: AppColors.priorityCritical),
                        const SizedBox(height: 8),
                        Text('Failed to load notifications: $e', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.refresh(notificationsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (notifs) {
                    if (notifs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_none, size: 48, color: AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No notifications yet',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'You will be notified when your reported issues are assigned or resolved.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: notifs.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (ctx, index) {
                        final n = notifs[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: n.isRead
                                ? (isDark ? AppColors.surfaceDark : Colors.grey.shade100)
                                : AppColors.primary.withValues(alpha: 0.12),
                            child: Icon(
                              n.type == 'ASSIGNMENT'
                                  ? Icons.badge_outlined
                                  : n.type == 'STATUS_CHANGE'
                                      ? Icons.update
                                      : Icons.notifications_outlined,
                              color: n.isRead ? AppColors.textSecondaryLight : AppColors.primary,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!n.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(left: 6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: n.body != null
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    n.body!,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                  ),
                                )
                              : null,
                          trailing: Text(
                            '${n.sentAt.day}/${n.sentAt.month} ${n.sentAt.hour.toString().padLeft(2, '0')}:${n.sentAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                          onTap: () async {
                            if (!n.isRead) {
                              try {
                                await ref.read(issueRepositoryProvider).markNotificationAsRead(n.id);
                                ref.invalidate(notificationsProvider);
                                ref.invalidate(unreadNotificationsCountProvider);
                              } catch (_) {}
                            }
                            if (!context.mounted) return;
                            if (n.referenceType == 'ISSUE' && n.referenceId != null) {
                              Navigator.of(context).pop();
                              // Fixed path to /issues/:id matching app_router.dart
                              context.push('/issues/${n.referenceId}');
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
