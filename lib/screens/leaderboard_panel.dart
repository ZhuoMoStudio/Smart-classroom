import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../models/class_model.dart';
import '../theme/responsive.dart';
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
    final teaching = context.isTeachingLayout;

    if (cls == null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.school, size: teaching ? 80 : 32, color: t.colorScheme.outline),
        SizedBox(height: teaching ? 16 : 8),
        Text('请先选择班级', style: t.textTheme.bodyMedium?.copyWith(fontSize: teaching ? 32 : null, color: t.colorScheme.outline)),
      ]));
    }
    final ms = List<Member>.from(cls.allMembers)..sort((a, b) => b.score.compareTo(a.score));
    final gs = List<Group>.from(cls.groups)..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return Column(children: [
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'member', label: Text('个人榜'), icon: Icon(Icons.person, size: 16)),
          ButtonSegment(value: 'group', label: Text('小组榜'), icon: Icon(Icons.groups, size: 16)),
        ],
        selected: {ls.showGroupBoard ? 'group' : 'member'},
        onSelectionChanged: (_) => ref.read(leaderboardProvider.notifier).toggleBoard(),
        style: teaching ? ButtonStyle(
          visualDensity: VisualDensity.standard,
          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 28)),
          iconSize: WidgetStateProperty.all(36.0),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
        ) : ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      SizedBox(height: teaching ? 16 : 8),
      Expanded(child: ls.showGroupBoard ? _gTable(gs, context, teaching) : _mTable(ms, cls, ref, context, teaching)),
      TextButton.icon(
        icon: Icon(Icons.open_in_full, size: teaching ? 32 : 16),
        label: Text('完整排行', style: TextStyle(fontSize: teaching ? 24 : null)),
        onPressed: () => showDialog(context: context, builder: (_) => const FullLeaderboardDialog()),
      ),
    ]);
  }

  Widget _mTable(List<Member> ms, Classroom cls, WidgetRef ref, BuildContext ctx, bool teaching) {
    final ls = ref.watch(leaderboardProvider);
    final t = Theme.of(ctx);
    if (ms.isEmpty) return Center(child: Text('暂无成员数据', style: t.textTheme.bodyMedium?.copyWith(fontSize: teaching ? 32 : null)));
    final top = ms.take(10).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Scrollbar(
        thumbVisibility: teaching,
        thickness: teaching ? AppScrollbar.teachingThickness : null,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: teaching ? 32 : 8,
            dataRowMinHeight: teaching ? 80 : 36,
            dataRowMaxHeight: teaching ? 100 : 44,
            headingTextStyle: TextStyle(fontSize: teaching ? 28 : null, fontWeight: FontWeight.bold),
            dataTextStyle: TextStyle(fontSize: teaching ? 26 : null),
            columns: const [DataColumn(label: Text('排名')), DataColumn(label: Text('姓名')), DataColumn(label: Text('积分')), DataColumn(label: Text('操作'))],
            rows: top.map((m) {
              final ri = ms.indexOf(m) + 1;
              final lk = ls.lockedMemberUid == m.uid;
              Color? rc;
              if (ri == 1) rc = Colors.yellow.shade100;
              else if (ri == 2) rc = Colors.grey.shade200;
              else if (ri == 3) rc = Colors.orange.shade100;
              Group? pg;
              for (final g in cls.groups) { if (g.members.any((x) => x.uid == m.uid)) { pg = g; break; } }
              return DataRow(color: WidgetStateProperty.resolveWith((_) => rc ?? Colors.transparent), cells: [
                DataCell(Text('$ri', style: TextStyle(fontWeight: ri <= 3 ? FontWeight.bold : null, fontSize: teaching ? 28 : null))),
                DataCell(GestureDetector(
                  onTap: () => ref.read(leaderboardProvider.notifier).lockMember(m.uid),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(child: Text(m.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: teaching ? 28 : null))),
                    if (lk) ...[SizedBox(width: teaching ? 8 : 4), Icon(Icons.lock, size: teaching ? 28 : 12, color: Colors.orange)],
                  ]),
                )),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(m.score.toStringAsFixed(1), style: TextStyle(fontSize: teaching ? 28 : null)),
                  SizedBox(width: teaching ? 8 : 4),
                  RankBadge(score: m.score, teaching: teaching),
                ])),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  ScoreButton(label: '+1', onTap: () { if (pg != null) { ref.read(classProvider.notifier).changeScore(cls.uid, pg.uid, m.uid, 1); AudioEngine().playScoreUp(); } }, teaching: teaching),
                  SizedBox(width: teaching ? 8 : 2),
                  ScoreButton(label: '-1', onTap: () { if (pg != null) { ref.read(classProvider.notifier).changeScore(cls.uid, pg.uid, m.uid, -1); AudioEngine().playScoreDown(); } }, teaching: teaching),
                ])),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _gTable(List<Group> gs, BuildContext ctx, bool teaching) {
    final t = Theme.of(ctx);
    if (gs.isEmpty) return Center(child: Text('暂无小组数据', style: t.textTheme.bodyMedium?.copyWith(fontSize: teaching ? 32 : null)));
    final top = gs.take(10).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Scrollbar(
        thumbVisibility: teaching,
        thickness: teaching ? AppScrollbar.teachingThickness : null,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: teaching ? 32 : 8,
            dataRowMinHeight: teaching ? 80 : 36,
            dataRowMaxHeight: teaching ? 100 : 44,
            headingTextStyle: TextStyle(fontSize: teaching ? 28 : null, fontWeight: FontWeight.bold),
            dataTextStyle: TextStyle(fontSize: teaching ? 26 : null),
            columns: const [DataColumn(label: Text('排名')), DataColumn(label: Text('小组')), DataColumn(label: Text('总分')), DataColumn(label: Text('人数'))],
            rows: top.map((g) {
              final ri = gs.indexOf(g) + 1;
              return DataRow(cells: [
                DataCell(Text('$ri', style: TextStyle(fontWeight: ri <= 3 ? FontWeight.bold : null, fontSize: teaching ? 28 : null))),
                DataCell(Text(g.name, style: TextStyle(fontSize: teaching ? 28 : null))),
                DataCell(Text(g.totalScore.toStringAsFixed(1), style: TextStyle(fontSize: teaching ? 28 : null))),
                DataCell(Text('${g.memberCount}', style: TextStyle(fontSize: teaching ? 28 : null))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
