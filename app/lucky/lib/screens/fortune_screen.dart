import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucky/providers/user_provider.dart';
import 'package:lucky/providers/fortune_provider.dart';
import 'package:lucky/screens/fortune_detail_screen.dart';

class FortuneScreen extends StatefulWidget {
  const FortuneScreen({super.key});

  @override
  State<FortuneScreen> createState() => _FortuneScreenState();
}

class _FortuneScreenState extends State<FortuneScreen> {
  // Widget to display star ratings for each fortune aspect
  Widget _buildFortuneRatingRow(
    BuildContext context,
    String label,
    int rating,
    Color color,
  ) {
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

    // Use microtask to avoid build-time state updates
    Future.microtask(() {
      setState(() {
        _isGenerating = true;
      });
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final fortuneProvider = Provider.of<FortuneProvider>(
        context,
        listen: false,
      );

      if (userProvider.user != null) {
        await fortuneProvider.generateTodayFortune(userProvider.user!);
      }
    } finally {
      if (mounted) {
        // Use microtask to avoid build-time state updates
        Future.microtask(() {
          setState(() {
            _isGenerating = false;
          });
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
      body:
          fortuneProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : fortuneProvider.todayFortune == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('暂无今日运势数据'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _generateFortune,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child:
                          _isGenerating
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('生成今日运势'),
                    ),
                  ],
                ),
              )
              : const FortuneDetailScreen(),
    );
  }
}
