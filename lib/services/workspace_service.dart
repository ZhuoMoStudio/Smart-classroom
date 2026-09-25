import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/class_model.dart';
import '../models/question_bank.dart';
import 'app_log.dart';
import 'excel_service.dart';
import 'roster_manager.dart';
import 'storage_service.dart';

/// 工作区管理服务
///
/// 目录约定（老师选定的根文件夹下）：
///   学生信息/  —— 既是「导入名单的投放点」，也是「本应用保存积分的落点」
///   题库/      —— 题库 xlsx
///   数据存档/  —— 被淘汰的旧名单、同步冲突备份、批注 JSON
class WorkspaceService {
  static const String _rootPathKey = 'workspace_root_path';
  static const String _studentsDir = '学生信息';
  static const String _questionsDir = '题库';
  static const String _archiveDir = '数据存档';

  final Ref _ref;
  String? _rootPath;

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  WorkspaceService(this._ref);

  StorageService get _storage => _ref.read(storageServiceProvider);

  String? get rootPath => _rootPath;

  /// 根文件夹名（用于界面显示）。以前界面用 `path.split('/')` 取，
  /// 在 Windows 上整条路径都会被当成文件夹名。
  String get rootFolderName =>
      _rootPath == null ? '未设置' : fileNameOf(_rootPath!);

  Future<void> setRootPath(String path) async {
    _rootPath = path;
    await _storage.setString(_rootPathKey, path);
    await _ensureDirectories();
  }

  Future<void> loadSavedPath() async {
    final saved = _storage.getString(_rootPathKey);
    if (saved.isNotEmpty && Directory(saved).existsSync()) {
      _rootPath = saved;
      await _ensureDirectories();
    }
  }

