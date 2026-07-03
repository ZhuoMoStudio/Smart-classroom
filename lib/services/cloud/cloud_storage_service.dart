import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/services_provider.dart';
import '../file_service.dart';
import '../storage_service.dart';
import 'webdav_plus_sync.dart';
import 'sync_engine.dart';

/// 云存储服务 — 统一使用 webdav_plus 包
class CloudStorageService {
  final Ref _ref;
  final WebdavPlusSyncService _wd;
  SyncEngine? _se;

  CloudStorageService(this._ref, this._wd);

  SyncEngine get _engine {
    _se ??= SyncEngine(
      _ref,
      _ref.read(fileServiceProvider),
      _ref.read(storageServiceProvider),
      _wd,
    );
    return _se!;
  }

  /// 测试连接 — 委托给 webdav_plus
  Future<bool> testConnection() async {
    return _wd.testConnection();
  }

  /// 执行同步
  Future<bool> sync() => _engine.performSync();
}
