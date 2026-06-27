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
import '../widgets/central_console.dart';
import '../widgets/toast_overlay.dart';
import '../widgets/auto_save_indicator.dart';
import '../widgets/sync_status_indicator.dart';
import '../providers/services_provider.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  Timer? _autoSaveTimer;
  bool _usbChecked = false;

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

      // 后台自动清理旧文件
      fileService.autoCleanup(await fileService.getWorkingDir());

      if (!silent) ToastOverlay.show(context, '保存成功');
    } catch (e) {
      if (!silent) ToastOverlay.show(context, '保存失败: $e');
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
        ToastOverlay.show(context, '加载成功');
      }
    } catch (e) {
      ToastOverlay.show(context, '加载失败: $e');
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

  // ===================== Excel/Roster 导入 =====================
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
      ref.read(classProvider.notifier).loadFromData(
            classrooms,
            classrooms.first.uid,
          );
      ToastOverlay.show(context, '导入名单成功: ${classrooms.length} 个班级');
    } catch (e) {
      ToastOverlay.show(context, '导入名单失败: $e');
    }
  }

  Future<void> _exportScores() async {
    try {
      final cs = ref.read(classProvider);
      final data = AppData(classrooms: cs.classrooms, questionBanks: []);
      await ref.read(fileServiceProvider).exportScores(data);
      ToastOverlay.show(context, '积分导出成功');
    } catch (e) {
      ToastOverlay.show(context, '积分导出失败: $e');
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
              notifier.setScore(
                  classroom.uid, group.uid, member.uid, newScore);
            }
          }
        }
      }
      ToastOverlay.show(context, '积分导入成功');
    } catch (e) {
      ToastOverlay.show(context, '积分导入失败: $e');
    }
  }

  Future<void> _exportMemberTemplate() async {
    try {
      await ref.read(fileServiceProvider).exportMemberTemplate();
      ToastOverlay.show(context, '名单模板已导出到工作目录');
    } catch (e) {
      ToastOverlay.show(context, '模板导出失败: $e');
    }
  }

  Future<void> _exportQuestionTemplate() async {
    try {
      await ref.read(fileServiceProvider).exportQuestionTemplate();
      ToastOverlay.show(context, '题库模板已导出到工作目录');
    } catch (e) {
      ToastOverlay.show(context, '模板导出失败: $e');
    }
  }

  Future<void> _sync() async {
    showDialog(context: context, builder: (_) => const SyncProgressDialog());
    ref.read(syncProvider.notifier).startSync();
    await Future.delayed(const Duration(seconds: 2));
    ref.read(syncProvider.notifier).syncComplete();
    if (mounted) Navigator.pop(context);
    ToastOverlay.show(context, '同步完成');
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (_) => const SettingsDialog(),
    ).then((_) => _startAutoSave());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height && size.width >= 768;

    return Scaffold(
      body: Stack(
        children: [
          isLandscape ? _landscape() : _portrait(),
          Positioned(
            bottom: isLandscape ? 16 : 24,
            right: isLandscape ? 16 : 24,
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
          Positioned(
            top: 8,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AutoSaveIndicator(
                    isDirty: ref.watch(classProvider).isDirty),
                const SizedBox(height: 4),
                const SyncStatusIndicator(),
              ],
            ),
          ),
          // 左上角教材入口
          Positioned(
            top: 8,
            left: 16,
            child: _buildTextbookButton(),
          ),
        ],
      ),
    );
  }

  Widget _landscape() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
            child: Column(
              children: [
                const SizedBox(height: 36),
                const Expanded(child: DrawPanel()),
                const SizedBox(height: 4),
                const Expanded(child: TimerPanel()),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 12, 8),
            child: Column(
              children: [
                const SizedBox(height: 36),
                const Expanded(child: QuestionPanel()),
                const SizedBox(height: 4),
                const Expanded(child: LeaderboardPanel()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _portrait() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _card('抽取模块', Icons.casino, const DrawPanel()),
          const SizedBox(height: 12),
          _card('题库模块', Icons.quiz, const QuestionPanel()),
          const SizedBox(height: 12),
          _card('时钟 & 计时器', Icons.timer, const TimerPanel()),
          const SizedBox(height: 12),
          _card('排行榜', Icons.leaderboard, const LeaderboardPanel()),
          const SizedBox(height: 84),
        ],
      ),
    );
  }

  Widget _card(String title, IconData icon, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  /// 教材按钮 + 年级/学科切换 + 开源说明
  Widget _buildTextbookButton() {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 教材
        _chip(Icons.menu_book, '教材', theme.colorScheme.primaryContainer, theme.colorScheme.primary, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TextbookBrowserScreen()));
        }),
        const SizedBox(width: 6),
        // 年级快捷切换
        _gradeSubjectChip(settings),
        const SizedBox(width: 6),
        // 开源说明
        _chip(Icons.favorite, '开源', theme.colorScheme.errorContainer, theme.colorScheme.error, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OpenSourceScreen()));
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
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppSpacing.lg),
          boxShadow: [BoxShadow(color: fg.withOpacity(0.12), blurRadius: 4)]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: fg), const SizedBox(width: 5),
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
