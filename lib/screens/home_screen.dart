import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/sync_provider.dart';
import '../services/data_service.dart';
import '../services/workspace_service.dart';
import '../services/storage_service.dart';
import '../services/auto_sync_timer.dart';
import '../providers/services_provider.dart';
import '../theme/design_tokens.dart';
import '../theme/responsive.dart';
import '../theme/route_utils.dart';
import '../widgets/glass_panel.dart';
import '../widgets/toast_overlay.dart';
import '../widgets/auto_save_indicator.dart';
import '../widgets/sync_status_indicator.dart';
import '../widgets/textbook_panel.dart';
import '../widgets/workspace_picker_dialog.dart';
import '../services/audio_engine.dart';
import '../services/excel_service.dart';
import '../models/class_model.dart';
import 'draw_panel.dart';
import 'question_panel.dart';
import 'timer_panel.dart';
import 'leaderboard_panel.dart';
import 'dialogs/settings_dialog.dart';
import 'open_source_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;
  static const _tabLabels = ['课堂', '班级', '资源', '设置'];
  static const _tabIcons = [
    Icons.school,
    Icons.people,
    Icons.menu_book,
    Icons.settings
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_LifecycleObserver(
        onBackground: () =>
            ref.read(dataServiceProvider).saveImmediate(silent: true)));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ws = ref.read(workspaceServiceProvider);
      await ws.loadSavedPath();
      if (ws.isConfigured) {
        await ws.ensureInitialTemplates();
        await ref.read(dataServiceProvider).loadFromWorkspace();
      }
      _restoreSyncState();

      // 启动自动同步定时器
      final autoSync = ref.read(autoSyncTimerProvider);
      autoSync.start();
    });
  }

  void _restoreSyncState() {
    final storage = ref.read(storageServiceProvider);
    final lastSync = storage.getString('last_sync_timestamp');
    if (lastSync.isNotEmpty) {
      ref.read(syncProvider.notifier).restoreLastSyncTime(lastSync);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(autoSaveProvider);
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isWide = size.width >= AppBreakpoints.desktop;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide
          ? _buildWideLayout()
          : isLandscape
              ? _buildLandscapeLayout()
              : _buildPortraitLayout(),
    );
  }

  // ==================== 宽屏（希沃16:9） ====================
  Widget _buildWideLayout() {
    return Row(
      children: [
        _buildLeftToolbar(),
        Expanded(child: _buildMainContent()),
        const SizedBox(width: 1),
      ],
    );
  }

  // ==================== 横屏（平板/手机横屏） ====================
  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        _buildLeftToolbar(compact: true),
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  // ==================== 竖屏（手机竖屏） ====================
  Widget _buildPortraitLayout() {
    return Column(
      children: [
        Padding(
          padding:
              EdgeInsets.only(top: MediaQuery.of(context).padding.top + 4),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('灵动课堂',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                const SyncStatusIndicator(),
                const SizedBox(width: 8),
                AutoSaveIndicator(
                    isDirty: ref.watch(classProvider).isDirty),
              ],
            ),
          ),
        ),
        Expanded(child: _buildMainContent()),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildLeftToolbar({bool compact = false}) {
    return FrostedPanel(
      width: compact ? 60 : 72,
      height: double.infinity,
      blur: 20,
      borderRadius: BorderRadius.zero,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        children: [
          const SizedBox(height: compact ? 20 : 32),
          for (int i = 0; i < _tabLabels.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _toolbarBtn(
                icon: _tabIcons[i],
                label: _tabLabels[i],
                selected: _tabIndex == i,
                onTap: () => setState(() => _tabIndex = i),
                compact: compact,
              ),
            ),
          const Spacer(),
          AutoSaveIndicator(
              isDirty: ref.watch(classProvider).isDirty),
          const SizedBox(height: 4),
          const SyncStatusIndicator(),
        ],
      ),
    );
  }

  Widget _toolbarBtn({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: FrostedPanel(
        blur: 8,
        padding: EdgeInsets.symmetric(
            vertical: compact ? 6 : 8, horizontal: 4),
        backgroundColor: selected
            ? AppColors.brandPrimary.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: compact ? 20 : 22,
                color: selected
                    ? AppColors.brandPrimary
                    : AppColors.textSecondary),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: compact ? 9 : 10,
                  color: selected
                      ? AppColors.brandPrimary
                      : AppColors.textSecondary,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_tabIndex) {
      case 0:
        return const _ClassroomView();
      case 1:
        return const _ClassDataView();
      case 2:
        return const TextbookPanel();
      case 3:
        return const _SettingsPage();
      default:
        return const _ClassroomView();
    }
  }

  Widget _buildBottomBar() {
    return FrostedPanel(
      blur: 20,
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(20)),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin:
          EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabLabels.length, (i) {
            return GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: FrostedPanel(
                blur: 6,
                padding: const EdgeInsets.symmetric(
                    vertical: 6, horizontal: 12),
                backgroundColor: _tabIndex == i
                    ? AppColors.brandPrimary.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_tabIcons[i],
                        size: 18,
                        color: _tabIndex == i
                            ? AppColors.brandPrimary
                            : AppColors.textSecondary),
                    if (_tabIndex == i) ...[
                      const SizedBox(width: 4),
                      Text(_tabLabels[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandPrimary,
                          )),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ==================== 课堂主页 ====================
class _ClassroomView extends ConsumerWidget {
  const _ClassroomView();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 500;
      return Padding(
        padding: const EdgeInsets.all(8),
        child: isNarrow
            ? Column(
                children: [
                  Expanded(
                      child: _FeatureCard(
                          icon: Icons.casino,
                          label: '随机抽取',
                          color: AppColors.brandPrimary,
                          child: const DrawPanel())),
                  const SizedBox(height: 8),
                  Expanded(
                      child: _FeatureCard(
                          icon: Icons.timer,
                          label: '课堂计时',
                          color: Colors.orange,
                          child: const TimerPanel())),
                  const SizedBox(height: 8),
                  Expanded(
                      child: _FeatureCard(
                          icon: Icons.leaderboard,
                          label: '排行榜',
                          color: Colors.green,
                          child: const LeaderboardPanel())),
                  const SizedBox(height: 8),
                  Expanded(
                      child: _FeatureCard(
                          icon: Icons.quiz,
                          label: '题库',
                          color: Colors.purple,
                          child: const QuestionPanel())),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                            child: _FeatureCard(
                                icon: Icons.casino,
                                label: '随机抽取',
                                color: AppColors.brandPrimary,
                                child: const DrawPanel())),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _FeatureCard(
                                icon: Icons.timer,
                                label: '课堂计时',
                                color: Colors.orange,
                                child: const TimerPanel())),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                            child: _FeatureCard(
                                icon: Icons.leaderboard,
                                label: '排行榜',
                                color: Colors.green,
                                child: const LeaderboardPanel())),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _FeatureCard(
                                icon: Icons.quiz,
                                label: '题库',
                                color: Colors.purple,
                                child: const QuestionPanel())),
                      ],
                    ),
                  ),
                ],
              ),
      );
    });
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget child;
  const _FeatureCard(
      {required this.icon,
      required this.label,
      required this.color,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return FrostedPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ]),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ==================== 班级数据管理 ====================
