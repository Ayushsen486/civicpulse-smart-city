import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notification/domain/notification_model.dart';
import '../data/issue_repository.dart';
import '../domain/category_model.dart';
import '../domain/comment_model.dart';
import '../domain/intelligence_model.dart';
import '../domain/issue_model.dart';
import '../domain/timeline_event_model.dart';

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(issueRepositoryProvider);
  return repo.getCategories();
});

final issueListProvider = FutureProvider.autoDispose<List<IssueModel>>((ref) async {
  final repo = ref.watch(issueRepositoryProvider);
  return repo.getIssues();
});

final myIssuesProvider = FutureProvider.autoDispose.family<List<IssueModel>, String>((ref, reporterId) async {
  final repo = ref.watch(issueRepositoryProvider);
  return repo.getIssues(reporterId: reporterId);
});

final officerAssignedIssuesProvider = FutureProvider.autoDispose.family<List<IssueModel>, String>((ref, officerId) async {
  final repo = ref.watch(issueRepositoryProvider);
  return repo.getIssues(officerId: officerId);
});

final issueDetailProvider = FutureProvider.family<IssueModel, String>((ref, issueId) async {
  final repo = ref.watch(issueRepositoryProvider);
  return repo.getIssueById(issueId);
});

final issueTimelineProvider = FutureProvider.family<List<TimelineEventModel>, String>((ref, issueId) async {
  final repo = ref.watch(issueRepositoryProvider);
  final raw = await repo.getTimeline(issueId);
  return raw.map((json) => TimelineEventModel.fromJson(json as Map<String, dynamic>)).toList();
});

final issueCommentsProvider = FutureProvider.family<List<CommentModel>, String>((ref, issueId) async {
  final repo = ref.watch(issueRepositoryProvider);
  final raw = await repo.getComments(issueId);
  return raw.map((json) => CommentModel.fromJson(json as Map<String, dynamic>)).toList();
});

final issueIntelligenceProvider = FutureProvider.family<IntelligenceModel?, String>((ref, issueId) async {
  final repo = ref.watch(issueRepositoryProvider);
  return repo.getIssueIntelligence(issueId);
});

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final repo = ref.watch(issueRepositoryProvider);
  final raw = await repo.getNotifications();
  return raw.map((json) => NotificationModel.fromJson(json as Map<String, dynamic>)).toList();
});

final unreadNotificationsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(issueRepositoryProvider);
  return repo.getUnreadNotificationsCount();
});
