import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/class_provider.dart';
import '../providers/question_provider.dart';
import '../providers/settings_provider.dart';
import '../services/data_service.dart';
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
  bool _usbChecked = false;
  int _mobileTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tryAutoLoadUsb();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tryAutoLoadUsb();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // 应用进入后台时立即保存
      ref.read(dataServiceProvider).saveImmediate(silent: true);
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

  // ==================== 数据操作（委托给 DataService） ====================

  Future<void> _save() async {
    try {
      await ref.read(dataServiceProvider).save(silent: false, immediate: true);
      ToastOverlay.show(context, '保存成功', type: ToastType.success);
    } catch (e) {
      ToastOverlay.show(context, '保存失败: $e', type: ToastType.error);
    }
  }

  Future<void> _load() async {
    try {
      await ref.read(dataServiceProvider).load();
      ToastOverlay.show(context, '加载成功', type: ToastType.success);
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

  // ==================== 导入导出合并菜单 ====================

  /// 显示统一的导入/导出底部菜单
  void _showDataImportExportSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.import_export, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('数据导入/导出', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Divider(height: 1),
              _sheetGroup('导入', [
                _sheetItem(Icons.person_add_alt, '导入学生名单', _importRoster),
                _sheetItem(Icons.upload_file, '导入积分数据', _importScores),
              ]),
              const Divider(height: 1, indent: 56),
              _sheetGroup('导出', [
                _sheetItem(Icons.download, '导出积分数据', _exportScores),
                _sheetItem(Icons.note_add, '导出名单模板', _exportMemberTemplate),
                _sheetItem(Icons.quiz_outlined, '导出题库模板', _exportQuestionTemplate),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetGroup(String title, List<Widget> items) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 8, bottom: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _sheetItem(IconData icon, String label, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () {
        Navigator.pop(context); // 关闭底部菜单
        onTap?.call();
      },
      dense: true,
    );
  }

  // ==================== 具体数据操作 ====================

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
      ref.read(classProvider.notifier).loadFromData(classrooms, classrooms.first.uid);
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
      final result = await ref.read(fileServiceProvider).exportQuestionTemplate();
      if (result != null) {
        ToastOverlay.show(context, '题库模板已导出', type: ToastType.success);
      }
    } catch (e) {
      ToastOverlay.show(context, '模板导出失败: $e', type: ToastType.error);
    }
  }

  Future<void> _sync() async {
    showDialog(context: context, builder: (_) => const SyncProgressDialog());
    try {
      final cloudService = ref.read(cloudStorageServiceProvider);
      final success = await cloudService.sync();
      if (mounted) {
        Navigator.pop(context);
        ToastOverlay.show(
          context,
          success ? '同步完成' : '同步失败，请检查网络和云端配置',
          type: success ? ToastType.success : ToastType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ToastOverlay.show(context, '同步异常: $e', type: ToastType.error);
      }
    }
  }

  void _openSettings() {
    showDialog(context: context, builder: (_) => const SettingsDialog());
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
        case 0: return const DrawPanel();
        case 1: return const QuestionPanel();
        case 2: return const TimerPanel();
        case 3: return const LeaderboardPanel();
        case 4: return const TextbookPanel();
        case 5: return _mobileMorePanel();
        default: return const DrawPanel();
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
          _iOSSection('数据管理', [
            _moreTile(Icons.folder_open, '选择文件夹', _pickFolder),
            _moreTile(Icons.save_alt, '保存数据', () => _save()),
            _moreTile(Icons.file_open, '加载数据', _load),
          ]),
          const SizedBox(height: 8),
          _iOSSection('数据导入/导出', [
            _moreTile(Icons.import_export, '导入/导出数据', _showDataImportExportSheet),
          ]),
          const SizedBox(height: 8),
          _iOSSection('云端同步', [
            _moreTile(Icons.cloud_sync, '云端同步', _sync),
          ]),
          const SizedBox(height: 8),
          _iOSSection('其他', [
            _moreTile(Icons.class_, '切换班级', _showClassPicker),
            _moreTile(Icons.favorite, '开源说明', () {
              Navigator.push(context, slideFadePageRoute(const OpenSourceScreen()));
            }),
            _moreTile(Icons.settings, '设置', _openSettings),
          ]),
        ],
      ),
    );
  }

  Widget _iOSSection(String title, List<Widget> tiles) {
    final theme = Theme.of(context);
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
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      height: 1, indent: 56, endIndent: 16,
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

  Widget _moreTile(IconData icon, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, size: 20, color: theme.colorScheme.primary),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: Icon(Icons.chevron_right, size: 18,
          color: theme.colorScheme.onSurface.withOpacity(0.3)),
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
        // 左侧导航栏
        SizedBox(
          width: 56,
          child: Column(
            children: [
              const SizedBox(height: 48),
              GestureDetector(
                onTap: _showClassPicker,
                child: Container(
                  width: 40, height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.class_, size: 20, color: theme.colorScheme.primary),
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
        Container(width: 1, color: theme.colorScheme.outline.withOpacity(0.1)),
        Expanded(child: _buildTabletContent(theme)),
      ],
    );
  }

  Widget _navIcon(IconData icon, String tooltip, int index) {
    final selected = _mobileTabIndex == index;
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onTap: () => setState(() => _mobileTabIndex = index),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: selected ? theme.colorScheme.primaryContainer : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon, size: 22,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletContent(ThemeData theme) {
    switch (_mobileTabIndex) {
      case 0: return const DrawPanel();
      case 1: return const QuestionPanel();
      case 2: return const TimerPanel();
      case 3: return const LeaderboardPanel();
      case 4: return const TextbookPanel();
      case 5: return _tabletMorePanel();
      default: return const DrawPanel();
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
                _sectionCard('数据导入/导出', [
                  _tabletMoreTile(Icons.import_export, '导入/导出数据', _showDataImportExportSheet),
                ]),
                const SizedBox(height: 8),
                _sectionCard('其他', [
                  _tabletMoreTile(Icons.class_, '切换班级', _showClassPicker),
                  _tabletMoreTile(Icons.settings, '设置', _openSettings),
                  _tabletMoreTile(Icons.favorite, '开源说明', () {
                    Navigator.push(context, slideFadePageRoute(const OpenSourceScreen()));
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
              fontSize: 13, fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: tiles.asMap().entries.map((entry) {
              final idx = entry.key;
              final tile = entry.value;
              if (idx < tiles.length - 1) {
                return Column(
                  children: [
                    tile,
                    Divider(height: 1, indent: 56, endIndent: 16,
                        color: theme.colorScheme.outline.withOpacity(0.12)),
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
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Icon(Icons.chevron_right, size: 18,
          color: theme.colorScheme.onSurface.withOpacity(0.3)),
      onTap: onTap,
      dense: true,
    );
  }

  // ===================== 主构建 =====================

  @override
  Widget build(BuildContext context) {
    final screen = context.screenType;

    // 监听自动保存（DataService 的防抖机制）
    ref.watch(autoSaveProvider);

    if (screen == ScreenType.tablet) {
      return Scaffold(
        body: Stack(
          children: [
            _tabletBody(),
            Positioned(top: 8, right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AutoSaveIndicator(isDirty: ref.watch(classProvider).isDirty),
                  const SizedBox(height: 2),
                  const SyncStatusIndicator(),
                ],
              ),
            ),
            Positioned(bottom: 20, right: 20,
              child: CentralConsole(
                onSave: () => _save(),
                onLoad: _load,
                onPickFolder: _pickFolder,
                onSettings: _openSettings,
                onSync: _sync,
                onImportRoster: _importRoster,
                onImportScores: _importScores,
                onExportScores: _exportScores,
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
          Padding(padding: const EdgeInsets.only(top: 4), child: _mobileBody()),
          Positioned(top: 2, right: 6,
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
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.85),
        indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
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