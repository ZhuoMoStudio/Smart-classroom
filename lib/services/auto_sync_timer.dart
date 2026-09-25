import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/services_provider.dart';
import 'app_log.dart';
import 'cloud/cloud_storage_service.dart';

/// 自动同步定时器
///
/// 修掉两个让「自动同步」实际从不生效的问题：
///   1. 这个 provider 原本是 `Provider.autoDispose`，而界面用的是 `ref.read(...).start()`。
///      autoDispose 在没有监听者时会立刻销毁，于是 start() 排好的定时器
///      紧接着就在 dispose() 里被 cancel —— 功能等于不存在。
///   2. 原本是「一次性长定时器 + onSettingsChanged 重新排期」，
///      但 onSettingsChanged 从来没被任何地方调用过，
///      所以改同步间隔或开关自动同步都必须重启应用才生效。
/// 现在改成每 30 秒自查一次的轻量轮询：设置改了 30 秒内自动生效，
/// 也不需要界面配合调用任何回调。
class AutoSyncTimer {
  final Ref _ref;
  Timer? _ticker;
  DateTime _lastRun = DateTime.now();

  static const Duration _checkInterval = Duration(seconds: 30);

  AutoSyncTimer(this._ref);

  void start() {
    if (_ticker != null) return;
    _lastRun = DateTime.now();
    _ticker = Timer.periodic(_checkInterval, (_) => _tick());
    AppLog.info('自动同步', '定时器已启动');
  }

  void _tick() {
    final settings = _ref.read(settingsProvider);
    if (!settings.autoSync || settings.autoSyncInterval <= 0) return;

    final elapsed = DateTime.now().difference(_lastRun);
    if (elapsed < Duration(minutes: settings.autoSyncInterval)) return;

    _lastRun = DateTime.now();
    _doAutoSync();
  }

  Future<void> _doAutoSync() async {
    try {
      final settings = _ref.read(settingsProvider);
      if (!settings.autoSync) return;
      if (settings.webdavUsername.isEmpty ||
          !settings.webdavUrl.startsWith('http')) {
        AppLog.warn('自动同步', 'WebDAV 未配置，跳过');
        return;
      }

      AppLog.info('自动同步', '开始后台同步');
      final cloudService = _ref.read(cloudStorageServiceProvider);
      final ok = await cloudService.sync();
      if (!ok) AppLog.warn('自动同步', '同步未成功完成');
    } catch (e, st) {
      // 不再静默：后台失败也要留痕，否则老师只会觉得「云同步时好时坏」
      AppLog.error('自动同步', '后台同步异常', e, st);
    }
  }

  void stop() {
    _ticker?.cancel();
    _ticker = null;
  }

  void dispose() => stop();
}

/// 注意：这里**不能**是 autoDispose。
/// 界面用 ref.read 启动它，autoDispose 会在没有监听者时立刻销毁，
/// 定时器随之被取消，自动同步就永远不会触发。
final autoSyncTimerProvider = Provider<AutoSyncTimer>((ref) {
  final timer = AutoSyncTimer(ref);
  ref.onDispose(timer.dispose);
  return timer;
});
