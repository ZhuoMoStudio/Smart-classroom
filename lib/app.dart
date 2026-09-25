import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'providers/settings_provider.dart';
import 'services/app_log.dart';
import 'services/storage_service.dart';
import 'services/update_service.dart';
import 'services/workspace_service.dart';
import 'services/data_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/workspace_picker_dialog.dart';
import 'widgets/toast_overlay.dart';
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
  bool _updateChecked = false;

  /// 老师选择「稍后再说」时记住版本号，避免每次启动都弹同一个提示
  static const String _skippedVersionKey = 'update_skipped_version';

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
              final updatedWs = ref.read(workspaceServiceProvider);
              if (updatedWs.isConfigured) {
                await ref.read(dataServiceProvider).loadFromWorkspace();
              }
            },
          ),
        );
      } else if (ws.isConfigured && mounted) {
        await ref.read(dataServiceProvider).loadFromWorkspace();
      }
    });
  }

  /// 启动时检查更新。
  ///
  /// 放在启动而不是塞进设置页深处：老师不会主动去设置里找「检查更新」，
  /// 有新版就当场告诉他更符合预期。同一个版本只提示一次。
  Future<void> _maybeCheckUpdate() async {
    if (_updateChecked) return;
    _updateChecked = true;

    try {
      final result = await UpdateService.check();
      if (!mounted) return;
      if (!result.hasUpdate) return;

      final skipped =
          ref.read(storageServiceProvider).getString(_skippedVersionKey);
      if (skipped == result.latestVersion) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('发现新版本'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('当前版本：${result.currentVersion ?? '未知'}'),
              const SizedBox(height: 4),
              Text('最新版本：${result.latestVersion ?? '未知'}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('前往下载页获取新版本安装包。',
                  style: TextStyle(fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref
                    .read(storageServiceProvider)
                    .setString(_skippedVersionKey, result.latestVersion ?? '');
                Navigator.pop(ctx);
              },
              child: const Text('跳过此版本'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('稍后'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final url = result.downloadUrl;
                if (url == null) return;
                try {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                } catch (e) {
                  AppLog.warn('更新', '无法打开下载页: $e');
                  if (mounted) {
                    ToastOverlay.show(context, '无法打开下载页：$url',
                        type: ToastType.warning);
                  }
                }
              },
              child: const Text('前往下载'),
            ),
          ],
        ),
      );
    } catch (e, st) {
      // 检查更新失败绝不能影响启动
      AppLog.warn('更新', '检查更新失败: $e');
      AppLog.error('更新', '检查更新异常', e, st);
    }
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
      _maybeCheckUpdate();
      return const HomeScreen();
    }

    return OnboardingScreen(
      key: const ValueKey('onboarding'),
      onComplete: _onOnboardingComplete,
    );
  }
}
