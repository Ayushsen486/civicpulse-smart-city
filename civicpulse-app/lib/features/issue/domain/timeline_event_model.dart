class TimelineEventModel {
  final String id;
  final String eventType;
  final String? fromStatus;
  final String? toStatus;
  final String? actorName;
  final String? actorRole;
  final String? remarks;
  final DateTime createdAt;

  const TimelineEventModel({
    required this.id,
    required this.eventType,
    this.fromStatus,
    this.toStatus,
    this.actorName,
    this.actorRole,
    this.remarks,
    required this.createdAt,
  });

  factory TimelineEventModel.fromJson(Map<String, dynamic> json) {
    return TimelineEventModel(
      id: json['id'] as String,
      eventType: json['eventType'] as String? ?? 'UPDATED',
      fromStatus: json['fromStatus'] as String?,
      toStatus: json['toStatus'] as String?,
      actorName: json['actorName'] as String?,
      actorRole: json['actorRole'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
