import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../providers/settings_provider.dart';
import '../../providers/sync_provider.dart';
import '../app_log.dart';
import '../roster_manager.dart';
import '../storage_service.dart';
import '../workspace_service.dart';
import 'webdav_plus_sync.dart';

/// 同步引擎 —— 按修改时间做增量，绝不盲目覆盖
///
/// 三条原则，都是为了不再丢老师的数据：
///  1. **任何一步失败都不能报成功**。旧实现上传失败后仍继续走完并调用
///     syncComplete()，界面显示「同步完成」而文件根本没传上去。
///  2. **只传需要传的**。用 DavResource.modified 比对本地与云端时间戳，
///     而不是把整个目录来回覆盖一遍。旧实现是无条件上传 + 无条件下载，
///     老师在电脑上批改完、手机上同步一下，手机上的旧数据就把新成绩盖掉了。
///  3. **覆盖之前先留底**。内容不同且要覆盖时，先把被覆盖的那一份
///     存进工作区的 `数据存档/`，老师至少还能找回来。
class SyncEngine {
  final Ref _ref;
  final WorkspaceService _ws;
  final StorageService _ss;
  final WebdavPlusSyncService _wd;

  /// mtime 比对的时间容差。
  /// 不同平台/文件系统的秒级精度与写入耗时不一致，过于严格会导致
  /// 「刚同步完又认为有差异」的来回传。
  static const Duration _mtimeTolerance = Duration(seconds: 3);

  SyncEngine(this._ref, this._ws, this._ss, this._wd);

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

      sn.updateProgress(0.05, '测试云端连接...');
      if (!await _wd.testConnection(settings: st, password: pw)) {
        sn.syncError('无法连接云端。请确认地址为 ${WebdavPlusSyncService.jianguoyunUrl} 之类，'
            '且密码为第三方应用密码（不是登录密码）');
        return false;
      }

      sn.updateProgress(0.1, '准备云端目录...');
      if (!await _wd.ensureAppFolders(settings: st, password: pw)) {
        sn.syncError('无法创建云端目录，请确认账号有写入权限');
        return false;
      }

      bool ok = false;
      switch (st.syncStrategy) {
        case 'upload_only':
          sn.updateProgress(0.2, '上传本地文件...');
          ok = await _push(
              settings: st, password: pw, sn: sn,
              from: 0.2, to: 0.9, force: true);
        case 'download_first':
          sn.updateProgress(0.2, '从云端下载...');
          ok = await _pull(
              settings: st, password: pw, sn: sn,
              from: 0.2, to: 0.6, force: true);
          if (ok) {
            sn.updateProgress(0.6, '上传本地文件...');
            ok = await _push(
                settings: st, password: pw, sn: sn,
                from: 0.6, to: 0.9, force: false);
          }
        default:
          // 默认：双向增量。先推新的本地改动，再拉新的云端改动。
          sn.updateProgress(0.2, '比对本地与云端...');
          ok = await _push(
              settings: st, password: pw, sn: sn,
              from: 0.2, to: 0.55, force: false);
          if (ok) {
            ok = await _pull(
                settings: st, password: pw, sn: sn,
                from: 0.55, to: 0.9, force: false);
          }
      }

      if (!ok) {
        // 关键：不在这里覆盖成「完成」，失败就是失败
        AppLog.warn('同步', '同步中断，未记录成功时间戳');
        return false;
      }

      sn.updateProgress(0.95, '保存同步记录...');
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

  // ==================== 路径 ====================

  /// 远端相对路径：`students/<年级班级>/<文件名>`
  String _remoteRosterPath(File f) {
    final name = WorkspaceService.fileNameOf(f.path);
    final seg = RosterManager.pathSegment(name);
    return '${RemoteLayout.students}/$seg/${WebdavPlusSyncService.safeSegment(name)}';
  }

  String _remoteQuestionPath(File f) {
    final name = WorkspaceService.fileNameOf(f.path);
    return '${RemoteLayout.questions}/${WebdavPlusSyncService.safeSegment(name)}';
  }

  // ==================== 上传 ====================

