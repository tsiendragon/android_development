class Fortune {
  final String id;
  final String userId;
  final DateTime date;
  final String fortuneText;
  final bool isFavorite;
  final DateTime createdAt;
  
  // New fields for version 1.1 - ratings for different aspects (0-5 stars)
  final int loveRating;     // 爱情运势评分
  final int careerRating;   // 事业运势评分
  final int healthRating;   // 健康运势评分
  final int wealthRating;   // 财运评分
  
  // New fields for version 1.2 - things to do and avoid to improve fortune
  final List<String> thingsToDo;      // 宜做事项
  final List<String> thingsToAvoid;   // 忌做事项

  Fortune({
    required this.id,
    required this.userId,
    required this.date,
    required this.fortuneText,
    this.isFavorite = false,
    required this.createdAt,
    this.loveRating = 0,
    this.careerRating = 0,
    this.healthRating = 0,
    this.wealthRating = 0,
    this.thingsToDo = const [],
    this.thingsToAvoid = const [],
  });

  factory Fortune.fromJson(Map<String, dynamic> json) {
    return Fortune(
      id: json['id'],
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      fortuneText: json['fortuneText'],
      isFavorite: json['isFavorite'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      loveRating: json['loveRating'] ?? 0,
      careerRating: json['careerRating'] ?? 0,
      healthRating: json['healthRating'] ?? 0,
      wealthRating: json['wealthRating'] ?? 0,
      thingsToDo: json['thingsToDo'] != null 
          ? List<String>.from(json['thingsToDo']) 
          : const [],
      thingsToAvoid: json['thingsToAvoid'] != null 
          ? List<String>.from(json['thingsToAvoid']) 
          : const [],
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
      'loveRating': loveRating,
      'careerRating': careerRating,
      'healthRating': healthRating,
      'wealthRating': wealthRating,
      'thingsToDo': thingsToDo,
      'thingsToAvoid': thingsToAvoid,
    };
  }

  Fortune copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? fortuneText,
    bool? isFavorite,
    DateTime? createdAt,
    int? loveRating,
    int? careerRating,
    int? healthRating,
    int? wealthRating,
  }) {
    return Fortune(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      fortuneText: fortuneText ?? this.fortuneText,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      loveRating: loveRating ?? this.loveRating,
      careerRating: careerRating ?? this.careerRating,
      healthRating: healthRating ?? this.healthRating,
      wealthRating: wealthRating ?? this.wealthRating,
    );
  }
}