class _ClassDataView extends ConsumerStatefulWidget {
  const _ClassDataView();
  @override
  ConsumerState<_ClassDataView> createState() => _ClassDataViewState();
}

class _ClassDataViewState extends ConsumerState<_ClassDataView> {
  String? _expandedClassUid;
  String? _expandedGroupUid;

  @override
  Widget build(BuildContext context) {
    final cs = ref.watch(classProvider);
    final theme = Theme.of(context);

    if (cs.classrooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined,
                size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            const Text('还没有班级数据'),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('添加班级'),
              onPressed: () => _showAddClassDialog(context),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              icon: const Icon(Icons.file_open, size: 16),
              label: const Text('从 xlsx 导入'),
              onPressed: () => _importRoster(context),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 顶部操作栏
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(children: [
            Text(
                '${cs.classrooms.length} 个班级 · ${cs.classrooms.fold<int>(0, (s, c) => s + c.allMembers.length)} 名学生',
                style: theme.textTheme.bodySmall),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.add, size: 20),
                tooltip: '添加班级',
                onPressed: () => _showAddClassDialog(context),
                visualDensity: VisualDensity.compact),
            IconButton(
                icon: const Icon(Icons.file_open, size: 18),
                tooltip: '导入名单',
                onPressed: () => _importRoster(context),
                visualDensity: VisualDensity.compact),
          ]),
        ),
        const Divider(height: 1),
        // 班级树形列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: cs.classrooms.length,
            itemBuilder: (_, ci) {
              final cls = cs.classrooms[ci];
              final isExpanded = _expandedClassUid == cls.uid;
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    // 班级标题
                    ListTile(
                      leading: Icon(
                          isExpanded
                              ? Icons.school
                              : Icons.school_outlined,
                          color: theme.colorScheme.primary,
                          size: 22),
                      title: Text(cls.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      subtitle: Text(
                          '${cls.groups.length} 组 · ${cls.allMembers.length} 人',
                          style: const TextStyle(fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.edit, size: 16),
                              tooltip: '重命名',
                              onPressed: () =>
                                  _showRenameDialog(
                                      context, cls.name, (v) {
                                    ref
                                        .read(classProvider.notifier)
                                        .renameClass(cls.uid, v);
                                  }),
                              visualDensity: VisualDensity.compact),
                          IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 16),
                              tooltip: '删除班级',
                              onPressed: () => _confirmDelete(
                                  context,
                                  '删除班级 "${cls.name}"？',
                                  () => ref
                                      .read(classProvider.notifier)
                                      .deleteClass(cls.uid)),
                              visualDensity: VisualDensity.compact),
                        ],
                      ),
                      onTap: () => setState(() =>
                          _expandedClassUid =
                              isExpanded ? null : cls.uid),
                    ),
                    // 展开的小组列表
                    if (isExpanded)
                      ...cls.groups.map((g) {
                        final isGExpanded =
                            _expandedGroupUid == g.uid;
                        return Column(
                          children: [
                            const Divider(height: 1, indent: 48),
                            ListTile(
                              leading: const Icon(Icons.groups,
                                  size: 20,
                                  color: AppColors.brandSecondary),
                              title: Text(g.name,
                                  style:
                                      const TextStyle(fontSize: 13)),
                              subtitle: Text(
                                  '${g.members.length} 人 · 总分 ${g.totalScore.toStringAsFixed(1)}',
                                  style:
                                      const TextStyle(fontSize: 11)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      icon: const Icon(
                                          Icons.person_add,
                                          size: 16),
                                      tooltip: '添加成员',
                                      onPressed: () =>
                                          _showAddMemberDialog(
                                              context, cls.uid,
                                              g.uid),
                                      visualDensity:
                                          VisualDensity.compact),
                                  IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline,
                                          size: 16),
                                      tooltip: '删除小组',
                                      onPressed: () =>
                                          _confirmDelete(
                                              context,
                                              '删除小组 "${g.name}"？',
                                              () => ref
                                                  .read(
                                                      classProvider
                                                          .notifier)
                                                  .deleteGroup(
                                                      cls.uid,
                                                      g.uid)),
                                      visualDensity:
                                          VisualDensity.compact),
                                ],
                              ),
                              onTap: () => setState(() =>
                                  _expandedGroupUid = isGExpanded
                                      ? null
                                      : g.uid),
                            ),
                            // 成员列表
                            if (isGExpanded)
                              ...g.members.map((m) => Padding(
                                    padding:
                                        const EdgeInsets.only(
                                            left: 60,
                                            right: 8,
                                            bottom: 2),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            child: Text(
                                                m.name,
                                                style:
                                                    const TextStyle(
                                                        fontSize:
                                                            12))),
                                        Text(
                                            m.score
                                                .toStringAsFixed(
                                                    1),
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: theme
                                                    .colorScheme
                                                    .primary)),
                                        const SizedBox(width: 8),
                                        IconButton(
                                            icon: const Icon(
                                                Icons.delete,
                                                size: 14),
                                            tooltip: '删除',
                                            onPressed: () => ref
                                                .read(classProvider
                                                    .notifier)
                                                .deleteMember(
                                                    cls.uid,
                                                    g.uid,
                                                    m.uid),
                                            visualDensity:
                                                VisualDensity
                                                    .compact),
                                      ],
                                    ),
                                  )),
                          ],
                        );
                      }),
                    // 添加小组按钮
                    if (isExpanded)
                      TextButton.icon(
                        icon:
                            const Icon(Icons.add, size: 14),
                        label: const Text('添加小组'),
                        onPressed: () =>
                            _showAddGroupDialog(
                                context, cls.uid),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ========== 对话框辅助方法 ==========

  void _showAddClassDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加班级'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '班级名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
          FilledButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  ref
                      .read(classProvider.notifier)
                      .addClass(ctrl.text.trim());
                  Navigator.pop(ctx);
                }
              },
              child: const Text('添加')),
        ],
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context, String classUid) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加小组'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '小组名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
          FilledButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  ref
                      .read(classProvider.notifier)
                      .selectClass(classUid);
                  ref
                      .read(classProvider.notifier)
                      .addGroup(ctrl.text.trim());
                  Navigator.pop(ctx);
                }
              },
              child: const Text('添加')),
        ],
      ),
    );
  }

  void _showAddMemberDialog(
      BuildContext context, String classUid, String groupUid) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加成员'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '成员姓名'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
          FilledButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  ref
                      .read(classProvider.notifier)
                      .selectClass(classUid);
                  ref
                      .read(classProvider.notifier)
                      .addMember(groupUid, ctrl.text.trim());
                  Navigator.pop(ctx);
                }
              },
              child: const Text('添加')),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String oldName,
      Function(String) onRename) {
    final ctrl = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '新名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
          FilledButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  onRename(ctrl.text.trim());
                  Navigator.pop(ctx);
                }
              },
              child: const Text('确定')),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red),
              onPressed: () {
                onConfirm();
                Navigator.pop(ctx);
              },
              child: const Text('删除')),
        ],
      ),
    );
  }

  Future<void> _importRoster(BuildContext context) async {
    try {
      final r = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx', 'xls']);
      if (r == null || r.files.isEmpty) return;
      final path = r.files.single.path;
      if (path == null) return;
      final classrooms = await ExcelService.parseRoster(path);
      if (classrooms.isEmpty) {
        ToastOverlay.show(context, '未能解析到任何班级数据');
        return;
      }
      ref
          .read(classProvider.notifier)
          .loadFromData(classrooms, classrooms.first.uid);
      ToastOverlay.show(
          context, '导入成功: ${classrooms.length} 个班级',
          type: ToastType.success);
    } catch (e) {
      ToastOverlay.show(context, '导入失败: $e', type: ToastType.error);
    }
  }
}

