import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'providers/settings_provider.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'theme/design_tokens.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'l10n/generated/app_localizations.dart';

class SmartClassroomApp extends ConsumerStatefulWidget {
  const SmartClassroomApp({super.key});

  @override
  ConsumerState<SmartClassroomApp> createState() => _SmartClassroomAppState();
}

class _SmartClassroomAppState extends ConsumerState<SmartClassroomApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 教学模式下锁定竖屏… 实际不应锁定，由内部响应式处理
  }

  ThemeData _resolveTheme(bool isTeaching, bool isDark) {
    if (isTeaching) return AppTheme.teaching();
    return isDark ? AppTheme.dark() : AppTheme.light();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isTeaching = settings.teachingMode;

    // 教学大屏：强制全屏沉浸式
    if (isTeaching) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

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
      theme: _resolveTheme(isTeaching, false),
      darkTheme: _resolveTheme(false, true),
      themeMode: isTeaching ? ThemeMode.light : (settings.isDarkMode ? ThemeMode.dark : ThemeMode.light),
      builder: (ctx, child) {
        // 1. 教学大屏：全屏 + 无 SafeArea + 不限制缩放
        // 2. 手机端：限制最大文本缩放 + SafeArea
        if (isTeaching) {
          return MediaQuery(
            data: MediaQuery.of(ctx).copyWith(
              // 大屏不禁用任何缩放
              textScaler: TextScaler.noScaling,
            ),
            child: child!,
          );
        }
        // 手机/平板：限制最大缩放 1.3x + SafeArea
        final extant = MediaQuery.of(ctx).textScaler;
        final clamped = extant.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3);
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(textScaler: clamped),
          child: SafeArea(child: child!),
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
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('灵动课堂', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
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