  Future<bool> _push({
    required SettingsState settings,
    required String password,
    required SyncNotifier sn,
    required double from,
    required double to,
    required bool force,
  }) async {
    final rosterFiles = await _ws.listRosterFiles();
    final questionFiles = await _ws.listQuestionFiles();
    final total = rosterFiles.length + questionFiles.length;
    if (total == 0) return true;

    // 一次列全，避免每个文件都发一次 PROPFIND
    final remote = <String, RemoteEntry>{
      for (final e in await _wd.listStudentsRecursive(
          settings: settings, password: password))
        e.relativePath: e,
      for (final e in await _wd.listDir(
          settings: settings,
          password: password,
          relativeDir: RemoteLayout.questions))
        e.relativePath: e,
    };

    int done = 0;
    int failed = 0;
    int skipped = 0;

    Future<void> handle(File f, String relative) async {
      done++;
      final pct = from + (done / total) * (to - from);
      try {
        final localStat = await f.stat();
        final remoteTime = remote[relative]?.modified;

        // 只有「云端确实更新」时才跳过上传；其余情况一律上传。
        // 有些服务端不返回 lastModified，这种情况下保守地上传，
        // 而不是凭猜测跳过 —— 漏传比多传危险得多。
        if (!force && remoteTime != null) {
          if (!localStat.modified.isAfter(remoteTime.add(_mtimeTolerance))) {
            skipped++;
            sn.updateProgress(pct, '上传 ($done/$total)...');
            return;
          }
          // 要覆盖云端：先把云端旧版本留底
          final old = await _wd.downloadFile(
              relativePath: relative, settings: settings, password: password);
          if (old != null) {
            final fresh = await f.readAsBytes();
            if (!_sameBytes(old, fresh)) {
              await _backupBytes(
                  old, '云端备份-${_stamp()}-${p.basename(relative)}');
            }
          }
        }

        final ok = await _wd.uploadFile(
          localPath: f.path,
          relativePath: relative,
          settings: settings,
          password: password,
        );
        if (!ok) {
          failed++;
          AppLog.warn('同步', '上传失败: $relative');
        }
      } catch (e, st) {
        failed++;
        AppLog.error('同步', '上传异常: $relative', e, st);
      }
      sn.updateProgress(pct, '上传 ($done/$total)...');
    }

    for (final f in rosterFiles) {
      await handle(f, _remoteRosterPath(f));
    }
    for (final f in questionFiles) {
      await handle(f, _remoteQuestionPath(f));
    }

    if (skipped > 0) AppLog.info('同步', '上传阶段跳过 $skipped 个（云端更新）');
    if (failed > 0) {
      sn.syncError('有 $failed 个文件上传失败，请检查网络后重试');
      return false;
    }
    return true;
  }

  // ==================== 下载 ====================

  Future<bool> _pull({
    required SettingsState settings,
    required String password,
    required SyncNotifier sn,
    required double from,
    required double to,
    required bool force,
  }) async {
    final studentsPath = _ws.studentsPath;
    final questionsPath = _ws.questionsPath;
    if (studentsPath == null || questionsPath == null) return true;

    final entries = <RemoteEntry>[
      ...await _wd.listStudentsRecursive(settings: settings, password: password),
      ...await _wd.listDir(
          settings: settings,
          password: password,
          relativeDir: RemoteLayout.questions),
    ];
    if (entries.isEmpty) return true;

    int done = 0;
    int failed = 0;
    int skipped = 0;

    for (final e in entries) {
      done++;
      final pct = from + (done / entries.length) * (to - from);

      // 本地不做年级分目录（只有云端分），因此只取文件名回落到扁平目录。
      final localName = WebdavPlusSyncService.safeSegment(e.fileName);
      if (!localName.toLowerCase().endsWith('.xlsx')) {
        sn.updateProgress(pct, '下载 ($done/${entries.length})...');
        continue;
      }

      final isQuestion = e.relativePath.startsWith(RemoteLayout.questions);
      final target =
          File('${isQuestion ? questionsPath : studentsPath}/$localName');

      try {
        if (await target.exists()) {
          final localStat = await target.stat();
          if (!force && e.modified != null) {
            // 本地同样新或更新 → 保留本地（它会在上传阶段被推上去）
            if (!e.modified!.isAfter(localStat.modified.add(_mtimeTolerance))) {
              skipped++;
              sn.updateProgress(pct, '下载 ($done/${entries.length})...');
              continue;
            }
          }
          // 要覆盖本地：先把本地那份留底 —— 老师的批改结果不能被静默盖掉
          final localBytes = await target.readAsBytes();
          final remoteBytes = await _wd.downloadFile(
              relativePath: e.relativePath,
              settings: settings,
              password: password);
          if (remoteBytes == null) {
            failed++;
            AppLog.warn('同步', '下载失败: ${e.relativePath}');
            sn.updateProgress(pct, '下载 ($done/${entries.length})...');
            continue;
          }
          if (!_sameBytes(localBytes, remoteBytes)) {
            await _backupBytes(localBytes, '同步冲突-${_stamp()}-$localName');
          }
          await target.writeAsBytes(remoteBytes, flush: true);
        } else {
          final bytes = await _wd.downloadFile(
              relativePath: e.relativePath,
              settings: settings,
              password: password);
          if (bytes == null) {
            failed++;
            AppLog.warn('同步', '下载失败: ${e.relativePath}');
            sn.updateProgress(pct, '下载 ($done/${entries.length})...');
            continue;
          }
          await target.writeAsBytes(bytes, flush: true);
        }
      } catch (e2, st) {
        failed++;
        AppLog.error('同步', '下载异常: ${e.relativePath}', e2, st);
      }
      sn.updateProgress(pct, '下载 ($done/${entries.length})...');
    }

    if (skipped > 0) AppLog.info('同步', '下载阶段跳过 $skipped 个（本地更新或相同）');
    if (failed > 0) {
      sn.syncError('有 $failed 个文件下载失败，请检查网络后重试');
      return false;
    }
    return true;
  }

  // ==================== 工具 ====================

  Future<void> _backupBytes(List<int> bytes, String label) async {
    final archive = _ws.archivePath;
    if (archive == null) {
      AppLog.warn('同步', '无工作区，跳过备份 $label');
      return;
    }
    try {
      final dir = Directory(archive);
      if (!await dir.exists()) await dir.create(recursive: true);
      await File(p.join(archive, label)).writeAsBytes(bytes, flush: true);
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
