import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sync_models.dart';
import '../providers/class_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/draw_provider.dart';
import '../services/data_service.dart';
import '../services/workspace_service.dart';
import '../services/storage_service.dart';
import '../services/auto_sync_timer.dart';
import '../services/cloud/webdav_plus_sync.dart';
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
import 'open_source_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;
  static const _tabLabels = ['课堂', '班级', '资源', '设置'];
  static const _tabIcons = [Icons.school, Icons.people, Icons.menu_book, Icons.settings];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_LifecycleObserver(
        onBackground: () => ref.read(dataServiceProvider).saveImmediate(silent: true)));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ws = ref.read(workspaceServiceProvider);
      await ws.loadSavedPath();
      if (ws.isConfigured) { await ws.ensureInitialTemplates(); await ref.read(dataServiceProvider).loadFromWorkspace(); }
      _restoreSyncState();
      ref.read(autoSyncTimerProvider).start();
    });
  }

  void _restoreSyncState() {
    final t = ref.read(storageServiceProvider).getString('last_sync_timestamp');
    if (t.isNotEmpty) ref.read(syncProvider.notifier).restoreLastSyncTime(t);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(autoSaveProvider);
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isWide = size.width >= AppBreakpoints.desktop;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide ? _buildWideLayout() : isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
    );
  }

  Widget _buildWideLayout() => Row(children: [_buildLeftToolbar(), Expanded(child: _buildMainContent()), const SizedBox(width: 1)]);
  Widget _buildLandscapeLayout() => Row(children: [_buildLeftToolbar(compact: true), Expanded(child: _buildMainContent())]);

  Widget _buildPortraitLayout() => Column(children: [
    Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Text('灵动课堂', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(), const SyncStatusIndicator(), const SizedBox(width: 8),
          AutoSaveIndicator(isDirty: ref.watch(classProvider).isDirty),
        ]),
      ),
    ),
    Expanded(child: _buildMainContent()),
    _buildBottomBar(),
  ]);

  Widget _buildLeftToolbar({bool compact = false}) => FrostedPanel(
    width: compact ? 60 : 72, height: double.infinity, blur: 20, borderRadius: BorderRadius.zero,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
    child: Column(children: [
      SizedBox(height: compact ? 20 : 32),
      for (int i = 0; i < _tabLabels.length; i++)
        Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: _toolBtn(i, compact)),
      const Spacer(),
      AutoSaveIndicator(isDirty: ref.watch(classProvider).isDirty), const SizedBox(height: 4),
      const SyncStatusIndicator(),
    ]),
  );

  Widget _toolBtn(int i, bool compact) => GestureDetector(
    onTap: () => setState(() => _tabIndex = i),
    child: FrostedPanel(blur: 8, padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8, horizontal: 4),
      backgroundColor: _tabIndex == i ? AppColors.brandPrimary.withOpacity(0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(_tabIcons[i], size: compact ? 20 : 22,
            color: _tabIndex == i ? AppColors.brandPrimary : AppColors.textSecondary),
        const SizedBox(height: 2),
        Text(_tabLabels[i], style: TextStyle(fontSize: compact ? 9 : 10,
            color: _tabIndex == i ? AppColors.brandPrimary : AppColors.textSecondary,
            fontWeight: _tabIndex == i ? FontWeight.w600 : FontWeight.w400)),
      ]),
    ),
  );

  Widget _buildMainContent() {
    switch (_tabIndex) {
      case 0: return const _ClassroomView();
      case 1: return const _ClassDataView();
      case 2: return const TextbookPanel();
      case 3: return const _SettingsPage();
      default: return const _ClassroomView();
    }
  }

  Widget _buildBottomBar() => FrostedPanel(blur: 20,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
    child: SafeArea(top: false, child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(_tabLabels.length, (i) => GestureDetector(
        onTap: () => setState(() => _tabIndex = i),
        child: FrostedPanel(blur: 6, padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          backgroundColor: _tabIndex == i ? AppColors.brandPrimary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_tabIcons[i], size: 18, color: _tabIndex == i ? AppColors.brandPrimary : AppColors.textSecondary),
            if (_tabIndex == i) ...[const SizedBox(width: 4),
              Text(_tabLabels[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandPrimary))],
          ]),
        ),
      )),
    )),
  );
}

