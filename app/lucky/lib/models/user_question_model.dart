class UserQuestion {
  final String id;
  final String question;
  final String answer;
  final String category; // 'love', 'career', 'health', 'wealth'
  final DateTime createdAt;

  UserQuestion({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserQuestion.fromJson(Map<String, dynamic> json) {
    return UserQuestion(
      id: json['id'],
      question: json['question'],
      answer: json['answer'],
      category: json['category'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
