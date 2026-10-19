class CommentModel {
  final String id;
  final String issueId;
  final String? authorName;
  final String? authorRole;
  final String body;
  final bool isInternal;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.issueId,
    this.authorName,
    this.authorRole,
    required this.body,
    required this.isInternal,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      issueId: json['issueId'] as String? ?? '',
      authorName: json['authorName'] as String?,
      authorRole: json['authorRole'] as String?,
      body: (json['body'] ?? json['content'] ?? '') as String,
      isInternal: json['isInternal'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
