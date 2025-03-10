import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucky/providers/fortune_provider.dart';
import 'package:lucky/providers/user_provider.dart';
import 'package:lucky/services/fortune_service.dart';
import 'package:lucky/models/user_question_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class FortuneScreen extends StatefulWidget {
  const FortuneScreen({super.key});

  @override
  State<FortuneScreen> createState() => _FortuneScreenState();
}

class _FortuneScreenState extends State<FortuneScreen> {
  final TextEditingController _answerController = TextEditingController();
  String? _currentQuestion;
  String? _currentCategory;
  Map<String, Map<String, List<String>>> _suggestions = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllSuggestions();
  }

  @override
  void dispose() {
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

  Future<void> _generateQuestion(String category) async {
    setState(() {
      _isLoading = true;
      _currentCategory = category;
    });

    try {
      final question = await FortuneService.generateRandomQuestion(category);
      setState(() {
        _currentQuestion = question;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('生成问题失败，请重试')));
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

  Widget _buildCombinedFortuneCurve() {
    final now = DateTime.now();
    final List<FlSpot> loveSpots = [];
    final List<FlSpot> careerSpots = [];
    final List<FlSpot> healthSpots = [];
    final List<FlSpot> wealthSpots = [];

    // 生成过去30天的数据
    for (int i = 0; i < 30; i++) {
      loveSpots.add(FlSpot(i.toDouble(), 2 + (i % 3).toDouble()));
      careerSpots.add(FlSpot(i.toDouble(), 2 + ((i + 1) % 3).toDouble()));
      healthSpots.add(FlSpot(i.toDouble(), 2 + ((i + 2) % 3).toDouble()));
      wealthSpots.add(FlSpot(i.toDouble(), 2 + ((i + 3) % 3).toDouble()));
    }

    // 生成未来5天的预测数据
    for (int i = 0; i < 5; i++) {
      loveSpots.add(FlSpot((30 + i).toDouble(), 2 + (i % 3).toDouble()));
      careerSpots.add(
        FlSpot((30 + i).toDouble(), 2 + ((i + 1) % 3).toDouble()),
      );
      healthSpots.add(
        FlSpot((30 + i).toDouble(), 2 + ((i + 2) % 3).toDouble()),
      );
      wealthSpots.add(
        FlSpot((30 + i).toDouble(), 2 + ((i + 3) % 3).toDouble()),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 5,
          gridData: FlGridData(show: false),
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
                  return Text(
                    DateFormat('MM/dd').format(date),
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: loveSpots,
              isCurved: true,
              color: const Color(0xFFE57373),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: careerSpots,
              isCurved: true,
              color: const Color(0xFF81C784),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: healthSpots,
              isCurved: true,
              color: const Color(0xFF64B5F6),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: wealthSpots,
              isCurved: true,
              color: const Color(0xFFFFB74D),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final fortuneProvider = Provider.of<FortuneProvider>(context);
    final fortune = fortuneProvider.todayFortune;

    if (fortune == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('运势详情')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 综合运势曲线
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('运势趋势', style: Theme.of(context).textTheme.titleLarge),
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
                      Text(
                        '补充信息',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
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
      ),
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

  Widget _buildQuestionButton(String category, String label) {
    return ElevatedButton(
      onPressed: () => _generateQuestion(category),
      child: Text(label),
    );
  }
}
