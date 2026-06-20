import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_provider.dart';
import '../providers/question_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/settings_provider.dart';
import '../models/question_bank.dart';
import '../services/file_service.dart';
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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _at;

  @override
  void initState() { super.initState(); _startAutoSave(); }
  @override
  void dispose() { _at?.cancel(); super.dispose(); }

  void _startAutoSave() {
    final s = ref.read(settingsProvider);
    if (s.autoSave) { _at?.cancel(); _at = Timer.periodic(Duration(seconds: s.autoSaveInterval), (_) => _save(silent: true)); }
  }

  Future<void> _save({bool silent = false}) async {
    try {
      final cs = ref.read(classProvider); final qs = ref.read(questionProvider);
      if (!cs.isDirty && !qs.isDirty) return;
      final d = AppData(classrooms: cs.classrooms, questionBanks: qs.banks, lastModified: DateTime.now().toIso8601String());
      await ref.read(fileServiceProvider).saveJson(d);
      ref.read(classProvider.notifier).clearDirty(); ref.read(questionProvider.notifier).clearDirty();
      if (!silent) ToastOverlay.show(context, '保存成功');
    } catch (e) { if (!silent) ToastOverlay.show(context, '保存失败: $e'); }
  }

  Future<void> _load() async {
    try {
      final d = await ref.read(fileServiceProvider).pickAndLoadJson();
      if (d != null) {
        ref.read(classProvider.notifier).loadFromData(d.classrooms, d.classrooms.isNotEmpty ? d.classrooms.first.uid : null);
        ref.read(questionProvider.notifier).loadFromData(d.questionBanks);
        ToastOverlay.show(context, '加载成功');
      }
    } catch (e) { ToastOverlay.show(context, '加载失败: $e'); }
  }

  Future<void> _pickFolder() async {
    final p = await ref.read(fileServiceProvider).pickFolder();
    if (p != null) ToastOverlay.show(context, '已选择文件夹');
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
    showDialog(context: context, builder: (_) => const SettingsDialog()).then((_) => _startAutoSave());
  }

  @override
  Widget build(BuildContext ctx) {
    final sz = MediaQuery.of(ctx).size;
    final isLand = sz.width > sz.height && sz.width >= 768;
    return Scaffold(body: Stack(children: [
      isLand ? _land() : _port(),
      Positioned(bottom: 24, right: 24,
        child: CentralConsole(onSave: () => _save(), onLoad: _load, onPickFolder: _pickFolder,
            onSettings: _openSettings, onSync: _sync)),
      Positioned(top: 8, right: 16,
        child: Column(children: [
          AutoSaveIndicator(isDirty: ref.watch(classProvider).isDirty),
          const SizedBox(height: 4),
          const SyncStatusIndicator(),
        ])),
    ]));
  }

  Widget _land() => Padding(padding: const EdgeInsets.all(12), child: Column(children: [
    const SizedBox(height: 40),
    Expanded(child: Row(children: const [Expanded(child: DrawPanel()), Expanded(child: QuestionPanel())])),
    Expanded(child: Row(children: const [Expanded(child: TimerPanel()), Expanded(child: LeaderboardPanel())])),
    const SizedBox(height: 72),
  ]));

  Widget _port() => SingleChildScrollView(padding: const EdgeInsets.all(12), child: Column(children: [
    const SizedBox(height: 40),
    _sec('抽取模块', const DrawPanel()), const SizedBox(height: 12),
    _sec('题库模块', const QuestionPanel()), const SizedBox(height: 12),
    _sec('时钟 & 计时器', const TimerPanel()), const SizedBox(height: 12),
    _sec('排行榜', const LeaderboardPanel()), const SizedBox(height: 84),
  ]));

  Widget _sec(String t, Widget w) => Card(child: Padding(padding: const EdgeInsets.all(8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), w])));
}