// ==================== 设置页面 ====================
class _SettingsPage extends ConsumerWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final ws = ref.watch(workspaceServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _section('下载源', context),
        _actionTile(
          theme,
          Icons.cloud_download,
          '教材/更新下载源',
          settings.downloadSource == 'github'
              ? 'GitHub 官方源'
              : '国内镜像加速',
          () async {
            final result =
                await _showDownloadSourcePicker(context, settings);
            if (result != null) {
              ref.read(settingsProvider.notifier).update(
                  settings.copyWith(downloadSource: result));
            }
          },
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 8),

        _section('交互反馈', context),
        SwitchListTile.adaptive(
          title: const Text('音效', style: TextStyle(fontSize: 14)),
          subtitle: const Text('抽取、加减分、计时结束等音效',
              style: TextStyle(fontSize: 12)),
          value: settings.soundEnabled,
          dense: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) {
            ref
                .read(settingsProvider.notifier)
                .update(settings.copyWith(soundEnabled: v));
            AudioEngine().setSoundEnabled(v);
          },
        ),
        SwitchListTile.adaptive(
          title: const Text('触感反馈', style: TextStyle(fontSize: 14)),
          subtitle: const Text('按钮按压振动',
              style: TextStyle(fontSize: 12)),
          value: settings.hapticFeedback,
          dense: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) {
            ref
                .read(settingsProvider.notifier)
                .update(settings.copyWith(hapticFeedback: v));
            AudioEngine().setHapticEnabled(v);
          },
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 8),

        _section('数据管理', context),
        _actionTile(
            theme, Icons.save_alt, '立即保存', '手动保存当前积分数据',
            () async {
          try {
            await ref
                .read(dataServiceProvider)
                .save(silent: false, immediate: true);
            ToastOverlay.show(context, '保存成功',
                type: ToastType.success);
          } catch (e) {
            ToastOverlay.show(context, '保存失败: $e',
                type: ToastType.error);
          }
        }),
        const SizedBox(height: 4),
        _actionTile(
            theme,
            Icons.folder_open,
            '工作目录',
            ws.isConfigured
                ? ws.rootPath!.split('/').last
                : '未设置',
            () async {
          final path = await ws.pickFolder();
          if (path != null && ws.isConfigured) {
            await ws.ensureInitialTemplates();
            await ref
                .read(dataServiceProvider)
                .loadFromWorkspace();
            ToastOverlay.show(
                context, '工作目录已设置',
                type: ToastType.success);
          }
        }),
        const SizedBox(height: 4),
        _actionTile(theme, Icons.import_export, '导入/导出',
            '名单/模板', () => _showImportExportSheet(context, ref)),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 8),

        _section('云端同步', context),
        _actionTile(
            theme,
            Icons.cloud_sync,
            'WebDAV 同步',
            settings.webdavUsername.isNotEmpty ? '已配置' : '未配置',
            () => _openFullSettings(context)),
        const SizedBox(height: 4),
        const SyncStatusIndicator(),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 8),

        _section('关于', context),
        _actionTile(
            theme, Icons.info_outline, '灵动课堂 v1.30',
            '版本信息与开源说明', () {
          Navigator.push(context,
              slideFadePageRoute(const OpenSourceScreen()));
        }),
        const SizedBox(height: 24),
        SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('打开完整设置',
                  style: TextStyle(fontSize: 14)),
              onPressed: () => _openFullSettings(context),
            )),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _section(String t, BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14)),
      );

  Widget _actionTile(ThemeData theme, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color:
          theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading:
            Icon(icon, size: 22, color: theme.colorScheme.primary),
        title: Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle:
            Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
        dense: true,
      ),
    );
  }
}

