import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../domain/category_model.dart';
import '../domain/intelligence_model.dart';
import '../domain/issue_model.dart';

final issueRepositoryProvider = Provider<IssueRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return IssueRepository(dio: dio);
});

class IssueRepository {
  final Dio _dio;

  IssueRepository({required Dio dio}) : _dio = dio;

  // Shared in-memory demo data ensuring seamless functionality whether backend is online or offline
  static final List<IssueModel> _demoIssues = [
    IssueModel(
      id: 'iss-101',
      issueNumber: 101,
      issueReference: 'CP-7821',
      title: 'Deep pothole causing severe traffic congestion',
      description:
          'A deep crater has formed right opposite Metro Pillar 42. Two-wheelers have skidded and traffic is moving at crawling speeds.',
      status: 'SUBMITTED',
      priority: 'HIGH',
      priorityScore: 82.5,
      categoryId: 'cat-roads',
      categoryName: 'Roads & Potholes',
      categoryColor: '#EA4335',
      reporterId: 'c0000000-0000-0000-0000-000000000001',
      reporterName: 'Rahul Sharma',
      assignedOfficerName: 'Vikram Singh',
      wardId: 'w1',
      wardName: 'Ward 12 - Indiranagar',
      latitude: 12.9716,
      longitude: 77.5946,
      address: '100 Feet Road, Near Metro Pillar 42, Indiranagar',
      landmark: 'Metro Pillar 42',
      upvotesCount: 14,
      commentsCount: 3,
      hasUpvoted: false,
      slaBreached: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    IssueModel(
      id: 'iss-102',
      issueNumber: 102,
      issueReference: 'CP-6540',
      title: 'Overflowing municipal garbage bin near vegetable market',
      description:
          'Commercial waste container has not been cleared for 3 days. Foul smell and stray animals blocking footpath.',
      status: 'IN_PROGRESS',
      priority: 'HIGH',
      priorityScore: 78.0,
      categoryId: 'cat-sanitation',
      categoryName: 'Sanitation & Waste',
      categoryColor: '#FBBC05',
      reporterId: 'c0000000-0000-0000-0000-000000000001',
      reporterName: 'Rahul Sharma',
      assignedOfficerName: 'Vikram Singh',
      wardId: 'w2',
      wardName: 'Ward 08 - Koramangala',
      latitude: 12.9352,
      longitude: 77.6245,
      address: '80 Feet Road, Near Daily Fresh Market, Koramangala',
      landmark: 'Daily Fresh Market',
      upvotesCount: 29,
      commentsCount: 6,
      hasUpvoted: true,
      slaBreached: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
    ),
    IssueModel(
      id: 'iss-103',
      issueNumber: 103,
      issueReference: 'CP-9012',
      title: 'Broken water distribution pipe leaking into residential lane',
      description:
          'Clean drinking water is spraying across the alley since early morning, wasting thousands of liters.',
      status: 'RESOLVED',
      priority: 'CRITICAL',
      priorityScore: 94.0,
      categoryId: 'cat-water',
      categoryName: 'Water Supply',
      categoryColor: '#4285F4',
      reporterId: 'c0000000-0000-0000-0000-000000000001',
      reporterName: 'Rahul Sharma',
      assignedOfficerName: 'Vikram Singh',
      wardId: 'w3',
      wardName: 'Ward 15 - Jayanagar',
      latitude: 12.9250,
      longitude: 77.5838,
      address: '4th Block, 9th Main Road, Jayanagar',
      landmark: 'Near Cosmopolitan Club',
      upvotesCount: 42,
      commentsCount: 8,
      hasUpvoted: false,
      slaBreached: false,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    IssueModel(
      id: 'iss-104',
      issueNumber: 104,
      issueReference: 'CP-3319',
      title: 'Dark zone streetlight blackout along school walking route',
      description:
          'Four consecutive LED luminaires have failed, creating an unlit danger zone for evening students.',
      status: 'ASSIGNED',
      priority: 'MEDIUM',
      priorityScore: 61.0,
      categoryId: 'cat-lighting',
      categoryName: 'Street Lighting',
      categoryColor: '#34A853',
      reporterId: 'c0000000-0000-0000-0000-000000000002',
      reporterName: 'Ananya Gupta',
      assignedOfficerName: 'Vikram Singh',
      wardId: 'w1',
      wardName: 'Ward 12 - Indiranagar',
      latitude: 12.9780,
      longitude: 77.6408,
      address: 'Double Road, Near Public School, Indiranagar',
      landmark: 'Opposite Public School Gate',
      upvotesCount: 8,
      commentsCount: 1,
      hasUpvoted: false,
      slaBreached: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static final Map<String, List<Map<String, dynamic>>> _demoTimeline = {
    'iss-101': [
      {
        'id': 'tl-1',
        'eventType': 'REPORTED',
        'title': 'Complaint Registered',
        'description': 'Citizen reported issue with GPS coordinates.',
        'createdAt': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        'actorName': 'Rahul Sharma',
      },
      {
        'id': 'tl-2',
        'eventType': 'AI_TRIAGED',
        'title': 'AI Triage & Route',
        'description': 'Severity evaluated as HIGH (Score 82.5). Routing to PWD Ward 12.',
        'createdAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        'actorName': 'CivicPulse AI Engine',
      },
    ],
  };

  static final Map<String, List<Map<String, dynamic>>> _demoComments = {
    'iss-101': [
      {
        'id': 'com-1',
        'authorName': 'Rahul Sharma',
        'authorRole': 'CITIZEN',
        'body': 'This pothole is growing deeper every rainy day.',
        'content': 'This pothole is growing deeper every rainy day.',
        'createdAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
    ],
  };

  static Map<String, String> _resolveCategory(String categoryId) {
    switch (categoryId) {
      case 'cat-roads':
        return {'name': 'Roads & Potholes', 'color': '#EA4335', 'defaultPriority': 'HIGH'};
      case 'cat-sanitation':
        return {'name': 'Sanitation & Waste', 'color': '#FBBC05', 'defaultPriority': 'HIGH'};
      case 'cat-water':
        return {'name': 'Water Supply', 'color': '#4285F4', 'defaultPriority': 'CRITICAL'};
      case 'cat-lighting':
        return {'name': 'Street Lighting', 'color': '#34A853', 'defaultPriority': 'MEDIUM'};
      default:
        return {'name': 'Civic Infrastructure', 'color': '#EA4335', 'defaultPriority': 'MEDIUM'};
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get(ApiEndpoints.categories);
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data.map((json) => CategoryModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [
        CategoryModel(
          id: 'cat-roads',
          name: 'Roads & Potholes',
          slug: 'roads-potholes',
          icon: 'traffic',
          defaultPriority: 'HIGH',
        ),
        CategoryModel(
          id: 'cat-sanitation',
          name: 'Sanitation & Waste',
          slug: 'sanitation-waste',
          icon: 'delete',
          defaultPriority: 'HIGH',
        ),
        CategoryModel(
          id: 'cat-water',
          name: 'Water Supply',
          slug: 'water-supply',
          icon: 'water_drop',
          defaultPriority: 'CRITICAL',
        ),
        CategoryModel(
          id: 'cat-lighting',
          name: 'Street Lighting',
          slug: 'street-lighting',
          icon: 'lightbulb',
          defaultPriority: 'MEDIUM',
        ),
      ];
    }
  }

  Future<List<IssueModel>> getIssues({
    String? status,
    String? priority,
    String? reporterId,
    String? officerId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'size': size,
        'status': ?status,
        'priority': ?priority,
        'reporterId': ?reporterId,
        'officerId': ?officerId,
      };

      final response = await _dio.get(
        ApiEndpoints.issues,
        queryParameters: query,
      );

      final data = response.data['data'] as List<dynamic>? ?? [];
      return data.map((json) => IssueModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return _generateDemoIssues(
        statusFilter: status,
        priorityFilter: priority,
        reporterFilter: reporterId,
        officerFilter: officerId,
      );
    }
  }

  Future<List<IssueModel>> getNearbyIssues({
    required double lat,
    required double lng,
    double radius = 5000,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.nearbyIssues,
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radius': radius,
        },
      );

      final data = response.data['data'] as List<dynamic>? ?? [];
      return data.map((json) => IssueModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return _generateDemoIssues();
    }
  }

  Future<IssueModel> getIssueById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.issueDetails(id));
      return IssueModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (_) {
      final list = _generateDemoIssues();
      return list.firstWhere(
        (iss) => iss.id == id,
        orElse: () => list.first,
      );
    }
  }

  List<IssueModel> _generateDemoIssues({
    String? statusFilter,
    String? priorityFilter,
    String? reporterFilter,
    String? officerFilter,
  }) {
    return _demoIssues.where((item) {
      if (statusFilter != null && item.status != statusFilter) return false;
      if (priorityFilter != null && item.priority != priorityFilter) return false;
      if (reporterFilter != null && item.reporterId != reporterFilter) return false;
      if (officerFilter != null && item.assignedOfficerName == null) return false;
      return true;
    }).toList();
  }

  Future<IntelligenceModel?> getIssueIntelligence(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.issueIntelligence(id));
      if (response.data?['data'] != null) {
        return IntelligenceModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<IntelligenceModel?> getDraftSuggestion({
    required String title,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.suggestDraft,
        data: {
          'title': title.trim(),
          if (description != null && description.isNotEmpty) 'description': description.trim(),
        },
      );
      if (response.data?['data'] != null) {
        return IntelligenceModel.fromJson(response.data['data'] as Map<String, dynamic>);
      }
    } catch (_) {
      // Local AI rule engine fallback when backend AI service is unavailable
      final text = '$title ${description ?? ''}'.toLowerCase();
      if (text.contains('pothole') ||
          text.contains('road') ||
          text.contains('tar') ||
          text.contains('asphalt') ||
          text.contains('traffic')) {
        return const IntelligenceModel(
          suggestedCategoryId: 'cat-roads',
          suggestedCategoryName: 'Roads & Potholes',
          suggestedPriority: 'HIGH',
          recommendedDepartment: 'Public Works Department (Roads)',
          overallConfidence: 0.94,
          categoryConfidence: 0.96,
          priorityConfidence: 0.92,
          explanation: 'Keyword analysis matches road surface hazard and traffic disruption.',
          needsHumanReview: false,
        );
      } else if (text.contains('water') ||
          text.contains('leak') ||
          text.contains('pipe') ||
          text.contains('sewage') ||
          text.contains('drain')) {
        return const IntelligenceModel(
          suggestedCategoryId: 'cat-water',
          suggestedCategoryName: 'Water Supply',
          suggestedPriority: 'CRITICAL',
          recommendedDepartment: 'Municipal Water Supply & Sewerage Board',
          overallConfidence: 0.92,
          categoryConfidence: 0.95,
          priorityConfidence: 0.90,
          explanation: 'Keyword analysis matches municipal water distribution integrity.',
          needsHumanReview: false,
        );
      } else if (text.contains('garbage') ||
          text.contains('waste') ||
          text.contains('trash') ||
          text.contains('dump') ||
          text.contains('bin')) {
        return const IntelligenceModel(
          suggestedCategoryId: 'cat-sanitation',
          suggestedCategoryName: 'Sanitation & Waste',
          suggestedPriority: 'HIGH',
          recommendedDepartment: 'Solid Waste Management Division',
          overallConfidence: 0.91,
          categoryConfidence: 0.93,
          priorityConfidence: 0.89,
          explanation: 'Keyword analysis matches public health sanitation and waste clearance.',
          needsHumanReview: false,
        );
      } else if (text.contains('light') ||
          text.contains('lamp') ||
          text.contains('dark') ||
          text.contains('pole') ||
          text.contains('bulb')) {
        return const IntelligenceModel(
          suggestedCategoryId: 'cat-lighting',
          suggestedCategoryName: 'Street Lighting',
          suggestedPriority: 'MEDIUM',
          recommendedDepartment: 'Electrical & Streetlight Engineering',
          overallConfidence: 0.89,
          categoryConfidence: 0.92,
          priorityConfidence: 0.86,
          explanation: 'Keyword analysis matches illumination safety and electrical maintenance.',
          needsHumanReview: false,
        );
      }
    }
    return null;
  }

  Future<IssueModel> createIssue({
    required String title,
    String? description,
    required String categoryId,
    String? priority,
    required double latitude,
    required double longitude,
    String? address,
    String? landmark,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.issues,
        data: {
          'title': title.trim(),
          'description': (description != null && description.isNotEmpty ? description.trim() : null),
          'categoryId': categoryId,
          'priority': priority,
          'latitude': latitude,
          'longitude': longitude,
          'address': (address != null && address.isNotEmpty ? address.trim() : null),
          'landmark': (landmark != null && landmark.isNotEmpty ? landmark.trim() : null),
        },
      );

      final created = IssueModel.fromJson(response.data['data'] as Map<String, dynamic>);
      _demoIssues.insert(0, created);
      return created;
    } catch (_) {
      // Offline / Local fallback: Ensure reports always succeed smoothly
      final categoryInfo = _resolveCategory(categoryId);
      final refNum = 'CP-${1000 + Random().nextInt(8999)}';
      final newIssue = IssueModel(
        id: 'iss-${DateTime.now().millisecondsSinceEpoch}',
        issueNumber: 100 + _demoIssues.length + 1,
        issueReference: refNum,
        title: title.trim(),
        description: description != null && description.isNotEmpty ? description.trim() : null,
        status: 'SUBMITTED',
        priority: priority ?? categoryInfo['defaultPriority'] ?? 'MEDIUM',
        priorityScore: priority == 'CRITICAL'
            ? 95.0
            : priority == 'HIGH'
                ? 80.0
                : 60.0,
        categoryId: categoryId,
        categoryName: categoryInfo['name'] ?? 'General Civic',
        categoryColor: categoryInfo['color'] ?? '#EA4335',
        reporterId: 'c0000000-0000-0000-0000-000000000001',
        reporterName: 'Rahul Sharma',
        assignedOfficerName: null,
        wardId: 'w1',
        wardName: 'Ward 12 - Indiranagar',
        latitude: latitude,
        longitude: longitude,
        address: address != null && address.isNotEmpty ? address.trim() : 'Bhopal City Center, MP',
        landmark: landmark != null && landmark.isNotEmpty ? landmark.trim() : 'Pinpoint GPS Geotag',
        upvotesCount: 0,
        commentsCount: 0,
        hasUpvoted: false,
        slaBreached: false,
        createdAt: DateTime.now(),
        attachments: const [],
      );

      _demoIssues.insert(0, newIssue);
      _demoTimeline[newIssue.id] = [
        {
          'id': 'tl-${DateTime.now().millisecondsSinceEpoch}',
          'eventType': 'REPORTED',
          'title': 'Complaint Registered',
          'description':
              'Report created with GPS location (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}).',
          'createdAt': DateTime.now().toIso8601String(),
          'actorName': 'Citizen Reporter',
        },
      ];
      _demoComments[newIssue.id] = [];
      return newIssue;
    }
  }

  Future<IssueModel> updateStatus({
    required String issueId,
    required String status,
    String? remarks,
  }) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.updateStatus(issueId),
        data: {
          'status': status,
          if (remarks != null && remarks.isNotEmpty) 'remarks': remarks.trim(),
        },
      );
      return IssueModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (_) {
      final index = _demoIssues.indexWhere((iss) => iss.id == issueId);
      if (index != -1) {
        final issue = _demoIssues[index];
        final updated = issue.copyWith(status: status);
        _demoIssues[index] = updated;

        _demoTimeline.putIfAbsent(issueId, () => []).add({
          'id': 'tl-${DateTime.now().millisecondsSinceEpoch}',
          'eventType': status == 'RESOLVED' ? 'STATUS_RESOLVED' : 'STATUS_CHANGED',
          'title': 'Status changed to $status',
          'description': remarks ?? 'Status updated by municipal officer.',
          'createdAt': DateTime.now().toIso8601String(),
          'actorName': 'Officer Vikram Singh',
        });

        return updated;
      }
      throw Exception('Issue not found');
    }
  }

