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
      if (result != null) {
        ToastOverlay.show(context, '名单模板已导出');
      }
    } catch (e) { ToastOverlay.show(context, '模板导出失败: $e'); }
  }

  Future<void> _exportQuestionTemplate() async {
    try {
      final result = await ref.read(fileServiceProvider).exportQuestionTemplate();
      if (result != null) {
        ToastOverlay.show(context, '题库模板已导出');
      }
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
          // 数据管理组
          Card(
            child: Column(children: [
              _moreTile(Icons.folder_open, '选择文件夹', _pickFolder),
              _moreTile(Icons.save_alt, '保存数据', () => _save()),
              _moreTile(Icons.file_open, '加载数据', _load),
            ]),
          ),
          const SizedBox(height: 8),
          // 同步
          Card(
            child: _moreTile(Icons.cloud_sync, '云端同步', _sync),
          ),
          const SizedBox(height: 8),
          // 导入/导出
          Card(
            child: Column(children: [
              _moreTile(Icons.person_add_alt, '导入名单', _importRoster),
              _moreTile(Icons.upload_file, '导入积分', _importScores),
              const Divider(height: 1, indent: 56, endIndent: 16),
              _moreTile(Icons.download, '导出积分', _exportScores),
              _moreTile(Icons.note_add, '导出名单模板', _exportMemberTemplate),
              _moreTile(Icons.quiz_outlined, '导出题库模板', _exportQuestionTemplate),
            ]),
          ),
          const SizedBox(height: 8),
          // 工具
          Card(
            child: Column(children: [
              _moreTile(Icons.menu_book, '教材仓库', () {
                Navigator.push(context, slideFadePageRoute(const TextbookBrowserScreen()));
              }),
              const Divider(height: 1, indent: 56, endIndent: 16),
              _moreTile(Icons.settings, '设置', _openSettings),
              const Divider(height: 1, indent: 56, endIndent: 16),
              _moreTile(Icons.favorite, '开源说明', () {
                Navigator.push(context, slideFadePageRoute(const OpenSourceScreen()));
              }),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _moreTile(IconData icon, String label, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // ===================== 桌面/平板布局 =====================
  Widget _tabletBody() {
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    return Row(
      children: [
        Expanded(flex: 5, child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
          child: Column(children: [
            const SizedBox(height: 36),
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
      ],
    );
  }

  // ===================== 教学大屏布局（100寸希沃） =====================
  Widget _teachingBody() {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth > constraints.maxHeight;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.teachingSafeMargin),
          child: Column(
            children: [
              // 顶部课程标题栏
              _teachingTopBar(),
              const SizedBox(height: 24),
              // 核心教学区域
              Expanded(
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 5, child: _teachingPanel('🎲  抽取', const DrawPanel())),
                          const SizedBox(width: 24),
                          Expanded(flex: 5, child: _teachingPanel('📝  题库', const QuestionPanel())),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(child: _teachingPanel('🎲  抽取', const DrawPanel())),
                          const SizedBox(height: 24),
                          Expanded(child: _teachingPanel('📝  题库', const QuestionPanel())),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              // 底部功能区
              SizedBox(
                height: 160,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _teachingPanel('⏱  计时器', const TimerPanel())),
                    const SizedBox(width: 24),
                    Expanded(child: _teachingPanel('🏆  排行', const LeaderboardPanel())),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 底部操作栏（大按钮，无右键菜单，无悬停）
              _teachingBottomDock(),
            ],
          ),
        );
      },
    );
  }

  Widget _teachingTopBar() {
    final settings = ref.watch(settingsProvider);
    final cs = ref.watch(classProvider);
    return Row(
      children: [
        Text('灵动课堂', style: Theme.of(context).textTheme.headlineMedium),
        const Spacer(),
        // 班级快捷切换
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.teachingSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.teachingBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('当前班级：${cs.selectedClass?.name ?? "未选择"}', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              const Icon(Icons.arrow_drop_down, size: 48),
            ],
          ),
        ),
      ],
    );
  }

  Widget _teachingPanel(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.teachingSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.teachingBorder, width: 2),
        boxShadow: AppShadows.level2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _teachingBottomDock() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.level2,
      ),
      // 底部死区：下边缘留 20px 不可触区域防掌误触
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTouchTarget.teachingBottomDeadZone),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _teachingDockBtn(Icons.save_alt, '保存', () => _save()),
            _teachingDockBtn(Icons.file_open, '加载', _load),
            _teachingDockBtn(Icons.cloud_sync, '同步', _sync),
            _teachingDockBtn(Icons.person_add_alt, '名单', _importRoster),
            _teachingDockBtn(Icons.settings, '设置', _openSettings),
            _teachingDockBtn(Icons.menu_book, '教材', () {
              Navigator.push(context, slideFadePageRoute(const TextbookBrowserScreen()));
            }),
            // 教学/备课模式切换
            _teachingDockBtn(Icons.tv, '课堂', () {
              final notifier = ref.read(settingsProvider.notifier);
              notifier.toggleTeachingMode();
            }),
          ],
        ),
      ),
    );
  }

  Widget _teachingDockBtn(IconData icon, String label, VoidCallback onTap) {
    return _TeachingDockButton(
      icon: icon,
      label: label,
      onTap: onTap,
    );
  }

  // ===================== 主构建 =====================
  @override
  Widget build(BuildContext context) {
    final screen = context.screenType;
    final settings = ref.watch(settingsProvider);
    final isTeaching = settings.teachingMode || screen == ScreenType.teaching;

    // 如果是大屏但 teachingMode 未开启，自动启用
    if (screen == ScreenType.teaching && !settings.teachingMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(settingsProvider.notifier).setTeachingMode(true);
      });
    }

    if (isTeaching) {
      return Scaffold(
        body: _teachingBody(),
        // 大屏无 SafeArea，全屏渲染
        resizeToAvoidBottomInset: false,
      );
    }

    if (screen == ScreenType.tablet) {
      return Scaffold(
        body: Stack(
          children: [
            _tabletBody(),
            // 桌面浮动工具栏
            Positioned(bottom: 16, right: 16, child: CentralConsole(
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
            )),
            Positioned(top: 8, right: 16, child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AutoSaveIndicator(isDirty: ref.watch(classProvider).isDirty),
                const SizedBox(height: 4),
                const SyncStatusIndicator(),
              ],
            )),
            Positioned(top: 8, left: 16, child: _buildTextbookButton()),
          ],
        ),
        resizeToAvoidBottomInset: true,
      );
    }

    // 手机端：底部导航栏（带 AnimatedSwitcher 标签页过渡）
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _mobileBody(),
          ),
          Positioned(top: 4, right: 8, child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AutoSaveIndicator(isDirty: ref.watch(classProvider).isDirty),
              const SizedBox(height: 2),
              const SyncStatusIndicator(),
            ],
          )),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _mobileTabIndex,
        onDestinationSelected: (i) => setState(() => _mobileTabIndex = i),
        destinations: _mobileTabs.map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label)).toList(),
      ),
      resizeToAvoidBottomInset: true,
    );
  }

  // ===================== 教材/年级/开源按钮（桌面端） =====================
  Widget _buildTextbookButton() {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(Icons.menu_book, '教材', theme.colorScheme.primaryContainer, theme.colorScheme.primary, () {
          Navigator.push(context, slideFadePageRoute(const TextbookBrowserScreen()));
        }),
        const SizedBox(width: 6),
        _gradeSubjectChip(settings),
        const SizedBox(width: 6),
        _chip(Icons.favorite, '开源', theme.colorScheme.errorContainer, theme.colorScheme.error, () {
          Navigator.push(context, slideFadePageRoute(const OpenSourceScreen()));
        }),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color bg, Color fg, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppSpacing.lg), boxShadow: [BoxShadow(color: fg.withOpacity(0.12), blurRadius: 4)]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _gradeSubjectChip(SettingsState settings) {
    final theme = Theme.of(context);
    final grade = settings.currentGrade ?? '年级';
    final subject = settings.currentSubject ?? '学科';
    return InkWell(
      onTap: _showGradeSubjectPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: theme.colorScheme.tertiary.withOpacity(0.15), blurRadius: 4)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.school, size: 18, color: theme.colorScheme.tertiary),
          const SizedBox(width: 4),
          Text('$grade · $subject', style: TextStyle(color: theme.colorScheme.tertiary, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 2),
          Icon(Icons.arrow_drop_down, size: 16, color: theme.colorScheme.tertiary),
        ]),
      ),
    );
  }

  void _showGradeSubjectPicker() {
    final settings = ref.read(settingsProvider);
    const grades = ['一年级','二年级','三年级','四年级','五年级','六年级','初一','初二','初三','高一','高二','高三'];
    const subjects = ['语文','数学','英语','物理','化学','生物','历史','地理','政治','科学','信息技术','通用技术','体育','音乐','美术'];
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('切换年级和学科'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String?>(
          value: settings.currentGrade, isDense: true,
          decoration: const InputDecoration(labelText: '年级'),
          items: [const DropdownMenuItem<String?>(value: null, child: Text('不限')), ...grades.map((g) => DropdownMenuItem<String?>(value: g, child: Text(g)))],
          onChanged: (v) => ref.read(settingsProvider.notifier).setGrade(v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          value: settings.currentSubject, isDense: true,
          decoration: const InputDecoration(labelText: '学科'),
          items: [const DropdownMenuItem<String?>(value: null, child: Text('不限')), ...subjects.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s)))],
          onChanged: (v) => ref.read(settingsProvider.notifier).setSubject(v),
        ),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭'))],
    ));
  }
}

/// 教学大屏 Dock 按钮 — 带背景闪烁反馈动画
class _TeachingDockButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TeachingDockButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_TeachingDockButton> createState() => _TeachingDockButtonState();
}

class _TeachingDockButtonState extends State<_TeachingDockButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<Color?> _flashColor;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashColor = ColorTween(
      begin: AppColors.teachingSurface,
      end: AppColors.brandPrimary.withOpacity(0.15),
    ).animate(CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeInOut,
    ));
    _flashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _flashController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // 触感反馈 + 背景闪烁
    AudioEngine().hapticHeavy();
    widget.onTap();
    _flashController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _flashColor,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: _flashColor.value ?? AppColors.teachingSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.teachingBorder, width: 2),
            ),
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 48, color: AppColors.neutral700),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TabDefinition {
  final IconData icon;
  final String label;
  const TabDefinition(this.icon, this.label);
}
