import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_provider.dart';
import '../providers/draw_provider.dart';
import '../providers/question_provider.dart';
import '../providers/services_provider.dart';
import '../providers/settings_provider.dart';
import 'app_log.dart';
import 'pdf_cache_manager.dart';
import 'workspace_service.dart';

/// 数据管理服务 — 基于工作区文件夹的保存/加载
///
/// 保存策略：
/// - 班级/成员/积分 → 写入 学生信息/*.xlsx（每个班级一个文件）
/// - 题库 → 从 题库/*.xlsx 加载
/// - 教材 PDF → 缓存在 课本/（工作区内，跨设备可直接读取）
class DataService {
  final Ref _ref;
  Timer? _debounceTimer;
  bool _saving = false;

  /// 保存进行中又到来的请求。旧实现直接把它丢掉，导致「最后一次改动永远不落盘」。
  bool _saveQueued = false;

  String? _lastError;

  static const Duration _debounceDuration = Duration(seconds: 5);

  DataService(this._ref);

  WorkspaceService get _ws => _ref.read(workspaceServiceProvider);

  /// 最近一次保存失败的原因，供界面显示。以前失败只写 debugPrint，老师完全看不到。
  String? get lastError => _lastError;

  /// 保存积分到 xlsx（防抖合并）
  Future<bool> save({
    bool silent = false,
    bool immediate = false,
    bool force = false,
  }) async {
    if (immediate) {
      _debounceTimer?.cancel();
      _debounceTimer = null;
      return _doSaveScores(force: force);
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _doSaveScores(force: force);
    });
    return true; // 已受理，等待防抖
  }

  /// 立即保存
  Future<bool> saveImmediate({bool silent = true, bool force = false}) =>
      save(silent: silent, immediate: true, force: force);

  /// 实际写入积分到 xlsx
  Future<bool> _doSaveScores({bool force = false}) async {
    if (_saving) {
      // 不丢弃：等当前这次写完后补一次，否则这段时间里的改动会永远丢
      _saveQueued = true;
      return false;
    }

    _saving = true;
    try {
      final cs = _ref.read(classProvider);
      if (!force && !cs.isDirty) return true;

      if (!_ws.isConfigured) {
        _lastError = '工作目录未设置';
        AppLog.warn('数据', '工作区未配置，跳过保存');
        return false;
      }

      await _ws.saveScores(cs.classrooms);
      _ref.read(classProvider.notifier).clearDirty();
      _lastError = null;
      return true;
    } catch (e, st) {
      _lastError = '$e';
      AppLog.error('数据', '保存积分失败', e, st);
      return false;
    } finally {
      _saving = false;
      if (_saveQueued) {
        _saveQueued = false;
        // 用微任务错开，避免在上一次调用的 finally 里递归
        scheduleMicrotask(() => _doSaveScores(force: force));
      }
    }
  }

  /// 把工作区派生出来的存储位置交给各服务。
  ///
  /// 为什么放在这里：工作区路径只有一个归属（WorkspaceService），
  /// 而它一旦变化，课本缓存目录、模板导出目录都要跟着变。
  /// 集中到「工作区就绪」这一个时点，避免各处各自去读路径而产生分歧。
  void _applyWorkspacePaths() {
    final root = _ws.rootPath;
    if (root == null) return;

    // 课本存到工作区：跟着文件夹跨设备，同一本教材不必在每台机器上重下
    PdfCacheManager().setStoreDir(_ws.textbooksPath);

    // 模板导出的兜底位置也落在工作区，而不是应用私有目录
    _ref.read(fileServiceProvider).setWorkingDir(root);
  }

  /// 从工作区加载所有数据
  Future<void> loadFromWorkspace() async {
    // 先把日志目录接上，这样加载期的错误也能落盘
    AppLog.setLogDirectory(_ws.archivePath);
    _applyWorkspacePaths();

    try {
      final classrooms = await _ws.loadAllRosters();
      if (classrooms.isNotEmpty) {
        _ref.read(classProvider.notifier).loadFromData(
              classrooms,
              classrooms.first.uid,
            );
        // 每次载入都会重新生成 uid，候选池与锁定分组必须一起清掉
        _ref.read(drawProvider.notifier).resetForNewData();
      } else {
        AppLog.info('数据', '工作区里没有可用名单');
      }

      final banks = await _ws.loadAllQuestionBanks();
      if (banks.isNotEmpty) {
        _ref.read(questionProvider.notifier).loadFromData(banks);
      }

      AppLog.info(
        '数据',
        '从工作区加载完成: ${classrooms.length} 个班级、'
            '${classrooms.fold<int>(0, (s, c) => s + c.allMembers.length)} 名学生、'
            '${banks.length} 个题库',
      );
    } catch (e, st) {
      AppLog.error('数据', '从工作区加载失败', e, st);
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
    if (_debounceTimer?.isActive == true) {
      AppLog.warn('数据', '退出时仍有未落盘的改动，已尝试立即保存');
    }
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}

/// DataService Provider
final dataServiceProvider = Provider<DataService>((ref) {
  final service = DataService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

/// 自动保存 Provider
///
/// 注意：这是在 provider 的 body 里做副作用，属于不好的写法，
/// 但它目前确实工作正常，且是主流程的一环，暂不改动以免引入回归。
final autoSaveProvider = Provider.autoDispose<void>((ref) {
  final dataService = ref.watch(dataServiceProvider);
  final cs = ref.watch(classProvider);
  final settings = ref.watch(settingsProvider);
  if (cs.isDirty && settings.autoSave) {
    dataService.save(silent: true);
  }
});
