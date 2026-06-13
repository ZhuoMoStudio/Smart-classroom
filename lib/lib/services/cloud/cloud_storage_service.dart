import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/services_provider.dart';
import '../file_service.dart';
import '../storage_service.dart';
import 'webdav_client.dart';
import 'sync_engine.dart';

class CloudStorageService {
  final Ref _ref;
  final WebDavClientService _webdav;

  CloudStorageService(this._ref, this._webdav);

  SyncEngine get _syncEngine => SyncEngine(
        _ref,
        _ref.read(fileServiceProvider),
        _ref.read(storageServiceProvider),
        _webdav,
      );

  Future<bool> testConnection() async {
    final settings = _ref.read(settingsProvider);
    final password = await _ref.read(storageServiceProvider).getSecure('webdav_password') ?? '';
    return _webdav.connect(url: settings.webdavUrl, username: settings.webdavUsername, password: password);
  }

  Future<bool> sync() => _syncEngine.performSync();
}