// ==================== 课堂主页 + 控制栏 ====================
class _ClassroomView extends ConsumerWidget {
  const _ClassroomView();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = ref.watch(classProvider);
    final ds = ref.watch(drawProvider);
    final cls = cs.selectedClass;
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.of(context).size.width < 500;

    return Column(children: [
      // 课堂控制栏
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(children: [
          // 班级选择器
          Expanded(
            child: cls != null
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.school, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Flexible(child: Text(cls.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 4),
                    Text('${cls.groups.length}组·${cls.allMembers.length}人',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  ])
                : Text('请先添加班级', style: TextStyle(fontSize: 13, color: theme.colorScheme.outline)),
          ),
          // 排除已选开关
          _ctrlChip(theme, '排除已选', ds.excludeDrawn,
              () => ref.read(drawProvider.notifier).toggleExcludeDrawn()),
          const SizedBox(width: 4),
          _ctrlChip(theme, '不重复', ds.noReplacement,
              () => ref.read(drawProvider.notifier).toggleNoReplacement()),
          const SizedBox(width: 4),
          // 重置排除
          InkWell(
            onTap: () { ref.read(drawProvider.notifier).resetDrawnOnly(); ToastOverlay.show(context, '已重置排除列表'); },
            child: Icon(Icons.refresh, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
        ]),
      ),
      const Divider(height: 1),
      // 功能卡片
      Expanded(child: Padding(padding: const EdgeInsets.all(6),
        child: isNarrow
            ? Column(children: [
                Expanded(child: _fc(Icons.casino, '抽取', AppColors.brandPrimary, const DrawPanel())),
                const SizedBox(height: 4),
                Expanded(child: _fc(Icons.timer, '计时', Colors.orange, const TimerPanel())),
                const SizedBox(height: 4),
                Expanded(child: _fc(Icons.leaderboard, '排行', Colors.green, const LeaderboardPanel())),
                const SizedBox(height: 4),
                Expanded(child: _fc(Icons.quiz, '题库', Colors.purple, const QuestionPanel())),
              ])
            : Column(children: [
                Expanded(child: Row(children: [
                  Expanded(child: _fc(Icons.casino, '抽取', AppColors.brandPrimary, const DrawPanel())),
                  const SizedBox(width: 4), Expanded(child: _fc(Icons.timer, '计时', Colors.orange, const TimerPanel())),
                ])),
                const SizedBox(height: 4),
                Expanded(child: Row(children: [
                  Expanded(child: _fc(Icons.leaderboard, '排行', Colors.green, const LeaderboardPanel())),
                  const SizedBox(width: 4), Expanded(child: _fc(Icons.quiz, '题库', Colors.purple, const QuestionPanel())),
                ])),
              ]),
      )),
    ]);
  }

  Widget _ctrlChip(ThemeData theme, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: active ? AppColors.brandPrimary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppColors.brandPrimary : theme.colorScheme.outline.withOpacity(0.2)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: active ? AppColors.brandPrimary : theme.colorScheme.outline)),
      ),
    );
  }

  Widget _fc(IconData icon, String label, Color color, Widget child) => FrostedPanel(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color))]),
      const SizedBox(height: 4), Expanded(child: child),
    ],
  ));
}

// ==================== 班级数据 ====================
class _ClassDataView extends ConsumerStatefulWidget {
  const _ClassDataView();
  @override
  ConsumerState<_ClassDataView> createState() => _ClassDataViewState();
}

class _ClassDataViewState extends ConsumerState<_ClassDataView> {
  String? _expandedClassUid, _expandedGroupUid;

