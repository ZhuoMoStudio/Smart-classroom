import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sync_provider.dart';
import '../../providers/settings_provider.dart';
import '../file_service.dart';
import '../storage_service.dart';
import 'webdav_client.dart';

class SyncEngine {
  final Ref _ref;
  final FileService _fs;
  final StorageService _ss;
  final WebDavClientService _wd;
  SyncEngine(this._ref, this._fs, this._ss, this._wd);

  Future<bool> performSync() async {
    final sn = _ref.read(syncProvider.notifier); sn.startSync();
    try {
      final st = _ref.read(settingsProvider); sn.updateProgress(0.1, '已连接云端');
      final ld = await _fs.getWorkingDir();
      final lfs = await _fs.listArchives(ld);
      if (lfs.isNotEmpty && st.syncStrategy != 'download') {
        sn.updateProgress(0.3, '正在上传...');
        await _wd.uploadFile(lfs.first.path, '${st.remoteFolder}${lfs.first.path.split('/').last}');
      }
      final cfs = await _wd.listFiles(st.remoteFolder);
      if (cfs.isNotEmpty && st.syncStrategy != 'upload') {
        final rjs = cfs.where((f) => f.name.endsWith('.json')).toList();
        rjs.sort((a, b) => b.lastModified.compareTo(a.lastModified));
        if (rjs.isNotEmpty) {
          sn.updateProgress(0.6, '正在下载...');
          await _wd.downloadFile('${st.remoteFolder}${rjs.first.name}', '$ld/${rjs.first.name}');
        }
      }
      sn.updateProgress(0.8, '清理旧存档...');
      await _fs.cleanArchives(ld);
      await _ss.setString('last_sync_timestamp', DateTime.now().toIso8601String());
      sn.syncComplete(); return true;
    } catch (e) { sn.syncError(e.toString()); return false; }
  }
}
