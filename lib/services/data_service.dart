import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_bank.dart';
import '../providers/class_provider.dart';
import '../providers/question_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/services_provider.dart';
import 'file_service.dart';

/// 数据管理服务 — 集中化保存/加载逻辑
///
/// 特性：
/// - 防抖自动保存（dirty 后 N 秒内无新修改才保存）
/// - 生命周期自动保存（应用进入后台时）
/// - 统一的 save()/load() API
/// - 所有 save/load 操作过该服务，避免状态不一致
class DataService {
  final Ref _ref;
  Timer? _debounceTimer;
  bool _saving = false;

  static const Duration _debounceDuration = Duration(seconds: 5);

  DataService(this._ref);

  /// 获取 FileService
  FileService get _fileService => _ref.read(fileServiceProvider);

  /// 保存数据，含防抖合并
  ///
  /// 多次连续调用会被合并，仅在最后一次调用后 [debounceDuration] 内
  /// 无新调用时真正执行
  Future<void> save({bool silent = false, bool immediate = false}) async {
    if (_saving) return;

    // 如果要求立即保存，取消防抖直接执行
    if (immediate) {
      _debounceTimer?.cancel();
      await _doSave(silent: silent);
      return;
    }

    // 防抖：重置计时器
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () async {
      await _doSave(silent: silent);
    });
  }

  /// 立即保存（不经过防抖，用于退出/切后台等场景）
  Future<void> saveImmediate({bool silent = true}) async {
    await save(silent: silent, immediate: true);
  }

  /// 实际执行保存
  Future<void> _doSave({bool silent = false}) async {
    if (_saving) return;
    _saving = true;

    try {
      final cs = _ref.read(classProvider);
      final qs = _ref.read(questionProvider);

      if (!cs.isDirty && !qs.isDirty) return;

      final data = AppData(
        classrooms: cs.classrooms,
        questionBanks: qs.banks,
        lastModified: DateTime.now().toIso8601String(),
      );

      final file = await _fileService.saveJson(data);
      _ref.read(classProvider.notifier).clearDirty();
      _ref.read(questionProvider.notifier).clearDirty();
      _fileService.autoCleanup(await _fileService.getWorkingDir());

      debugPrint('DataService: saved to ${file.path}');
    } catch (e) {
      debugPrint('DataService: save error - $e');
      if (!silent) rethrow;
    } finally {
      _saving = false;
    }
  }

  /// 加载数据（从用户选择的 JSON 文件）
  Future<void> load() async {
    try {
      final data = await _fileService.pickAndLoadJson();
      if (data != null) {
        _ref.read(classProvider.notifier).loadFromData(
              data.classrooms,
              data.classrooms.isNotEmpty ? data.classrooms.first.uid : null,
            );
        _ref.read(questionProvider.notifier).loadFromData(data.questionBanks);
      }
    } catch (e) {
      debugPrint('DataService: load error - $e');
      rethrow;
    }
  }

  /// 检查是否还有未保存的修改
  bool get hasUnsavedChanges {
    final cs = _ref.read(classProvider);
    final qs = _ref.read(questionProvider);
    return cs.isDirty || qs.isDirty;
  }

  /// 取消待处理的防抖保存
  void cancelPendingSave() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// 清理
  void dispose() {
    _debounceTimer?.cancel();
  }
}

/// DataService Provider — 懒加载单例
final dataServiceProvider = Provider<DataService>((ref) {
  final service = DataService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

/// 自动保存 Provider — 监听 dirty 状态并触发防抖保存
final autoSaveProvider = Provider.autoDispose<void>((ref) {
  final dataService = ref.watch(dataServiceProvider);
  final cs = ref.watch(classProvider);
  final settings = ref.watch(settingsProvider);

  // 监听 dirty 状态变化，触发防抖保存
  if (cs.isDirty && settings.autoSave) {
    dataService.save(silent: true);
  }

  // 返回 void，仅用于触发副作用
});
