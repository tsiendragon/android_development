/// Version information for the Lucky app
class AppVersion {
  /// The current version of the app
  static const String version = '1.4.0';

  /// The build number of the app
  static const int buildNumber = 5;

  /// Release date of this version
  static const String releaseDate = '2025-06-20';

  /// Version history with notable changes
  static const List<Map<String, String>> versionHistory = [
    {
      'version': '1.0.0',
      'date': '2025-02-15',
      'changes': '初始版本发布，包含基础功能：用户登录、个人信息设置、运势生成、功德值累积',
    },
    {
      'version': '1.1.0',
      'date': '2025-03-10',
      'changes': '增加四个方面运势评分、调整UI布局、优化用户体验',
    },
    {
      'version': '1.2.0',
      'date': '2025-04-20',
      'changes': '修复OpenAI API返回的运势详情显示问题、优化刷新运势功能、增加API调用日志',
    },
    {
      'version': '1.3.0',
      'date': '2025-05-15',
      'changes': '新增敲击木鱼+1效果、优化主页运势展示、新增积德页面、增加历史信息记录功能',
    },
    {
      'version': '1.4.0',
      'date': '2025-06-20',
      'changes': '优化UI布局：新增运势曲线展示、完善个人中心信息、优化积德页面交互、增加运势建议功能',
    },
  ];
}