// ==================== 辅助函数 ====================

void _openFullSettings(BuildContext context) {
  showDialog(
      context: context, builder: (_) => const SettingsDialog());
}

Future<String?> _showDownloadSourcePicker(
    BuildContext context, SettingsState settings) async {
  final theme = Theme.of(context);
  return showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              child: Row(children: [
                Icon(Icons.cloud_download,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('选择下载源',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ])),
          const Divider(height: 1),
          RadioListTile<String>(
            title: const Text('GitHub 官方源',
                style: TextStyle(fontSize: 14)),
            subtitle: const Text('适用于海外及网络条件好的用户',
                style: TextStyle(fontSize: 12)),
            value: 'github',
            groupValue: settings.downloadSource,
            onChanged: (v) => Navigator.pop(ctx, v),
          ),
          RadioListTile<String>(
            title: const Text('国内镜像加速',
                style: TextStyle(fontSize: 14)),
            subtitle: const Text('适用于中国大陆用户',
                style: TextStyle(fontSize: 12)),
            value: 'mirror',
            groupValue: settings.downloadSource,
            onChanged: (v) => Navigator.pop(ctx, v),
          ),
        ]),
      ),
    ),
  );
}

void _showImportExportSheet(BuildContext context, WidgetRef ref) {
  final theme = Theme.of(context);
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child:
            Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              child: Row(children: [
                Icon(Icons.import_export,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('数据导入/导出',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ])),
          const Divider(height: 1),
          _groupLabel(theme, '导入'),
          ListTile(
            leading:
                const Icon(Icons.person_add_alt, size: 20),
            title: const Text('导入学生名单',
                style: TextStyle(fontSize: 14)),
            trailing:
                const Icon(Icons.chevron_right, size: 18),
            onTap: () {
              Navigator.pop(ctx);
              _doImportRoster(context, ref);
            },
            dense: true,
          ),
          const Divider(height: 1, indent: 56),
          _groupLabel(theme, '导出'),
          ListTile(
            leading:
                const Icon(Icons.note_add, size: 20),
            title: const Text('导出名单模板',
                style: TextStyle(fontSize: 14)),
            trailing:
                const Icon(Icons.chevron_right, size: 18),
            onTap: () {
              Navigator.pop(ctx);
              _doExportMemberTemplate(context, ref);
            },
            dense: true,
          ),
          ListTile(
            leading: const Icon(Icons.quiz_outlined,
                size: 20),
            title: const Text('导出题库模板',
                style: TextStyle(fontSize: 14)),
            trailing:
                const Icon(Icons.chevron_right, size: 18),
            onTap: () {
              Navigator.pop(ctx);
              _doExportQuestionTemplate(context, ref);
            },
            dense: true,
          ),
        ]),
      ),
    ),
  );
}

