import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sync_provider.dart';
import '../../providers/settings_provider.dart';
import '../app_log.dart';
import '../workspace_service.dart';
import '../storage_service.dart';
import 'webdav_plus_sync.dart';

/// 同步引擎 — WebDAV 双向同步
///
/// 核心原则：**任何一步失败都不能报成功，任何一次覆盖都要先留底。**
/// 旧实现有两处会直接毁掉老师的数据：
///   1. 上传失败时只调用 syncError 然后 return，performSync 却继续往下走，
///      最后调用 syncComplete —— 界面显示「同步完成」，实际文件根本没传上去；
///   2. 下载时无条件覆盖本地文件。老师在电脑上批改完、手机上同步一下，
///      手机上的旧数据会把电脑上的新成绩覆盖掉，且不留任何痕迹。
class SyncEngine {
  final Ref _ref;
  final WorkspaceService _ws;
  final StorageService _ss;
  final WebdavPlusSyncService _wd;

  SyncEngine(this._ref, this._ws, this._ss, this._wd);

  /// 执行完整同步。返回是否真正成功。
  Future<bool> performSync() async {
    final sn = _ref.read(syncProvider.notifier);
    sn.startSync();

    try {
      final st = _ref.read(settingsProvider);
      final pw = await _ss.getSecure('webdav_password') ?? '';

      if (!_ws.isConfigured) {
        sn.syncError('工作目录未设置');
        return false;
      }

      if (st.webdavUsername.isEmpty || !st.webdavUrl.startsWith('http')) {
        sn.syncError('WebDAV 未配置');
        return false;
      }

      sn.updateProgress(0.03, '测试云端连接...');
      final connected = await _wd.testConnection(settings: st, password: pw);
      if (!connected) {
        sn.syncError('无法连接云端，请检查地址和密码');
        AppLog.warn('同步', '连接测试失败: ${st.webdavUrl}');
        return false;
      }

      sn.updateProgress(0.08, '准备远程目录...');
      final madeStudents = await _wd.createRemoteDir(
          dirPath: '学生信息', settings: st, password: pw);
      final madeQuestions = await _wd.createRemoteDir(
          dirPath: '题库', settings: st, password: pw);
      if (!madeStudents || !madeQuestions) {
        // 目录建不出来时后续上传必然失败，早点说清楚
        sn.syncError('无法创建云端目录，请确认账号有写入权限');
        return false;
      }

      final strategy = st.syncStrategy;
      bool ok;

      if (strategy == 'download_first') {
        sn.updateProgress(0.1, '从云端下载...');
        ok = await _downloadAll(st, pw, sn, 0.1, 0.45);
        if (ok) {
          sn.updateProgress(0.5, '上传本地文件...');
          ok = await _uploadAll(st, pw, sn, 0.5, 0.85);
        }
      } else if (strategy == 'upload_only') {
        sn.updateProgress(0.1, '上传本地文件...');
        ok = await _uploadAll(st, pw, sn, 0.1, 0.85);
      } else {
        // bidirectional（默认）：先上传再下载
        sn.updateProgress(0.1, '上传本地文件...');
        ok = await _uploadAll(st, pw, sn, 0.1, 0.5);
        if (ok) {
          sn.updateProgress(0.55, '从云端下载...');
          ok = await _downloadAll(st, pw, sn, 0.55, 0.85);
        }
      }

      if (!ok) {
        // 关键：不要在这里覆盖成「完成」，失败就是失败
        AppLog.warn('同步', '同步中断，未记录成功时间戳');
        return false;
      }

      sn.updateProgress(0.9, '保存同步记录...');
      await _ss.setString(
          'last_sync_timestamp', DateTime.now().toIso8601String());

      sn.syncComplete();
      AppLog.info('同步', '同步完成');
      return true;
    } catch (e, st) {
      sn.syncError('同步异常: $e');
      AppLog.error('同步', '同步异常', e, st);
      return false;
    }
  }

