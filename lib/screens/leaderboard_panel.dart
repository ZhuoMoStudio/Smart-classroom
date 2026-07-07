import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/class_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../models/class_model.dart';
import '../models/score_history.dart';
import '../services/excel_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/rank_badge.dart';
import '../widgets/score_button.dart';
import '../widgets/toast_overlay.dart';
import '../services/audio_engine.dart';
import 'dialogs/full_leaderboard_dialog.dart';

class LeaderboardPanel extends ConsumerStatefulWidget {
  const LeaderboardPanel({super.key});
  @override
  ConsumerState<LeaderboardPanel> createState() => _LeaderboardPanelState();
}

class _LeaderboardPanelState extends ConsumerState<LeaderboardPanel> {
  bool _batchMode = false;
  final Set<String> _selected = {};

  void _toggleBatch() {
    setState(() { _batchMode = !_batchMode; _selected.clear(); });
  }

  void _batchScore(double delta) {
    final cs = ref.read(classProvider);
    final cls = cs.selectedClass;
    if (cls == null || _selected.isEmpty) return;
    ref.read(classProvider.notifier).batchChangeScore(cls.uid, _selected.toList(), delta);
    if (delta > 0) AudioEngine().playScoreUp(); else AudioEngine().playScoreDown();
    setState(() => _selected.clear());
    ToastOverlay.show(context, '已批量${delta > 0 ? "加" : "减"}分: ${_selected.length} 人');
  }

