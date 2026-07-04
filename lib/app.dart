import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'providers/settings_provider.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'l10n/generated/app_localizations.dart';

class SmartClassroomApp extends ConsumerStatefulWidget {
  const SmartClassroomApp({super.key});

  @override
  ConsumerState<SmartClassroomApp> createState() => _SmartClassroomAppState();
}

class _SmartClassroomAppState extends ConsumerState<SmartClassroomApp> {
  @override
  void initState() {
    super.initState();
    // 全屏沉浸式 + 适配状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: '灵动课堂',
      debugShowCheckedModeBanner: false,
      locale: Locale(settings.localeTag),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (ctx, child) {
        // 限制最大文本缩放 1.3x
        final extant = MediaQuery.of(ctx).textScaler;
        final clamped = extant.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3);
        // 添加顶部 SafeArea 防止状态栏遮挡
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(
            textScaler: clamped,
            // 小屏幕使用更紧凑的 padding
            padding: MediaQuery.of(ctx).padding.copyWith(
              top: MediaQuery.of(ctx).padding.top > 30
                  ? MediaQuery.of(ctx).padding.top : 24,
            ),
          ),
          child: SafeArea(
            top: true,
            bottom: true,
            child: child!,
          ),
        );
      },
      home: const _AppBootstrap(),
    );
  }
}

class _AppBootstrap extends ConsumerStatefulWidget {
  const _AppBootstrap();

  @override
  ConsumerState<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<_AppBootstrap> {
  bool? _onboardingComplete;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  void _checkOnboarding() {
    final storage = ref.read(storageServiceProvider);
    setState(() {
      _onboardingComplete = storage.getBool('onboarding_complete', false);
    });
  }

  void _onOnboardingComplete() {
    ref.read(storageServiceProvider).setBool('onboarding_complete', true);
    setState(() => _onboardingComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school, size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text('灵动课堂', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ),
        ),
      );
    }

    if (_onboardingComplete == true) {
      return const HomeScreen();
    }

    return OnboardingScreen(key: const ValueKey('onboarding'), onComplete: _onOnboardingComplete);
  }
}
