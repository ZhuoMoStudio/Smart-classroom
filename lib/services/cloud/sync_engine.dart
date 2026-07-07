import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sync_provider.dart';
import '../../providers/settings_provider.dart';
import '../workspace_service.dart';
import '../storage_service.dart';
import 'webdav_plus_sync.dart';

/// 同步引擎 — 同步工作区下的 xlsx 文件到 WebDAV
class SyncEngine {
  final Ref _ref;
  final WorkspaceService _ws;
  final StorageService _ss;
  final WebdavPlusSyncService _wd;

  SyncEngine(this._ref, this._ws, this._ss, this._wd);

  Future<bool> performSync() async {
    final sn = _ref.read(syncProvider.notifier);
    sn.startSync();
    try {
      final st = _ref.read(settingsProvider);
      final pw = await _ss.getSecure('webdav_password') ?? '';
      sn.updateProgress(0.1, '连接云端...');

      if (!_ws.isConfigured) {
        sn.syncError('工作区未配置');
        return false;
      }

      // 确保远程目录存在
      sn.updateProgress(0.2, '准备远程目录...');
      await _wd.createRemoteDir(dirPath: '学生信息', settings: st, password: pw);
      await _wd.createRemoteDir(dirPath: '题库', settings: st, password: pw);

      // 上传学生信息 xlsx
      sn.updateProgress(0.4, '上传学生信息...');
      final studentFiles = await _ws.listRosterFiles();
      for (final f in studentFiles) {
        await _wd.uploadFile(
          localPath: f.path,
          fileName: '学生信息/${f.path.split('/').last}',
          settings: st,
          password: pw,
        );
      }

      // 上传题库 xlsx
      sn.updateProgress(0.6, '上传题库...');
      final qFiles = await _ws.listQuestionFiles();
      for (final f in qFiles) {
        await _wd.uploadFile(
          localPath: f.path,
          fileName: '题库/${f.path.split('/').last}',
          settings: st,
          password: pw,
        );
      }

      sn.updateProgress(0.8, '同步完成');
      await _ss.setString('last_sync_timestamp', DateTime.now().toIso8601String());
      sn.syncComplete();
      return true;
    } catch (e) {
      sn.syncError(e.toString());
      return false;
    }
  }
}
