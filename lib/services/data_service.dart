import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_bank.dart';
import '../providers/class_provider.dart';
import '../providers/question_provider.dart';
import '../providers/settings_provider.dart';
import 'workspace_service.dart';

/// 数据管理服务 — 基于工作区文件夹的保存/加载
///
/// 保存策略：
/// - 班级/成员/积分 → 写入 学生信息/*.xlsx（每个班级一个文件）
/// - 题库 → 从 题库/*.xlsx 加载
class DataService {
  final Ref _ref;
  Timer? _debounceTimer;
  bool _saving = false;

  static const Duration _debounceDuration = Duration(seconds: 5);

  DataService(this._ref);

  WorkspaceService get _ws => _ref.read(workspaceServiceProvider);

  /// 保存积分到 xlsx（防抖合并）
  Future<void> save({bool silent = false, bool immediate = false}) async {
    if (_saving) return;
    if (immediate) {
      _debounceTimer?.cancel();
      await _doSaveScores();
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () async {
      await _doSaveScores();
    });
  }

  /// 立即保存
  Future<void> saveImmediate({bool silent = true}) async {
    await save(silent: silent, immediate: true);
  }

  /// 实际写入积分到 xlsx
  Future<void> _doSaveScores() async {
    if (_saving) return;
    _saving = true;
    try {
      final cs = _ref.read(classProvider);
      if (!cs.isDirty) return;
      if (!_ws.isConfigured) {
        debugPrint('DataService: 工作区未配置，跳过保存');
        return;
      }
      await _ws.saveScores(cs.classrooms);
      _ref.read(classProvider.notifier).clearDirty();
      debugPrint('DataService: 积分已保存');
    } catch (e) {
      debugPrint('DataService: 保存错误 - $e');
    } finally {
      _saving = false;
    }
  }

  /// 从工作区加载所有数据
  Future<void> loadFromWorkspace() async {
    try {
      final classrooms = await _ws.loadAllRosters();
      if (classrooms.isNotEmpty) {
        _ref.read(classProvider.notifier).loadFromData(
              classrooms,
              classrooms.first.uid,
            );
      }
      final banks = await _ws.loadAllQuestionBanks();
      if (banks.isNotEmpty) {
        _ref.read(questionProvider.notifier).loadFromData(banks);
      }
      debugPrint('DataService: 从工作区加载完成');
    } catch (e) {
      debugPrint('DataService: 加载错误 - $e');
    }
  }

  /// 检查是否还有未保存的修改
  bool get hasUnsavedChanges => _ref.read(classProvider).isDirty;

  /// 取消待处理的防抖保存
  void cancelPendingSave() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}

/// DataService Provider
final dataServiceProvider = Provider<DataService>((ref) {
  final service = DataService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

/// 自动保存 Provider
final autoSaveProvider = Provider.autoDispose<void>((ref) {
  final dataService = ref.watch(dataServiceProvider);
  final cs = ref.watch(classProvider);
  final settings = ref.watch(settingsProvider);
  if (cs.isDirty && settings.autoSave) {
    dataService.save(silent: true);
  }
});