  Future<String?> pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      await setRootPath(path);
    }
    return path;
  }

  Future<void> _ensureDirectories() async {
    if (_rootPath == null) return;
    for (final dir in [_studentsDir, _questionsDir, _archiveDir]) {
      final d = Directory('$_rootPath/$dir');
      if (!await d.exists()) {
        await d.create(recursive: true);
        AppLog.info('工作区', '创建目录 $dir');
      }
    }
  }

  String? get studentsPath =>
      _rootPath != null ? '$_rootPath/$_studentsDir' : null;
  String? get questionsPath =>
      _rootPath != null ? '$_rootPath/$_questionsDir' : null;
  String? get archivePath =>
      _rootPath != null ? '$_rootPath/$_archiveDir' : null;

  // ==================== 路径工具 ====================

  /// 取路径里的文件名，同时兼容 `/` 与 `\`。
  /// 原先各处用 `path.split('/').last`，在 Windows 上会返回整条路径，
  /// 导致云同步把绝对路径当远程文件名上传。
  static String fileNameOf(String path) {
    final i = path.lastIndexOf(RegExp(r'[/\\]'));
    return i < 0 ? path : path.substring(i + 1);
  }

  /// 取不含扩展名的文件名。
  static String fileBaseNameOf(String path) {
    final name = fileNameOf(path);
    final dot = name.lastIndexOf('.');
    return dot <= 0 ? name : name.substring(0, dot);
  }

  static String _sanitize(String name) =>
      name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

  static String _stamp() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}${two(n.month)}${two(n.day)}-'
        '${two(n.hour)}${two(n.minute)}${two(n.second)}';
  }

  // ==================== 学生名单管理 ====================

  Future<List<File>> listRosterFiles() async {
    if (studentsPath == null) return [];
    final dir = Directory(studentsPath!);
    if (!await dir.exists()) return [];
    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.xlsx')) {
        files.add(entity);
      }
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  /// 加载工作区里所有名单。
  ///
  /// 这里要解决一个真实存在的问题：`学生信息/` 既是导入投放点，也是保存落点。
  /// 老师导入 `我的名单.xlsx` 后，应用又把同一个班级保存成 `三年二班.xlsx`，
  /// 于是同一个班级存在于两个文件里。早期实现直接 `addAll` 拼接，
  /// 班级列表里就会出现两个「三年二班」，学生也全都重复。
  ///
  /// 现在按文件格式区分权威性：
  /// 只要某个班级在本应用自己写出的文件里出现过，就只采信这类文件；
  /// 只存在于老师原始文件里的班级（尚未保存过）才从原始文件读取。
  Future<List<Classroom>> loadAllRosters() async {
    final files = await listRosterFiles();
    if (files.isEmpty) return [];

    final parsed = <ParsedRosterFile>[];
    for (final f in files) {
      try {
        parsed.add(await ExcelService.parseRosterFile(f.path));
      } catch (e, st) {
        AppLog.error('工作区', '加载名单失败 ${fileNameOf(f.path)}', e, st);
      }
    }

    final ownNames = <String>{};
    for (final p in parsed.where((p) => p.isAppFormat)) {
      ownNames.addAll(p.classrooms.map((c) => c.name));
    }

    final merged = <String, Classroom>{};
    for (final p in parsed) {
      // 非本应用写出的文件，跳过那些已经有了权威来源的班级
      if (!p.isAppFormat) {
        final only = p.classrooms.where((c) => !ownNames.contains(c.name));
        for (final c in only) {
          _mergeClassroom(merged, c);
        }
      } else {
        for (final c in p.classrooms) {
          _mergeClassroom(merged, c);
        }
      }
    }

    final result = merged.values.toList();
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  /// 按「班级名 → 小组名 → 成员名」逐层合并，同名成员保留分数较高的一份，
  /// 避免任何路径下把积分越读越少。
  static void _mergeClassroom(Map<String, Classroom> merged, Classroom incoming) {
    final existing = merged[incoming.name];
    if (existing == null) {
      merged[incoming.name] = incoming;
      return;
    }

    final groups = <String, Group>{
      for (final g in existing.groups) g.name: g,
    };

    for (final g in incoming.groups) {
      final prev = groups[g.name];
      if (prev == null) {
        groups[g.name] = g;
        continue;
      }
      final members = <String, Member>{
        for (final m in prev.members) m.name: m,
      };
      for (final m in g.members) {
        final dup = members[m.name];
        if (dup == null || m.score > dup.score) members[m.name] = m;
      }
      groups[g.name] = prev.copyWith(members: members.values.toList());
    }

    merged[incoming.name] = existing.copyWith(groups: groups.values.toList());
  }

  /// 上一次保存涉及的文件名集合。
  /// 用作归档检查的短路条件：saveScores 在每次防抖保存后都会调用，
  /// 若每次都对 学生信息/ 下所有 xlsx 做一遍「是不是应用格式」的解析，
  /// 班级一多就会在低端安卓设备上明显卡顿。班级集合没变时无需重复检查。
  Set<String>? _lastSavedFileNames;

  /// 保存积分（带重试），并把已经不存在或被改名的班级的旧文件归档。
  Future<void> saveScores(List<Classroom> classrooms) async {
    if (studentsPath == null) return;
    await _ensureDirectories();

    final written = <String>{};

    for (final cls in classrooms) {
      final safeName = _sanitize(cls.name);
      final filePath = '$studentsPath/$safeName.xlsx';
      written.add('$safeName.xlsx');

      int attempt = 0;
      while (attempt < _maxRetries) {
        try {
          await ExcelService.writeRosterWithScores(cls, filePath);
          break;
        } catch (e, st) {
          attempt++;
          if (attempt >= _maxRetries) {
            AppLog.error(
              '工作区',
              '保存 $safeName.xlsx 失败（已重试 $_maxRetries 次）',
              e,
              st,
            );
            rethrow;
          }
          AppLog.warn('工作区', '保存 $safeName.xlsx 失败，第 $attempt 次重试...');
          await Future.delayed(_retryDelay * attempt);
        }
      }
    }

    final previous = _lastSavedFileNames;
    if (previous == null || !_sameNameSet(previous, written)) {
      await _archiveStaleRosters(written);
      _lastSavedFileNames = written;
    }

    // 同一（年级+班级）的名单只保留「最旧 1 份 + 最新 5 份」。
    // 放在归档之后：先把已不存在的班级搬走，再对仍在使用的班级做版本收敛。
    await _pruneRosterVersions();
  }

  /// 名单版本收敛：同名年级班级只留 keepOldest + keepRecent 份。
  ///
  /// 只对「文件名能被识别出年级班级」的分组生效；
  /// 识别不出的文件一份都不删 —— 分组一旦搞错就会删掉另一个班的名单，
  /// 那是不可逆的数据损失，宁可少清理也不能删错（见 RosterManager 的注释）。
  Future<void> _pruneRosterVersions() async {
    final dir = studentsPath;
    if (dir == null) return;
    try {
      final removed = await RosterManager.applyRetention(dir);
      if (removed > 0) {
        AppLog.info('工作区', '名单版本收敛：淘汰 $removed 份旧名单');
      }
    } catch (e, st) {
      // 清理失败绝不能影响保存本身
      AppLog.error('工作区', '名单版本收敛失败', e, st);
    }
  }

  static bool _sameNameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  /// 把「本应用写过、但当前班级列表里已经没有」的名单文件移到 数据存档/。
  ///
  /// 不这样做会留下两个必现 bug：
  ///   删除班级 → 文件还在 → 下次启动班级又回来了；
  ///   重命名班级 → 旧文件与新文件并存 → 班级列表里出现两个同名班级。
  /// 这里选择归档而不是删除：老师的数据不该由应用悄悄抹掉。
  Future<void> _archiveStaleRosters(Set<String> currentFileNames) async {
    final archive = archivePath;
    if (archive == null) return;
    final dir = Directory(archive);
    if (!await dir.exists()) await dir.create(recursive: true);

    for (final f in await listRosterFiles()) {
      final name = fileNameOf(f.path);
      if (currentFileNames.contains(name)) continue;
      try {
        final parsed = await ExcelService.parseRosterFile(f.path);
        // 只处理本应用自己写出的文件；老师手动放进来的原始名单绝不搬动
        if (!parsed.isAppFormat) continue;
        if (parsed.classrooms.isEmpty) continue;

        final dest = '$archive/${_stamp()}-$name';
        await f.rename(dest);
        AppLog.info('工作区', '旧名单已归档: $name -> 数据存档/');
      } catch (e, st) {
        AppLog.warn('工作区', '归档 ${fileNameOf(f.path)} 失败: $e');
        AppLog.error('工作区', '归档异常 ${fileNameOf(f.path)}', e, st);
      }
    }
  }

  Future<void> ensureInitialTemplates() async {
    await _ensureDirectories();
    final files = await listRosterFiles();
    if (files.isEmpty && studentsPath != null) {
      try {
        await ExcelService.exportMemberTemplate('$studentsPath/示例名单.xlsx');
      } catch (e, st) {
        AppLog.error('工作区', '创建初始模板失败', e, st);
      }
    }
    final qFiles = await listQuestionFiles();
    if (qFiles.isEmpty && questionsPath != null) {
      try {
        await ExcelService.exportQuestionTemplate('$questionsPath/示例题库.xlsx');
      } catch (e, st) {
        AppLog.error('工作区', '创建初始题库模板失败', e, st);
      }
    }
  }

  // ==================== 题库管理 ====================

  Future<List<File>> listQuestionFiles() async {
    if (questionsPath == null) return [];
    final dir = Directory(questionsPath!);
    if (!await dir.exists()) return [];
    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.xlsx')) {
        files.add(entity);
      }
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  Future<List<QuestionBank>> loadAllQuestionBanks() async {
    final files = await listQuestionFiles();
    final banks = <QuestionBank>[];
    for (final f in files) {
      try {
        final bank = await ExcelService.parseQuestionBank(
          f.path,
          fileBaseNameOf(f.path),
        );
        banks.add(bank);
      } catch (e, st) {
        AppLog.error('工作区', '加载题库失败 ${fileNameOf(f.path)}', e, st);
      }
    }
    return banks;
  }

  bool get isConfigured => _rootPath != null;
}

final workspaceServiceProvider =
    Provider<WorkspaceService>((ref) {
  return WorkspaceService(ref);
});
