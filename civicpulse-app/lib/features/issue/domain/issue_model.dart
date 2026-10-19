class AttachmentModel {
  final String id;
  final String fileUrl;
  final String originalFilename;
  final String fileType;
  final int fileSize;
  final String attachmentType;
  final bool isBefore;
  final DateTime createdAt;

  const AttachmentModel({
    required this.id,
    required this.fileUrl,
    required this.originalFilename,
    required this.fileType,
    required this.fileSize,
    required this.attachmentType,
    required this.isBefore,
    required this.createdAt,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] as String,
      fileUrl: json['fileUrl'] as String? ?? '',
      originalFilename: json['originalFilename'] as String? ?? 'photo.jpg',
      fileType: json['fileType'] as String? ?? 'IMAGE',
      fileSize: json['fileSize'] as int? ?? 0,
      attachmentType: json['attachmentType'] as String? ?? 'REPORT',
      isBefore: json['isBefore'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class IssueModel {
  final String id;
  final int issueNumber;
  final String? issueReference;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final double priorityScore;
  final String categoryId;
  final String categoryName;
  final String? categoryColor;
  final String reporterId;
  final String reporterName;
  final String? assignedOfficerName;
  final String? wardId;
  final String? wardName;
  final double latitude;
  final double longitude;
  final String? address;
  final String? landmark;
  final int upvotesCount;
  final int commentsCount;
  final bool hasUpvoted;
  final DateTime? slaDeadline;
  final bool slaBreached;
  final DateTime createdAt;
  final List<AttachmentModel> attachments;

  const IssueModel({
    required this.id,
    required this.issueNumber,
    this.issueReference,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.priorityScore,
    required this.categoryId,
    required this.categoryName,
    this.categoryColor,
    required this.reporterId,
    required this.reporterName,
    this.assignedOfficerName,
    this.wardId,
    this.wardName,
    required this.latitude,
    required this.longitude,
    this.address,
    this.landmark,
    required this.upvotesCount,
    required this.commentsCount,
    required this.hasUpvoted,
    this.slaDeadline,
    required this.slaBreached,
    required this.createdAt,
    this.attachments = const [],
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'] as List<dynamic>? ?? [];
    final attachmentsList = rawAttachments
        .map((a) => AttachmentModel.fromJson(a as Map<String, dynamic>))
        .toList();

    return IssueModel(
      id: json['id'] as String,
      issueNumber: json['issueNumber'] as int? ?? 0,
      issueReference: json['issueReference'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'REPORTED',
      priority: json['priority'] as String? ?? 'MEDIUM',
      priorityScore: (json['priorityScore'] as num?)?.toDouble() ?? 0.0,
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? 'General',
      categoryColor: json['categoryColor'] as String?,
      reporterId: json['reporterId'] as String? ?? '',
      reporterName: json['reporterName'] as String? ?? 'Anonymous',
      assignedOfficerName: json['assignedOfficerName'] as String?,
      wardId: json['wardId'] as String?,
      wardName: json['wardName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String?,
      landmark: json['landmark'] as String?,
      upvotesCount: json['upvotesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      hasUpvoted: json['hasUpvoted'] as bool? ?? false,
      slaDeadline: json['slaDeadline'] != null
          ? DateTime.tryParse(json['slaDeadline'] as String)
          : null,
      slaBreached: json['slaBreached'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      attachments: attachmentsList,
    );
  }

  IssueModel copyWith({
    String? id,
    int? issueNumber,
    String? issueReference,
    String? title,
    String? description,
    String? status,
    String? priority,
    double? priorityScore,
    String? categoryId,
    String? categoryName,
    String? categoryColor,
    String? reporterId,
    String? reporterName,
    String? assignedOfficerName,
    String? wardId,
    String? wardName,
    double? latitude,
    double? longitude,
    String? address,
    String? landmark,
    int? upvotesCount,
    int? commentsCount,
    bool? hasUpvoted,
    DateTime? slaDeadline,
    bool? slaBreached,
    DateTime? createdAt,
    List<AttachmentModel>? attachments,
  }) {
    return IssueModel(
      id: id ?? this.id,
      issueNumber: issueNumber ?? this.issueNumber,
      issueReference: issueReference ?? this.issueReference,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      priorityScore: priorityScore ?? this.priorityScore,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      assignedOfficerName: assignedOfficerName ?? this.assignedOfficerName,
      wardId: wardId ?? this.wardId,
      wardName: wardName ?? this.wardName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      landmark: landmark ?? this.landmark,
      upvotesCount: upvotesCount ?? this.upvotesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      hasUpvoted: hasUpvoted ?? this.hasUpvoted,
      slaDeadline: slaDeadline ?? this.slaDeadline,
      slaBreached: slaBreached ?? this.slaBreached,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
    );
  }
}

