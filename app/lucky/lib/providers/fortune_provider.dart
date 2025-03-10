import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucky/models/fortune_model.dart';
import 'package:lucky/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:lunar/lunar.dart';
import 'package:http/http.dart' as http;
import 'package:lucky/providers/api_key_provider.dart';

class FortuneProvider extends ChangeNotifier {
  Fortune? _todayFortune;
  bool _isLoading = false;
  String? _error;

  Fortune? get todayFortune => _todayFortune;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Reference to the ApiKeyProvider
  ApiKeyProvider? _apiKeyProvider;

  // Set the ApiKeyProvider reference
  void setApiKeyProvider(ApiKeyProvider provider) {
    _apiKeyProvider = provider;
  }

  // Check if today's fortune is already generated
  Future<bool> checkTodayFortune(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final fortuneKey = 'fortune_${userId}_$today';

      final fortuneData = prefs.getString(fortuneKey);
      if (fortuneData != null) {
        _todayFortune = Fortune.fromJson(json.decode(fortuneData));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking today fortune: $e');
      }
      return false;
    }
  }

  // Generate today's fortune
  Future<bool> generateTodayFortune(User user) async {
    try {
      _isLoading = true;
      notifyListeners();

      final today = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(today);

      if (kDebugMode) {
        print('Generating fortune for user: ${user.name} on $todayStr');
      }

      // Always generate a new fortune when explicitly requested
      // (removed the check for existing fortune to allow refresh)

      // Calculate Chinese zodiac
      final lunar = Lunar.fromDate(user.birthDate);
      final chineseZodiac = _getChineseZodiac(lunar.getYearZhi());
      final heavenlyStem = lunar.getYearGan(); // 天干
      final earthlyBranch = lunar.getYearZhi(); // 地支

      // Generate fortune
      Map<String, dynamic> fortuneResult;

      // Check if API key is available
      final apiKeyProvider = _apiKeyProvider;
      if (apiKeyProvider != null && apiKeyProvider.hasApiKey) {
        // Use OpenAI API to generate fortune
        try {
          fortuneResult = await _generateOpenAIFortune(
            user.name,
            chineseZodiac,
            heavenlyStem,
            earthlyBranch,
            user.meritPoints,
            apiKeyProvider.openAiApiKey!,
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error generating fortune with OpenAI: $e');
          }
          // Fallback to mock fortune if API call fails
          fortuneResult = _generateMockFortuneWithRatings(
            user.name,
            chineseZodiac,
            heavenlyStem,
            earthlyBranch,
            user.meritPoints,
          );
        }
      } else {
        // Use mock fortune generation
        fortuneResult = _generateMockFortuneWithRatings(
          user.name,
          chineseZodiac,
          heavenlyStem,
          earthlyBranch,
          user.meritPoints,
        );
      }

      // Create and save the fortune
      final fortune = Fortune(
        id: 'fortune_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.id,
        date: today,
        fortuneText: fortuneResult['text'],
        createdAt: DateTime.now(),
        loveRating: fortuneResult['loveRating'],
        careerRating: fortuneResult['careerRating'],
        healthRating: fortuneResult['healthRating'],
        wealthRating: fortuneResult['wealthRating'],
        thingsToDo: List<String>.from(fortuneResult['thingsToDo'] ?? []),
        thingsToAvoid: List<String>.from(fortuneResult['thingsToAvoid'] ?? []),
      );

      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      final fortuneKey = 'fortune_${user.id}_$todayStr';
      await prefs.setString(fortuneKey, jsonEncode(fortune.toJson()));

      if (kDebugMode) {
        print('Fortune saved successfully for $todayStr');
        print('Fortune text: ${fortune.fortuneText}');
        print(
          'Ratings: Love=${fortune.loveRating}, Career=${fortune.careerRating}, Health=${fortune.healthRating}, Wealth=${fortune.wealthRating}',
        );
        print('Things to do: ${fortune.thingsToDo}');
        print('Things to avoid: ${fortune.thingsToAvoid}');
      }

      _todayFortune = fortune;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating fortune: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      _error = 'Error generating fortune: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Generate fortune using OpenAI API
  Future<Map<String, dynamic>> _generateOpenAIFortune(
    String name,
    String zodiac,
    String heavenlyStem,
    String earthlyBranch,
    int meritPoints,
    String apiKey,
  ) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final prompt = '''
    作为一位精通中国传统命理学的大师，请根据以下信息为用户生成今日运势预测：

    用户姓名: $name
    生肖: $zodiac
    天干: $heavenlyStem
    地支: $earthlyBranch
    功德值: $meritPoints (功德值越高，运势越好)

    请提供以下内容：
    1. 今日运势总体评价（详细描述今日的整体运势，包括吉凶祸福）
    2. 爱情运势评分（1-5分）和详细解读
    3. 事业运势评分（1-5分）和详细解读
    4. 健康运势评分（1-5分）和详细解读
    5. 财运评分（1-5分）和详细解读
    6. 今日宜做事项（至少3条，具体可行的建议，需要积极向上，偶尔可以加一些心灵鸡汤）
    7. 今日忌做事项（至少3条，具体可行的建议，需要积极向上）
    8. 提升运势的建议（具体可行的建议，包括穿着颜色、行为等）

    请使用JSON格式返回，格式如下：
    {
      "text": "运势预测文字...",
      "loveRating": 评分,
      "careerRating": 评分,
      "healthRating": 评分,
      "wealthRating": 评分,
      "thingsToDo": ["宜做事项1", "宜做事项2", "宜做事项3"],
      "thingsToAvoid": ["忌做事项1", "忌做事项2", "忌做事项3"]
    }

    只返回JSON格式，不要有其他内容。确保返回的JSON格式正确且可解析。
    ''';

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  '你是一位精通中国传统命理学的大师，擅长根据生辰八字分析运势。你的预测应该详细、具体，并且根据用户的功德值给予相应的运势加成。功德值越高，运势应该越好。',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Raw response: ${utf8.decode(response.bodyBytes)}');
        }

        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final content = responseData['choices'][0]['message']['content'];

        if (kDebugMode) {
          print('OpenAI API Response received:');
          print(content);
        }

        // Parse the JSON response
        try {
          final fortuneData = jsonDecode(content);
          // Extract things to do and avoid
          List<String> thingsToDo = [];
          if (fortuneData['thingsToDo'] != null) {
            if (fortuneData['thingsToDo'] is List) {
              thingsToDo = List<String>.from(fortuneData['thingsToDo']);
            } else if (fortuneData['thingsToDo'] is String) {
              thingsToDo = [fortuneData['thingsToDo']];
            }
          }

          if (kDebugMode) {
            print('Parsed thingsToDo: $thingsToDo');
          }

          List<String> thingsToAvoid = [];
          if (fortuneData['thingsToAvoid'] != null) {
            if (fortuneData['thingsToAvoid'] is List) {
              thingsToAvoid = List<String>.from(fortuneData['thingsToAvoid']);
            } else if (fortuneData['thingsToAvoid'] is String) {
              thingsToAvoid = [fortuneData['thingsToAvoid']];
            }
          }

          if (kDebugMode) {
            print('Parsed thingsToAvoid: $thingsToAvoid');
          }

          return {
            'text': fortuneData['text'] ?? '无法获取运势信息',
            'loveRating': _ensureRatingRange(fortuneData['loveRating']),
            'careerRating': _ensureRatingRange(fortuneData['careerRating']),
            'healthRating': _ensureRatingRange(fortuneData['healthRating']),
            'wealthRating': _ensureRatingRange(fortuneData['wealthRating']),
            'thingsToDo': thingsToDo,
            'thingsToAvoid': thingsToAvoid,
          };
        } catch (e) {
          if (kDebugMode) {
            print('Failed to parse OpenAI response: $e');
            print('Raw content: $content');
          }
          throw Exception('Failed to parse OpenAI response');
        }
      } else {
        if (kDebugMode) {
          print(
            'OpenAI API error: ${response.statusCode} ${utf8.decode(response.bodyBytes)}',
          );
        }
        throw Exception('OpenAI API error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error calling OpenAI API: $e');
      }
      throw Exception('Error calling OpenAI API');
    }
  }

  // Ensure rating is within valid range (1-5)
  int _ensureRatingRange(dynamic rating) {
    int ratingInt;
    if (rating is String) {
      try {
        ratingInt = int.parse(rating);
      } catch (e) {
        // If parsing fails, try to extract the first digit
        final match = RegExp(r'\d').firstMatch(rating);
        if (match != null) {
          ratingInt = int.parse(match.group(0)!);
        } else {
          ratingInt = 3;
        }
      }
    } else if (rating is int) {
      ratingInt = rating;
    } else if (rating is double) {
      ratingInt = rating.round();
    } else {
      ratingInt = 3;
    }

    return max(1, min(5, ratingInt));
  }

  // Extract rating from text using regex
  int? _extractRating(String text, String aspect) {
    // Try different patterns to extract rating
    final patterns = [
      '$aspect.*?(\\d)[^\\d]*分',
      '$aspect.*?评分.*?(\\d)',
      '$aspect.*?(\\d)\\s*星',
      '$aspect.*?(\\d)\\s*/\\s*5',
    ];

    for (final pattern in patterns) {
      final regex = RegExp(pattern);
      final match = regex.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        return int.tryParse(match.group(1)!);
      }
    }

    // If no match found, look for any digit near the aspect name
    final nearDigitRegex = RegExp('$aspect[^\\d]{0,30}(\\d)');
    final nearMatch = nearDigitRegex.firstMatch(text);
    if (nearMatch != null && nearMatch.groupCount >= 1) {
      return int.tryParse(nearMatch.group(1)!);
    }

    return null;
  }

  // Extract list items from text
  List<String>? _extractListItems(String text, String keyword) {
    // Try to find sections with the keyword (宜/忌)
    final sectionRegex = RegExp('$keyword[^\\n]*\\n((?:[^\\n]+\\n)+)');
    final sectionMatch = sectionRegex.firstMatch(text);

    if (sectionMatch != null && sectionMatch.groupCount >= 1) {
      final sectionText = sectionMatch.group(1)!;

      // Extract bullet points or numbered items
      final items = <String>[];

      // Try different item patterns
      final bulletRegex = RegExp(r'(?:•|\*|-|\d+\.|\(\d+\))\s*([^\n]+)');

      final bulletMatches = bulletRegex.allMatches(sectionText);

      if (bulletMatches.isNotEmpty) {
        for (final match in bulletMatches) {
          if (match.groupCount >= 1) {
            final item = match.group(1)!.trim();
            if (item.isNotEmpty) {
              items.add(item);
            }
          }
        }
      } else {
        // If no bullet points found, split by newlines
        final lines = sectionText.split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) {
            items.add(trimmed);
          }
        }
      }

      return items;
    }

    // If no section found, try to find individual items
    final itemRegex = RegExp('$keyword[^：]*：([^\\n]+)');
    final itemMatch = itemRegex.firstMatch(text);

    if (itemMatch != null && itemMatch.groupCount >= 1) {
      final itemsText = itemMatch.group(1)!;
      final items = itemsText.split('、').map((e) => e.trim()).toList();
      return items.where((item) => item.isNotEmpty).toList();
    }

    return null;
  }

  // Helper method to get rating description based on rating value
  String _getRatingDescription(String aspect, int rating) {
    switch (rating) {
      case 0:
        return '$aspect运势极差，需谨慎行事';
      case 1:
        return '$aspect运势不佳，宜低调行事';
      case 2:
        return '$aspect运势一般，保持平常心';
      case 3:
        return '$aspect运势尚可，有小幸运';
      case 4:
        return '$aspect运势良好，可把握机会';
      case 5:
        return '$aspect运势极佳，大吉大利';
      default:
        return '$aspect运势一般';
    }
  }

  // Generate mock fortune with ratings for all aspects
  Map<String, dynamic> _generateMockFortuneWithRatings(
    String name,
    String zodiac,
    String heavenlyStem,
    String earthlyBranch,
    int meritPoints,
  ) {
    final fortunes = [
      '今天整体运势不错，工作上可能会有意外收获。建议多关注人际关系，可能会有贵人相助。财运方面平稳，适合理财规划。',
      '今日运势平平，工作中需要更加专注，避免分心。人际关系方面可能会有小摩擦，建议保持冷静。财运一般，不宜大额支出。',
      '今天运势较好，工作效率高，创意思维活跃。人际关系融洽，是社交的好时机。财运上可能有小惊喜，但不宜冲动消费。',
      '今日运势起伏较大，工作中可能遇到挑战，需要耐心应对。人际关系需要多加沟通，避免误会。财运一般，建议量入为出。',
      '今天运势良好，工作上会得到领导或同事的认可。人际关系和谐，适合拓展社交圈。财运方面有上升趋势，可以考虑适当投资。',
    ];

    // 根据功德值调整运势好坏
    int fortuneIndex = 0;
    if (meritPoints > 100) {
      fortuneIndex = 4; // 最好的运势
    } else if (meritPoints > 50) {
      fortuneIndex = 2;
    } else if (meritPoints > 20) {
      fortuneIndex = 0;
    } else {
      fortuneIndex = 1; // 较差的运势
    }

    // 生成四个方面的星级评分 (0-5星)
    // 基于功德值、生肖和八字生成随机但有规律的评分
    final random = Random().nextInt(100);
    final baseRating = (meritPoints / 20).clamp(1.0, 5.0).floor();

    // 使用不同的计算方式，让各方面评分有所区别
    int loveRating =
        (baseRating + (zodiac.codeUnitAt(0) % 3) - 1).clamp(0, 5).toInt();
    int careerRating =
        (baseRating + (heavenlyStem.codeUnitAt(0) % 3) - 1).clamp(0, 5).toInt();
    int healthRating = (baseRating + (random % 3) - 1).clamp(0, 5).toInt();
    int wealthRating =
        (baseRating + (earthlyBranch.codeUnitAt(0) % 3) - 1)
            .clamp(0, 5)
            .toInt();

    // 生成宜做和忌做事项
    final thingsToDo = _generateThingsToDo();
    final thingsToAvoid = _generateThingsToAvoid();

    // 添加个性化元素和四个方面的运势描述
    String fortuneText = '''尊敬的$name，

您的生肖为$zodiac，八字天干为$heavenlyStem，地支为$earthlyBranch。根据您的八字和当前功德值($meritPoints)分析：

${fortunes[fortuneIndex]}

爱情运势：${_getRatingDescription('爱情', loveRating)}
事业运势：${_getRatingDescription('事业', careerRating)}
健康运势：${_getRatingDescription('健康', healthRating)}
财运：${_getRatingDescription('财运', wealthRating)}

今日宜做：
• ${thingsToDo[0]}
• ${thingsToDo[1]}
• ${thingsToDo[2]}

今日忌做：
• ${thingsToAvoid[0]}
• ${thingsToAvoid[1]}
• ${thingsToAvoid[2]}

提升今日运势的建议：多行善事，积累功德，保持平和心态。
''';

    return {
      'text': fortuneText,
      'loveRating': loveRating,
      'careerRating': careerRating,
      'healthRating': healthRating,
      'wealthRating': wealthRating,
      'thingsToDo': thingsToDo,
      'thingsToAvoid': thingsToAvoid,
    };
  }

  // Get Chinese zodiac based on earthly branch
  String _getChineseZodiac(String earthlyBranch) {
    switch (earthlyBranch) {
      case '子':
        return '鼠';
      case '丑':
        return '牛';
      case '寅':
        return '虎';
      case '卯':
        return '兔';
      case '辰':
        return '龙';
      case '巳':
        return '蛇';
      case '午':
        return '马';
      case '未':
        return '羊';
      case '申':
        return '猴';
      case '酉':
        return '鸡';
      case '戌':
        return '狗';
      case '亥':
        return '猪';
      default:
        return '未知';
    }
  }

  // Generate things to do for mock fortune
  List<String> _generateThingsToDo() {
    final options = [
      '早起锻炼，增强体质',
      '与家人共进早餐，增进感情',
      '整理工作计划，提高效率',
      '阅读一本好书，充实自己',
      '联系老朋友，维护人际关系',
      '尝试新的烹饪方式，增添生活乐趣',
      '冥想放松，平静心情',
      '参加户外活动，亲近自然',
      '学习新技能，拓展视野',
      '做一件善事，积累功德',
      '写日记，反思成长',
      '整理居家环境，提升运势',
      '穿着明亮色彩的衣服，增添活力',
      '尝试新的工作方法，提高效率',
      '与积极向上的人交流，获取正能量',
      '制定未来计划，明确方向',
      '表达感谢，培养感恩之心',
      '分享知识，帮助他人',
      '保持微笑，传递快乐',
      '尝试新的运动方式，增强体质',
    ];

    final random = Random();
    final result = <String>[];
    final indices = <int>{};

    // Select 3 unique items
    while (indices.length < 3) {
      indices.add(random.nextInt(options.length));
    }

    for (final index in indices) {
      result.add(options[index]);
    }

    return result;
  }

  // Generate things to avoid for mock fortune
  List<String> _generateThingsToAvoid() {
    final options = [
      '熬夜，影响健康',
      '过度消费，影响财运',
      '情绪化决策，影响判断',
      '与人争执，破坏人际关系',
      '拖延工作，影响效率',
      '过度使用电子设备，伤害眼睛',
      '暴饮暴食，影响健康',
      '轻信谣言，误导自己',
      '过度担忧，消耗精力',
      '忽视家人，影响家庭和谐',
      '做重大决定，时机不佳',
      '参与高风险活动，注意安全',
      '穿着暗沉色彩，影响心情',
      '过度批评他人，伤害关系',
      '忽视休息，透支身体',
      '独自决策重要事项，需集思广益',
      '回避问题，延误解决时机',
      '过度自我怀疑，影响信心',
      '忽视细节，造成失误',
      '盲目跟风，失去自我判断',
    ];

    final random = Random();
    final result = <String>[];
    final indices = <int>{};

    // Select 3 unique items
    while (indices.length < 3) {
      indices.add(random.nextInt(options.length));
    }

    for (final index in indices) {
      result.add(options[index]);
    }

    return result;
  }

  // Save fortune to favorites
  Future<bool> toggleFavorite() async {
    if (_todayFortune == null) return false;

    try {
      final updatedFortune = _todayFortune!.copyWith(
        isFavorite: !_todayFortune!.isFavorite,
      );

      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(_todayFortune!.date);
      final fortuneKey = 'fortune_${_todayFortune!.userId}_$today';

      await prefs.setString(fortuneKey, json.encode(updatedFortune.toJson()));

      _todayFortune = updatedFortune;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling favorite: $e');
      }
      return false;
    }
  }

  void clearFortune() {
    _todayFortune = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
