import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../models/class_model.dart';
import '../widgets/rank_badge.dart';
import '../widgets/score_button.dart';
import 'dialogs/full_leaderboard_dialog.dart';

class LeaderboardPanel extends ConsumerWidget {
  const LeaderboardPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classState = ref.watch(classProvider);
    final lbState = ref.watch(leaderboardProvider);
    final cls = classState.selectedClass;
    final theme = Theme.of(context);

    if (cls == null) return const Center(child: Text('请先选择班级'));

    final members = List<Member>.from(cls.allMembers)..sort((a, b) => b.score.compareTo(a.score));
    final groups = List<Group>.from(cls.groups)..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return Column(children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        ChoiceChip(label: const Text('个人榜'), selected: !lbState.showGroupBoard,
            onSelected: (_) => ref.read(leaderboardProvider.notifier).toggleBoard()),
        const SizedBox(width: 8),
        ChoiceChip(label: const Text('小组榜'), selected: lbState.showGroupBoard,
            onSelected: (_) => ref.read(leaderboardProvider.notifier).toggleBoard()),
      ]),
      const SizedBox(height: 8),
      Expanded(child: lbState.showGroupBoard ? _groupTable(groups) : _memberTable(context, members, cls, ref)),
      TextButton(onPressed: () => showDialog(context: context, builder: (_) => const FullLeaderboardDialog()),
          child: const Text('完整排行')),
    ]);
  }

  Widget _memberTable(BuildContext context, List<Member> members, Classroom cls, WidgetRef ref) {
    final lbState = ref.watch(leaderboardProvider);
    return SingleChildScrollView(child: DataTable(columnSpacing: 8, columns: const [
      DataColumn(label: Text('排名')), DataColumn(label: Text('姓名')), DataColumn(label: Text('积分')), DataColumn(label: Text('操作')),
    ], rows: members.take(10).map((m) {
      final idx = members.indexOf(m) + 1;
      final isLocked = lbState.lockedMemberUid == m.uid;
      Color? bg;
      if (idx == 1) bg = Colors.yellow.shade100;
      else if (idx == 2) bg = Colors.grey.shade200;
      else if (idx == 3) bg = Colors.orange.shade100;
      Group? parentGroup;
      for (final g in cls.groups) {
        if (g.members.any((x) => x.uid == m.uid)) { parentGroup = g; break; }
      }
      return DataRow(color: WidgetStateProperty.resolveWith((_) => bg ?? Colors.transparent), cells: [
        DataCell(Text('$idx')),
        DataCell(GestureDetector(
          onTap: () => ref.read(leaderboardProvider.notifier).lockMember(m.uid),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Text(m.name), if (isLocked) const Icon(Icons.lock, size: 12)]),
        )),
        DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
          Text(m.score.toStringAsFixed(1)), const SizedBox(width: 4), RankBadge(score: m.score),
        ])),
        DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
          ScoreButton(label: '+1', onTap: () { if (parentGroup != null) ref.read(classProvider.notifier).changeScore(cls.uid, parentGroup.uid, m.uid, 1); }),
          ScoreButton(label: '-1', onTap: () { if (parentGroup != null) ref.read(classProvider.notifier).changeScore(cls.uid, parentGroup.uid, m.uid, -1); }),
        ])),
      ]);
    }).toList()));
  }

  Widget _groupTable(List<Group> groups) => SingleChildScrollView(child: DataTable(columns: const [
    DataColumn(label: Text('排名')), DataColumn(label: Text('小组')), DataColumn(label: Text('总分')), DataColumn(label: Text('人数')),
  ], rows: groups.take(10).map((g) {
    final idx = groups.indexOf(g) + 1;
    return DataRow(cells: [
      DataCell(Text('$idx')), DataCell(Text(g.name)),
      DataCell(Text(g.totalScore.toStringAsFixed(1))), DataCell(Text('${g.memberCount}')),
    ]);
  }).toList()));
}