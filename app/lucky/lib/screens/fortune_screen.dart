import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucky/providers/user_provider.dart';
import 'package:lucky/providers/fortune_provider.dart';

class FortuneScreen extends StatefulWidget {
  const FortuneScreen({super.key});

  @override
  State<FortuneScreen> createState() => _FortuneScreenState();
}

class _FortuneScreenState extends State<FortuneScreen> {
  // Widget to display star ratings for each fortune aspect
  Widget _buildFortuneRatingRow(BuildContext context, String label, int rating, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          return Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: index < rating ? color : Colors.grey[300],
            size: 24,
          );
        }),
        const Spacer(),
        Text(
          '$rating/5',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
  bool _isGenerating = false;

  Future<void> _generateFortune() async {
    if (_isGenerating) return;
    
    setState(() {
      _isGenerating = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final fortuneProvider = Provider.of<FortuneProvider>(context, listen: false);
      
      if (userProvider.user != null) {
        await fortuneProvider.generateTodayFortune(userProvider.user!);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法获取用户信息，请重试')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('生成运势时发生错误，请重试')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fortuneProvider = Provider.of<FortuneProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日运势'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withAlpha(26), // 0.1 * 255 = 26
              Theme.of(context).colorScheme.secondary.withAlpha(13), // 0.05 * 255 = 13
            ],
          ),
        ),
        child: fortuneProvider.todayFortune != null
            ? _buildFortuneContent(context, fortuneProvider)
            : _buildGenerateFortuneContent(context),
      ),
    );
  }
  
  Widget _buildFortuneContent(BuildContext context, FortuneProvider fortuneProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date card
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
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('yyyy年MM月dd日').format(fortuneProvider.todayFortune!.date),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Fortune content
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
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '运势详情',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          fortuneProvider.todayFortune!.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: fortuneProvider.todayFortune!.isFavorite
                              ? Colors.red
                              : Colors.grey,
                        ),
                        onPressed: () {
                          fortuneProvider.toggleFavorite();
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    fortuneProvider.todayFortune!.fortuneText,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Fortune ratings section
                  Text(
                    '运势评分',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Love fortune rating
                  _buildFortuneRatingRow(
                    context,
                    '爱情运势',
                    fortuneProvider.todayFortune!.loveRating,
                    Colors.pink,
                  ),
                  const SizedBox(height: 12),
                  // Career fortune rating
                  _buildFortuneRatingRow(
                    context,
                    '事业运势',
                    fortuneProvider.todayFortune!.careerRating,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  // Health fortune rating
                  _buildFortuneRatingRow(
                    context,
                    '健康运势',
                    fortuneProvider.todayFortune!.healthRating,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  // Wealth fortune rating
                  _buildFortuneRatingRow(
                    context,
                    '财运',
                    fortuneProvider.todayFortune!.wealthRating,
                    Colors.amber,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tip card
          Card(
            elevation: 2,
            color: Theme.of(context).colorScheme.primary.withAlpha(26), // 0.1 * 255 = 26
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '小贴士',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '敲击木鱼可以增加功德值，功德值越高，运势越好。每天可敲击108次。',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Refresh button
          Center(
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateFortune,
              icon: const Icon(Icons.refresh),
              label: Text(_isGenerating ? '生成中...' : '刷新运势'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGenerateFortuneContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 80,
            color: Colors.amber,
          ),
          const SizedBox(height: 24),
          Text(
            '今日运势尚未生成',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          const Text(
            '点击下方按钮，根据您的生辰八字生成今日运势',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generateFortune,
            icon: const Icon(Icons.auto_awesome),
            label: Text(_isGenerating ? '生成中...' : '生成今日运势'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          if (_isGenerating) ...[
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
