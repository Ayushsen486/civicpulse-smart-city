import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:civicpulse_app/core/constants/api_endpoints.dart';
import 'package:civicpulse_app/core/theme/app_colors.dart';
import 'package:civicpulse_app/core/widgets/civic_map_widget.dart';
import 'package:civicpulse_app/features/auth/application/auth_controller.dart';
import 'package:civicpulse_app/features/issue/application/issue_controller.dart';
import 'package:civicpulse_app/features/issue/data/issue_repository.dart';
import 'package:civicpulse_app/features/issue/domain/issue_model.dart';

class IssueDetailScreen extends ConsumerStatefulWidget {
  final String issueId;

  const IssueDetailScreen({super.key, required this.issueId});

  @override
  ConsumerState<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends ConsumerState<IssueDetailScreen> {
  bool _isUpvoting = false;
  bool _isUpdatingStatus = false;

  Future<void> _updateIssueStatus(String id, String status, String remarks) async {
    setState(() => _isUpdatingStatus = true);
    try {
      final repo = ref.read(issueRepositoryProvider);
      await repo.updateStatus(issueId: id, status: status, remarks: remarks);
      ref.invalidate(issueDetailProvider(widget.issueId));
      ref.invalidate(issueTimelineProvider(widget.issueId));
      ref.invalidate(issueListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complaint status updated to $status'),
            backgroundColor: AppColors.statusResolved,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status update failed: $e'),
            backgroundColor: AppColors.priorityCritical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  void _showResolveDialog(BuildContext context, IssueModel issue) {
    final remarksController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.statusResolved),
            SizedBox(width: 8),
            Text('Resolve Complaint'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter resolution remarks describing field actions taken:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarksController,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g., Road resurfaced, debris cleared by zonal crew.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusResolved,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final remarks = remarksController.text.trim();
              if (remarks.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter resolution remarks.')),
                );
                return;
              }
              Navigator.of(ctx).pop();
              _updateIssueStatus(issue.id, 'RESOLVED', remarks);
            },
            child: const Text('Confirm Resolution'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpvote(IssueModel issue) async {
    setState(() => _isUpvoting = true);
    try {
      final repo = ref.read(issueRepositoryProvider);
      await repo.toggleUpvote(issue.id);
      ref.invalidate(issueDetailProvider(widget.issueId));
      ref.invalidate(issueListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upvote action failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpvoting = false);
    }
  }

  void _showEnlargedImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 300,
                    color: Colors.black45,
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: const Text('Failed to load image', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsSheet(BuildContext context, IssueModel issue) {
    final textController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final commentsAsync = ref.watch(issueCommentsProvider(widget.issueId));

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            child: SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Comments & Updates (${issue.commentsCount})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: commentsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Failed to load comments: $e')),
                        data: (comments) {
                          if (comments.isEmpty) {
                            return const Center(
                              child: Text(
                                'No comments yet.\nBe the first to leave a message.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondaryLight),
                              ),
                            );
                          }

                          return ListView.separated(
                            itemCount: comments.length,
                            separatorBuilder: (context, index) => const Divider(height: 12),
                            itemBuilder: (context, index) {
                              final c = comments[index];
                              final isOfficial = c.authorRole != null && c.authorRole != 'CITIZEN';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: isOfficial
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : Colors.grey.shade200,
                                  child: Icon(
                                    isOfficial ? Icons.verified_user : Icons.person,
                                    color: isOfficial ? AppColors.primary : Colors.grey.shade700,
                                    size: 20,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      c.authorName ?? 'Citizen',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    if (isOfficial) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          c.authorRole ?? 'Officer',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(c.body, style: const TextStyle(fontSize: 13)),
                                ),
                                trailing: Text(
                                  '${c.createdAt.day}/${c.createdAt.month}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            decoration: InputDecoration(
                              hintText: 'Write a comment or remark...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          color: AppColors.primary,
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final text = textController.text.trim();
                                  if (text.isEmpty) return;
                                  setSheetState(() => isSubmitting = true);
                                  try {
                                    final repo = ref.read(issueRepositoryProvider);
                                    await repo.addComment(widget.issueId, text);
                                    textController.clear();
                                    ref.invalidate(issueCommentsProvider(widget.issueId));
                                    ref.invalidate(issueDetailProvider(widget.issueId));
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(content: Text('Failed to post comment: $e')),
                                      );
                                    }
                                  } finally {
                                    setSheetState(() => isSubmitting = false);
                                  }
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final issueAsync = ref.watch(issueDetailProvider(widget.issueId));
    final intelAsync = ref.watch(issueIntelligenceProvider(widget.issueId));
    final timelineAsync = ref.watch(issueTimelineProvider(widget.issueId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(issueDetailProvider(widget.issueId));
              ref.invalidate(issueTimelineProvider(widget.issueId));
              ref.invalidate(issueCommentsProvider(widget.issueId));
            },
          ),
        ],
      ),
      body: issueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.priorityCritical),
              const SizedBox(height: 12),
              Text('Failed to load issue: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(issueDetailProvider(widget.issueId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (issue) {
          final statusColor = AppColors.getStatusColor(issue.status);
          final priorityColor = AppColors.getPriorityColor(issue.priority);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(issueDetailProvider(widget.issueId));
              ref.invalidate(issueTimelineProvider(widget.issueId));
              ref.invalidate(issueCommentsProvider(widget.issueId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Category badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          issue.status.replaceAll('_', ' '),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flag, size: 12, color: priorityColor),
                            const SizedBox(width: 4),
                            Text(
                              issue.priority,
                              style: TextStyle(
                                color: priorityColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (issue.issueReference != null)
                        Text(
                          issue.issueReference!,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    issue.title,
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Category tag
                  Row(
                    children: [
                      const Icon(Icons.category_outlined, size: 16, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 6),
                      Text(
                        issue.categoryName,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Description
                  if (issue.description != null && issue.description!.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Text(
                          issue.description!,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Photographic Evidence Gallery
                  if (issue.attachments.isNotEmpty) ...[
                    Text(
                      'Photographic Evidence (${issue.attachments.length})',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: issue.attachments.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 10),
                        itemBuilder: (ctx, i) {
                          final att = issue.attachments[i];
                          // Robust image URL resolution via ApiEndpoints.getImageUrl
                          final fullUrl = ApiEndpoints.getImageUrl(att.fileUrl);

                          return GestureDetector(
                            onTap: () => _showEnlargedImage(context, fullUrl),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 140,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                                  border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      fullUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (c, child, p) => p == null
                                          ? child
                                          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      errorBuilder: (context, error, stackTrace) => const Center(
                                        child: Icon(Icons.broken_image, color: Colors.grey),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Assigned Field Officer Card
                  if (issue.assignedOfficerName != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.statusAssigned.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.statusAssigned.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.statusAssigned.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.badge_outlined, color: AppColors.statusAssigned, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Assigned Field Officer',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.statusAssigned),
                              ),
                              Text(
                                issue.assignedOfficerName!,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // AI Intelligence Advisory Card
                  intelAsync.maybeWhen(
                    data: (intel) {
                      if (intel == null) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.aiBadge.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.aiBadge.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: AppColors.aiBadge, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'AI Dispatch Routing',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.aiBadge),
                                ),
                                const Spacer(),
                                Text(
                                  '${(intel.overallConfidence * 100).toInt()}% Confidence',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.aiBadge),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Department: ${intel.recommendedDepartment}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              intel.explanation,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),

                  // Location & Interactive Map Card
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              const Text('Incident Location & Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${issue.latitude.toStringAsFixed(5)}°, ${issue.longitude.toStringAsFixed(5)}°',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Embedded Interactive Mini-Map
                          CivicMapWidget(
                            centerLatitude: issue.latitude,
                            centerLongitude: issue.longitude,
                            height: 170,
                            initialZoom: 15.5,
                            issues: [issue],
                            selectedIssue: issue,
                            showUserRadar: false,
                          ),
                          const SizedBox(height: 10),
                          Text('Address: ${issue.address ?? 'Not specified'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          if (issue.landmark != null) ...[
                            const SizedBox(height: 3),
                            Text('Landmark: ${issue.landmark}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight)),
                          ],
                          if (issue.wardName != null) ...[
                            const SizedBox(height: 3),
                            Text('Ward: ${issue.wardName}', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Timeline & Audit Trail with connected vertical progress
                  Text(
                    'Status Timeline & Audit Trail',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  timelineAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Text('Could not load timeline: $e'),
                    data: (events) {
                      if (events.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No status transitions recorded yet.'),
                          ),
                        );
                      }
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: events.length,
                            itemBuilder: (ctx, i) {
                              final ev = events[i];
                              final isLast = i == events.length - 1;
                              final isFinal = ev.toStatus == 'RESOLVED' || ev.toStatus == 'CLOSED';

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Stepper column with icon and line
                                    Column(
                                      children: [
                                        Icon(
                                          isFinal ? Icons.check_circle : Icons.radio_button_checked,
                                          size: 18,
                                          color: isFinal ? AppColors.statusResolved : AppColors.primary,
                                        ),
                                        if (!isLast)
                                          Expanded(
                                            child: Container(
                                              width: 2,
                                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                              margin: const EdgeInsets.symmetric(vertical: 4),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    // Event details
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(bottom: isLast ? 0 : 16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  ev.eventType.replaceAll('_', ' '),
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  '${ev.createdAt.day}/${ev.createdAt.month} ${ev.createdAt.hour.toString().padLeft(2, '0')}:${ev.createdAt.minute.toString().padLeft(2, '0')}',
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                            if (ev.actorName != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                'By: ${ev.actorName} (${ev.actorRole ?? 'Citizen'})',
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                              ),
                                            ],
                                            if (ev.remarks != null && ev.remarks!.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  ev.remarks!,
                                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Field Officer Action Control Card
                  Consumer(
                    builder: (context, ref, _) {
                      final currentUser = ref.watch(authControllerProvider).value;
                      final isOfficer = currentUser != null &&
                          (currentUser.role.contains('OFFICER') || currentUser.role.contains('ADMIN'));
                      final isResolved = issue.status == 'RESOLVED' || issue.status == 'CLOSED';

                      if (!isOfficer || isResolved) return const SizedBox.shrink();

                      final canStartWork = issue.status == 'REPORTED' ||
                          issue.status == 'ACKNOWLEDGED' ||
                          issue.status == 'ASSIGNED';
                      final canResolve = issue.status == 'IN_PROGRESS';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.engineering, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Field Officer Controls',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    currentUser.role.replaceAll('ROLE_', ''),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Update complaint resolution lifecycle directly from the field:',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: 14),
                            if (canStartWork)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.statusInProgress,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _isUpdatingStatus
                                    ? null
                                    : () => _updateIssueStatus(
                                          issue.id,
                                          'IN_PROGRESS',
                                          'Field officer dispatched and initiated on-site investigation.',
                                        ),
                                icon: _isUpdatingStatus
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.play_arrow),
                                label: const Text('Start Work (Mark In-Progress)'),
                              ),
                            if (canResolve)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.statusResolved,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _isUpdatingStatus ? null : () => _showResolveDialog(context, issue),
                                icon: _isUpdatingStatus
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.check_circle_outline),
                                label: const Text('Complete & Mark Resolved'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Actions row: Upvote & Comments
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isUpvoting ? null : () => _handleUpvote(issue),
                          icon: Icon(
                            issue.hasUpvoted ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                            size: 18,
                          ),
                          label: Text(issue.hasUpvoted ? 'Upvoted (${issue.upvotesCount})' : 'Upvote (${issue.upvotesCount})'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showCommentsSheet(context, issue),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: Text('Comments (${issue.commentsCount})'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
