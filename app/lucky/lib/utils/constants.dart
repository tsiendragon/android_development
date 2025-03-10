class AppConstants {
  // App info
  static const String appName = '生辰八字运势';
  static const String appVersion = '1.0.0';
  
  // API endpoints
  static const String openAiApiUrl = 'https://api.openai.com/v1/chat/completions';
  
  // Shared preferences keys
  static const String userIdKey = 'userId';
  static const String authTypeKey = 'authType';
  static const String isProfileCompleteKey = 'isProfileComplete';
  
  // Time periods for birth time
  static const Map<String, String> timePeriods = {
    '子时 (23:00-00:59)': '23:00-00:59',
    '丑时 (01:00-02:59)': '01:00-02:59',
    '寅时 (03:00-04:59)': '03:00-04:59',
    '卯时 (05:00-06:59)': '05:00-06:59',
    '辰时 (07:00-08:59)': '07:00-08:59',
    '巳时 (09:00-10:59)': '09:00-10:59',
    '午时 (11:00-12:59)': '11:00-12:59',
    '未时 (13:00-14:59)': '13:00-14:59',
    '申时 (15:00-16:59)': '15:00-16:59',
    '酉时 (17:00-18:59)': '17:00-18:59',
    '戌时 (19:00-20:59)': '19:00-20:59',
    '亥时 (21:00-22:59)': '21:00-22:59',
  };
  
  // Merit points
  static const int meritPointsPerTap = 1;
  static const int maxTapsPerDay = 108;
}
