class MeritHistory {
  final String id;
  final DateTime date;
  final int points;
  final String type; // 'wooden_fish', 'random', 'reflection'
  final String? description;
  final String? category;

  MeritHistory({
    required this.id,
    required this.date,
    required this.points,
    required this.type,
    this.description,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'points': points,
      'type': type,
      'description': description,
      'category': category,
    };
  }

  factory MeritHistory.fromJson(Map<String, dynamic> json) {
    return MeritHistory(
      id: json['id'],
      date: DateTime.parse(json['date']),
      points: json['points'],
      type: json['type'],
      description: json['description'],
      category: json['category'],
    );
  }
}
