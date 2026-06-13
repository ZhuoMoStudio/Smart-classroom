import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sync_provider.dart';
import '../../providers/settings_provider.dart';
import '../file_service.dart';
import '../storage_service.dart';
import 'webdav_client.dart';

class SyncEngine {
  final Ref _ref;
  final FileService _fileService;
  final StorageService _storage;
  final WebDavClientService _webdav;

  SyncEngine(this._ref, this._fileService, this._storage, this._webdav);

  Future<bool> performSync() async {
    final syncNotifier = _ref.read(syncProvider.notifier);
    syncNotifier.startSync();

    try {
      final settings = _ref.read(settingsProvider);
      syncNotifier.updateProgress(0.1, '已连接云端');

      final localDir = await _fileService.getWorkingDir();
      final localFiles = await _fileService.listArchives(localDir);

      if (localFiles.isNotEmpty && settings.syncStrategy != 'download') {
        final latestLocal = localFiles.first;
        final remotePath = '${settings.remoteFolder}${latestLocal.path.split('/').last}';
        syncNotifier.updateProgress(0.3, '正在上传...');
        await _webdav.uploadFile(latestLocal.path, remotePath);
      }

      final cloudFiles = await _webdav.listFiles(settings.remoteFolder);
      if (cloudFiles.isNotEmpty && settings.syncStrategy != 'upload') {
        final remoteJsonFiles = cloudFiles.where((f) => f.name.endsWith('.json')).toList();
        remoteJsonFiles.sort((a, b) => b.lastModified.compareTo(a.lastModified));
        if (remoteJsonFiles.isNotEmpty) {
          final latestRemote = remoteJsonFiles.first;
          final localPath = '$localDir/${latestRemote.name}';
          syncNotifier.updateProgress(0.6, '正在下载...');
          await _webdav.downloadFile('${settings.remoteFolder}${latestRemote.name}', localPath);
        }
      }

      syncNotifier.updateProgress(0.8, '清理旧存档...');
      await _fileService.cleanArchives(localDir);
      await _storage.setString('last_sync_timestamp', DateTime.now().toIso8601String());
      syncNotifier.syncComplete();
      return true;
    } catch (e) {
      syncNotifier.syncError(e.toString());
      return false;
    }
  }
}