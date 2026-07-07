import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/class_model.dart';
import '../models/question_bank.dart';
import 'excel_service.dart';
import 'storage_service.dart';

/// 工作区管理服务 — v1.30 文件锁重试
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
        debugPrint('Workspace: 创建目录 $dir');
      }
    }
  }

  String? get studentsPath =>
      _rootPath != null ? '$_rootPath/$_studentsDir' : null;
  String? get questionsPath =>
      _rootPath != null ? '$_rootPath/$_questionsDir' : null;
  String? get archivePath =>
      _rootPath != null ? '$_rootPath/$_archiveDir' : null;

  // ==================== 学生名单管理 ====================

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

  /// 保存积分（带重试）
  Future<void> saveScores(List<Classroom> classrooms) async {
    if (studentsPath == null) return;
    await _ensureDirectories();

    for (final cls in classrooms) {
      final safeName =
          cls.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final filePath = '$studentsPath/$safeName.xlsx';

      int attempt = 0;
      while (attempt < _maxRetries) {
        try {
          await ExcelService.writeRosterWithScores(cls, filePath);
          break;
        } catch (e) {
          attempt++;
          if (attempt >= _maxRetries) {
            debugPrint(
                'Workspace: 保存 $filePath 失败（已重试 $_maxRetries 次）: $e');
            rethrow;
          }
          debugPrint(
              'Workspace: 保存 $filePath 失败，第 $attempt 次重试...');
          await Future.delayed(_retryDelay * attempt);
        }
      }
    }
  }

  Future<void> ensureInitialTemplates() async {
    await _ensureDirectories();
    final files = await listRosterFiles();
    if (files.isEmpty && studentsPath != null) {
      try {
        await ExcelService.exportMemberTemplate(
            '$studentsPath/示例名单.xlsx');
      } catch (e) {
        debugPrint('创建初始模板失败: $e');
      }
    }
    final qFiles = await listQuestionFiles();
    if (qFiles.isEmpty && questionsPath != null) {
      try {
        await ExcelService.exportQuestionTemplate(
            '$questionsPath/示例题库.xlsx');
      } catch (e) {
        debugPrint('创建初始题库模板失败: $e');
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
      if (entity is File && entity.path.endsWith('.xlsx')) {
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
          f.path.split('/').last.replaceAll('.xlsx', ''),
        );
        banks.add(bank);
      } catch (e) {
        debugPrint('加载题库失败 ${f.path}: $e');
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
