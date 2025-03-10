import 'dart:math';
import 'package:lucky/models/fortune_suggestion_model.dart';
import 'package:uuid/uuid.dart';

class FortuneSuggestionService {
  static List<FortuneSuggestion> generateSuggestions({
    required double averageRating,
    required Map<String, double> categoryRatings,
    required DateTime date,
  }) {
    final List<FortuneSuggestion> suggestions = [];
    final random = Random();

    // 根据平均运势生成总体建议
    if (averageRating < 3.0) {
      suggestions.add(
        FortuneSuggestion(
          id: const Uuid().v4(),
          title: '今日运势偏低，建议谨慎行事',
          content: '今天运势不太理想，建议保持低调，避免冒险。可以多做一些积累和准备的工作。',
          category: 'general',
          date: date,
          priority: 5,
        ),
      );
    } else if (averageRating > 4.0) {
      suggestions.add(
        FortuneSuggestion(
          id: const Uuid().v4(),
          title: '今日运势旺盛，把握机会',
          content: '今天运势很好，适合大胆尝试新事物。可以主动出击，把握机会。',
          category: 'general',
          date: date,
          priority: 5,
        ),
      );
    }

    // 根据各分类运势生成具体建议
    categoryRatings.forEach((category, rating) {
      if (rating < 3.0) {
        suggestions.add(_generateLowRatingSuggestion(category, date));
      } else if (rating > 4.0) {
        suggestions.add(_generateHighRatingSuggestion(category, date));
      }
    });

    // 随机添加一些日常建议
    if (random.nextDouble() < 0.3) {
      suggestions.add(_generateRandomSuggestion(date));
    }

    return suggestions;
  }

  static FortuneSuggestion _generateLowRatingSuggestion(
    String category,
    DateTime date,
  ) {
    final Map<String, Map<String, String>> lowRatingSuggestions = {
      'career': {
        'title': '事业运势低迷，建议稳扎稳打',
        'content': '今天事业运势不太理想，建议保持谨慎，避免冒险决策。可以专注于日常工作和积累。',
      },
      'health': {
        'title': '健康运势欠佳，注意休息',
        'content': '今天健康运势较弱，建议多注意休息，避免过度劳累。可以适当运动，保持良好作息。',
      },
      'wealth': {
        'title': '财运不佳，谨慎理财',
        'content': '今天财运不太理想，建议谨慎理财，避免冲动消费。可以多关注理财知识的学习。',
      },
      'love': {
        'title': '感情运势低迷，保持耐心',
        'content': '今天感情运势较弱，建议保持耐心，避免冲动决定。可以多关注自我提升。',
      },
    };

    final suggestion = lowRatingSuggestions[category]!;
    return FortuneSuggestion(
      id: const Uuid().v4(),
      title: suggestion['title']!,
      content: suggestion['content']!,
      category: category,
      date: date,
      priority: 4,
    );
  }

  static FortuneSuggestion _generateHighRatingSuggestion(
    String category,
    DateTime date,
  ) {
    final Map<String, Map<String, String>> highRatingSuggestions = {
      'career': {
        'title': '事业运势旺盛，把握机会',
        'content': '今天事业运势很好，适合大胆尝试新项目。可以主动争取机会，展现才能。',
      },
      'health': {
        'title': '健康运势良好，适合运动',
        'content': '今天健康运势很好，适合进行运动锻炼。可以尝试新的运动项目，增强体质。',
      },
      'wealth': {
        'title': '财运亨通，把握机会',
        'content': '今天财运很好，适合进行理财投资。可以关注市场机会，但也要注意风险控制。',
      },
      'love': {
        'title': '感情运势旺盛，主动出击',
        'content': '今天感情运势很好，适合表达感情。可以主动创造机会，增进感情。',
      },
    };

    final suggestion = highRatingSuggestions[category]!;
    return FortuneSuggestion(
      id: const Uuid().v4(),
      title: suggestion['title']!,
      content: suggestion['content']!,
      category: category,
      date: date,
      priority: 4,
    );
  }

  static FortuneSuggestion _generateRandomSuggestion(DateTime date) {
    final List<Map<String, String>> randomSuggestions = [
      {
        'title': '今日宜静不宜动',
        'content': '今天适合静心思考，避免冲动行事。可以多读书学习，提升自我。',
        'category': 'general',
      },
      {
        'title': '今日宜动不宜静',
        'content': '今天适合外出活动，不要宅在家里。可以参加社交活动，拓展人脉。',
        'category': 'general',
      },
      {
        'title': '今日宜早不宜晚',
        'content': '今天适合早起，把握早晨的黄金时间。可以提前规划，提高效率。',
        'category': 'general',
      },
      {
        'title': '今日宜晚不宜早',
        'content': '今天适合晚睡，可以多思考人生。但要注意作息规律，保持健康。',
        'category': 'general',
      },
    ];

    final random = Random();
    final suggestion =
        randomSuggestions[random.nextInt(randomSuggestions.length)];

    return FortuneSuggestion(
      id: const Uuid().v4(),
      title: suggestion['title']!,
      content: suggestion['content']!,
      category: suggestion['category']!,
      date: date,
      priority: 3,
    );
  }
}
