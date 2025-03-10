import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucky/models/fortune_model.dart';
import 'package:lucky/providers/fortune_provider.dart';
import 'package:intl/intl.dart';
import 'package:lucky/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _answerController.dispose();
    super.dispose();
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

  // 构建运势详情卡片
  Widget _buildFortuneCard(String title, String content, {Color? color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color ?? Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(content, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
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

          // 宜做事项
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
                    '今日宜做',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...fortune.thingsToDo.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(fontSize: 16),
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

          const SizedBox(height: 20),

          // 忌做事项
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
                    '今日忌做',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...fortune.thingsToAvoid.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.cancel, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(fontSize: 16),
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

          const SizedBox(height: 20),

          // 反馈问题
          _buildFeedbackCard('综合', '您对今日的运势预测有什么看法？'),
        ],
      ),
    );
  }

  // 构建爱情运势页面
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

          // 爱情运势详情
          _buildFortuneCard(
            '爱情运势详解',
            '今日爱情运势为${fortune.loveRating}星。' +
                (fortune.fortuneText.contains('爱情')
                    ? fortune.fortuneText.split('爱情')[1].split('事业')[0]
                    : '单身的朋友可能会有新的邂逅，已有伴侣的朋友可以增进感情交流。'),
            color: Colors.pink,
          ),

          const SizedBox(height: 20),

          // 爱情运势建议
          _buildFortuneCard(
            '爱情运势建议',
            fortune.loveRating >= 4
                ? '今天是增进感情的好时机，可以安排一次约会或给对方一个惊喜。'
                : (fortune.loveRating >= 3
                    ? '今天爱情运势一般，保持平常心，避免过度敏感。'
                    : '今天爱情运势较低，建议避免争执，给彼此一些空间。'),
            color: Colors.pink,
          ),

          const SizedBox(height: 20),

          // 反馈问题
          _buildFeedbackCard('爱情', '您最近的感情生活如何？有什么想要分享的经历吗？'),
        ],
      ),
    );
  }

  // 构建事业运势页面
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

          // 事业运势详情
          _buildFortuneCard(
            '事业运势详解',
            '今日事业运势为${fortune.careerRating}星。' +
                (fortune.fortuneText.contains('事业')
                    ? fortune.fortuneText.split('事业')[1].split('健康')[0]
                    : '工作中可能会有新的机会，建议保持积极主动的态度。'),
            color: Colors.blue,
          ),

          const SizedBox(height: 20),

          // 事业运势建议
          _buildFortuneCard(
            '事业运势建议',
            fortune.careerRating >= 4
                ? '今天是展示才能的好时机，可以主动承担重要任务，提出创新想法。'
                : (fortune.careerRating >= 3
                    ? '今天事业运势一般，专注于日常工作，避免冒险。'
                    : '今天事业运势较低，建议低调行事，避免与同事或上级发生冲突。'),
            color: Colors.blue,
          ),

          const SizedBox(height: 20),

          // 反馈问题
          _buildFeedbackCard('事业', '您最近的工作或学习有什么进展？遇到了哪些挑战？'),
        ],
      ),
    );
  }

  // 构建健康运势页面
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

          // 健康运势详情
          _buildFortuneCard(
            '健康运势详解',
            '今日健康运势为${fortune.healthRating}星。' +
                (fortune.fortuneText.contains('健康')
                    ? fortune.fortuneText.split('健康')[1].split('财运')[0]
                    : '身体状况良好，但仍需注意作息规律，保持良好的生活习惯。'),
            color: Colors.green,
          ),

          const SizedBox(height: 20),

          // 健康运势建议
          _buildFortuneCard(
            '健康运势建议',
            fortune.healthRating >= 4
                ? '今天身体状况良好，是进行体育锻炼的好时机，可以适当增加运动强度。'
                : (fortune.healthRating >= 3
                    ? '今天健康运势一般，保持规律作息，避免过度劳累。'
                    : '今天健康运势较低，建议多休息，避免剧烈运动，注意饮食健康。'),
            color: Colors.green,
          ),

          const SizedBox(height: 20),

          // 反馈问题
          _buildFeedbackCard('健康', '您最近的身体状况如何？有什么健康方面的困扰吗？'),
        ],
      ),
    );
  }

  // 构建财运页面
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

          // 财运详情
          _buildFortuneCard(
            '财运详解',
            '今日财运为${fortune.wealthRating}星。' +
                (fortune.fortuneText.contains('财运')
                    ? fortune.fortuneText.split('财运')[1].split('今日宜做')[0]
                    : '财务状况稳定，可能会有意外收入，但也要避免冲动消费。'),
            color: Colors.amber,
          ),

          const SizedBox(height: 20),

          // 财运建议
          _buildFortuneCard(
            '财运建议',
            fortune.wealthRating >= 4
                ? '今天财运良好，适合进行投资理财，也可能有意外收获。'
                : (fortune.wealthRating >= 3
                    ? '今天财运一般，量入为出，避免不必要的开支。'
                    : '今天财运较低，建议谨慎消费，避免大额支出和投资。'),
            color: Colors.amber,
          ),

          const SizedBox(height: 20),

          // 反馈问题
          _buildFeedbackCard('财运', '您最近的财务状况如何？有什么理财计划或困扰吗？'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fortuneProvider = Provider.of<FortuneProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

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
    final user = userProvider.user;

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
