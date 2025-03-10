class Fortune {
  final String id;
  final String userId;
  final DateTime date;
  final String fortuneText;
  final bool isFavorite;
  final DateTime createdAt;

  // New fields for version 1.1 - ratings for different aspects (0-5 stars)
  final int loveRating; // 爱情运势评分
  final int careerRating; // 事业运势评分
  final int healthRating; // 健康运势评分
  final int wealthRating; // 财运评分

  // New fields for version 1.2 - things to do and avoid to improve fortune
  final List<String> thingsToDo; // 宜做事项
  final List<String> thingsToAvoid; // 忌做事项

  // New fields for version 1.3 - fortune curve data
  final List<FortunePoint> fortuneCurve; // 运势曲线数据点

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
    this.fortuneCurve = const [],
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
      thingsToDo:
          json['thingsToDo'] != null
              ? List<String>.from(json['thingsToDo'])
              : const [],
      thingsToAvoid:
          json['thingsToAvoid'] != null
              ? List<String>.from(json['thingsToAvoid'])
              : const [],
      fortuneCurve:
          json['fortuneCurve'] != null
              ? (json['fortuneCurve'] as List)
                  .map((point) => FortunePoint.fromJson(point))
                  .toList()
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
      'fortuneCurve': fortuneCurve.map((point) => point.toJson()).toList(),
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
    List<String>? thingsToDo,
    List<String>? thingsToAvoid,
    List<FortunePoint>? fortuneCurve,
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
      thingsToDo: thingsToDo ?? this.thingsToDo,
      thingsToAvoid: thingsToAvoid ?? this.thingsToAvoid,
      fortuneCurve: fortuneCurve ?? this.fortuneCurve,
    );
  }
}

class FortunePoint {
  final int hour; // 时辰（0-23）
  final double value; // 运势值（0-5）

  FortunePoint({required this.hour, required this.value});

  factory FortunePoint.fromJson(Map<String, dynamic> json) {
    return FortunePoint(hour: json['hour'], value: json['value'].toDouble());
  }

  Map<String, dynamic> toJson() {
    return {'hour': hour, 'value': value};
  }
}
