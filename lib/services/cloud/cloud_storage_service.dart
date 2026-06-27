import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/services_provider.dart';
import '../file_service.dart';
import '../storage_service.dart';
import 'webdav_client.dart';
import 'sync_engine.dart';

class CloudStorageService {
  final Ref _ref;
  final WebDavClientService _wd;
  SyncEngine? _se;
  CloudStorageService(this._ref, this._wd);

  SyncEngine get _engine {
    _se ??= SyncEngine(_ref, _ref.read(fileServiceProvider), _ref.read(storageServiceProvider), _wd);
    return _se!;
  }

  Future<bool> testConnection() async {
    final st = _ref.read(settingsProvider);
    final pw = await _ref.read(storageServiceProvider).getSecure('webdav_password') ?? '';
    return _wd.connect(url: st.webdavUrl, username: st.webdavUsername, password: pw);
  }

  Future<bool> sync() => _engine.performSync();
}