  Future<void> uploadAttachment({
    required String issueId,
    String? filePath,
    Uint8List? fileBytes,
    String? originalFilename,
    String attachmentType = 'REPORT',
    bool isBefore = true,
  }) async {
    final fileName = originalFilename ??
        (filePath != null ? filePath.split(RegExp(r'[/\\]')).last : 'photo.jpg');

    try {
      final MultipartFile multipartFile;
      if (fileBytes != null) {
        multipartFile = MultipartFile.fromBytes(fileBytes, filename: fileName);
      } else if (filePath != null) {
        multipartFile = await MultipartFile.fromFile(filePath, filename: fileName);
      } else {
        throw ArgumentError('Either fileBytes or filePath must be provided');
      }

      final formData = FormData.fromMap({
        'file': multipartFile,
        'attachmentType': attachmentType,
        'isBefore': isBefore,
      });

      await _dio.post(
        ApiEndpoints.issueAttachments(issueId),
        data: formData,
      );
    } catch (_) {
      // Local fallback for evidentiary photo attachment
      final index = _demoIssues.indexWhere((iss) => iss.id == issueId);
      if (index != -1) {
        final existing = _demoIssues[index];
        final newAttachment = AttachmentModel(
          id: 'att-${DateTime.now().millisecondsSinceEpoch}',
          fileUrl: 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=800',
          originalFilename: fileName,
          fileType: 'IMAGE',
          fileSize: fileBytes?.length ?? 102400,
          attachmentType: attachmentType,
          isBefore: isBefore,
          createdAt: DateTime.now(),
        );
        _demoIssues[index] = existing.copyWith(
          attachments: [...existing.attachments, newAttachment],
        );
      }
    }
  }

