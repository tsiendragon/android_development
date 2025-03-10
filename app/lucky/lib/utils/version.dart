/// Version information for the Lucky app
class AppVersion {
  /// The current version of the app
  static const String version = '1.1.0';
  
  /// The build number of the app
  static const int buildNumber = 2;
  
  /// Release date of this version
  static const String releaseDate = '2025-03-10';
  
  /// Version history with notable changes
  static const List<Map<String, String>> versionHistory = [
    {
      'version': '1.0.0',
      'date': '2025-02-15',
      'changes': '初始版本发布，包含基础功能：用户登录、个人信息设置、运势生成、功德值累积'
    },
    {
      'version': '1.1.0',
      'date': '2025-03-10',
      'changes': '增加四个方面运势评分、调整UI布局、优化用户体验'
    },
  ];
}
