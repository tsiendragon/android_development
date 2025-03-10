class User {
  final String id;
  final String name;
  final String gender;
  final DateTime birthDate;
  final String birthTime;
  final String birthPlace;
  final int meritPoints;
  final String? avatarUrl;
  final String authProvider; // 'gmail' or 'wechat'

  User({
    required this.id,
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.birthTime,
    required this.birthPlace,
    this.meritPoints = 0,
    this.avatarUrl,
    required this.authProvider,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      gender: json['gender'],
      birthDate: DateTime.parse(json['birthDate']),
      birthTime: json['birthTime'],
      birthPlace: json['birthPlace'],
      meritPoints: json['meritPoints'] ?? 0,
      avatarUrl: json['avatarUrl'],
      authProvider: json['authProvider'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'birthDate': birthDate.toIso8601String(),
      'birthTime': birthTime,
      'birthPlace': birthPlace,
      'meritPoints': meritPoints,
      'avatarUrl': avatarUrl,
      'authProvider': authProvider,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? gender,
    DateTime? birthDate,
    String? birthTime,
    String? birthPlace,
    int? meritPoints,
    String? avatarUrl,
    String? authProvider,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      birthTime: birthTime ?? this.birthTime,
      birthPlace: birthPlace ?? this.birthPlace,
      meritPoints: meritPoints ?? this.meritPoints,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      authProvider: authProvider ?? this.authProvider,
    );
  }
}
