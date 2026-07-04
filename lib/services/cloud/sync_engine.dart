import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sync_provider.dart';
import '../../providers/settings_provider.dart';
import '../file_service.dart';
import '../storage_service.dart';
import 'webdav_plus_sync.dart';

/// 同步引擎 — 使用 webdav_plus 包
class SyncEngine {
  final Ref _ref;
  final FileService _fs;
  final StorageService _ss;
  final WebdavPlusSyncService _wd;

  SyncEngine(this._ref, this._fs, this._ss, this._wd);

  Future<bool> performSync() async {
    final sn = _ref.read(syncProvider.notifier);
    sn.startSync();
    try {
      final st = _ref.read(settingsProvider);
      final pw =
          await _ss.getSecure('webdav_password') ?? '';
      sn.updateProgress(0.1, '已连接云端');

      final ld = await _fs.getWorkingDir();
      final lfs = await _fs.listArchives(ld);

      // 确保远程目录存在
      sn.updateProgress(0.2, '准备远程目录...');
      await _wd.createRemoteDir(dirPath: '', settings: st, password: pw);

      if (lfs.isNotEmpty && st.syncStrategy != 'download') {
        sn.updateProgress(0.4, '正在上传...');
        await _wd.uploadFile(
          localPath: lfs.first.path,
          fileName: 'data.json',
          settings: st,
          password: pw,
        );
      }

      // 下载远程文件
      if (st.syncStrategy != 'upload') {
        sn.updateProgress(0.6, '正在下载...');
        final data = await _wd.downloadFile(
          fileName: 'data.json',
          settings: st,
          password: pw,
        );
        if (data != null) {
          await File('$ld/remote_backup.json').writeAsBytes(data);
        }
      }

      sn.updateProgress(0.8, '清理旧存档...');
      await _fs.cleanArchives(ld);
      await _ss.setString(
        'last_sync_timestamp',
        DateTime.now().toIso8601String(),
      );
      sn.syncComplete();
      return true;
    } catch (e) {
      sn.syncError(e.toString());
      return false;
    }
  }
}