  @override
  Widget build(BuildContext context) {
    final cs = ref.watch(classProvider); final theme = Theme.of(context);
    if (cs.classrooms.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.school_outlined, size: 48, color: theme.colorScheme.outline), const SizedBox(height: 12),
        const Text('还没有班级数据'), const SizedBox(height: 8),
        FilledButton.tonalIcon(icon: const Icon(Icons.add, size: 16), label: const Text('添加班级'),
            onPressed: () => _addDialog(context, '班级', (v) => ref.read(classProvider.notifier).addClass(v))),
        const SizedBox(height: 4),
        TextButton.icon(icon: const Icon(Icons.file_open, size: 16), label: const Text('从 xlsx 导入'),
            onPressed: () => _import(context)),
      ]));
    }
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Row(children: [
          Text('${cs.classrooms.length} 个班级 · ${cs.classrooms.fold<int>(0, (s,c) => s + c.allMembers.length)} 名学生',
              style: theme.textTheme.bodySmall), const Spacer(),
          IconButton(icon: const Icon(Icons.add, size: 20), tooltip: '添加班级',
              onPressed: () => _addDialog(context, '班级', (v) => ref.read(classProvider.notifier).addClass(v)),
              visualDensity: VisualDensity.compact),
          IconButton(icon: const Icon(Icons.file_open, size: 18), tooltip: '导入名单',
              onPressed: () => _import(context), visualDensity: VisualDensity.compact),
        ]),
      ), const Divider(height: 1),
      Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: cs.classrooms.length,
        itemBuilder: (_, ci) {
          final cls = cs.classrooms[ci]; final exp = _expandedClassUid == cls.uid;
          return Card(margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              ListTile(
                leading: Icon(exp ? Icons.school : Icons.school_outlined, color: theme.colorScheme.primary, size: 22),
                title: Text(cls.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('${cls.groups.length} 组 · ${cls.allMembers.length} 人', style: const TextStyle(fontSize: 11)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit, size: 16), tooltip: '重命名',
                      onPressed: () => _renameDialog(context, cls.name, (v) => ref.read(classProvider.notifier).renameClass(cls.uid, v)),
                      visualDensity: VisualDensity.compact),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 16), tooltip: '删除',
                      onPressed: () => _confirm(context, '删除班级 "${cls.name}"？', () => ref.read(classProvider.notifier).deleteClass(cls.uid)),
                      visualDensity: VisualDensity.compact),
                ]),
                onTap: () => setState(() => _expandedClassUid = exp ? null : cls.uid),
              ),
              if (exp) ...cls.groups.map((g) {
                final gExp = _expandedGroupUid == g.uid;
                return Column(children: [
                  const Divider(height: 1, indent: 48),
                  ListTile(
                    leading: const Icon(Icons.groups, size: 20, color: AppColors.brandSecondary),
                    title: Text(g.name, style: const TextStyle(fontSize: 13)),
                    subtitle: Text('${g.members.length} 人 · ${g.totalScore.toStringAsFixed(1)} 分', style: const TextStyle(fontSize: 11)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.person_add, size: 16), tooltip: '添加成员',
                          onPressed: () => _addDialog(context, '成员', (v) { ref.read(classProvider.notifier).selectClass(cls.uid); ref.read(classProvider.notifier).addMember(g.uid, v); }),
                          visualDensity: VisualDensity.compact),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 16), tooltip: '删除小组',
                          onPressed: () => _confirm(context, '删除小组 "${g.name}"？', () => ref.read(classProvider.notifier).deleteGroup(cls.uid, g.uid)),
                          visualDensity: VisualDensity.compact),
                    ]),
                    onTap: () => setState(() => _expandedGroupUid = gExp ? null : g.uid),
                  ),
                  if (gExp) ...g.members.map((m) => Padding(padding: const EdgeInsets.only(left: 60, right: 8, bottom: 2),
                    child: Row(children: [
                      Expanded(child: Text(m.name, style: const TextStyle(fontSize: 12))),
                      Text(m.score.toStringAsFixed(1), style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                      const SizedBox(width: 8),
                      IconButton(icon: const Icon(Icons.delete, size: 14), tooltip: '删除',
                          onPressed: () => ref.read(classProvider.notifier).deleteMember(cls.uid, g.uid, m.uid),
                          visualDensity: VisualDensity.compact),
                    ]),
                  )),
                ]);
              }),
              if (exp) TextButton.icon(icon: const Icon(Icons.add, size: 14), label: const Text('添加小组'),
                  onPressed: () => _addDialog(context, '小组', (v) { ref.read(classProvider.notifier).selectClass(cls.uid); ref.read(classProvider.notifier).addGroup(v); })),
            ]),
          );
        },
      )),
    ]);
  }

  void _addDialog(BuildContext ctx, String what, Function(String) onAdd) {
    final c = TextEditingController();
    showDialog(context: ctx, builder: (ctx2) => AlertDialog(
      title: Text('添加$what'), content: TextField(controller: c, decoration: InputDecoration(hintText: '${what}名称'), autofocus: true),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('取消')),
        FilledButton(onPressed: () { if (c.text.trim().isNotEmpty) { onAdd(c.text.trim()); Navigator.pop(ctx2); } }, child: const Text('添加'))],
    ));
  }

  void _renameDialog(BuildContext ctx, String old, Function(String) cb) {
    final c = TextEditingController(text: old);
    showDialog(context: ctx, builder: (ctx2) => AlertDialog(
      title: const Text('重命名'), content: TextField(controller: c, autofocus: true),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('取消')),
        FilledButton(onPressed: () { if (c.text.trim().isNotEmpty) { cb(c.text.trim()); Navigator.pop(ctx2); } }, child: const Text('确定'))],
    ));
  }

  void _confirm(BuildContext ctx, String msg, VoidCallback cb) {
    showDialog(context: ctx, builder: (ctx2) => AlertDialog(
      title: const Text('确认删除'), content: Text(msg),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('取消')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { cb(); Navigator.pop(ctx2); }, child: const Text('删除'))],
    ));
  }

  Future<void> _import(BuildContext ctx) async {
    try {
      final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
      if (r == null || r.files.isEmpty) return;
      final p = r.files.single.path; if (p == null) return;
      final cs = await ExcelService.parseRoster(p);
      if (cs.isEmpty) { ToastOverlay.show(ctx, '未能解析到任何班级数据'); return; }
      ref.read(classProvider.notifier).loadFromData(cs, cs.first.uid);
      ToastOverlay.show(ctx, '导入成功: ${cs.length} 个班级', type: ToastType.success);
    } catch (e) { ToastOverlay.show(ctx, '导入失败: $e', type: ToastType.error); }
  }
}

