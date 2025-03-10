import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:lucky/models/fortune_model.dart';
import 'package:lucky/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:lunar/lunar.dart';

class FortuneProvider extends ChangeNotifier {
  Fortune? _todayFortune;
  bool _isLoading = false;
  String? _error;
  
  Fortune? get todayFortune => _todayFortune;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
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
  
  // Generate today's fortune using OpenAI API
  Future<bool> generateTodayFortune(User user) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final today = DateTime.now();
      final todayFormatted = DateFormat('yyyy-MM-dd').format(today);
      final fortuneKey = 'fortune_${user.id}_$todayFormatted';
      
      // Convert solar date to lunar date for Chinese zodiac calculations
      final lunar = Lunar.fromDate(user.birthDate);
      final chineseZodiac = _getChineseZodiac(lunar.getYearZhi());
      final heavenlyStem = lunar.getYearGan(); // 天干
      final earthlyBranch = lunar.getYearZhi(); // 地支
      final eightCharacters = '${lunar.getYearGan()}${lunar.getYearZhi()} ${lunar.getMonthGan()}${lunar.getMonthZhi()} ${lunar.getDayGan()}${lunar.getDayZhi()} ${lunar.getTimeGan()}${lunar.getTimeZhi()}';
      
      // Prepare the prompt for OpenAI
      // This will be used when we implement the actual OpenAI API call
      // For now, we're using a mock implementation
      // ignore: unused_local_variable
      final prompt = '''
根据用户的生辰八字信息，生成今日运势预测：
- 用户信息：${user.name}，${user.gender}
- 出生日期：${DateFormat('yyyy-MM-dd').format(user.birthDate)}
- 出生时间：${user.birthTime}
- 出生地点：${user.birthPlace}
- 生肖：$chineseZodiac
- 八字：$eightCharacters
- 功德值：${user.meritPoints}

请生成一段简短的今日（${DateFormat('yyyy年MM月dd日').format(today)}）运势预测，包括整体运势、事业、财运等方面。
''';

      // For MVP, we'll simulate the API call with a mock response
      // In a real app, this would call the OpenAI API
      final fortuneText = _generateMockFortune(
        user.name, 
        chineseZodiac, 
        heavenlyStem,
        earthlyBranch,
        user.meritPoints
      );
      
      // Create and save the fortune
      final fortune = Fortune(
        id: 'fortune_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.id,
        date: today,
        fortuneText: fortuneText,
        createdAt: DateTime.now(),
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(fortuneKey, json.encode(fortune.toJson()));
      
      _todayFortune = fortune;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = '生成运势失败，请稍后再试';
      if (kDebugMode) {
        print('Error generating fortune: $e');
      }
      notifyListeners();
      return false;
    }
  }
  
  // Mock fortune generation for MVP
  String _generateMockFortune(String name, String zodiac, String heavenlyStem, String earthlyBranch, int meritPoints) {
    final fortunes = [
      '今天整体运势不错，工作上可能会有意外收获。建议多关注人际关系，可能会有贵人相助。财运方面平稳，适合理财规划。',
      '今日运势平平，工作中需要更加专注，避免分心。人际关系方面可能会有小摩擦，建议保持冷静。财运一般，不宜大额支出。',
      '今天运势较好，工作效率高，创意思维活跃。人际关系融洽，是社交的好时机。财运上可能有小惊喜，但不宜冲动消费。',
      '今日运势起伏较大，工作中可能遇到挑战，需要耐心应对。人际关系需要多加沟通，避免误会。财运一般，建议量入为出。',
      '今天运势良好，工作上会得到领导或同事的认可。人际关系和谐，适合拓展社交圈。财运方面有上升趋势，可以考虑适当投资。'
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
    
    // 添加个性化元素
    return '''尊敬的$name，
    
您的生肖为$zodiac，八字天干为$heavenlyStem，地支为$earthlyBranch。根据您的八字和当前功德值($meritPoints)分析：

${fortunes[fortuneIndex]}

今日宜：冥想、读书、与朋友聚会
今日忌：冲动消费、争执、熬夜

提升今日运势的建议：多行善事，积累功德，保持平和心态。
''';
  }
  
  // Get Chinese zodiac based on earthly branch
  String _getChineseZodiac(String earthlyBranch) {
    switch (earthlyBranch) {
      case '子': return '鼠';
      case '丑': return '牛';
      case '寅': return '虎';
      case '卯': return '兔';
      case '辰': return '龙';
      case '巳': return '蛇';
      case '午': return '马';
      case '未': return '羊';
      case '申': return '猴';
      case '酉': return '鸡';
      case '戌': return '狗';
      case '亥': return '猪';
      default: return '未知';
    }
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
