import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:lucky/models/user_question_model.dart';

class FortuneService {
  static const String _baseUrl = 'YOUR_API_BASE_URL';
  static const String _apiKey = 'YOUR_API_KEY';

  // 临时使用本地生成问题，避免API调用错误
  static Future<String> generateRandomQuestion(String category) async {
    final Map<String, List<String>> questions = {
      'love': [
        '你最近一次心动是什么时候？',
        '你理想中的另一半是什么样的？',
        '你觉得爱情中最重要的是什么？',
        '你有什么难忘的恋爱经历吗？',
        '你会为了爱情放弃什么？',
      ],
      'career': [
        '你最近在工作上遇到了什么挑战？',
        '你理想的工作环境是什么样的？',
        '你职业生涯中最自豪的成就是什么？',
        '你未来的职业规划是什么？',
        '你最想提升哪些职业技能？',
      ],
      'health': [
        '你最近的作息规律吗？',
        '你最喜欢的运动是什么？',
        '你平时如何保持健康的生活方式？',
        '你最近有什么困扰你的健康问题吗？',
        '你觉得保持健康最重要的是什么？',
      ],
      'wealth': [
        '你最近的财务状况如何？',
        '你有什么理财目标吗？',
        '你是如何规划自己的收支的？',
        '你认为理财最重要的原则是什么？',
        '你有什么成功或失败的投资经历吗？',
      ],
    };

    // 模拟网络请求延迟
    await Future.delayed(const Duration(seconds: 1));

    final questionList = questions[category] ?? [];
    if (questionList.isEmpty) {
      throw Exception('Invalid category');
    }

    final random = Random();
    return questionList[random.nextInt(questionList.length)];
  }

  // 临时使用本地生成建议，避免API调用错误
  static Future<Map<String, List<String>>> generateSuggestions(
    String category,
  ) async {
    final Map<String, Map<String, List<String>>> suggestions = {
      'love': {
        '宜': ['与心仪对象共进晚餐', '表达真诚的感情', '参加社交活动'],
        '忌': ['过分计较得失', '陷入无谓的感情纠葛', '对感情过于悲观'],
      },
      'career': {
        '宜': ['主动承担重要任务', '学习新的技能', '与同事多交流'],
        '忌': ['与上级发生冲突', '轻易放弃机会', '工作态度消极'],
      },
      'health': {
        '宜': ['适度运动健身', '保持规律作息', '注意饮食均衡'],
        '忌': ['熬夜伤身体', '暴饮暴食', '久坐不运动'],
      },
      'wealth': {
        '宜': ['合理规划支出', '把握投资机会', '学习理财知识'],
        '忌': ['冲动消费', '高风险投资', '借贷过度'],
      },
    };

    // 模拟网络请求延迟
    await Future.delayed(const Duration(seconds: 1));

    final categorySuggestions = suggestions[category];
    if (categorySuggestions == null) {
      throw Exception('Invalid category');
    }

    return categorySuggestions;
  }

  static String _getPromptForCategory(String category) {
    switch (category) {
      case 'love':
        return '生成一个关于爱情经历的随机问题，比如"你最近一次心动是什么时候？"或"你理想中的另一半是什么样的？"问题要能帮助了解用户的感情经历和期望。';
      case 'career':
        return '生成一个关于事业发展的随机问题，比如"你最近在工作上遇到了什么挑战？"或"你理想的工作环境是什么样的？"问题要能了解用户的工作经历和职业规划。';
      case 'health':
        return '生成一个关于健康状况的随机问题，比如"你最近的作息规律吗？"或"你最喜欢的运动是什么？"问题要能了解用户的生活习惯和健康状况。';
      case 'wealth':
        return '生成一个关于财运的随机问题，比如"你最近的投资收益如何？"或"你理想中的理财方式是什么？"问题要能了解用户的理财习惯和财务目标。';
      default:
        throw Exception('Invalid category');
    }
  }

  static String _getPromptForSuggestions(String category) {
    return '''请为$category运势生成"宜"和"忌"的建议，每个类别3-4条建议。
要求：
1. 建议要诙谐幽默，同时能够激励人心
2. 每个建议不超过20个字
3. 建议要具体可行，避免空泛
4. 可以适当加入一些流行梗或网络用语
5. 建议要积极向上，给人希望

请按照以下格式返回：
宜：
1. 建议1
2. 建议2
3. 建议3

忌：
1. 建议1
2. 建议2
3. 建议3''';
  }

  static Map<String, List<String>> _parseSuggestions(String content) {
    final Map<String, List<String>> result = {'宜': [], '忌': []};

    final lines = content.split('\n');
    String currentSection = '';

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      if (line.startsWith('宜：')) {
        currentSection = '宜';
      } else if (line.startsWith('忌：')) {
        currentSection = '忌';
      } else if (line.trim().startsWith(RegExp(r'^\d+\.'))) {
        final suggestion = line.trim().replaceFirst(RegExp(r'^\d+\.\s*'), '');
        if (suggestion.isNotEmpty) {
          result[currentSection]?.add(suggestion);
        }
      }
    }

    return result;
  }
}