// ==================== 设置页面（内联所有设置） ====================
class _SettingsPage extends ConsumerWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context); final s = ref.watch(settingsProvider);
    final ws = ref.watch(workspaceServiceProvider);
    return SingleChildScrollView(padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sec('下载源', theme),
        _tile(theme, Icons.cloud_download, '教材/更新下载源',
            s.downloadSource == 'github' ? 'GitHub 官方源' : '国内镜像加速',
            () => _showPicker(context, s, ref)),
        const SizedBox(height: 10), const Divider(height: 1), const SizedBox(height: 6),
        _sec('交互反馈', theme),
        SwitchListTile.adaptive(title: const Text('音效', style: TextStyle(fontSize: 14)), value: s.soundEnabled, dense: true,
            contentPadding: EdgeInsets.zero, onChanged: (v) { ref.read(settingsProvider.notifier).update(s.copyWith(soundEnabled: v)); AudioEngine().setSoundEnabled(v); }),
        SwitchListTile.adaptive(title: const Text('触感反馈', style: TextStyle(fontSize: 14)), value: s.hapticFeedback, dense: true,
            contentPadding: EdgeInsets.zero, onChanged: (v) { ref.read(settingsProvider.notifier).update(s.copyWith(hapticFeedback: v)); AudioEngine().setHapticEnabled(v); }),
        const SizedBox(height: 6), const Divider(height: 1), const SizedBox(height: 6),
        _sec('主题与界面', theme),
        SwitchListTile.adaptive(title: const Text('24小时制', style: TextStyle(fontSize: 14)), value: s.is24Hour, dense: true,
            contentPadding: EdgeInsets.zero, onChanged: (v) => ref.read(settingsProvider.notifier).update(s.copyWith(is24Hour: v))),
        SwitchListTile.adaptive(title: const Text('深色模式', style: TextStyle(fontSize: 14)), value: s.isDarkMode, dense: true,
            contentPadding: EdgeInsets.zero, onChanged: (v) => ref.read(settingsProvider.notifier).update(s.copyWith(isDarkMode: v))),
        const SizedBox(height: 4),
        _ddStr(theme, '布局方向', s.layoutMode, const [
          DropdownMenuItem(value: 'auto', child: Text('自动', style: TextStyle(fontSize: 14))),
          DropdownMenuItem(value: 'landscape', child: Text('横屏', style: TextStyle(fontSize: 14))),
          DropdownMenuItem(value: 'portrait', child: Text('竖屏', style: TextStyle(fontSize: 14))),
        ], (v) => ref.read(settingsProvider.notifier).update(s.copyWith(layoutMode: v!))),
        const SizedBox(height: 6), const Divider(height: 1), const SizedBox(height: 6),
        _sec('数据管理', theme),
        _tile(theme, Icons.save_alt, '立即保存', '手动保存当前积分数据', () async {
          try { await ref.read(dataServiceProvider).save(silent: false, immediate: true); ToastOverlay.show(context, '保存成功', type: ToastType.success); }
          catch (e) { ToastOverlay.show(context, '保存失败: $e', type: ToastType.error); }
        }),
        const SizedBox(height: 2),
        _tile(theme, Icons.folder_open, '工作目录', ws.isConfigured ? ws.rootPath!.split('/').last : '未设置', () async {
          final p = await ws.pickFolder(); if (p != null && ws.isConfigured) { await ws.ensureInitialTemplates(); await ref.read(dataServiceProvider).loadFromWorkspace(); ToastOverlay.show(context, '工作目录已设置', type: ToastType.success); }
        }),
        const SizedBox(height: 2),
        _tile(theme, Icons.import_export, '导入/导出', '名单/模板', () => _showImportExportSheet(context, ref)),
        const SizedBox(height: 6), const Divider(height: 1), const SizedBox(height: 6),

        // ===== 云端同步（内联组件） =====
        _sec('云端同步 (WebDAV)', theme),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: Text('同步至坚果云', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: theme.colorScheme.primary))),
          TextButton.icon(icon: const Icon(Icons.open_in_new, size: 14), label: const Text('注册账号', style: TextStyle(fontSize: 13)),
              onPressed: () => launchUrl(Uri.parse('https://www.jianguoyun.com/signup'), mode: LaunchMode.externalApplication)),
        ]),
        const SizedBox(height: 4),
        _ddStr(theme, '云服务', s.cloudServiceType, [
          for (final p in cloudPresets) DropdownMenuItem(value: p.name, child: Text(p.name, style: const TextStyle(fontSize: 14))),
        ], (v) {
          final ps = cloudPresets.firstWhere((p) => p.name == v);
          ref.read(settingsProvider.notifier).update(s.copyWith(cloudServiceType: v!, webdavUrl: ps.defaultUrl));
        }),
        const SizedBox(height: 4),
        _tf(theme, 'WebDAV 地址', s.webdavUrl, hint: 'https://dav.jianguoyun.com/dav/', onChanged: (v) => ref.read(settingsProvider.notifier).update(s.copyWith(webdavUrl: v))),
        const SizedBox(height: 4),
        _tf(theme, '用户名', s.webdavUsername, onChanged: (v) => ref.read(settingsProvider.notifier).update(s.copyWith(webdavUsername: v))),
        const SizedBox(height: 4),
        _SyncPasswordField(),
        const SizedBox(height: 4),
        _tf(theme, '远程文件夹', s.remoteFolder, onChanged: (v) => ref.read(settingsProvider.notifier).update(s.copyWith(remoteFolder: v))),
        const SizedBox(height: 6),
        // 同步状态
        Consumer(builder: (ctx, ref, _) {
          final sy = ref.watch(syncProvider);
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(color: _syncBg(sy.status), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const SyncStatusIndicator(), const Spacer(),
              if (sy.status == SyncStatus.syncing) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            ]),
          );
        }),
        const SizedBox(height: 6),
        _SyncButtons(),
        const SizedBox(height: 4),
        SwitchListTile.adaptive(title: const Text('自动同步', style: TextStyle(fontSize: 14)), value: s.autoSync, dense: true,
            contentPadding: EdgeInsets.zero, onChanged: (v) => ref.read(settingsProvider.notifier).update(s.copyWith(autoSync: v))),
        _ddInt(theme, '同步间隔', s.autoSyncInterval, const [
          DropdownMenuItem(value: 0, child: Text('手动', style: TextStyle(fontSize: 14))),
          DropdownMenuItem(value: 5, child: Text('5分钟', style: TextStyle(fontSize: 14))),
          DropdownMenuItem(value: 15, child: Text('15分钟', style: TextStyle(fontSize: 14))),
          DropdownMenuItem(value: 30, child: Text('30分钟', style: TextStyle(fontSize: 14))),
        ], (v) => ref.read(settingsProvider.notifier).update(s.copyWith(autoSyncInterval: v!))),
        const SizedBox(height: 2),
        _ddStr(theme, '同步策略', s.syncStrategy, const [
          DropdownMenuItem(value: 'bidirectional', child: Text('双向同步（先上传后下载）', style: TextStyle(fontSize: 14))),
          DropdownMenuItem(value: 'upload_only', child: Text('仅上传', style: TextStyle(fontSize: 14))),
          DropdownMenuItem(value: 'download_first', child: Text('下载优先', style: TextStyle(fontSize: 14))),
        ], (v) => ref.read(settingsProvider.notifier).update(s.copyWith(syncStrategy: v!))),
        const SizedBox(height: 6), const Divider(height: 1), const SizedBox(height: 6),
        _sec('本地存档', theme),
        SwitchListTile.adaptive(title: const Text('自动保存', style: TextStyle(fontSize: 14)), value: s.autoSave, dense: true,
            contentPadding: EdgeInsets.zero, onChanged: (v) => ref.read(settingsProvider.notifier).update(s.copyWith(autoSave: v))),
        _ddInt(theme, '保存间隔', s.autoSaveInterval, const [
          DropdownMenuItem(value: 15, child: Text('15秒', style: TextStyle(fontSize: 14))),
          DropdownMenuItem(value: 30, child: Text('30秒', style: TextStyle(fontSize: 14))),
          DropdownMenuItem(value: 60, child: Text('60秒', style: TextStyle(fontSize: 14))),
          DropdownMenuItem(value: 120, child: Text('120秒', style: TextStyle(fontSize: 14))),
        ], (v) => ref.read(settingsProvider.notifier).update(s.copyWith(autoSaveInterval: v!))),
        const SizedBox(height: 6), const Divider(height: 1), const SizedBox(height: 6),
        _sec('关于', theme),
        _tile(theme, Icons.info_outline, '灵动课堂 v1.31', '版本信息与开源说明 | Apache 2.0', () {
          Navigator.push(context, slideFadePageRoute(const OpenSourceScreen()));
        }),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _sec(String t, ThemeData th) => Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: th.colorScheme.primary, fontSize: 14));

  Widget _tile(ThemeData th, IconData ic, String t, String sub, VoidCallback onTap) => Card(
    elevation: 0, color: th.colorScheme.surfaceContainerHighest.withOpacity(0.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: ListTile(leading: Icon(ic, size: 22, color: th.colorScheme.primary),
        title: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 18), onTap: onTap, dense: true),
  );

  Widget _ddStr(ThemeData th, String label, String value, List<DropdownMenuItem<String>> items, Function(String?) cb) =>
      DropdownButtonFormField<String>(value: value, decoration: InputDecoration(labelText: label, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)), items: items, onChanged: cb);

  Widget _ddInt(ThemeData th, String label, int value, List<DropdownMenuItem<int>> items, Function(int?) cb) =>
      DropdownButtonFormField<int>(value: value, decoration: InputDecoration(labelText: label, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)), items: items, onChanged: cb);

  Widget _tf(ThemeData th, String label, String value, {String? hint, Function(String)? onChanged}) =>
      TextFormField(initialValue: value, decoration: InputDecoration(labelText: label, isDense: true, hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)), style: const TextStyle(fontSize: 14), onChanged: onChanged);

  Color _syncBg(SyncStatus s) {
    switch (s) {
      case SyncStatus.syncing: return Colors.blue.withOpacity(0.08);
      case SyncStatus.online: return Colors.green.withOpacity(0.08);
      case SyncStatus.error: return Colors.red.withOpacity(0.08);
      case SyncStatus.offline: return Colors.orange.withOpacity(0.08);
      default: return Colors.grey.withOpacity(0.06);
    }
  }

  void _showPicker(BuildContext ctx, SettingsState s, WidgetRef ref) async {
    final r = await showModalBottomSheet<String>(context: ctx,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        RadioListTile<String>(title: const Text('GitHub 官方源'), value: 'github', groupValue: s.downloadSource, onChanged: (v) => Navigator.pop(c, v)),
        RadioListTile<String>(title: const Text('国内镜像加速'), value: 'mirror', groupValue: s.downloadSource, onChanged: (v) => Navigator.pop(c, v)),
      ])));
    if (r != null) ref.read(settingsProvider.notifier).update(s.copyWith(downloadSource: r));
  }
}