Widget _groupLabel(ThemeData theme, String title) {
  return Padding(
    padding:
        const EdgeInsets.only(left: 20, top: 8, bottom: 4),
    child: Text(title,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.4))),
  );
}

Future<void> _doImportRoster(
    BuildContext context, WidgetRef ref) async {
  try {
    final r = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls']);
    if (r == null || r.files.isEmpty) return;
    final path = r.files.single.path;
    if (path == null) return;
    final classrooms = await ExcelService.parseRoster(path);
    if (classrooms.isEmpty) {
      ToastOverlay.show(context, '未能解析到任何班级数据');
      return;
    }
    ref
        .read(classProvider.notifier)
        .loadFromData(classrooms, classrooms.first.uid);
    ToastOverlay.show(
        context, '导入成功: ${classrooms.length} 个班级',
        type: ToastType.success);
  } catch (e) {
    ToastOverlay.show(context, '导入失败: $e',
        type: ToastType.error);
  }
}

Future<void> _doExportMemberTemplate(
    BuildContext context, WidgetRef ref) async {
  try {
    final result =
        await ref.read(fileServiceProvider).exportMemberTemplate();
    if (result != null) {
      final msg = result.path
                  .contains('/storage/emulated/0/Download') ||
              result.path.contains('/Download')
          ? '模板已保存到 Downloads 文件夹'
          : '名单模板已导出';
      ToastOverlay.show(context, msg, type: ToastType.success);
    }
  } catch (e) {
    ToastOverlay.show(context, '模板导出失败: $e',
        type: ToastType.error);
  }
}

Future<void> _doExportQuestionTemplate(
    BuildContext context, WidgetRef ref) async {
  try {
    final result = await ref
        .read(fileServiceProvider)
        .exportQuestionTemplate();
    if (result != null) {
      final msg = result.path
                  .contains('/storage/emulated/0/Download') ||
              result.path.contains('/Download')
          ? '模板已保存到 Downloads 文件夹'
          : '题库模板已导出';
      ToastOverlay.show(context, msg, type: ToastType.success);
    }
  } catch (e) {
    ToastOverlay.show(context, '模板导出失败: $e',
        type: ToastType.error);
  }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  final void Function() onBackground;
  _LifecycleObserver({required this.onBackground});
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      onBackground();
    }
  }
}
