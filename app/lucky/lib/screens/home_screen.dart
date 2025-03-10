import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucky/providers/auth_provider.dart';
import 'package:lucky/providers/user_provider.dart';
import 'package:lucky/providers/fortune_provider.dart';
import 'package:lucky/screens/fortune_screen.dart';
import 'package:lucky/screens/login_screen.dart';
import 'package:lucky/utils/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Refresh controller
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Last merit points value to track changes
  int _lastMeritPoints = 0;
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
            size: 18,
          );
        }),
      ],
    );
  }

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _tapCount = 0;
  bool _canTap = true;

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

    // Set up listener for merit points changes and check today's fortune
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _lastMeritPoints = userProvider.meritPoints;

      // 将_checkTodayFortune的调用移到这里
      _checkTodayFortune();
    });
  }

  Future<void> _checkTodayFortune() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userId != null) {
      final fortuneProvider = Provider.of<FortuneProvider>(
        context,
        listen: false,
      );
      await fortuneProvider.checkTodayFortune(authProvider.userId!);
    }
  }

  // Refresh fortune when pulled down
  Future<void> _refreshFortune() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final fortuneProvider = Provider.of<FortuneProvider>(
      context,
      listen: false,
    );

    if (userProvider.user != null) {
      await fortuneProvider.generateTodayFortune(userProvider.user!);
      return;
    }
  }

  Future<void> _onWoodenFishTap() async {
    if (!_canTap) return;

    // Get user provider before async gap
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _canTap = false;
    });

    await _animationController.forward();
    await _animationController.reverse();

    // Check if widget is still mounted before proceeding
    if (!mounted) return;

    // Update merit points - no context needed here since we already have userProvider
    final newMeritPoints =
        (userProvider.user?.meritPoints ?? 0) + AppConstants.meritPointsPerTap;
    await userProvider.updateMeritPoints(
      AppConstants.meritPointsPerTap,
      type: 'wooden_fish',
    );

    // Check if widget is still mounted before proceeding
    if (!mounted) return;

    // Show merit points increase animation
    setState(() {
      _tapCount++;
      _canTap = true;
      _showPlusOne = true;
    });

    // 启动+1动画
    _plusOneController.forward();

    // Check if merit points increased by 10 or more
    if (newMeritPoints - _lastMeritPoints >= 10) {
      _lastMeritPoints = newMeritPoints;
      await _refreshFortune();
    }
  }

  Future<void> _signOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final fortuneProvider = Provider.of<FortuneProvider>(
      context,
      listen: false,
    );

    await authProvider.signOut();
    userProvider.clearUser();
    fortuneProvider.clearFortune();

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  Widget _buildFortuneCurve() {
    final fortuneProvider = Provider.of<FortuneProvider>(context);
    final fortune = fortuneProvider.todayFortune;

    if (fortune == null || fortune.fortuneCurve.isEmpty) {
      return const SizedBox(height: 120);
    }

    // Convert fortune points to FlSpot list
    final spots =
        fortune.fortuneCurve
            .map((point) => FlSpot(point.hour.toDouble(), point.value))
            .toList();

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                interval: 6,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(color: Colors.grey, fontSize: 12);
                  Widget text;
                  switch (value.toInt()) {
                    case 0:
                      text = const Text('子时', style: style);
                      break;
                    case 6:
                      text = const Text('午时', style: style);
                      break;
                    case 12:
                      text = const Text('酉时', style: style);
                      break;
                    default:
                      text = const Text('');
                      break;
                  }
                  return SideTitleWidget(axisSide: meta.axisSide, child: text);
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    Theme.of(context).colorScheme.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _plusOneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final fortuneProvider = Provider.of<FortuneProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(
                context,
              ).colorScheme.primary.withAlpha(204), // 0.8 * 255 = 204
              Theme.of(
                context,
              ).colorScheme.secondary.withAlpha(153), // 0.6 * 255 = 153
            ],
          ),
        ),
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _refreshFortune,
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Colors.white,
          child: SafeArea(
            child: ListView(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '生辰八字运势',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: _signOut,
                      ),
                    ],
                  ),
                ),
                // Date display
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('yyyy年MM月dd日').format(DateTime.now()),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Section title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    '功德修行',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Merit points display
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Merit points info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '当前功德值',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${userProvider.meritPoints}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE57373),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '今日已敲击: $_tapCount/${AppConstants.maxTapsPerDay}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Vertical divider
                      Container(
                        height: 120,
                        width: 1,
                        color: Colors.grey.withAlpha(100),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      // Wooden fish icon
                      Column(
                        children: [
                          const Text(
                            '木鱼',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onTap: _onWoodenFishTap,
                                child: ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: Container(
                                    width: 60,
                                    height: 60,
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
                                        color: Colors.white,
                                        width: 40,
                                        height: 40,
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Section title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    '今日运势',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Fortune section
                if (fortuneProvider.todayFortune != null)
                  GestureDetector(
                    onTap: () {
                      // Navigate to fortune screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FortuneScreen(),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '今日运势',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Fortune summary
                          Text(
                            fortuneProvider.todayFortune!.fortuneText.split(
                              '\n',
                            )[0],
                            style: const TextStyle(fontSize: 16, height: 1.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          // Fortune curve
                          _buildFortuneCurve(),
                          const SizedBox(height: 12),
                          // Fortune ratings
                          _buildFortuneRatingRow(
                            context,
                            '爱情',
                            fortuneProvider.todayFortune!.loveRating,
                            const Color(0xFFE57373),
                          ),
                          const SizedBox(height: 8),
                          _buildFortuneRatingRow(
                            context,
                            '事业',
                            fortuneProvider.todayFortune!.careerRating,
                            const Color(0xFF81C784),
                          ),
                          const SizedBox(height: 8),
                          _buildFortuneRatingRow(
                            context,
                            '健康',
                            fortuneProvider.todayFortune!.healthRating,
                            const Color(0xFF64B5F6),
                          ),
                          const SizedBox(height: 8),
                          _buildFortuneRatingRow(
                            context,
                            '财运',
                            fortuneProvider.todayFortune!.wealthRating,
                            const Color(0xFFFFB74D),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
