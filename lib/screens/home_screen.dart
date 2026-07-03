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
import '../providers/services_provider.dart';
import '../services/audio_engine.dart';
import '../services/cloud/cloud_storage_service.dart';
import 'draw_panel.dart';
import 'question_panel.dart';
import 'timer_panel.dart';
import 'leaderboard_panel.dart';
import 'dialogs/settings_dialog.dart';
import 'dialogs/sync_progress_dialog.dart';
import 'textbook_browser_screen.dart';
import 'open_source_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.resumed) { _tryAutoLoadUsb(); }
    else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) { _save(silent: true); }
  }

  Future<void> _tryAutoLoadUsb() async {
    if (_usbChecked) return;
    _usbChecked = true;
    try {
      final fileService = ref.read(fileServiceProvider);
      final usbPath = await fileService.autoDetectUsb();
      if (usbPath != null && mounted) { ToastOverlay.show(context, '检测到U盘: $usbPath'); }
    } catch (_) {}
  }

  void _startAutoSave() {
    final settings = ref.read(settingsProvider);
    if (settings.autoSave) {
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer.periodic(Duration(seconds: settings.autoSaveInterval), (_) => _save(silent: true));
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
      if (!silent) ToastOverlay.show(context, '保存成功');
    } catch (e) { if (!silent) ToastOverlay.show(context, '保存失败: $e'); }
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(fileServiceProvider).pickAndLoadJson();
      if (data != null) {
        ref.read(classProvider.notifier).loadFromData(data.classrooms, data.classrooms.isNotEmpty ? data.classrooms.first.uid : null);
        ref.read(questionProvider.notifier).loadFromData(data.questionBanks);
        ToastOverlay.show(context, '加载成功');
      }
    } catch (e) { ToastOverlay.show(context, '加载失败: $e'); }
  }

  Future<void> _pickFolder() async {
    final path = await ref.read(fileServiceProvider).pickFolder();
    if (path != null) {
      ref.read(settingsProvider.notifier).update(ref.read(settingsProvider).copyWith(usbDataPath: path));
      ToastOverlay.show(context, '已选择文件夹');
    }
  }

  Future<void> _importRoster() async {
    try {
      final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls']);
      if (r == null || r.files.isEmpty) return;
      final path = r.files.single.path;
      if (path == null) return;
      final classrooms = await ExcelService.parseRoster(path);
      if (classrooms.isEmpty) { ToastOverlay.show(context, '未能解析到任何班级数据'); return; }
      // 导入后弹出班级选择
      ref.read(classProvider.notifier).loadFromData(classrooms, classrooms.first.uid);
      ToastOverlay.show(context, '导入名单成功: ${classrooms.length} 个班级');
    } catch (e) { ToastOverlay.show(context, '导入名单失败: $e'); }
  }

  Future<void> _exportScores() async {
    try {
      final cs = ref.read(classProvider);
      final data = AppData(classrooms: cs.classrooms, questionBanks: []);
      await ref.read(fileServiceProvider).exportScores(data);
      ToastOverlay.show(context, '积分导出成功');
    } catch (e) { ToastOverlay.show(context, '积分导出失败: $e'); }
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
            if (newScore != null) { notifier.setScore(classroom.uid, group.uid, member.uid, newScore); }
          }
        }
      }
      ToastOverlay.show(context, '积分导入成功');
    } catch (e) { ToastOverlay.show(context, '积分导入失败: $e'); }
  }

  Future<void> _exportMemberTemplate() async {
    try {
      final result = await ref.read(fileServiceProvider).exportMemberTemplate();
      if (result != null) ToastOverlay.show(context, '名单模板已导出');
    } catch (e) { ToastOverlay.show(context, '模板导出失败: $e'); }
  }

  Future<void> _exportQuestionTemplate() async {
    try {
      final result = await ref.read(fileServiceProvider).exportQuestionTemplate();
      if (result != null) ToastOverlay.show(context, '题库模板已导出');
    } catch (e) { ToastOverlay.show(context, '模板导出失败: $e'); }
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
        ToastOverlay.show(context, success ? '同步完成' : '同步失败，请检查网络和云端配置');
      }
    } catch (e) {
      if (mounted) { ref.read(syncProvider.notifier).syncError(e.toString()); Navigator.pop(context); ToastOverlay.show(context, '同步异常: $e'); }
    }
  }

  void _openSettings() {
    showDialog(context: context, builder: (_) => const SettingsDialog()).then((_) => _startAutoSave());
  }

  // ===================== 班级选择器 =====================
  void _showClassPicker() {
    final cs = ref.read(classProvider);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('选择上课班级'),
      content: SizedBox(
        width: 240,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (cs.classrooms.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('暂无班级，请先导入名单'))
          else
            ...cs.classrooms.map((c) => ListTile(
              title: Text(c.name),
              trailing: cs.selectedClass?.uid == c.uid ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                ref.read(classProvider.notifier).selectClass(c.uid);
                Navigator.pop(ctx);
              },
            )),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭'))],
    ));
  }

  // ===================== 移动端底部导航标签页 =====================
  static const _mobileTabs = <TabDefinition>[
    TabDefinition(Icons.casino, '抽取'),
    TabDefinition(Icons.quiz, '题库'),
    TabDefinition(Icons.timer, '计时'),
    TabDefinition(Icons.leaderboard, '排行'),
    TabDefinition(Icons.more_horiz, '更多'),
  ];

  Widget _mobileBody() {
    final tabWidget = () {
      switch (_mobileTabIndex) {
        case 0: return const DrawPanel();
        case 1: return const QuestionPanel();
        case 2: return const TimerPanel();
        case 3: return const LeaderboardPanel();
        case 4: return _mobileMorePanel();
        default: return const DrawPanel();
      }
    }();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.3, end: 1.0).animate(animation),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey('mobile_tab_$_mobileTabIndex'), child: tabWidget),
    );
  }

  Widget _mobileMorePanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Card(child: Column(children: [
          _moreTile(Icons.folder_open, '选择文件夹', _pickFolder),
          _moreTile(Icons.save_alt, '保存数据', () => _save()),
          _moreTile(Icons.file_open, '加载数据', _load),
        ])),
        const SizedBox(height: 6),
        Card(child: _moreTile(Icons.cloud_sync, '云端同步', _sync)),
        const SizedBox(height: 6),
        Card(child: Column(children: [
          _moreTile(Icons.person_add_alt, '导入名单', _importRoster),
          _moreTile(Icons.upload_file, '导入积分', _importScores),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _moreTile(Icons.download, '导出积分', _exportScores),
          _moreTile(Icons.note_add, '导出名单模板', _exportMemberTemplate),
          _moreTile(Icons.quiz_outlined, '导出题库模板', _exportQuestionTemplate),
        ])),
        const SizedBox(height: 6),
        Card(child: Column(children: [
          _moreTile(Icons.class_, '切换班级', _showClassPicker),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _moreTile(Icons.menu_book, '教材仓库', () => Navigator.push(context, slideFadePageRoute(const TextbookBrowserScreen()))),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _moreTile(Icons.settings, '设置', _openSettings),
          const Divider(height: 1, indent: 56, endIndent: 16),
          _moreTile(Icons.favorite, '开源说明', () => Navigator.push(context, slideFadePageRoute(const OpenSourceScreen()))),
        ])),
      ]),
    );
  }

  Widget _moreTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(leading: Icon(icon, size: 20), title: Text(label, style: const TextStyle(fontSize: 14)), trailing: const Icon(Icons.chevron_right, size: 18), onTap: onTap);
  }

  // ===================== 桌面/平板布局 =====================
  Widget _tabletBody() {
    final cs = ref.watch(classProvider);
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    return Row(children: [
      Expanded(flex: 5, child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
        child: Column(children: [
          // 班级选择栏
          Padding(padding: const EdgeInsets.only(bottom: 4),
            child: GestureDetector(
              onTap: _showClassPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.class_, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(cs.selectedClass?.name ?? '选择班级', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.primary)),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Expanded(child: DrawPanel()),
          const SizedBox(height: 4),
          const Expanded(child: TimerPanel()),
        ]),
      )),
      Expanded(flex: 5, child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 12, 8),
        child: Column(children: [
          const SizedBox(height: 36),
          const Expanded(child: QuestionPanel()),
          const SizedBox(height: 4),
          const Expanded(child: LeaderboardPanel()),
        ]),
      )),
    ]);
  }

  // ===================== 主构建 =====================
  @override
  Widget build(BuildContext context) {
    final screen = context.screenType;

    if (screen == ScreenType.tablet) {
      return Scaffold(
        body: Stack(children: [
          _tabletBody(),
          Positioned(bottom: 16, right: 16, child: CentralConsole(
            onSave: () => _save(), onLoad: _load, onPickFolder: _pickFolder,
            onSettings: _openSettings, onSync: _sync,
            onImportRoster: _importRoster, onExportScores: _exportScores,
            onImportScores: _importScores, onExportMemberTemplate: _exportMemberTemplate,
            onExportQuestionTemplate: _exportQuestionTemplate,
          )),
          Positioned(top: 8, right: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            AutoSaveIndicator(isDirty: ref.watch(classProvider).isDirty),
            const SizedBox(height: 2),
            const SyncStatusIndicator(),
          ])),
          Positioned(top: 8, left: 16, child: _buildTextbookButton()),
        ]),
        resizeToAvoidBottomInset: true,
      );
    }

    // 手机端
    return Scaffold(
      body: Stack(children: [
        Padding(padding: const EdgeInsets.only(top: 4), child: _mobileBody()),
        Positioned(top: 2, right: 6, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          AutoSaveIndicator(isDirty: ref.watch(classProvider).isDirty),
          const SizedBox(height: 1),
          const SyncStatusIndicator(),
        ])),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _mobileTabIndex,
        onDestinationSelected: (i) => setState(() => _mobileTabIndex = i),
        destinations: _mobileTabs.map((t) => NavigationDestination(icon: Icon(t.icon, size: 20), label: t.label)).toList(),
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  Widget _buildTextbookButton() {
    final theme = Theme.of(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _chip(Icons.menu_book, '教材', theme.colorScheme.primaryContainer, theme.colorScheme.primary, () {
        Navigator.push(context, slideFadePageRoute(const TextbookBrowserScreen()));
      }),
      const SizedBox(width: 4),
      _chip(Icons.favorite, '开源', theme.colorScheme.errorContainer, theme.colorScheme.error, () {
        Navigator.push(context, slideFadePageRoute(const OpenSourceScreen()));
      }),
    ]);
  }

  Widget _chip(IconData icon, String label, Color bg, Color fg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
        ]),
      ),
    );
  }
}

class TabDefinition {
  final IconData icon;
  final String label;
  const TabDefinition(this.icon, this.label);
}
