import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucky/providers/user_provider.dart';
import 'package:lucky/utils/constants.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';

class MeritScreen extends StatefulWidget {
  const MeritScreen({super.key});

  @override
  State<MeritScreen> createState() => _MeritScreenState();
}

class _MeritScreenState extends State<MeritScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _canTap = true;
  int _tapCount = 0;
  int _randomMeritPoints = 0;
  bool _hasRandomMeritToday = false;
  List<Map<String, dynamic>> _reflectionQuestions = [];
  int _selectedQuestionIndex = 0;
  final TextEditingController _answerController = TextEditingController();
  bool _isSubmitting = false;

  // 添加+1动画控制器
  late AnimationController _plusOneController;
  late Animation<double> _plusOneOpacity;
  late Animation<double> _plusOnePosition;
  bool _showPlusOne = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 初始化+1动画控制器
    _plusOneController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _plusOneOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _plusOneController,
        curve: const Interval(0.5, 1.0),
      ),
    );

    _plusOnePosition = Tween<double>(begin: 0.0, end: -30.0).animate(
      CurvedAnimation(parent: _plusOneController, curve: Curves.easeOut),
    );

    _plusOneController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showPlusOne = false;
        });
        _plusOneController.reset();
      }
    });

    // 生成反思问题（这是同步操作，可以保留）
    _generateReflectionQuestions();

    // 将异步操作移到addPostFrameCallback中
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTapCount();
      _checkRandomMerit();
    });
  }

  Future<void> _loadTapCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final tapCountKey = 'tap_count_$today';

    setState(() {
      _tapCount = prefs.getInt(tapCountKey) ?? 0;
    });
  }

  Future<void> _saveTapCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final tapCountKey = 'tap_count_$today';

    await prefs.setInt(tapCountKey, _tapCount);
  }

  Future<void> _checkRandomMerit() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final randomMeritKey = 'random_merit_$today';

    if (prefs.containsKey(randomMeritKey)) {
      setState(() {
        _hasRandomMeritToday = true;
        _randomMeritPoints = prefs.getInt(randomMeritKey) ?? 0;
      });
    }
  }

  Future<void> _generateRandomMerit() async {
    if (_hasRandomMeritToday) return;

    final random = Random();
    final points = random.nextInt(37); // 0-36

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.updateMeritPoints(points);

    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final randomMeritKey = 'random_merit_$today';

    await prefs.setInt(randomMeritKey, points);

    setState(() {
      _hasRandomMeritToday = true;
      _randomMeritPoints = points;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('恭喜获得随机功德 +$points')));
  }

  void _generateReflectionQuestions() {
    // 这里可以调用API生成问题，但为了简化，我们使用预设问题
    _reflectionQuestions = [
      {'question': '今天你做了哪些善事？', 'category': '善行'},
      {'question': '今天你的学习或工作中有什么收获？', 'category': '学习工作'},
      {'question': '今天你与家人或朋友的相处如何？', 'category': '人际关系'},
      {'question': '今天有什么让你感到快乐的事情？', 'category': '情绪'},
      {'question': '今天你有什么需要改进的地方？', 'category': '自省'},
    ];

    // 随机选择一个问题
    _selectedQuestionIndex = Random().nextInt(_reflectionQuestions.length);
  }

  Future<void> _submitReflection() async {
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入您的回答')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // 根据回答长度和质量计算功德值（简化版）
    final answerLength = _answerController.text.trim().length;
    int meritPoints = min(36, max(1, answerLength ~/ 10));

    // 保存回答到本地
    await _saveReflection(
      _reflectionQuestions[_selectedQuestionIndex]['question'],
      _reflectionQuestions[_selectedQuestionIndex]['category'],
      _answerController.text.trim(),
      meritPoints,
    );

    // 更新功德值
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.updateMeritPoints(meritPoints);

    setState(() {
      _isSubmitting = false;
    });

    // 清空输入框并生成新问题
    _answerController.clear();
    _generateReflectionQuestions();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('感谢您的自省，获得功德 +$meritPoints')));
  }

  Future<void> _saveReflection(
    String question,
    String category,
    String answer,
    int meritPoints,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 获取已有的反思记录
    final reflectionsJson = prefs.getString('reflections') ?? '[]';
    final reflections = List<Map<String, dynamic>>.from(
      jsonDecode(reflectionsJson),
    );

    // 添加新记录
    reflections.add({
      'date': today,
      'question': question,
      'category': category,
      'answer': answer,
      'meritPoints': meritPoints,
    });

    // 保存更新后的记录
    await prefs.setString('reflections', jsonEncode(reflections));
  }

  Future<void> _onWoodenFishTap() async {
    if (!_canTap || _tapCount >= AppConstants.maxTapsPerDay) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _canTap = false;
    });

    await _animationController.forward();
    await _animationController.reverse();

    if (!mounted) return;

    await userProvider.updateMeritPoints(AppConstants.meritPointsPerTap);

    if (!mounted) return;

    setState(() {
      _tapCount++;
      _canTap = true;
      _showPlusOne = true;
    });

    // 启动+1动画
    _plusOneController.forward();

    // 保存敲击次数
    _saveTapCount();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _plusOneController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('积德修行'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 功德值显示
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Theme.of(context).colorScheme.primary,
                        size: 36,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '当前功德值',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${userProvider.meritPoints}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 木鱼敲击
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '敲击木鱼',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '每日敲击木鱼可获得功德，上限为108次',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '今日已敲击: $_tapCount/${AppConstants.maxTapsPerDay}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onTap: _onWoodenFishTap,
                                child: ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8D6E63),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(50),
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: SvgPicture.asset(
                                        'assets/images/wooden_fish.svg',
                                        width: 60,
                                        height: 60,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_showPlusOne)
                                AnimatedBuilder(
                                  animation: _plusOneController,
                                  builder: (context, child) {
                                    return Positioned(
                                      top: _plusOnePosition.value,
                                      child: Opacity(
                                        opacity: _plusOneOpacity.value,
                                        child: const Text(
                                          '+1',
                                          style: TextStyle(
                                            color: Color(0xFFE57373),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _tapCount / AppConstants.maxTapsPerDay,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 随机功德
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '随机功德',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '每日可获得一次随机功德（0-36）',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      _hasRandomMeritToday
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '今日已获得随机功德 +$_randomMeritPoints',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                          : Center(
                            child: ElevatedButton(
                              onPressed: _generateRandomMerit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('获取随机功德'),
                            ),
                          ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 自省问答
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '每日自省',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '回答问题进行自省，获得功德（最多36点）',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _reflectionQuestions[_selectedQuestionIndex]['category'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _reflectionQuestions[_selectedQuestionIndex]['question'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _answerController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: '请输入您的回答...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitReflection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text('提交回答'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
