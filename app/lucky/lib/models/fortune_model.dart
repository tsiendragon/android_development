class Fortune {
  final String id;
  final String userId;
  final DateTime date;
  final String fortuneText;
  final bool isFavorite;
  final DateTime createdAt;

  Fortune({
    required this.id,
    required this.userId,
    required this.date,
    required this.fortuneText,
    this.isFavorite = false,
    required this.createdAt,
  });

  factory Fortune.fromJson(Map<String, dynamic> json) {
    return Fortune(
      id: json['id'],
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      fortuneText: json['fortuneText'],
      isFavorite: json['isFavorite'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'fortuneText': fortuneText,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Fortune copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? fortuneText,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Fortune(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      fortuneText: fortuneText ?? this.fortuneText,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