// ==================== 同步按钮组件 ====================
class _SyncButtons extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SyncButtons> createState() => _SyncButtonsState();
}
class _SyncButtonsState extends ConsumerState<_SyncButtons> {
  bool _testing = false, _syncing = false;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: OutlinedButton.icon(
          icon: Icon(_testing ? Icons.hourglass_empty : Icons.wifi, size: 16),
          label: Text(_testing ? '测试中...' : '测试连接', style: const TextStyle(fontSize: 13)),
          onPressed: _testing ? null : _testConn)),
      const SizedBox(width: 8),
      Expanded(child: FilledButton.tonalIcon(
          icon: Icon(_syncing ? Icons.hourglass_empty : Icons.sync, size: 16),
          label: Text(_syncing ? '同步中...' : '立即同步', style: const TextStyle(fontSize: 13)),
          onPressed: _syncing ? null : _doSync)),
    ]);
  }

  Future<void> _testConn() async {
    setState(() => _testing = true);
    final s = ref.read(settingsProvider);
    final pw = await ref.read(storageServiceProvider).getSecure('webdav_password') ?? '';
    final ok = await WebdavPlusSyncService().testConnection(settings: s, password: pw);
    if (mounted) { setState(() => _testing = false); if (ok) ref.read(syncProvider.notifier).setIdle(); ToastOverlay.show(context, ok ? '连接成功 ✓' : '连接失败'); }
  }

  Future<void> _doSync() async {
    setState(() => _syncing = true);
    ref.read(syncProvider.notifier).startSync(); ToastOverlay.show(context, '正在同步...');
    try {
      final ok = await ref.read(cloudStorageServiceProvider).sync();
      if (mounted) { setState(() => _syncing = false); ToastOverlay.show(context, ok ? '同步完成 ✓' : ref.read(syncProvider).message ?? '同步失败', type: ok ? ToastType.success : ToastType.error); }
    } catch (e) { if (mounted) { setState(() => _syncing = false); ToastOverlay.show(context, '异常: $e', type: ToastType.error); } }
  }
}

