class MeritAchievement {
  final String id;
  final String title;
  final String description;
  final int requiredPoints;
  final String icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  MeritAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredPoints,
    required this.icon,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requiredPoints': requiredPoints,
      'icon': icon,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory MeritAchievement.fromJson(Map<String, dynamic> json) {
    return MeritAchievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      requiredPoints: json['requiredPoints'],
      icon: json['icon'],
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt:
          json['unlockedAt'] != null
              ? DateTime.parse(json['unlockedAt'])
              : null,
    );
  }

  MeritAchievement copyWith({
    String? id,
    String? title,
    String? description,
    int? requiredPoints,
    String? icon,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return MeritAchievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      requiredPoints: requiredPoints ?? this.requiredPoints,
      icon: icon ?? this.icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
