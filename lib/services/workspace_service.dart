import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/class_model.dart';
import '../models/question_bank.dart';
import 'excel_service.dart';
import 'storage_service.dart';

/// 工作区管理服务
///
/// 管理用户选择的根文件夹，自动识别：
/// - 学生信息/   → 存放班级/成员/积分 xlsx
/// - 题库/       → 存放所有题库 xlsx
///
/// 结构：
///   根文件夹/
///   ├── 学生信息/
///   │   ├── 班级名单.xlsx
///   │   └── ...
///   ├── 题库/
///   │   ├── 数学题库.xlsx
///   │   └── ...
///   └── 数据存档/
class WorkspaceService {
  static const String _rootPathKey = 'workspace_root_path';
  static const String _studentsDir = '学生信息';
  static const String _questionsDir = '题库';
  static const String _archiveDir = '数据存档';

  String? _rootPath;

  /// 获取或设置根路径
  String? get rootPath => _rootPath;

  /// 设置根路径
  Future<void> setRootPath(String path) async {
    _rootPath = path;
    final prefs = await SharedPreferencesHelper.getInstance();
    await prefs.setString(_rootPathKey, path);
    await _ensureDirectories();
  }

  /// 加载保存的路径
  Future<void> loadSavedPath() async {
    final prefs = await SharedPreferencesHelper.getInstance();
    final saved = prefs.getString(_rootPathKey);
    if (saved != null && Directory(saved).existsSync()) {
      _rootPath = saved;
      await _ensureDirectories();
    }
  }

  /// 让用户选择文件夹
  Future<String?> pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      await setRootPath(path);
    }
    return path;
  }

  /// 确保子目录存在
  Future<void> _ensureDirectories() async {
    if (_rootPath == null) return;
    for (final dir in [_studentsDir, _questionsDir, _archiveDir]) {
      final d = Directory('$_rootPath/$dir');
      if (!await d.exists()) {
        await d.create(recursive: true);
        debugPrint('Workspace: 创建目录 $dir');
      }
    }
  }

  /// 学生信息目录
  String? get studentsPath => _rootPath != null ? '$_rootPath/$_studentsDir' : null;

  /// 题库目录
  String? get questionsPath => _rootPath != null ? '$_rootPath/$_questionsDir' : null;

  /// 数据存档目录
  String? get archivePath => _rootPath != null ? '$_rootPath/$_archiveDir' : null;

  // ==================== 学生名单管理 ====================

  /// 获取所有学生名单文件
  Future<List<File>> listRosterFiles() async {
    if (studentsPath == null) return [];
    final dir = Directory(studentsPath!);
    if (!await dir.exists()) return [];
    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.xlsx')) {
        files.add(entity);
      }
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  /// 从所有名单文件加载班级数据（含积分）
  Future<List<Classroom>> loadAllRosters() async {
    final files = await listRosterFiles();
    final allClassrooms = <Classroom>[];
    for (final f in files) {
      try {
        final classrooms = await ExcelService.parseRoster(f.path);
        allClassrooms.addAll(classrooms);
      } catch (e) {
        debugPrint('加载名单失败 ${f.path}: $e');
      }
    }
    return allClassrooms;
  }

  /// 保存积分到xlsx文件（更新现有文件或创建新文件）
  Future<void> saveScores(List<Classroom> classrooms) async {
    if (studentsPath == null) return;
    await _ensureDirectories();

    // 按班级名分组，每个班级保存为一个xlsx文件
    for (final cls in classrooms) {
      final safeName = cls.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final filePath = '$studentsPath/$safeName.xlsx';
      await ExcelService.writeRosterWithScores(cls, filePath);
    }
  }

  /// 如果学生信息目录为空，创建初始模板
  Future<void> ensureInitialTemplates() async {
    await _ensureDirectories();
    final files = await listRosterFiles();
    if (files.isEmpty && studentsPath != null) {
      await ExcelService.exportMemberTemplate('$studentsPath/示例名单.xlsx');
      debugPrint('Workspace: 创建初始学生名单模板');
    }
    final qFiles = await listQuestionFiles();
    if (qFiles.isEmpty && questionsPath != null) {
      await ExcelService.exportQuestionTemplate('$questionsPath/示例题库.xlsx');
      debugPrint('Workspace: 创建初始题库模板');
    }
  }

  // ==================== 题库管理 ====================

  /// 获取所有题库文件
  Future<List<File>> listQuestionFiles() async {
    if (questionsPath == null) return [];
    final dir = Directory(questionsPath!);
    if (!await dir.exists()) return [];
    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.xlsx')) {
        files.add(entity);
      }
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  /// 从所有题库文件加载题库
  Future<List<QuestionBank>> loadAllQuestionBanks() async {
    final files = await listQuestionFiles();
    final banks = <QuestionBank>[];
    for (final f in files) {
      try {
        final bank = await ExcelService.parseQuestionBank(
          f.path,
          f.path.split('/').last.replaceAll('.xlsx', ''),
        );
        banks.add(bank);
      } catch (e) {
        debugPrint('加载题库失败 ${f.path}: $e');
      }
    }
    return banks;
  }

  /// 工作区是否已配置
  bool get isConfigured => _rootPath != null;
}

/// WorkspaceService Provider
final workspaceServiceProvider = Provider<WorkspaceService>((ref) {
  return WorkspaceService();
});

/// 简易SharedPreferences封装
class SharedPreferencesHelper {
  static final Map<String, dynamic> _memory = {};
  static SharedPreferencesHelper? _instance;
  factory SharedPreferencesHelper.getInstance() => _instance ??= SharedPreferencesHelper._();
  SharedPreferencesHelper._();

  String getString(String key, [String defaultValue = '']) => _memory[key]?.toString() ?? defaultValue;
  Future<void> setString(String key, String value) async { _memory[key] = value; }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