// ==================== 密码输入组件 ====================
class _SyncPasswordField extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SyncPasswordField> createState() => _SyncPasswordFieldState();
}
class _SyncPasswordFieldState extends ConsumerState<_SyncPasswordField> {
  String _pw = ''; bool _obscured = true, _loading = true;
  @override
  void initState() {
    super.initState();
    ref.read(storageServiceProvider).getSecure('webdav_password').then((v) { if (mounted) setState(() { _pw = v ?? ''; _loading = false; }); });
  }
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)));
    return TextFormField(
      obscureText: _obscured, initialValue: _pw,
      decoration: InputDecoration(labelText: '第三方应用专用密码', isDense: true, hintText: '非登录密码',
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixIcon: IconButton(icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility, size: 16),
              onPressed: () => setState(() => _obscured = !_obscured))),
      style: const TextStyle(fontSize: 14),
      onChanged: (v) { _pw = v; ref.read(storageServiceProvider).setSecure('webdav_password', v); },
    );
  }
}

// ==================== 云服务预设 ====================
class CloudPreset { final String name, defaultUrl, description; const CloudPreset(this.name, this.defaultUrl, this.description); }
const cloudPresets = [
  CloudPreset('坚果云', 'https://dav.jianguoyun.com/dav/', '需在坚果云设置中开启第三方应用密码'),
  CloudPreset('Nextcloud', '', '请填写您的 Nextcloud 服务器地址'),
  CloudPreset('自定义', '', '任意 WebDAV 兼容服务'),
];

