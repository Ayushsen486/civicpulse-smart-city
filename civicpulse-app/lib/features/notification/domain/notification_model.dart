class NotificationModel {
  final String id;
  final String title;
  final String? body;
  final String type;
  final String? referenceType;
  final String? referenceId;
  final bool isRead;
  final DateTime sentAt;

  const NotificationModel({
    required this.id,
    required this.title,
    this.body,
    required this.type,
    this.referenceType,
    this.referenceId,
    required this.isRead,
    required this.sentAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String?,
      type: json['type'] as String? ?? 'GENERAL',
      referenceType: json['referenceType'] as String?,
      referenceId: json['referenceId'] as String?,
      isRead: json['read'] as bool? ?? json['isRead'] as bool? ?? false,
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
