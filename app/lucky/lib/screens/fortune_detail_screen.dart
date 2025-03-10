import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucky/models/fortune_model.dart';
import 'package:lucky/providers/fortune_provider.dart';
import 'package:intl/intl.dart';
import 'package:lucky/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:lucky/services/fortune_service.dart';
import 'package:lucky/models/user_question_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class FortuneDetailScreen extends StatefulWidget {
  const FortuneDetailScreen({super.key});

  @override
  State<FortuneDetailScreen> createState() => _FortuneDetailScreenState();
}

class _FortuneDetailScreenState extends State<FortuneDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _answerController = TextEditingController();
  bool _isSubmitting = false;
  String? _currentQuestion;
  String? _currentCategory;
  late final Map<String, Map<String, List<String>>> _suggestions;
  bool _isLoading = false;
  final Map<String, List<FlSpot>> _fortuneData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _suggestions = {};
    _loadAllSuggestions();
    _generateFortuneData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSuggestions() async {
    setState(() => _isLoading = true);
    try {
      final categories = ['love', 'career', 'health', 'wealth'];
      for (final category in categories) {
        final suggestions = await FortuneService.generateSuggestions(category);
        setState(() {
          _suggestions[category] = suggestions;
        });
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('加载建议失败，请重试')));
      }
    }
  }

  void _generateFortuneData() {
    final random = Random(DateTime.now().day);

    for (final category in ['love', 'career', 'health', 'wealth']) {
      final List<FlSpot> spots = [];

      for (int i = 0; i < 30; i++) {
        final baseValue = 3.0;
        final dayFactor = sin(i * 0.2) * 0.8;
        final randomFactor = random.nextDouble() * 0.4 - 0.2;
        final value = (baseValue + dayFactor + randomFactor).clamp(1.0, 5.0);
        spots.add(FlSpot(i.toDouble(), double.parse(value.toStringAsFixed(1))));
      }

      final lastValue = spots.last.y;
      for (int i = 0; i < 5; i++) {
        final prediction = (lastValue + (random.nextDouble() * 0.4 - 0.2))
            .clamp(1.0, 5.0);
        spots.add(
          FlSpot(
            (30 + i).toDouble(),
            double.parse(prediction.toStringAsFixed(1)),
          ),
        );
      }

      _fortuneData[category] = spots;
    }
  }

  Future<void> _generateQuestion(String category) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentCategory = category;
    });

    try {
      final question = await FortuneService.generateRandomQuestion(category);
      if (mounted) {
        setState(() {
          _currentQuestion = question;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('生成问题失败: ${e.toString()}')));
      }
    }
  }

  Future<void> _submitAnswer() async {
    if (_currentQuestion == null || _currentCategory == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final question = UserQuestion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      question: _currentQuestion!,
      answer: _answerController.text,
      category: _currentCategory!,
      createdAt: DateTime.now(),
    );

    await userProvider.addQuestion(question);
    _answerController.clear();
    setState(() {
      _currentQuestion = null;
      _currentCategory = null;
    });
  }

  // 保存用户对运势的反馈
  Future<void> _saveUserFeedback(
    String category,
    String question,
    String answer,
  ) async {
    if (answer.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入您的回答')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 获取已有的反馈记录
      final feedbacksJson = prefs.getString('fortune_feedbacks') ?? '[]';
      final feedbacks = List<Map<String, dynamic>>.from(
        jsonDecode(feedbacksJson),
      );

      // 添加新记录
      feedbacks.add({
        'date': today,
        'category': category,
        'question': question,
        'answer': answer,
      });

      // 保存更新后的记录
      await prefs.setString('fortune_feedbacks', jsonEncode(feedbacks));

      _answerController.clear();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('感谢您的反馈，已保存')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // 构建星级评分显示
  Widget _buildRatingStars(int rating, Color color) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: index < rating ? color : Colors.grey[300],
          size: 24,
        );
      }),
    );
  }

  // 构建反馈问题卡片
  Widget _buildFeedbackCard(String category, String question) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '反馈问题',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _answerController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '请输入您的回答...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isSubmitting
                        ? null
                        : () => _saveUserFeedback(
                          category,
                          question,
                          _answerController.text,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
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
                        : const Text('提交反馈'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建综合页面
  Widget _buildOverviewTab(Fortune fortune) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 运势总览
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '今日运势总览',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          fortune.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: fortune.isFavorite ? Colors.red : null,
                        ),
                        onPressed: () {
                          final fortuneProvider = Provider.of<FortuneProvider>(
                            context,
                            listen: false,
                          );
                          fortuneProvider.toggleFavorite();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fortune.fortuneText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 运势曲线
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
                    '运势趋势',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCombinedFortuneCurve(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem('爱情', const Color(0xFFE57373)),
                      _buildLegendItem('事业', const Color(0xFF81C784)),
                      _buildLegendItem('健康', const Color(0xFF64B5F6)),
                      _buildLegendItem('财运', const Color(0xFFFFB74D)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 四个方面的运势评分
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
                    '运势评分',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 爱情运势
                  Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: Text(
                          '爱情运势',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildRatingStars(fortune.loveRating, Colors.pink),
                      const Spacer(),
                      Text(
                        '${fortune.loveRating}/5',
                        style: const TextStyle(
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 事业运势
                  Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: Text(
                          '事业运势',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildRatingStars(fortune.careerRating, Colors.blue),
                      const Spacer(),
                      Text(
                        '${fortune.careerRating}/5',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 健康运势
                  Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: Text(
                          '健康运势',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildRatingStars(fortune.healthRating, Colors.green),
                      const Spacer(),
                      Text(
                        '${fortune.healthRating}/5',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 财运
                  Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: Text(
                          '财运',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildRatingStars(fortune.wealthRating, Colors.amber),
                      const Spacer(),
                      Text(
                        '${fortune.wealthRating}/5',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 运势建议
          _buildSuggestionsCard('love', '爱情运势'),
          _buildSuggestionsCard('career', '事业运势'),
          _buildSuggestionsCard('health', '健康运势'),
          _buildSuggestionsCard('wealth', '财运运势'),

          // 随机问题
          if (_currentQuestion != null)
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('补充信息', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text(_currentQuestion!),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _answerController,
                      decoration: const InputDecoration(
                        hintText: '请输入你的回答',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitAnswer,
                      child: const Text('提交'),
                    ),
                  ],
                ),
              ),
            ),

          // 生成问题按钮
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuestionButton('love', '爱情'),
                _buildQuestionButton('career', '事业'),
                _buildQuestionButton('health', '健康'),
                _buildQuestionButton('wealth', '财运'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoveTab(Fortune fortune) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 爱情运势评分
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
                    '爱情运势评分',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildRatingStars(fortune.loveRating, Colors.pink),
                      const Spacer(),
                      Text(
                        '${fortune.loveRating}/5',
                        style: const TextStyle(
                          color: Colors.pink,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 爱情运势曲线
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
                    '爱情运势趋势',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCombinedFortuneCurve(singleCategory: 'love'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_buildLegendItem('爱情', const Color(0xFFE57373))],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 爱情运势建议
          _buildSuggestionsCard('love', '爱情运势建议'),

          // 随机问题
          if (_currentQuestion != null && _currentCategory == 'love')
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('补充信息', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text(_currentQuestion!),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _answerController,
                      decoration: const InputDecoration(
                        hintText: '请输入你的回答',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitAnswer,
                      child: const Text('提交'),
                    ),
                  ],
                ),
              ),
            ),

          // 生成问题按钮
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildQuestionButton('love', '生成爱情问题')],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerTab(Fortune fortune) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 事业运势评分
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
                    '事业运势评分',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildRatingStars(fortune.careerRating, Colors.blue),
                      const Spacer(),
                      Text(
                        '${fortune.careerRating}/5',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 事业运势曲线
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
                    '事业运势趋势',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCombinedFortuneCurve(singleCategory: 'career'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_buildLegendItem('事业', const Color(0xFF81C784))],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 事业运势建议
          _buildSuggestionsCard('career', '事业运势建议'),

          // 随机问题
          if (_currentQuestion != null && _currentCategory == 'career')
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('补充信息', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text(_currentQuestion!),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _answerController,
                      decoration: const InputDecoration(
                        hintText: '请输入你的回答',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitAnswer,
                      child: const Text('提交'),
                    ),
                  ],
                ),
              ),
            ),

          // 生成问题按钮
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildQuestionButton('career', '生成事业问题')],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTab(Fortune fortune) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 健康运势评分
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
                    '健康运势评分',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildRatingStars(fortune.healthRating, Colors.green),
                      const Spacer(),
                      Text(
                        '${fortune.healthRating}/5',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 健康运势曲线
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
                    '健康运势趋势',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCombinedFortuneCurve(singleCategory: 'health'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_buildLegendItem('健康', const Color(0xFF64B5F6))],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 健康运势建议
          _buildSuggestionsCard('health', '健康运势建议'),

          // 随机问题
          if (_currentQuestion != null && _currentCategory == 'health')
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('补充信息', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text(_currentQuestion!),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _answerController,
                      decoration: const InputDecoration(
                        hintText: '请输入你的回答',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitAnswer,
                      child: const Text('提交'),
                    ),
                  ],
                ),
              ),
            ),

          // 生成问题按钮
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildQuestionButton('health', '生成健康问题')],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWealthTab(Fortune fortune) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 财运评分
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
                    '财运评分',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildRatingStars(fortune.wealthRating, Colors.amber),
                      const Spacer(),
                      Text(
                        '${fortune.wealthRating}/5',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 财运曲线
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
                    '财运趋势',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCombinedFortuneCurve(singleCategory: 'wealth'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_buildLegendItem('财运', const Color(0xFFFFB74D))],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 财运建议
          _buildSuggestionsCard('wealth', '财运建议'),

          // 随机问题
          if (_currentQuestion != null && _currentCategory == 'wealth')
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('补充信息', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text(_currentQuestion!),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _answerController,
                      decoration: const InputDecoration(
                        hintText: '请输入你的回答',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitAnswer,
                      child: const Text('提交'),
                    ),
                  ],
                ),
              ),
            ),

          // 生成问题按钮
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildQuestionButton('wealth', '生成财运问题')],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedFortuneCurve({String? singleCategory}) {
    List<LineChartBarData> getVisibleLines() {
      if (singleCategory == null) {
        return [
          LineChartBarData(
            spots: _fortuneData['love'] ?? [],
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFFE57373),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: _fortuneData['career'] ?? [],
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF81C784),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: _fortuneData['health'] ?? [],
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF64B5F6),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: _fortuneData['wealth'] ?? [],
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFFFFB74D),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ];
      }

      return [
        LineChartBarData(
          spots: _fortuneData[singleCategory] ?? [],
          isCurved: true,
          curveSmoothness: 0.35,
          color: _getCategoryColor(singleCategory),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ];
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 5,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 0.5,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.now().subtract(
                    Duration(days: 30 - value.toInt()),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: getVisibleLines(),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.black.withOpacity(0.8),
              tooltipRoundedRadius: 8,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final date = DateTime.now().subtract(
                    Duration(days: 30 - touchedSpot.x.toInt()),
                  );
                  final dateStr = DateFormat('MM/dd').format(date);
                  final valueStr = touchedSpot.y.toStringAsFixed(1);

                  return LineTooltipItem(
                    '$dateStr\n$valueStr',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator: (
              LineChartBarData barData,
              List<int> spotIndexes,
            ) {
              return spotIndexes.map((spotIndex) {
                return TouchedSpotIndicatorData(
                  FlLine(color: Colors.grey, strokeWidth: 1, dashArray: [5, 5]),
                  FlDotData(
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: barData.color ?? Colors.grey,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(String category, String title) {
    final suggestions = _suggestions[category] ?? {};
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildSuggestionSection('宜', suggestions['宜'] ?? []),
            const SizedBox(height: 16),
            _buildSuggestionSection('忌', suggestions['忌'] ?? []),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionSection(String title, List<String> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: title == '宜' ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        ...suggestions.map(
          (suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  title == '宜' ? Icons.check_circle : Icons.cancel,
                  color: title == '宜' ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(suggestion)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionButton(String category, String label) {
    final bool isLoading = _isLoading && _currentCategory == category;

    return ElevatedButton(
      onPressed: _isLoading ? null : () => _generateQuestion(category),
      style: ElevatedButton.styleFrom(
        backgroundColor: _getCategoryColor(category),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[400],
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child:
          isLoading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : Text(label),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'love':
        return const Color(0xFFE57373);
      case 'career':
        return const Color(0xFF81C784);
      case 'health':
        return const Color(0xFF64B5F6);
      case 'wealth':
        return const Color(0xFFFFB74D);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fortuneProvider = Provider.of<FortuneProvider>(context);

    if (fortuneProvider.todayFortune == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('运势详情'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('暂无运势数据，请先生成今日运势')),
      );
    }

    final fortune = fortuneProvider.todayFortune!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('运势详情'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '综合'),
            Tab(text: '爱情'),
            Tab(text: '事业'),
            Tab(text: '健康'),
            Tab(text: '财运'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(fortune),
          _buildLoveTab(fortune),
          _buildCareerTab(fortune),
          _buildHealthTab(fortune),
          _buildWealthTab(fortune),
        ],
      ),
    );
  }
}
