import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sync_provider.dart';
import '../../providers/settings_provider.dart';
import '../workspace_service.dart';
import '../storage_service.dart';
import 'webdav_plus_sync.dart';

/// 同步引擎 — v1.30 双向同步
class SyncEngine {
  final Ref _ref;
  final WorkspaceService _ws;
  final StorageService _ss;
  final WebdavPlusSyncService _wd;

  SyncEngine(this._ref, this._ws, this._ss, this._wd);

  /// 执行完整同步
  Future<bool> performSync() async {
    final sn = _ref.read(syncProvider.notifier);
    sn.startSync();

    try {
      final st = _ref.read(settingsProvider);
      final pw = await _ss.getSecure('webdav_password') ?? '';

      if (!_ws.isConfigured) {
        sn.syncError('工作区未配置');
        return false;
      }

      if (st.webdavUsername.isEmpty || !st.webdavUrl.startsWith('http')) {
        sn.syncError('WebDAV 未配置');
        return false;
      }

      // 测试连接
      sn.updateProgress(0.03, '测试云端连接...');
      final connected =
          await _wd.testConnection(settings: st, password: pw);
      if (!connected) {
        sn.syncError('无法连接云端，请检查地址和密码');
        return false;
      }

      // 确保远程目录存在
      sn.updateProgress(0.08, '准备远程目录...');
      await _wd.createRemoteDir(
          dirPath: '学生信息', settings: st, password: pw);
      await _wd.createRemoteDir(dirPath: '题库', settings: st, password: pw);

      final strategy = st.syncStrategy;

      if (strategy == 'download_first') {
        // 先下载后上传
        sn.updateProgress(0.1, '从云端下载...');
        await _downloadAll(st, pw, sn, 0.1, 0.45);
        sn.updateProgress(0.5, '上传本地文件...');
        await _uploadAll(st, pw, sn, 0.5, 0.85);
      } else if (strategy == 'upload_only') {
        sn.updateProgress(0.1, '上传本地文件...');
        await _uploadAll(st, pw, sn, 0.1, 0.85);
      } else {
        // bidirectional (default): upload first, then download
        sn.updateProgress(0.1, '上传本地文件...');
        await _uploadAll(st, pw, sn, 0.1, 0.5);
        sn.updateProgress(0.55, '从云端下载...');
        await _downloadAll(st, pw, sn, 0.55, 0.85);
      }

      sn.updateProgress(0.9, '保存同步记录...');
      await _ss.setString(
          'last_sync_timestamp', DateTime.now().toIso8601String());

      sn.syncComplete();
      return true;
    } catch (e) {
      sn.syncError('同步异常: $e');
      return false;
    }
  }

  /// 上传所有文件
  Future<void> _uploadAll(SettingsState st, String pw, SyncNotifier sn,
      double startPct, double endPct) async {
    final sFiles = await _ws.listRosterFiles();
    final qFiles = await _ws.listQuestionFiles();
    final total = sFiles.length + qFiles.length;
    if (total == 0) return;

    int done = 0;
    for (final f in sFiles) {
      final ok = await _wd.uploadFile(
        localPath: f.path,
        fileName: '学生信息/${f.path.split('/').last}',
        settings: st,
        password: pw,
      );
      done++;
      final p = startPct + (done / total) * (endPct - startPct);
      sn.updateProgress(p, '上传 ($done/$total)...');
      if (!ok) {
        sn.syncError('上传失败: ${f.path.split('/').last}');
        return;
      }
    }
    for (final f in qFiles) {
      final ok = await _wd.uploadFile(
        localPath: f.path,
        fileName: '题库/${f.path.split('/').last}',
        settings: st,
        password: pw,
      );
      done++;
      final p = startPct + (done / total) * (endPct - startPct);
      sn.updateProgress(p, '上传 ($done/$total)...');
      if (!ok) {
        sn.syncError('上传失败: ${f.path.split('/').last}');
        return;
      }
    }
  }

  /// 下载所有远程文件到本地
  Future<void> _downloadAll(SettingsState st, String pw, SyncNotifier sn,
      double startPct, double endPct) async {
    final remoteStudents = await _wd.listRemoteFiles(
        dirName: '学生信息', settings: st, password: pw);
    final remoteQuestions = await _wd.listRemoteFiles(
        dirName: '题库', settings: st, password: pw);
    final total = remoteStudents.length + remoteQuestions.length;
    if (total == 0) return;

    int done = 0;
    final studentsPath = _ws.studentsPath;
    final questionsPath = _ws.questionsPath;

    if (studentsPath != null) {
      for (final name in remoteStudents) {
        final bytes = await _wd.downloadFile(
          fileName: '学生信息/$name',
          settings: st,
          password: pw,
        );
        if (bytes != null) {
          await File('$studentsPath/$name').writeAsBytes(bytes);
        }
        done++;
        final p = startPct + (done / total) * (endPct - startPct);
        sn.updateProgress(p, '下载 ($done/$total)...');
      }
    }
    if (questionsPath != null) {
      for (final name in remoteQuestions) {
        final bytes = await _wd.downloadFile(
          fileName: '题库/$name',
          settings: st,
          password: pw,
        );
        if (bytes != null) {
          await File('$questionsPath/$name').writeAsBytes(bytes);
        }
        done++;
        final p = startPct + (done / total) * (endPct - startPct);
        sn.updateProgress(p, '下载 ($done/$total)...');
      }
    }
  }
}
