import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/class_provider.dart';
import '../providers/question_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/settings_provider.dart';
import '../models/question_bank.dart';
import '../services/file_service.dart';
import '../services/excel_service.dart';
import '../theme/design_tokens.dart';
import '../theme/responsive.dart';
import '../theme/route_utils.dart';
import '../widgets/central_console.dart';
import '../widgets/toast_overlay.dart';
import '../widgets/auto_save_indicator.dart';
import '../widgets/sync_status_indicator.dart';
import '../widgets/textbook_panel.dart';
import '../providers/services_provider.dart';
import '../services/audio_engine.dart';
import '../services/cloud/cloud_storage_service.dart';
import 'draw_panel.dart';
import 'question_panel.dart';
import 'timer_panel.dart';
import 'leaderboard_panel.dart';
import 'dialogs/settings_dialog.dart';
import 'dialogs/sync_progress_dialog.dart';
import 'open_source_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  Timer? _autoSaveTimer;
  bool _usbChecked = false;
  int _mobileTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startAutoSave();
    _tryAutoLoadUsb();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tryAutoLoadUsb();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _save(silent: true);
    }
  }

  Future<void> _tryAutoLoadUsb() async {
    if (_usbChecked) return;
    _usbChecked = true;
    try {
      final fileService = ref.read(fileServiceProvider);
      final usbPath = await fileService.autoDetectUsb();
      if (usbPath != null && mounted) {
        ToastOverlay.show(context, '检测到U盘: $usbPath');
      }
    } catch (_) {}
  }

  void _startAutoSave() {
    final settings = ref.read(settingsProvider);
    if (settings.autoSave) {
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer.periodic(
        Duration(seconds: settings.autoSaveInterval),
        (_) => _save(silent: true),
      );
    }
  }

  Future<void> _save({bool silent = false}) async {
    try {
      final cs = ref.read(classProvider);
      final qs = ref.read(questionProvider);
      if (!cs.isDirty && !qs.isDirty) return;
      final data = AppData(
        classrooms: cs.classrooms,
        questionBanks: qs.banks,
        lastModified: DateTime.now().toIso8601String(),
      );
      final fileService = ref.read(fileServiceProvider);
      await fileService.saveJson(data);
      ref.read(classProvider.notifier).clearDirty();
      ref.read(questionProvider.notifier).clearDirty();
      fileService.autoCleanup(await fileService.getWorkingDir());
      if (!silent) ToastOverlay.show(context, '保存成功', type: ToastType.success);
    } catch (e) {
      if (!silent) ToastOverlay.show(context, '保存失败: $e', type: ToastType.error);
    }
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(fileServiceProvider).pickAndLoadJson();
      if (data != null) {
        ref.read(classProvider.notifier).loadFromData(
              data.classrooms,
              data.classrooms.isNotEmpty ? data.classrooms.first.uid : null,
            );
        ref.read(questionProvider.notifier).loadFromData(data.questionBanks);
        ToastOverlay.show(context, '加载成功', type: ToastType.success);
      }
    } catch (e) {
      ToastOverlay.show(context, '加载失败: $e', type: ToastType.error);
    }
  }

  Future<void> _pickFolder() async {
    final path = await ref.read(fileServiceProvider).pickFolder();
    if (path != null) {
      ref.read(settingsProvider.notifier).update(
            ref.read(settingsProvider).copyWith(usbDataPath: path),
          );
      ToastOverlay.show(context, '已选择文件夹');
    }
  }

  Future<void> _importRoster() async {
    try {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      if (r == null || r.files.isEmpty) return;
      final path = r.files.single.path;
      if (path == null) return;
      final classrooms = await ExcelService.parseRoster(path);
      if (classrooms.isEmpty) {
        ToastOverlay.show(context, '未能解析到任何班级数据');
        return;
      }
      ref.read(classProvider.notifier)
          .loadFromData(classrooms, classrooms.first.uid);
      ToastOverlay.show(context, '导入名单成功: ${classrooms.length} 个班级',
          type: ToastType.success);
    } catch (e) {
      ToastOverlay.show(context, '导入名单失败: $e', type: ToastType.error);
    }
  }

  Future<void> _exportScores() async {
    try {
      final cs = ref.read(classProvider);
      final data = AppData(classrooms: cs.classrooms, questionBanks: []);
      await ref.read(fileServiceProvider).exportScores(data);
      ToastOverlay.show(context, '积分导出成功', type: ToastType.success);
    } catch (e) {
      ToastOverlay.show(context, '积分导出失败: $e', type: ToastType.error);
    }
  }

  Future<void> _importScores() async {
    try {
      final scores = await ref.read(fileServiceProvider).importScores();
      final notifier = ref.read(classProvider.notifier);
      final state = ref.read(classProvider);
      for (final classroom in state.classrooms) {
        final classScores = scores[classroom.name];
        if (classScores == null) continue;
        for (final group in classroom.groups) {
          final groupScores = classScores[group.name];
          if (groupScores == null) continue;
          for (final member in group.members) {
            final newScore = groupScores[member.name];
            if (newScore != null) {
              notifier.setScore(classroom.uid, group.uid, member.uid, newScore);
            }
          }
        }
      }
      ToastOverlay.show(context, '积分导入成功', type: ToastType.success);
    } catch (e) {
      ToastOverlay.show(context, '积分导入失败: $e', type: ToastType.error);
    }
  }

  Future<void> _exportMemberTemplate() async {
    try {
      final result = await ref.read(fileServiceProvider).exportMemberTemplate();
      if (result != null) {
        ToastOverlay.show(context, '名单模板已导出', type: ToastType.success);
      }
    } catch (e) {
      ToastOverlay.show(context, '模板导出失败: $e', type: ToastType.error);
    }
  }

  Future<void> _exportQuestionTemplate() async {
    try {
      final result =
          await ref.read(fileServiceProvider).exportQuestionTemplate();
      if (result != null) {
        ToastOverlay.show(context, '题库模板已导出', type: ToastType.success);
      }
    } catch (e) {
      ToastOverlay.show(context, '模板导出失败: $e', type: ToastType.error);
    }
  }

  Future<void> _sync() async {
    showDialog(context: context, builder: (_) => const SyncProgressDialog());
    ref.read(syncProvider.notifier).startSync();
    try {
      final cloudService = ref.read(cloudStorageServiceProvider);
      final success = await cloudService.sync();
      if (mounted) {
        ref.read(syncProvider.notifier).syncComplete();
        Navigator.pop(context);
        ToastOverlay.show(
          context,
          success ? '同步完成' : '同步失败，请检查网络和云端配置',
          type: success ? ToastType.success : ToastType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        ref.read(syncProvider.notifier).syncError(e.toString());
        Navigator.pop(context);
        ToastOverlay.show(context, '同步异常: $e', type: ToastType.error);
      }
    }
  }

  void _openSettings() {
    showDialog(context: context, builder: (_) => const SettingsDialog())
        .then((_) => _startAutoSave());
  }

  // ===================== 班级选择器 =====================
  void _showClassPicker() {
    final cs = ref.read(classProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择上课班级'),
        content: SizedBox(
          width: 240,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cs.classrooms.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('暂无班级，请先导入名单'),
                )
              else
                ...cs.classrooms.map(
                  (c) => ListTile(
                    title: Text(c.name),
                    trailing: cs.selectedClass?.uid == c.uid
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      ref.read(classProvider.notifier).selectClass(c.uid);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // ===================== Tab定义 =====================
  static const _mobileTabs = <_TabDef>[
    _TabDef(Icons.casino, '抽取'),
    _TabDef(Icons.quiz, '题库'),
    _TabDef(Icons.timer, '计时'),
    _TabDef(Icons.leaderboard, '排行'),
    _TabDef(Icons.menu_book, '教材'),
    _TabDef(Icons.more_horiz, '更多'),
  ];

  // ===================== 手机端布局 =====================

  Widget _mobileBody() {
    final tabWidget = () {
      switch (_mobileTabIndex) {
        case 0:
          return const DrawPanel();
        case 1:
          return const QuestionPanel();
        case 2:
          return const TimerPanel();
        case 3:
          return const LeaderboardPanel();
        case 4:
          return const TextbookPanel();
        case 5:
          return _mobileMorePanel();
        default:
          return const DrawPanel();
      }
    }();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.3, end: 1.0).animate(animation),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey('mobile_tab_$_mobileTabIndex'),
        child: tabWidget,
      ),
    );
  }

  Widget _mobileMorePanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // iOS风格分组卡片
          _iOSSection('数据管理', [
            _moreTile(Icons.folder_open, '选择文件夹', _pickFolder),
            _moreTile(Icons.save_alt, '保存数据', () => _save()),
            _moreTile(Icons.file_open, '加载数据', _load),
          ]),
          const SizedBox(height: 8),
          _iOSSection('云端同步', [
            _moreTile(Icons.cloud_sync, '云端同步', _sync),
          ]),
          const SizedBox(height: 8),
          _iOSSection('班级管理', [
            _moreTile(Icons.person_add_alt, '导入名单', _importRoster),
            _moreTile(Icons.upload_file, '导入积分', _importScores),
            _moreTile(Icons.download, '导出积分', _exportScores),
            _moreTile(Icons.note_add, '导出名单模板', _exportMemberTemplate),
            _moreTile(
                Icons.quiz_outlined, '导出题库模板', _exportQuestionTemplate),
          ]),
          const SizedBox(height: 8),
          _iOSSection('其他', [
            _moreTile(Icons.class_, '切换班级', _showClassPicker),
            _moreTile(Icons.favorite, '开源说明', () {
              Navigator.push(
                context,
                slideFadePageRoute(const OpenSourceScreen()),
              );
            }),
          ]),
          const SizedBox(height: 8),
          _iOSSection('设置', [
            _moreTile(Icons.settings, '设置', _openSettings),
          ]),
        ],
      ),
    );
  }

  Widget _iOSSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 6, top: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: tiles.asMap().entries.map((entry) {
              final idx = entry.key;
              final tile = entry.value;
              if (idx < tiles.length - 1) {
                return Column(
                  children: [
                    tile,
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.12),
                    ),
                  ],
                );
              }
              return tile;
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _moreTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: Icon(
        Icons.chevron_right,
        size: 18,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  // ===================== 平板端 SplitView 布局 =====================
  Widget _tabletBody() {
    final cs = ref.watch(classProvider);
    final theme = Theme.of(context);

    return Row(
      children: [
        // ========== 左侧导航栏 ==========
        SizedBox(
          width: 56,
          child: Column(
            children: [
              const SizedBox(height: 48),
              // 班级选择
              GestureDetector(
                onTap: _showClassPicker,
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.class_,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _navIcon(Icons.casino, '抽取', 0),
              _navIcon(Icons.quiz, '题库', 1),
              _navIcon(Icons.timer, '计时', 2),
              _navIcon(Icons.leaderboard, '排行', 3),
              _navIcon(Icons.menu_book, '教材', 4),
              const Spacer(),
              _navIcon(Icons.more_horiz, '更多', 5),
              const SizedBox(height: 12),
            ],
          ),
        ),
        // 分割线
        Container(
          width: 1,
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
        // ========== 右侧内容区 ==========
        Expanded(
          child: _buildTabletContent(theme),
        ),
      ],
    );
  }

  Widget _navIcon(IconData icon, String tooltip, int index) {
    final selected = _mobileTabIndex == index;
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onTap: () => setState(() => _mobileTabIndex = index),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletContent(ThemeData theme) {
    switch (_mobileTabIndex) {
      case 0:
        return const DrawPanel();
      case 1:
        return const QuestionPanel();
      case 2:
        return const TimerPanel();
      case 3:
        return const LeaderboardPanel();
      case 4:
        return const TextbookPanel();
      case 5:
        return _tabletMorePanel();
      default:
        return const DrawPanel();
    }
  }

  Widget _tabletMorePanel() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionCard('数据管理', [
                  _tabletMoreTile(Icons.folder_open, '选择文件夹', _pickFolder),
                  _tabletMoreTile(Icons.save_alt, '保存数据', () => _save()),
                  _tabletMoreTile(Icons.file_open, '加载数据', _load),
                ]),
                const SizedBox(height: 8),
                _sectionCard('云端同步', [
                  _tabletMoreTile(Icons.cloud_sync, '云端同步', _sync),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionCard('班级管理', [
                  _tabletMoreTile(
                      Icons.person_add_alt, '导入名单', _importRoster),
                  _tabletMoreTile(
                      Icons.upload_file, '导入积分', _importScores),
                  _tabletMoreTile(
                      Icons.download, '导出积分', _exportScores),
                  _tabletMoreTile(
                      Icons.note_add, '名单模板', _exportMemberTemplate),
                  _tabletMoreTile(
                      Icons.quiz_outlined, '题库模板', _exportQuestionTemplate),
                ]),
                const SizedBox(height: 8),
                _sectionCard('其他', [
                  _tabletMoreTile(Icons.class_, '切换班级', _showClassPicker),
                  _tabletMoreTile(Icons.settings, '设置', _openSettings),
                  _tabletMoreTile(Icons.favorite, '开源说明', () {
                    Navigator.push(
                      context,
                      slideFadePageRoute(const OpenSourceScreen()),
                    );
                  }),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> tiles) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: tiles.asMap().entries.map((entry) {
              final idx = entry.key;
              final tile = entry.value;
              if (idx < tiles.length - 1) {
                return Column(
                  children: [
                    tile,
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: theme.colorScheme.outline.withOpacity(0.12),
                    ),
                  ],
                );
              }
              return tile;
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _tabletMoreTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Icon(
        Icons.chevron_right,
        size: 18,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
      ),
      onTap: onTap,
      dense: true,
    );
  }

  // ===================== 主构建 =====================

  @override
  Widget build(BuildContext context) {
    final screen = context.screenType;

    if (screen == ScreenType.tablet) {
      // iPad SplitView 风格
      return Scaffold(
        body: Stack(
          children: [
            _tabletBody(),
            // 顶部安全区状态
            Positioned(
              top: 8,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AutoSaveIndicator(isDirty: ref.watch(classProvider).isDirty),
                  const SizedBox(height: 2),
                  const SyncStatusIndicator(),
                ],
              ),
            ),
            // 桌面控制台
            Positioned(
              bottom: 20,
              right: 20,
              child: CentralConsole(
                onSave: () => _save(),
                onLoad: _load,
                onPickFolder: _pickFolder,
                onSettings: _openSettings,
                onSync: _sync,
                onImportRoster: _importRoster,
                onExportScores: _exportScores,
                onImportScores: _importScores,
                onExportMemberTemplate: _exportMemberTemplate,
                onExportQuestionTemplate: _exportQuestionTemplate,
              ),
            ),
          ],
        ),
        resizeToAvoidBottomInset: true,
      );
    }

    // 手机端
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _mobileBody(),
          ),
          Positioned(
            top: 2,
            right: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AutoSaveIndicator(isDirty: ref.watch(classProvider).isDirty),
                const SizedBox(height: 1),
                const SyncStatusIndicator(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _mobileTabIndex,
        onDestinationSelected: (i) => setState(() => _mobileTabIndex = i),
        destinations: _mobileTabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon, size: 20),
                  label: t.label,
                ))
            .toList(),
        // iOS风格：透明背景
        backgroundColor:
            Theme.of(context).colorScheme.surface.withOpacity(0.85),
        indicatorColor:
            Theme.of(context).colorScheme.primary.withOpacity(0.12),
      ),
      resizeToAvoidBottomInset: true,
    );
  }
}

class _TabDef {
  final IconData icon;
  final String label;
  const _TabDef(this.icon, this.label);
}
