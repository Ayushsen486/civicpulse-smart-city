class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? icon;
  final String? color;
  final String defaultPriority;
  final int? slaHoursOverride;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.color,
    required this.defaultPriority,
    this.slaHoursOverride,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'General',
      slug: json['slug'] as String? ?? 'general',
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      defaultPriority: json['defaultPriority'] as String? ?? 'MEDIUM',
      slaHoursOverride: json['slaHoursOverride'] as int?,
    );
  }
}
