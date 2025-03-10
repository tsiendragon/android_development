import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucky/providers/auth_provider.dart';
import 'package:lucky/providers/user_provider.dart';
import 'package:lucky/providers/fortune_provider.dart';
import 'package:lucky/screens/fortune_screen.dart';
import 'package:lucky/screens/login_screen.dart';
import 'package:lucky/screens/settings_screen.dart';
import 'package:lucky/utils/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    await userProvider.updateMeritPoints(AppConstants.meritPointsPerTap);

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

  void _navigateToFortuneScreen() {
    // 不再需要导航到运势页面，因为可以通过底部导航栏访问
    // 可以在这里添加一些其他逻辑，比如显示一个提示
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('请点击底部导航栏的"运势"查看详情')));
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
                    color: Colors.white.withAlpha(230), // 0.9 * 255 = 230
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26), // 0.1 * 255 = 26
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

                // Section title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: Text(
                    '今日运势',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Today's fortune card
                Container(
                  margin: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: _navigateToFortuneScreen,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        // Make the card taller when fortune is available to accommodate the ratings
                        constraints: BoxConstraints(
                          minHeight:
                              fortuneProvider.todayFortune != null ? 250 : 150,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '今日运势',
                                  style:
                                      Theme.of(
                                        context,
                                      ).textTheme.headlineMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            fortuneProvider.todayFortune != null
                                ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '您今日的运势已生成，点击查看详情',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    const SizedBox(height: 16),
                                    // Love fortune rating
                                    _buildFortuneRatingRow(
                                      context,
                                      '爱情运势',
                                      fortuneProvider.todayFortune!.loveRating,
                                      Colors.pink,
                                    ),
                                    const SizedBox(height: 8),
                                    // Career fortune rating
                                    _buildFortuneRatingRow(
                                      context,
                                      '事业运势',
                                      fortuneProvider
                                          .todayFortune!
                                          .careerRating,
                                      Colors.blue,
                                    ),
                                    const SizedBox(height: 8),
                                    // Health fortune rating
                                    _buildFortuneRatingRow(
                                      context,
                                      '健康运势',
                                      fortuneProvider
                                          .todayFortune!
                                          .healthRating,
                                      Colors.green,
                                    ),
                                    const SizedBox(height: 8),
                                    // Wealth fortune rating
                                    _buildFortuneRatingRow(
                                      context,
                                      '财运',
                                      fortuneProvider
                                          .todayFortune!
                                          .wealthRating,
                                      Colors.amber,
                                    ),
                                  ],
                                )
                                : Text(
                                  '点击生成今日运势',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                            const SizedBox(height: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
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
