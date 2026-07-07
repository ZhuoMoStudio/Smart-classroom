import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/services_provider.dart';
import 'cloud/cloud_storage_service.dart';

/// 自动同步定时器 — v1.30
class AutoSyncTimer {
  final Ref _ref;
  Timer? _timer;

  AutoSyncTimer(this._ref);

  /// 启动定时同步
  void start() {
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    final settings = _ref.read(settingsProvider);
    if (!settings.autoSync || settings.autoSyncInterval <= 0) return;

    final interval = Duration(minutes: settings.autoSyncInterval);
    _timer = Timer(interval, () async {
      await _doAutoSync();
      _scheduleNext();
    });
  }

  Future<void> _doAutoSync() async {
    try {
      final settings = _ref.read(settingsProvider);
      if (!settings.autoSync) return;
      if (settings.webdavUsername.isEmpty ||
          !settings.webdavUrl.startsWith('http')) return;

      final cloudService = _ref.read(cloudStorageServiceProvider);
      await cloudService.sync();
    } catch (_) {
      // 静默失败，用户可手动查看状态
    }
  }

  /// 设置变更时重新调度
  void onSettingsChanged() {
    _timer?.cancel();
    _scheduleNext();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
  }
}

/// AutoSyncTimer Provider
final autoSyncTimerProvider = Provider.autoDispose<AutoSyncTimer>((ref) {
  final timer = AutoSyncTimer(ref);
  ref.onDispose(() => timer.dispose());
  return timer;
});