  /// 上传所有文件。返回是否全部成功。
  Future<bool> _uploadAll(SettingsState st, String pw, SyncNotifier sn,
      double startPct, double endPct) async {
    final sFiles = await _ws.listRosterFiles();
    final qFiles = await _ws.listQuestionFiles();
    final total = sFiles.length + qFiles.length;
    if (total == 0) return true;

    int done = 0;
    int failed = 0;

    Future<bool> push(File f, String dir) async {
      // 文件名只取末段：Windows 上 f.path 用反斜杠，
      // 旧实现 split('/').last 会把整条路径当文件名传给云端
      final name = WorkspaceService.fileNameOf(f.path);
      final relative = '$dir/$name';
      final localBytes = await f.readAsBytes();

      // 覆盖云端之前，先把云端的旧版本留一份到 数据存档/
      final existing = await _wd.downloadFile(
          fileName: relative, settings: st, password: pw);
      if (existing != null && !_sameBytes(existing, localBytes)) {
        await _backupBytes(existing, '云端备份-${_stamp()}-$name');
      }

      final ok = await _wd.uploadFile(
        localPath: f.path,
        fileName: relative,
        settings: st,
        password: pw,
      );
      if (!ok) {
        failed++;
        AppLog.warn('同步', '上传失败: $relative');
        sn.syncError('上传失败: $name');
      }
      done++;
      sn.updateProgress(
          startPct + (done / total) * (endPct - startPct), '上传 ($done/$total)...');
      return ok;
    }

    for (final f in sFiles) {
      await push(f, '学生信息');
    }
    for (final f in qFiles) {
      await push(f, '题库');
    }

    if (failed > 0) {
      sn.syncError('有 $failed 个文件上传失败，请检查网络后重试');
      return false;
    }
    return true;
  }

  /// 下载所有远程文件到本地。返回是否全部成功。
  Future<bool> _downloadAll(SettingsState st, String pw, SyncNotifier sn,
      double startPct, double endPct) async {
    final remoteStudents =
        await _wd.listRemoteFiles(dirName: '学生信息', settings: st, password: pw);
    final remoteQuestions =
        await _wd.listRemoteFiles(dirName: '题库', settings: st, password: pw);
    final total = remoteStudents.length + remoteQuestions.length;
    if (total == 0) return true;

    int done = 0;
    int failed = 0;
    final studentsPath = _ws.studentsPath;
    final questionsPath = _ws.questionsPath;

    Future<void> pull(String rawName, String dir, String? destDir) async {
      // 只取末段，同时也是防目录穿越：远端若给出 ../ 之类名字也不会写到目录外
      final name = WorkspaceService.fileNameOf(rawName);
      done++;
      final pct = startPct + (done / total) * (endPct - startPct);

      if (destDir == null || !name.toLowerCase().endsWith('.xlsx')) {
        sn.updateProgress(pct, '下载 ($done/$total)...');
        return;
      }

      final bytes = await _wd.downloadFile(
        fileName: '$dir/$name',
        settings: st,
        password: pw,
      );
      if (bytes == null) {
        failed++;
        AppLog.warn('同步', '下载失败: $dir/$name');
        sn.updateProgress(pct, '下载 ($done/$total)...');
        return;
      }

      final target = File('$destDir/$name');
      if (await target.exists()) {
        final local = await target.readAsBytes();
        // 内容不同 = 冲突。把本地那份先留底，绝不直接覆盖掉老师的批改结果。
        if (!_sameBytes(local, bytes)) {
          await _backupBytes(local, '同步冲突-${_stamp()}-$name');
        }
      }
      await target.writeAsBytes(bytes, flush: true);
      sn.updateProgress(pct, '下载 ($done/$total)...');
    }

    for (final n in remoteStudents) {
      await pull(n, '学生信息', studentsPath);
    }
    for (final n in remoteQuestions) {
      await pull(n, '题库', questionsPath);
    }

    if (failed > 0) {
      sn.syncError('有 $failed 个文件下载失败，请检查网络后重试');
      return false;
    }
    return true;
  }

  /// 覆盖之前留底。取不到工作区时只告警，不阻断同步。
  Future<void> _backupBytes(List<int> bytes, String label) async {
    final archive = _ws.archivePath;
    if (archive == null) {
      AppLog.warn('同步', '无工作区，跳过备份 $label');
      return;
    }
    try {
      final dir = Directory(archive);
      if (!await dir.exists()) await dir.create(recursive: true);
      await File('$archive/$label').writeAsBytes(bytes, flush: true);
      AppLog.info('同步', '已备份到 数据存档/$label');
    } catch (e, st) {
      AppLog.error('同步', '备份失败 $label', e, st);
    }
  }

  static bool _sameBytes(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static String _stamp() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}${two(n.month)}${two(n.day)}-'
        '${two(n.hour)}${two(n.minute)}${two(n.second)}';
  }
}