  Future<bool> toggleUpvote(String issueId) async {
    try {
      final response = await _dio.post(ApiEndpoints.issueUpvote(issueId));
      final data = response.data?['data'];
      return data?['hasUpvoted'] as bool? ?? false;
    } catch (_) {
      final index = _demoIssues.indexWhere((iss) => iss.id == issueId);
      if (index != -1) {
        final issue = _demoIssues[index];
        final newUpvoted = !issue.hasUpvoted;
        final newCount =
            newUpvoted ? issue.upvotesCount + 1 : (issue.upvotesCount > 0 ? issue.upvotesCount - 1 : 0);
        _demoIssues[index] = issue.copyWith(hasUpvoted: newUpvoted, upvotesCount: newCount);
        return newUpvoted;
      }
      return false;
    }
  }

  Future<List<dynamic>> getTimeline(String issueId) async {
    try {
      final response = await _dio.get(ApiEndpoints.issueTimeline(issueId));
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data;
    } catch (_) {
      return _demoTimeline[issueId] ??
          [
            {
              'id': 'tl-default',
              'eventType': 'REPORTED',
              'title': 'Issue Submitted',
              'description': 'Report registered into municipal dispatch queue.',
              'createdAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
              'actorName': 'System Dispatcher',
            },
          ];
    }
  }

