import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/services_provider.dart';
import '../workspace_service.dart';
import '../storage_service.dart';
import 'webdav_plus_sync.dart';
import 'sync_engine.dart';

/// 云存储服务 — 验证配置后再执行同步
class CloudStorageService {
  final Ref _ref;
  final WebdavPlusSyncService _wd;
  SyncEngine? _se;

  CloudStorageService(this._ref, this._wd);

  SyncEngine get _engine {
    _se ??= SyncEngine(
      _ref,
      _ref.read(workspaceServiceProvider),
      _ref.read(storageServiceProvider),
      _wd,
    );
    return _se!;
  }

  /// 检查 WebDAV 配置是否完整
  bool _isConfigured() {
    final st = _ref.read(settingsProvider);
    return st.webdavUsername.isNotEmpty &&
        st.webdavUrl.isNotEmpty &&
        st.webdavUrl.startsWith('http');
  }

  /// 测试连接
  Future<bool> testConnection() async {
    if (!_isConfigured()) return false;
    final st = _ref.read(settingsProvider);
    final pw =
        await _ref.read(storageServiceProvider).getSecure('webdav_password') ?? '';
    return _wd.testConnection(settings: st, password: pw);
  }

  /// 执行同步 — 未配置时直接返回 false
  Future<bool> sync() async {
    if (!_isConfigured()) return false;
    return _engine.performSync();
  }
}