// ==================== 导入导出面板 ====================
void _showImportExportSheet(BuildContext ctx, WidgetRef ref) {
  final theme = Theme.of(ctx);
  showModalBottomSheet(context: ctx,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (c) => SafeArea(child: Padding(padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(children: [Icon(Icons.import_export, size: 20, color: theme.colorScheme.primary), const SizedBox(width: 8),
              Text('数据导入/导出', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))])),
        const Divider(height: 1),
        _iLabel(theme, '导入'),
        _iItem(Icons.person_add_alt, '导入学生名单', () { Navigator.pop(c); _doImport(ctx, ref); }),
        const Divider(height: 1, indent: 56),
        _iLabel(theme, '导出'),
        _iItem(Icons.note_add, '导出名单模板', () { Navigator.pop(c); _doTmpl(ctx, ref, true); }),
        _iItem(Icons.quiz_outlined, '导出题库模板', () { Navigator.pop(c); _doTmpl(ctx, ref, false); }),
      ]),
    )),
  );
}
Widget _iLabel(ThemeData theme, String t) => Padding(padding: const EdgeInsets.only(left: 20, top: 8, bottom: 4),
    child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.4))));
Widget _iItem(IconData ic, String label, VoidCallback onTap) => ListTile(
    leading: Icon(ic, size: 20), title: Text(label, style: const TextStyle(fontSize: 14)),
    trailing: const Icon(Icons.chevron_right, size: 18), onTap: onTap, dense: true);

