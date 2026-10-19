import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:civicpulse_app/core/constants/api_endpoints.dart';
import 'package:civicpulse_app/core/theme/app_colors.dart';
import 'package:civicpulse_app/core/widgets/civic_map_widget.dart';
import 'package:civicpulse_app/features/issue/application/issue_controller.dart';
import 'package:civicpulse_app/features/issue/domain/issue_model.dart';
import 'package:civicpulse_app/features/notification/presentation/notifications_sheet.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  String _selectedCategoryFilter = 'ALL';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _showSearch = false;
  bool _showSplitMap = true; // Shows live map on top + feed below, matching reference UI

  // Real-time location state
  double _userLat = 28.6139; // Default City Coordinates (New Delhi / Municipal)
  double _userLng = 77.2090;
  bool _hasLocation = false;
  IssueModel? _selectedMapIssue;

  @override
  void initState() {
    super.initState();
    _fetchLiveLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
        if (mounted) {
          setState(() {
            _userLat = pos.latitude;
            _userLng = pos.longitude;
            _hasLocation = true;
          });
        }
      }
    } catch (_) {
      // Graceful fallback to default coordinates
    }
  }

  @override
  Widget build(BuildContext context) {
    final issuesAsync = ref.watch(issueListProvider);
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search complaints by keyword...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (q) => setState(() => _searchQuery = q.trim().toLowerCase()),
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_city, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CivicPulse', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Area Radar & Live Feed', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_showSplitMap ? Icons.map : Icons.map_outlined),
            tooltip: _showSplitMap ? 'Hide map' : 'Show area map',
            color: _showSplitMap ? AppColors.primary : null,
            onPressed: () => setState(() => _showSplitMap = !_showSplitMap),
          ),
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            tooltip: _showSearch ? 'Close search' : 'Search complaints',
            onPressed: () {
              setState(() {
                if (_showSearch) {
                  _searchQuery = '';
                  _searchController.clear();
                }
                _showSearch = !_showSearch;
              });
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () => NotificationsSheet.show(context),
              ),
              unreadCountAsync.maybeWhen(
                data: (count) {
                  if (count == 0) return const SizedBox.shrink();
                  return Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.priorityCritical,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: issuesAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text('Syncing area complaints...', style: TextStyle(color: AppColors.textSecondaryLight)),
            ],
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 54, color: AppColors.priorityHigh),
                const SizedBox(height: 16),
                const Text('Unable to load civic complaints', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 6),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(issueListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Connection'),
                ),
              ],
            ),
          ),
        ),
        data: (issues) {
          // If user location wasn't acquired yet and issues exist, center on first issue
          if (!_hasLocation && issues.isNotEmpty) {
            _userLat = issues.first.latitude;
            _userLng = issues.first.longitude;
          }

          // Category filter
          var filtered = _selectedCategoryFilter == 'ALL'
              ? issues
              : issues.where((i) => i.categoryName == _selectedCategoryFilter).toList();

          // Search query filter
          if (_searchQuery.isNotEmpty) {
            filtered = filtered.where((i) {
              final titleMatch = i.title.toLowerCase().contains(_searchQuery);
              final descMatch = i.description?.toLowerCase().contains(_searchQuery) ?? false;
              final refMatch = i.issueReference?.toLowerCase().contains(_searchQuery) ?? false;
              final locMatch = (i.address ?? '').toLowerCase().contains(_searchQuery);
              return titleMatch || descMatch || refMatch || locMatch;
            }).toList();
          }

          return Column(
            children: [
              // Categories horizontal filter chip bar
              categoriesAsync.maybeWhen(
                data: (categories) => Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: const Text('All Issues'),
                          selected: _selectedCategoryFilter == 'ALL',
                          onSelected: (_) => setState(() => _selectedCategoryFilter = 'ALL'),
                        ),
                      ),
                      ...categories.map((c) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(c.name),
                              selected: _selectedCategoryFilter == c.name,
                              onSelected: (_) => setState(() => _selectedCategoryFilter = c.name),
                            ),
                          )),
                    ],
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),

              // Interactive Radar Area Map (when _showSplitMap is enabled)
              if (_showSplitMap)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: Stack(
                    children: [
                      CivicMapWidget(
                        centerLatitude: _userLat,
                        centerLongitude: _userLng,
                        height: 280,
                        issues: filtered,
                        selectedIssue: _selectedMapIssue,
                        showUserRadar: true,
                        onIssueSelected: (issue) {
                          setState(() => _selectedMapIssue = issue);
                          context.push('/issues/${issue.id}');
                        },
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => context.push('/map'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fullscreen, size: 16, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'Full Map',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Section header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    Text(
                      'Latest in the area',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${filtered.length}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => context.push('/map'),
                      icon: const Icon(Icons.map_outlined, size: 15),
                      label: const Text('Interactive Map', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

              // Feed list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _fetchLiveLocation();
                    ref.invalidate(issueListProvider);
                  },
                  child: filtered.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 60),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.check_circle_outline, size: 56, color: Colors.green.shade400),
                                  const SizedBox(height: 12),
                                  const Text('No complaints found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 6),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'Try adjusting your search keywords.'
                                        : 'Everything looks clear in your municipal area!',
                                    style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                                  ),
                                  const SizedBox(height: 18),
                                  ElevatedButton.icon(
                                    onPressed: () => context.push('/report'),
                                    icon: const Icon(Icons.add_a_photo_outlined),
                                    label: const Text('Report New Issue'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final issue = filtered[index];
                            return _CivicIssueCard(
                              issue: issue,
                              userLat: _userLat,
                              userLng: _userLng,
                              isSelected: _selectedMapIssue?.id == issue.id,
                              onTap: () => context.push('/issues/${issue.id}'),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Refined Civic Card matching the user's reference mockup
class _CivicIssueCard extends StatelessWidget {
  final IssueModel issue;
  final double userLat;
  final double userLng;
  final bool isSelected;
  final VoidCallback onTap;

  const _CivicIssueCard({
    required this.issue,
    required this.userLat,
    required this.userLng,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getStatusColor(issue.status);
    final priorityColor = AppColors.getPriorityColor(issue.priority);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate approximate distance
    final distanceMeters = Geolocator.distanceBetween(
      userLat,
      userLng,
      issue.latitude,
      issue.longitude,
    );
    final miles = (distanceMeters / 1609.34).toStringAsFixed(1);
    final distanceText = '$miles mi • ${issue.address ?? issue.wardName ?? "Area Zone"}';

    // First attachment thumbnail
    final hasAttachment = issue.attachments.isNotEmpty;
    final thumbnailUrl = hasAttachment
        ? ApiEndpoints.getImageUrl(issue.attachments.first.fileUrl)
        : null;

    // Time ago formatted
    final diff = DateTime.now().toUtc().difference(issue.createdAt);
    final timeAgo = diff.inMinutes < 60
        ? '${diff.inMinutes.clamp(1, 59)}m ago'
        : diff.inHours < 24
            ? '${diff.inHours}h ago'
            : '${diff.inDays}d ago';

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Metadata Pill Row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      distanceText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 12, color: priorityColor),
                        const SizedBox(width: 3),
                        Text(
                          issue.priority,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: priorityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      issue.status.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title, Snippet & Right-Side Image Thumbnail
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            height: 1.25,
                          ),
                        ),
                        if (issue.description != null && issue.description!.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            issue.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Rounded thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 76,
                      height: 76,
                      color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                      child: thumbnailUrl != null
                          ? Image.network(
                              thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, size: 28, color: Colors.grey),
                              ),
                            )
                          : Container(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              child: const Icon(Icons.location_city, size: 30, color: AppColors.primary),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bottom Interaction Footer
              Row(
                children: [
                  Text(
                    'Updated $timeAgo',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const Spacer(),
                  // Like / Upvote Count
                  Row(
                    children: [
                      Icon(
                        issue.hasUpvoted ? Icons.favorite : Icons.favorite_border,
                        size: 15,
                        color: issue.hasUpvoted ? Colors.red : (isDark ? Colors.grey : Colors.grey.shade600),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${issue.upvotesCount} Likes',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Comments Count
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: isDark ? Colors.grey : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${issue.commentsCount}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