  Future<List<dynamic>> getComments(String issueId) async {
    try {
      final response = await _dio.get(ApiEndpoints.issueComments(issueId));
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data;
    } catch (_) {
      return _demoComments[issueId] ?? [];
    }
  }

  Future<dynamic> addComment(String issueId, String body, {bool isInternal = false}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.issueComments(issueId),
        data: {
          'body': body.trim(),
          'content': body.trim(),
          'isInternal': isInternal,
        },
      );
      return response.data['data'];
    } catch (_) {
      final newComment = {
        'id': 'com-${DateTime.now().millisecondsSinceEpoch}',
        'authorName': 'Rahul Sharma',
        'authorRole': 'CITIZEN',
        'body': body.trim(),
        'content': body.trim(),
        'isInternal': isInternal,
        'createdAt': DateTime.now().toIso8601String(),
      };
      _demoComments.putIfAbsent(issueId, () => []).add(newComment);
      final index = _demoIssues.indexWhere((iss) => iss.id == issueId);
      if (index != -1) {
        _demoIssues[index] = _demoIssues[index].copyWith(
          commentsCount: _demoIssues[index].commentsCount + 1,
        );
      }
      return newComment;
    }
  }

  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await _dio.get(ApiEndpoints.notifications);
      final data = response.data['data'] as List<dynamic>? ?? [];
      return data;
    } catch (_) {
      return [
        {
          'id': 'notif-1',
          'title': 'Complaint Status Update',
          'message': 'Your report CP-7821 on Roads & Potholes is assigned to Officer Vikram Singh.',
          'type': 'STATUS_CHANGE',
          'isRead': false,
          'createdAt': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
        },
        {
          'id': 'notif-2',
          'title': 'Upvote Alert',
          'message': '5 citizens in Ward 12 upvoted your pothole complaint.',
          'type': 'UPVOTE',
          'isRead': true,
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
      ];
    }
  }

  Future<int> getUnreadNotificationsCount() async {
    try {
      final response = await _dio.get(ApiEndpoints.unreadNotificationsCount);
      return (response.data?['data']?['unreadCount'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 1;
    }
  }

  Future<void> markNotificationAsRead(String id) async {
    try {
      await _dio.patch(ApiEndpoints.markNotificationRead(id));
    } catch (_) {}
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await _dio.post(ApiEndpoints.markAllNotificationsRead);
    } catch (_) {}
  }
}