  void _resetConfirm() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('清零确认'),
      content: const Text('确定要清零当前班级所有学生的积分吗？此操作不可恢复。'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { ref.read(classProvider.notifier).resetAllScores(); Navigator.pop(ctx); ToastOverlay.show(context, '已清零', type: ToastType.warning); },
            child: const Text('确认清零')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = ref.watch(classProvider);
    final ls = ref.watch(leaderboardProvider);
    final cls = cs.selectedClass;
    final t = Theme.of(context);

    if (cls == null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.school, size: 32, color: t.colorScheme.outline), const SizedBox(height: 8),
        Text('请先选择班级', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.outline)),
      ]));
    }

    final ms = List<Member>.from(cls.allMembers)..sort((a, b) => b.score.compareTo(a.score));
    final gs = List<Group>.from(cls.groups)..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return Column(children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Row(children: [
        Expanded(child: SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'member', label: Text('个人榜'), icon: Icon(Icons.person, size: 16)),
            ButtonSegment(value: 'group', label: Text('小组榜'), icon: Icon(Icons.groups, size: 16)),
          ],
          selected: {ls.showGroupBoard ? 'group' : 'member'},
          onSelectionChanged: (_) => ref.read(leaderboardProvider.notifier).toggleBoard(),
          style: const ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        )),
        // 撤销
        if (cs.history.records.isNotEmpty)
          IconButton(icon: const Icon(Icons.undo, size: 17), tooltip: '撤销',
              onPressed: () { final r = ref.read(classProvider.notifier).undoLastScoreChange();
                if (r != null) ToastOverlay.show(context, '已撤销: ${r.memberName}', type: ToastType.info); },
              visualDensity: VisualDensity.compact),
        // 批量模式
        IconButton(
          icon: Icon(_batchMode ? Icons.checklist : Icons.playlist_add_check, size: 17,
              color: _batchMode ? AppColors.brandPrimary : null),
          tooltip: _batchMode ? '退出批量' : '批量加减分',
          onPressed: _toggleBatch, visualDensity: VisualDensity.compact),
        // 清零
        IconButton(icon: const Icon(Icons.restart_alt, size: 17), tooltip: '清零积分',
            onPressed: _resetConfirm, visualDensity: VisualDensity.compact),
        // 导出
        IconButton(icon: const Icon(Icons.file_download, size: 17), tooltip: '导出报表',
            onPressed: () => _exportReport(context, ref), visualDensity: VisualDensity.compact),
      ])),
      // 批量操作栏
      if (_batchMode && _selected.isNotEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: AppColors.brandPrimary.withOpacity(0.08),
          child: Row(children: [
            Text('已选 ${_selected.length} 人', style: const TextStyle(fontSize: 12)),
            const Spacer(),
            _batchBtn('+1', 1), const SizedBox(width: 4),
            _batchBtn('-1', -1), const SizedBox(width: 4),
            TextButton(onPressed: () => setState(() => _selected.clear()), child: const Text('取消', style: TextStyle(fontSize: 11))),
          ]),
        ),
      // 历史
      if (cs.history.records.isNotEmpty)
        SizedBox(height: 22, child: ListView.builder(scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6), itemCount: min(cs.history.records.length, 10),
            itemBuilder: (_, i) {
              final r = cs.history.records[i];
              return Padding(padding: const EdgeInsets.only(right: 4), child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: (r.isPositive ? Colors.green : Colors.red).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text('${r.memberName} ${r.isPositive ? "+" : ""}${r.delta.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 10, color: r.isPositive ? Colors.green : Colors.red)),
              ));
            })),
      Expanded(child: ls.showGroupBoard ? _gTable(gs) : _mTable(ms, cls)),
      TextButton.icon(icon: const Icon(Icons.open_in_full, size: 16), label: const Text('完整排行'),
          onPressed: () => showDialog(context: context, builder: (_) => const FullLeaderboardDialog())),
    ]);
  }

  Widget _batchBtn(String label, double delta) => GestureDetector(
    onTap: () => _batchScore(delta),
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: delta > 0 ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
            color: delta > 0 ? Colors.green.shade700 : Colors.red.shade700))),
  );

  Widget _mTable(List<Member> ms, Classroom cls) {
    final ls = ref.watch(leaderboardProvider); final t = Theme.of(context);
    if (ms.isEmpty) return Center(child: Text('暂无成员数据', style: t.textTheme.bodyMedium));
    final top = ms.take(10).toList();
    return SingleChildScrollView(scrollDirection: Axis.vertical, child: SingleChildScrollView(scrollDirection: Axis.horizontal,
      child: DataTable(columnSpacing: 6, dataRowMinHeight: 34, dataRowMaxHeight: 42,
        columns: const [
          DataColumn(label: Text('排名')), DataColumn(label: Text('姓名')),
          DataColumn(label: Text('积分')), DataColumn(label: Text('操作')),
        ],
        rows: top.map((m) {
          final ri = ms.indexOf(m) + 1; final lk = ls.lockedMemberUid == m.uid;
          final sel = _batchMode && _selected.contains(m.uid);
          Color? rc; if (ri == 1) rc = Colors.yellow.shade100; else if (ri == 2) rc = Colors.grey.shade200; else if (ri == 3) rc = Colors.orange.shade100;
          Group? pg; for (final g in cls.groups) { if (g.members.any((x) => x.uid == m.uid)) { pg = g; break; } }
          return DataRow(color: WidgetStateProperty.resolveWith((_) => sel ? AppColors.brandPrimary.withOpacity(0.12) : (rc ?? Colors.transparent)),
              cells: [
                DataCell(Text('$ri', style: TextStyle(fontWeight: ri <= 3 ? FontWeight.bold : null))),
                DataCell(GestureDetector(
                  onTap: () {
                    if (_batchMode) { setState(() { if (_selected.contains(m.uid)) _selected.remove(m.uid); else _selected.add(m.uid); }); }
                    else ref.read(leaderboardProvider.notifier).lockMember(m.uid);
                  },
                  onLongPress: () { setState(() { _batchMode = true; _selected.add(m.uid); }); },
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (_batchMode) Icon(_selected.contains(m.uid) ? Icons.check_box : Icons.check_box_outline_blank, size: 14, color: AppColors.brandPrimary),
                    if (_batchMode) const SizedBox(width: 4),
                    Flexible(child: Text(m.name, overflow: TextOverflow.ellipsis)),
                    if (lk && !_batchMode) ...[const SizedBox(width: 4), const Icon(Icons.lock, size: 12, color: Colors.orange)],
                  ]),
                )),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(m.score.toStringAsFixed(1)), const SizedBox(width: 4), RankBadge(score: m.score),
                ])),
                DataCell(_batchMode ? const SizedBox() : Row(mainAxisSize: MainAxisSize.min, children: [
                  ScoreButton(label: '+1', onTap: () { if (pg != null) { ref.read(classProvider.notifier).changeScore(cls.uid, pg.uid, m.uid, 1); AudioEngine().playScoreUp(); } }),
                  const SizedBox(width: 2),
                  ScoreButton(label: '-1', onTap: () { if (pg != null) { ref.read(classProvider.notifier).changeScore(cls.uid, pg.uid, m.uid, -1); AudioEngine().playScoreDown(); } }),
                ])),
              ]);
        }).toList(),
      ),
    ));
  }

  Widget _gTable(List<Group> gs) {
    final t = Theme.of(context);
    if (gs.isEmpty) return Center(child: Text('暂无小组数据', style: t.textTheme.bodyMedium));
    final top = gs.take(10).toList();
    return SingleChildScrollView(scrollDirection: Axis.vertical, child: SingleChildScrollView(scrollDirection: Axis.horizontal,
      child: DataTable(columnSpacing: 6, dataRowMinHeight: 34, dataRowMaxHeight: 42,
        columns: const [DataColumn(label: Text('排名')), DataColumn(label: Text('小组')), DataColumn(label: Text('总分')), DataColumn(label: Text('人数'))],
        rows: top.map((g) {
          final ri = gs.indexOf(g) + 1;
          return DataRow(cells: [
            DataCell(Text('$ri', style: TextStyle(fontWeight: ri <= 3 ? FontWeight.bold : null))),
            DataCell(Text(g.name)), DataCell(Text(g.totalScore.toStringAsFixed(1))), DataCell(Text('${g.memberCount}')),
          ]);
        }).toList(),
      ),
    ));
  }
}

Future<void> _exportReport(BuildContext context, WidgetRef ref) async {
  try {
    final cs = ref.read(classProvider);
    if (cs.classrooms.isEmpty) { ToastOverlay.show(context, '没有可导出的班级数据'); return; }
    final tempDir = '${(await getApplicationDocumentsDirectory()).path}/灵动课堂';
    await Directory(tempDir).create(recursive: true);
    final now = DateTime.now();
    final ts = '${now.year}-${_p(now.month)}-${_p(now.day)}_${_p(now.hour)}${_p(now.minute)}';
    final tempPath = '$tempDir/积分报表_$ts.xlsx';
    await ExcelService.exportFullReport(cs.classrooms, tempPath);
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) { await File(tempPath).copy('${downloadsDir.path}/积分报表_$ts.xlsx'); ToastOverlay.show(context, '报表已保存到 Downloads', type: ToastType.success); return; }
    } catch (_) {}
    ToastOverlay.show(context, '报表已生成', type: ToastType.success);
  } catch (e) { ToastOverlay.show(context, '导出失败: $e', type: ToastType.error); }
}

String _p(int n) => n.toString().padLeft(2, '0');
