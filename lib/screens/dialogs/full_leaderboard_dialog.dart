import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/class_provider.dart';
import '../../widgets/rank_badge.dart';
import '../../widgets/score_button.dart';
import '../../models/class_model.dart';
import '../../services/audio_engine.dart';

class FullLeaderboardDialog extends ConsumerStatefulWidget {
  const FullLeaderboardDialog({super.key});

  @override
  ConsumerState<FullLeaderboardDialog> createState() =>
      _FullLeaderboardDialogState();
}

class _FullLeaderboardDialogState extends ConsumerState<FullLeaderboardDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);
    final classroom = classState.selectedClass;

    if (classroom == null) {
      return AlertDialog(
        title: const Text('班级管理'),
        content: const Text('请先在底部控制台选择一个班级'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.school, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${classroom.name} - 班级管理',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        height: 550,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '排行榜', icon: Icon(Icons.leaderboard, size: 18)),
                Tab(text: '成员管理', icon: Icon(Icons.people, size: 18)),
                Tab(text: '小组管理', icon: Icon(Icons.groups, size: 18)),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRankTab(classroom),
                  _buildMemberTab(classroom),
                  _buildGroupTab(classroom),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  // ===================== 排行榜 Tab =====================
  Widget _buildRankTab(Classroom classroom) {
    final members = List<Member>.from(classroom.allMembers)
      ..sort((a, b) => b.score.compareTo(a.score));

    if (members.isEmpty) {
      return const Center(child: Text('暂无成员数据'));
    }

    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final rank = index + 1;

        // 找到成员所在小组
        String? groupName;
        for (final g in classroom.groups) {
          if (g.members.any((m) => m.uid == member.uid)) {
            groupName = g.name;
            break;
          }
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _rankColor(rank),
              foregroundColor: Colors.white,
              child: Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text(member.name),
            subtitle: groupName != null ? Text('小组: $groupName') : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${member.score.toStringAsFixed(1)} 分',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                RankBadge(score: member.score),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade700;
      case 2:
        return Colors.blueGrey.shade400;
      case 3:
        return Colors.brown.shade400;
      default:
        return Colors.grey;
    }
  }

  // ===================== 成员管理 Tab =====================
  Widget _buildMemberTab(Classroom classroom) {
    return Column(
      children: [
        _AddMemberForm(classroom: classroom),
        const Divider(),
        Expanded(
          child: classroom.groups.isEmpty
              ? const Center(child: Text('暂无小组，请先创建小组'))
              : ListView(
                  children: classroom.groups
                      .expand((group) => [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.group,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    group.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 16, color: Colors.red),
                                    tooltip: '删除小组',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      _confirmDelete(context, '小组「${group.name}」',
                                          () {
                                        ref
                                            .read(classProvider.notifier)
                                            .deleteGroup(
                                                classroom.uid, group.uid);
                                        AudioEngine().playDeleteMember();
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${group.memberCount} 人 | ${group.totalScore.toStringAsFixed(1)} 分',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            ...group.members.map((member) => ListTile(
                                  dense: true,
                                  title: Text(member.name),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      RankBadge(score: member.score),
                                      const SizedBox(width: 4),
                                      ScoreButton(
                                        label: '+1',
                                        onTap: () {
                                          ref
                                              .read(classProvider.notifier)
                                              .changeScore(classroom.uid,
                                                  group.uid, member.uid, 1);
                                          AudioEngine().playScoreUp();
                                        },
                                      ),
                                      const SizedBox(width: 2),
                                      ScoreButton(
                                        label: '-1',
                                        onTap: () {
                                          ref
                                              .read(classProvider.notifier)
                                              .changeScore(classroom.uid,
                                                  group.uid, member.uid, -1);
                                          AudioEngine().playScoreDown();
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            size: 14, color: Colors.red),
                                        tooltip: '删除成员',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          _confirmDelete(context,
                                              '成员「${member.name}」', () {
                                            ref
                                                .read(classProvider.notifier)
                                                .deleteMember(classroom.uid,
                                                    group.uid, member.uid);
                                            AudioEngine().playDeleteMember();
                                          });
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                )),
                          ])
                      .toList(),
                ),
        ),
      ],
    );
  }

  // ===================== 小组管理 Tab =====================
  Widget _buildGroupTab(Classroom classroom) {
    final groups = List<Group>.from(classroom.groups)
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return Column(
      children: [
        _AddGroupForm(classroom: classroom),
        const Divider(),
        Expanded(
          child: groups.isEmpty
              ? const Center(child: Text('暂无小组，请点击上方添加'))
              : ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final rank = index + 1;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _rankColor(rank),
                          foregroundColor: Colors.white,
                          child: Text('$rank',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(group.name),
                        subtitle: Text(
                            '人数: ${group.memberCount} | 总分: ${group.totalScore.toStringAsFixed(1)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red, size: 18),
                          tooltip: '删除小组',
                          onPressed: () {
                            _confirmDelete(context, '小组「${group.name}」', () {
                              ref.read(classProvider.notifier).deleteGroup(
                                  classroom.uid, group.uid);
                              AudioEngine().playDeleteMember();
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmDelete(
      BuildContext context, String itemName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 $itemName 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

// ===================== 添加成员表单 =====================
class _AddMemberForm extends ConsumerStatefulWidget {
  final Classroom classroom;
  const _AddMemberForm({required this.classroom});

  @override
  ConsumerState<_AddMemberForm> createState() => _AddMemberFormState();
}

class _AddMemberFormState extends ConsumerState<_AddMemberForm> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedGroupUid;

  @override
  void initState() {
    super.initState();
    final groups = widget.classroom.groups;
    if (groups.isNotEmpty) _selectedGroupUid = groups.first.uid;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.classroom.groups;

    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          '请先在"小组管理"标签页创建小组',
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '成员姓名',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onSubmitted: (_) => _addMember(),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedGroupUid,
            hint: const Text('小组'),
            isDense: true,
            underline: const SizedBox(),
            items: groups
                .map((g) =>
                    DropdownMenuItem(value: g.uid, child: Text(g.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedGroupUid = v),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green),
            tooltip: '添加成员',
            onPressed: _addMember,
          ),
        ],
      ),
    );
  }

  void _addMember() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedGroupUid == null) return;

    ref
        .read(classProvider.notifier)
        .addMember(_selectedGroupUid!, name);
    _nameController.clear();
    AudioEngine().playAddMember();
  }
}

// ===================== 添加小组表单 =====================
class _AddGroupForm extends ConsumerStatefulWidget {
  final Classroom classroom;
  const _AddGroupForm({required this.classroom});

  @override
  ConsumerState<_AddGroupForm> createState() => _AddGroupFormState();
}

class _AddGroupFormState extends ConsumerState<_AddGroupForm> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '小组名称',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onSubmitted: (_) => _addGroup(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green),
            tooltip: '添加小组',
            onPressed: _addGroup,
          ),
        ],
      ),
    );
  }

  void _addGroup() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    ref.read(classProvider.notifier).addGroup(name);
    _nameController.clear();
    AudioEngine().playAddMember();
  }
}
