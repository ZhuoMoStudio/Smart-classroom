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

class LeaderboardPanel extends ConsumerWidget {
  const LeaderboardPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = ref.watch(classProvider);
    final ls = ref.watch(leaderboardProvider);
    final cls = cs.selectedClass;
    final t = Theme.of(context);

    if (cls == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, size: 32, color: t.colorScheme.outline),
            const SizedBox(height: 8),
            Text('请先选择班级',
                style: t.textTheme.bodyMedium
                    ?.copyWith(color: t.colorScheme.outline)),
          ],
        ),
      );
    }

    final ms = List<Member>.from(cls.allMembers)
      ..sort((a, b) => b.score.compareTo(a.score));
    final gs = List<Group>.from(cls.groups)
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return Column(
      children: [
        // 切换按钮 + 撤销 + 导出
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'member',
                        label: Text('个人榜'),
                        icon: Icon(Icons.person, size: 16)),
                    ButtonSegment(
                        value: 'group',
                        label: Text('小组榜'),
                        icon: Icon(Icons.groups, size: 16)),
                  ],
                  selected: {ls.showGroupBoard ? 'group' : 'member'},
                  onSelectionChanged: (_) => ref
                      .read(leaderboardProvider.notifier)
                      .toggleBoard(),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              // 撤销按钮
              if (cs.history.records.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.undo, size: 18),
                  tooltip: '撤销最近积分变动',
                  onPressed: () {
                    final record =
                        ref.read(classProvider.notifier).undoLastScoreChange();
                    if (record != null) {
                      ToastOverlay.show(
                          context,
                          '已撤销: ${record.memberName} ${record.delta > 0 ? "-" : "+"}${record.delta.abs().toStringAsFixed(1)}',
                          type: ToastType.info);
                    }
                  },
                  visualDensity: VisualDensity.compact,
                ),
              // 导出按钮
              IconButton(
                icon: const Icon(Icons.file_download, size: 18),
                tooltip: '导出积分报表',
                onPressed: () => _exportReport(context, ref),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // 最近变动记录
        if (cs.history.records.isNotEmpty)
          SizedBox(
            height: 26,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: min(cs.history.records.length, 10),
              itemBuilder: (_, i) {
                final r = cs.history.records[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: r.isPositive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${r.memberName} ${r.isPositive ? "+" : ""}${r.delta.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: r.isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 4),
        Expanded(
          child: ls.showGroupBoard
              ? _gTable(gs, context)
              : _mTable(ms, cls, ref, context),
        ),
        TextButton.icon(
          icon: const Icon(Icons.open_in_full, size: 16),
          label: const Text('完整排行'),
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const FullLeaderboardDialog(),
          ),
        ),
      ],
    );
  }

  Widget _mTable(
      List<Member> ms, Classroom cls, WidgetRef ref, BuildContext ctx) {
    final ls = ref.watch(leaderboardProvider);
    final t = Theme.of(ctx);
    if (ms.isEmpty) {
      return Center(
        child: Text('暂无成员数据', style: t.textTheme.bodyMedium),
      );
    }
    final top = ms.take(10).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 8,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 44,
          columns: const [
            DataColumn(label: Text('排名')),
            DataColumn(label: Text('姓名')),
            DataColumn(label: Text('积分')),
            DataColumn(label: Text('操作')),
          ],
          rows: top.map((m) {
            final ri = ms.indexOf(m) + 1;
            final lk = ls.lockedMemberUid == m.uid;
            Color? rc;
            if (ri == 1) {
              rc = Colors.yellow.shade100;
            } else if (ri == 2) {
              rc = Colors.grey.shade200;
            } else if (ri == 3) {
              rc = Colors.orange.shade100;
            }
            Group? pg;
            for (final g in cls.groups) {
              if (g.members.any((x) => x.uid == m.uid)) {
                pg = g;
                break;
              }
            }
            return DataRow(
              color: WidgetStateProperty.resolveWith(
                  (_) => rc ?? Colors.transparent),
              cells: [
                DataCell(Text('$ri',
                    style: TextStyle(
                        fontWeight:
                            ri <= 3 ? FontWeight.bold : null))),
                DataCell(GestureDetector(
                  onTap: () => ref
                      .read(leaderboardProvider.notifier)
                      .lockMember(m.uid),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(m.name,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (lk) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.lock,
                            size: 12, color: Colors.orange),
                      ],
                    ],
                  ),
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(m.score.toStringAsFixed(1)),
                    const SizedBox(width: 4),
                    RankBadge(score: m.score),
                  ],
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScoreButton(
                        label: '+1',
                        onTap: () {
                          if (pg != null) {
                            ref
                                .read(classProvider.notifier)
                                .changeScore(
                                    cls.uid, pg.uid, m.uid, 1);
                            AudioEngine().playScoreUp();
                          }
                        }),
                    const SizedBox(width: 2),
                    ScoreButton(
                        label: '-1',
                        onTap: () {
                          if (pg != null) {
                            ref
                                .read(classProvider.notifier)
                                .changeScore(
                                    cls.uid, pg.uid, m.uid, -1);
                            AudioEngine().playScoreDown();
                          }
                        }),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _gTable(List<Group> gs, BuildContext ctx) {
    final t = Theme.of(ctx);
    if (gs.isEmpty) {
      return Center(
        child: Text('暂无小组数据', style: t.textTheme.bodyMedium),
      );
    }
    final top = gs.take(10).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 8,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 44,
          columns: const [
            DataColumn(label: Text('排名')),
            DataColumn(label: Text('小组')),
            DataColumn(label: Text('总分')),
            DataColumn(label: Text('人数')),
          ],
          rows: top.map((g) {
            final ri = gs.indexOf(g) + 1;
            return DataRow(cells: [
              DataCell(Text('$ri',
                  style: TextStyle(
                      fontWeight:
                          ri <= 3 ? FontWeight.bold : null))),
              DataCell(Text(g.name)),
              DataCell(Text(g.totalScore.toStringAsFixed(1))),
              DataCell(Text('${g.memberCount}')),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

/// 导出积分报表
Future<void> _exportReport(
    BuildContext context, WidgetRef ref) async {
  try {
    final cs = ref.read(classProvider);
    if (cs.classrooms.isEmpty) {
      ToastOverlay.show(context, '没有可导出的班级数据');
      return;
    }

    final tempDir =
        '${(await getApplicationDocumentsDirectory()).path}/灵动课堂';
    await Directory(tempDir).create(recursive: true);
    final now = DateTime.now();
    final ts =
        '${now.year}-${_p(now.month)}-${_p(now.day)}_${_p(now.hour)}${_p(now.minute)}';
    final tempPath = '$tempDir/积分报表_$ts.xlsx';

    await ExcelService.exportFullReport(cs.classrooms, tempPath);

    // Android 尝试保存到 Downloads
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        final destPath = '${downloadsDir.path}/积分报表_$ts.xlsx';
        await File(tempPath).copy(destPath);
        ToastOverlay.show(context, '报表已保存到 Downloads 文件夹',
            type: ToastType.success);
        return;
      }
    } catch (_) {}

    ToastOverlay.show(context, '报表已生成', type: ToastType.success);
  } catch (e) {
    ToastOverlay.show(context, '导出失败: $e', type: ToastType.error);
  }
}

String _p(int n) => n.toString().padLeft(2, '0');
