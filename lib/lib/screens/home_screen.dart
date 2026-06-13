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
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _startAutoSave();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
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
      final classState = ref.read(classProvider);
      final questionState = ref.read(questionProvider);
      if (!classState.isDirty && !questionState.isDirty) return;
      final data = AppData(classrooms: classState.classrooms, questionBanks: questionState.banks,
          lastModified: DateTime.now().toIso8601String());
      final fileService = ref.read(fileServiceProvider);
      await fileService.saveJson(data);
      ref.read(classProvider.notifier).clearDirty();
      ref.read(questionProvider.notifier).clearDirty();
      if (!silent) ToastOverlay.show(context, '保存成功');
    } catch (e) {
      if (!silent) ToastOverlay.show(context, '保存失败: $e');
    }
  }

  Future<void> _load() async {
    try {
      final fileService = ref.read(fileServiceProvider);
      final data = await fileService.pickAndLoadJson();
      if (data != null) {
        ref.read(classProvider.notifier).loadFromData(
            data.classrooms, data.classrooms.isNotEmpty ? data.classrooms.first.uid : null);
        ref.read(questionProvider.notifier).loadFromData(data.questionBanks);
        ToastOverlay.show(context, '加载成功');
      }
    } catch (e) {
      ToastOverlay.show(context, '加载失败: $e');
    }
  }

  Future<void> _pickFolder() async {
    final fileService = ref.read(fileServiceProvider);
    final path = await fileService.pickFolder();
    if (path != null) ToastOverlay.show(context, '已选择文件夹');
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
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height && size.width >= 768;
    return Scaffold(
      body: Stack(children: [
        isLandscape ? _buildLandscape() : _buildPortrait(),
        Positioned(bottom: 24, right: 24, child: CentralConsole(
          onSave: () => _save(), onLoad: _load, onPickFolder: _pickFolder, onSettings: _openSettings, onSync: _sync,
        )),
        Positioned(top: 8, right: 16, child: Column(children: [
          AutoSaveIndicator(isDirty: ref.watch(classProvider).isDirty),
          const SizedBox(height: 4),
          const SyncStatusIndicator(),
        ])),
      ]),
    );
  }

  Widget _buildLandscape() => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          const SizedBox(height: 40),
          Expanded(child: Row(children: const [
            Expanded(child: DrawPanel()), Expanded(child: QuestionPanel()),
          ])),
          Expanded(child: Row(children: const [
            Expanded(child: TimerPanel()), Expanded(child: LeaderboardPanel()),
          ])),
          const SizedBox(height: 72),
        ]),
      );

  Widget _buildPortrait() => SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          const SizedBox(height: 40),
          _section('抽取模块', const DrawPanel()),
          const SizedBox(height: 12),
          _section('题库模块', const QuestionPanel()),
          const SizedBox(height: 12),
          _section('时钟 & 计时器', const TimerPanel()),
          const SizedBox(height: 12),
          _section('排行榜', const LeaderboardPanel()),
          const SizedBox(height: 84),
        ]),
      );

  Widget _section(String title, Widget child) => Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ]),
        ),
      );
}