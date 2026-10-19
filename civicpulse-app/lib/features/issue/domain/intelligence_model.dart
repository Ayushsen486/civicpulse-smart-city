class IntelligenceModel {
  final String? suggestedCategoryId;
  final String? suggestedCategoryName;
  final String suggestedPriority;
  final String recommendedDepartment;
  final double categoryConfidence;
  final double priorityConfidence;
  final double overallConfidence;
  final String explanation;
  final bool needsHumanReview;

  const IntelligenceModel({
    this.suggestedCategoryId,
    this.suggestedCategoryName,
    required this.suggestedPriority,
    required this.recommendedDepartment,
    required this.categoryConfidence,
    required this.priorityConfidence,
    required this.overallConfidence,
    required this.explanation,
    required this.needsHumanReview,
  });

  factory IntelligenceModel.fromJson(Map<String, dynamic> json) {
    return IntelligenceModel(
      suggestedCategoryId: json['suggestedCategoryId'] as String?,
      suggestedCategoryName: json['suggestedCategoryName'] as String?,
      suggestedPriority: json['suggestedPriority'] as String? ?? 'MEDIUM',
      recommendedDepartment: json['recommendedDepartment'] as String? ?? 'General Administration',
      categoryConfidence: (json['categoryConfidence'] as num?)?.toDouble() ?? 0.0,
      priorityConfidence: (json['priorityConfidence'] as num?)?.toDouble() ?? 0.0,
      overallConfidence: (json['overallConfidence'] as num?)?.toDouble() ?? 0.0,
      explanation: json['explanation'] as String? ?? '',
      needsHumanReview: json['needsHumanReview'] as bool? ?? false,
    );
  }
}
