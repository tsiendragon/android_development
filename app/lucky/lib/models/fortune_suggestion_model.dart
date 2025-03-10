class FortuneSuggestion {
  final String id;
  final String title;
  final String content;
  final String category; // 'career', 'health', 'wealth', 'love', 'general'
  final DateTime date;
  final int priority; // 1-5, 5 being highest priority

  FortuneSuggestion({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.date,
    required this.priority,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'date': date.toIso8601String(),
      'priority': priority,
    };
  }

  factory FortuneSuggestion.fromJson(Map<String, dynamic> json) {
    return FortuneSuggestion(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      category: json['category'],
      date: DateTime.parse(json['date']),
      priority: json['priority'],
    );
  }
}
