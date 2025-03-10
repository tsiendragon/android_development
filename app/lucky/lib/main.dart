import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucky/screens/splash_screen.dart';
import 'package:lucky/providers/auth_provider.dart';
import 'package:lucky/providers/user_provider.dart';
import 'package:lucky/providers/fortune_provider.dart';
import 'package:lucky/providers/api_key_provider.dart';
import 'package:lucky/providers/theme_provider.dart';
import 'package:lucky/utils/theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FortuneProvider()),
        ChangeNotifierProvider(create: (_) => ApiKeyProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final apiKeyProvider = Provider.of<ApiKeyProvider>(
        context,
        listen: false,
      );
      final fortuneProvider = Provider.of<FortuneProvider>(
        context,
        listen: false,
      );
      fortuneProvider.setApiKeyProvider(apiKeyProvider);

      // 使用Future.microtask来延迟执行，避免在构建过程中触发状态更新
      Future.microtask(() => apiKeyProvider.loadApiKey());
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;

    return MaterialApp(
      title: '生辰八字运势',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme, // 添加暗色主题
      themeMode: themeMode, // 根据用户设置切换主题
      home: const SplashScreen(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('zh'), // Chinese
      ],
      locale: const Locale('zh'), // Set default locale to Chinese
    );
  }
}
