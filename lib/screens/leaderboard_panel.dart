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
    final classState = ref.watch(classProvider);
    final leaderboardState = ref.watch(leaderboardProvider);
    final classroom = classState.selectedClass;
    final theme = Theme.of(context);

    if (classroom == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, size: 32, color: theme.colorScheme.outline),
            const SizedBox(height: 8),
            Text(
              '请先在底部控制台选择班级',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    final members = List<Member>.from(classroom.allMembers)
      ..sort((a, b) => b.score.compareTo(a.score));
    final groups = List<Group>.from(classroom.groups)
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return Column(
      children: [
        // 榜单模式切换
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'member', label: Text('个人榜'), icon: Icon(Icons.person, size: 16)),
            ButtonSegment(value: 'group', label: Text('小组榜'), icon: Icon(Icons.groups, size: 16)),
          ],
          selected: {leaderboardState.showGroupBoard ? 'group' : 'member'},
          onSelectionChanged: (_) =>
              ref.read(leaderboardProvider.notifier).toggleBoard(),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(height: 8),
        // 榜单内容
        Expanded(
          child: leaderboardState.showGroupBoard
              ? _buildGroupTable(groups)
              : _buildMemberTable(context, members, classroom, ref),
        ),
        // 完整排行按钮
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

  Widget _buildMemberTable(
    BuildContext context,
    List<Member> members,
    Classroom classroom,
    WidgetRef ref,
  ) {
    final leaderboardState = ref.watch(leaderboardProvider);
    final theme = Theme.of(context);

    if (members.isEmpty) {
      return Center(
        child: Text('暂无成员数据', style: theme.textTheme.bodyMedium),
      );
    }

    // 只显示前 10 名以优化性能
    final topMembers = members.take(10).toList();

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
        rows: topMembers.map((member) {
          final rankIndex = members.indexOf(member) + 1;
          final isLocked = leaderboardState.lockedMemberUid == member.uid;

          // 排名颜色
          Color? rowColor;
          if (rankIndex == 1) {
            rowColor = Colors.yellow.shade100;
          } else if (rankIndex == 2) {
            rowColor = Colors.grey.shade200;
          } else if (rankIndex == 3) {
            rowColor = Colors.orange.shade100;
          }

          // 找到成员所在的小组
          Group? parentGroup;
          for (final g in classroom.groups) {
            if (g.members.any((m) => m.uid == member.uid)) {
              parentGroup = g;
              break;
            }
          }

          return DataRow(
            color: WidgetStateProperty.resolveWith(
              (_) => rowColor ?? Colors.transparent,
            ),
            cells: [
              DataCell(Text(
                '$rankIndex',
                style: TextStyle(
                  fontWeight: rankIndex <= 3 ? FontWeight.bold : null,
                ),
              )),
              DataCell(
                GestureDetector(
                  onTap: () =>
                      ref.read(leaderboardProvider.notifier).lockMember(member.uid),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          member.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.lock, size: 12, color: Colors.orange),
                      ],
                    ],
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(member.score.toStringAsFixed(1)),
                    const SizedBox(width: 4),
                    RankBadge(score: member.score),
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
                        if (parentGroup != null) {
                          ref.read(classProvider.notifier).changeScore(
                            classroom.uid,
                            parentGroup.uid,
                            member.uid,
                            1,
                          );
                          AudioEngine().playScoreUp();
                        }
                      },
                    ),
                    const SizedBox(width: 2),
                    ScoreButton(
                      label: '-1',
                      onTap: () {
                        if (parentGroup != null) {
                          ref.read(classProvider.notifier).changeScore(
                            classroom.uid,
                            parentGroup.uid,
                            member.uid,
                            -1,
                          );
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

  Widget _buildGroupTable(List<Group> groups) {
    final theme = Theme.of(context);

    if (groups.isEmpty) {
      return Center(
        child: Text('暂无小组数据', style: theme.textTheme.bodyMedium),
      );
    }

    final topGroups = groups.take(10).toList();

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
        rows: topGroups.map((group) {
          final rankIndex = groups.indexOf(group) + 1;
          return DataRow(
            cells: [
              DataCell(Text(
                '$rankIndex',
                style: TextStyle(
                  fontWeight: rankIndex <= 3 ? FontWeight.bold : null,
                ),
              )),
              DataCell(Text(group.name)),
              DataCell(Text(group.totalScore.toStringAsFixed(1))),
              DataCell(Text('${group.memberCount}')),
            ],
          );
        }).toList(),
      ),
    );
  }
}