Future<void> _doImport(BuildContext ctx, WidgetRef ref) async {
  try {
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
    if (r == null || r.files.isEmpty) return;
    final p = r.files.single.path; if (p == null) return;
    final cs = await ExcelService.parseRoster(p);
    if (cs.isEmpty) { ToastOverlay.show(ctx, '未能解析到任何班级数据'); return; }
    ref.read(classProvider.notifier).loadFromData(cs, cs.first.uid);
    ToastOverlay.show(ctx, '导入成功: ${cs.length} 个班级', type: ToastType.success);
  } catch (e) { ToastOverlay.show(ctx, '导入失败: $e', type: ToastType.error); }
}

Future<void> _doTmpl(BuildContext ctx, WidgetRef ref, bool isMember) async {
  try {
    final f = isMember ? await ref.read(fileServiceProvider).exportMemberTemplate() : await ref.read(fileServiceProvider).exportQuestionTemplate();
    if (f != null) { final m = f.path.contains('/Download') ? '模板已保存到 Downloads 文件夹' : '模板已导出'; ToastOverlay.show(ctx, m, type: ToastType.success); }
  } catch (e) { ToastOverlay.show(ctx, '导出失败: $e', type: ToastType.error); }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  final void Function() onBackground;
  _LifecycleObserver({required this.onBackground});
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) onBackground();
  }
}
