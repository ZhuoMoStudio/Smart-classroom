import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../models/class_model.dart';
import '../widgets/rank_badge.dart';
import '../widgets/score_button.dart';
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
    if (cls == null)
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, size: 32, color: t.colorScheme.outline),
            const SizedBox(height: 8),
            Text(
              '请先在底部控制台选择班级',
              style: t.textTheme.bodyMedium?.copyWith(
                color: t.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    final ms = List<Member>.from(cls.allMembers)
      ..sort((a, b) => b.score.compareTo(a.score));
    final gs = List<Group>.from(cls.groups)
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return Column(
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'member',
              label: Text('个人榜'),
              icon: Icon(Icons.person, size: 16),
            ),
            ButtonSegment(
              value: 'group',
              label: Text('小组榜'),
              icon: Icon(Icons.groups, size: 16),
            ),
          ],
          selected: {ls.showGroupBoard ? 'group' : 'member'},
          onSelectionChanged:
              (_) => ref.read(leaderboardProvider.notifier).toggleBoard(),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child:
              ls.showGroupBoard
                  ? _gTable(gs, context)
                  : _mTable(ms, cls, ref, context),
        ),
        TextButton.icon(
          icon: const Icon(Icons.open_in_full, size: 16),
          label: const Text('完整排行'),
          onPressed:
              () => showDialog(
                context: context,
                builder: (_) => const FullLeaderboardDialog(),
              ),
        ),
      ],
    );
  }

  Widget _mTable(
    List<Member> ms,
    Classroom cls,
    WidgetRef ref,
    BuildContext ctx,
  ) {
    final ls = ref.watch(leaderboardProvider);
    final t = Theme.of(ctx);
    if (ms.isEmpty)
      return Center(child: Text('暂无成员数据', style: t.textTheme.bodyMedium));
    final top = ms.take(10).toList();
    return SingleChildScrollView(
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
        rows:
            top.map((m) {
              final ri = ms.indexOf(m) + 1;
              final lk = ls.lockedMemberUid == m.uid;
              Color? rc;
              if (ri == 1)
                rc = Colors.yellow.shade100;
              else if (ri == 2)
                rc = Colors.grey.shade200;
              else if (ri == 3)
                rc = Colors.orange.shade100;
              Group? pg;
              for (final g in cls.groups) {
                if (g.members.any((x) => x.uid == m.uid)) {
                  pg = g;
                  break;
                }
              }
              return DataRow(
                color: WidgetStateProperty.resolveWith(
                  (_) => rc ?? Colors.transparent,
                ),
                cells: [
                  DataCell(
                    Text(
                      '$ri',
                      style: TextStyle(
                        fontWeight: ri <= 3 ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                  DataCell(
                    GestureDetector(
                      onTap:
                          () => ref
                              .read(leaderboardProvider.notifier)
                              .lockMember(m.uid),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              m.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lk) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.lock,
                              size: 12,
                              color: Colors.orange,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(m.score.toStringAsFixed(1)),
                        const SizedBox(width: 4),
                        RankBadge(score: m.score),
                      ],
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScoreButton(
                          label: '+1',
                          onTap: () {
                            if (pg != null) {
                              ref
                                  .read(classProvider.notifier)
                                  .changeScore(cls.uid, pg.uid, m.uid, 1);
                              AudioEngine().playScoreUp();
                            }
                          },
                        ),
                        const SizedBox(width: 2),
                        ScoreButton(
                          label: '-1',
                          onTap: () {
                            if (pg != null) {
                              ref
                                  .read(classProvider.notifier)
                                  .changeScore(cls.uid, pg.uid, m.uid, -1);
                              AudioEngine().playScoreDown();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _gTable(List<Group> gs, BuildContext ctx) {
    final t = Theme.of(ctx);
    if (gs.isEmpty)
      return Center(child: Text('暂无小组数据', style: t.textTheme.bodyMedium));
    final top = gs.take(10).toList();
    return SingleChildScrollView(
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
        rows:
            top.map((g) {
              final ri = gs.indexOf(g) + 1;
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      '$ri',
                      style: TextStyle(
                        fontWeight: ri <= 3 ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                  DataCell(Text(g.name)),
                  DataCell(Text(g.totalScore.toStringAsFixed(1))),
                  DataCell(Text('${g.memberCount}')),
                ],
              );
            }).toList(),
      ),
    );
  }
}
