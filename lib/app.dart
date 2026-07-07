import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'providers/settings_provider.dart';
import 'services/storage_service.dart';
import 'services/workspace_service.dart';
import 'services/data_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/workspace_picker_dialog.dart';
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
        final extant = MediaQuery.of(ctx).textScaler;
        final clamped = extant.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3);
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(
            textScaler: clamped,
            padding: MediaQuery.of(ctx).padding.copyWith(
              top: MediaQuery.of(ctx).padding.top > 30
                  ? MediaQuery.of(ctx).padding.top
                  : 24,
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
  bool _workspacePromptShown = false;

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

  void _maybeShowWorkspacePicker() {
    if (_workspacePromptShown) return;
    _workspacePromptShown = true;

    final ws = ref.read(workspaceServiceProvider);
    // 仅在首次且未配置工作区时弹出
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ws.loadSavedPath();
      if (!ws.isConfigured && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => WorkspacePickerDialog(
            onComplete: () async {
              // 加载工作区数据
              final updatedWs = ref.read(workspaceServiceProvider);
              if (updatedWs.isConfigured) {
                await ref.read(dataServiceProvider).loadFromWorkspace();
              }
            },
          ),
        );
      } else if (ws.isConfigured && mounted) {
        // 已配置则直接加载
        await ref.read(dataServiceProvider).loadFromWorkspace();
      }
    });
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
                Icon(Icons.school,
                    size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text('灵动课堂',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ),
        ),
      );
    }

    if (_onboardingComplete == true) {
      _maybeShowWorkspacePicker();
      return const HomeScreen();
    }

    return OnboardingScreen(
      key: const ValueKey('onboarding'),
      onComplete: _onOnboardingComplete,
    );
  }
}
