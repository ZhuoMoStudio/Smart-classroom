import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/class_provider.dart';
import '../../widgets/rank_badge.dart';
import '../../widgets/score_button.dart';
import '../../models/class_model.dart';

class FullLeaderboardDialog extends ConsumerStatefulWidget {
  const FullLeaderboardDialog({super.key});

  @override
  ConsumerState<FullLeaderboardDialog> createState() => _FullLeaderboardDialogState();
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
    final cls = classState.selectedClass;

    if (cls == null) {
      return AlertDialog(
        title: const Text('班级管理'),
        content: const Text('请先选择班级'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
      );
    }

    return AlertDialog(
      title: Text('${cls.name} - 班级管理'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(children: [
          TabBar(controller: _tabController, tabs: const [
            Tab(text: '排行榜'), Tab(text: '成员管理'), Tab(text: '小组管理'),
          ]),
          Expanded(child: TabBarView(controller: _tabController, children: [
            _buildRankTab(cls),
            _buildMemberTab(cls),
            _buildGroupTab(cls),
          ])),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
    );
  }

  Widget _buildRankTab(Classroom cls) {
    final members = List<Member>.from(cls.allMembers)..sort((a, b) => b.score.compareTo(a.score));
    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, i) {
        final m = members[i];
        return ListTile(
          leading: CircleAvatar(child: Text('${i + 1}')),
          title: Text(m.name),
          subtitle: Text('${m.score.toStringAsFixed(1)} 分'),
          trailing: RankBadge(score: m.score),
        );
      },
    );
  }

  Widget _buildMemberTab(Classroom cls) {
    return Column(children: [
      _AddMemberForm(cls: cls),
      const Divider(),
      Expanded(child: ListView(children: cls.groups.expand((g) => [
            Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(g.name, style: Theme.of(context).textTheme.titleSmall)),
            ...g.members.map((m) => ListTile(
                  dense: true,
                  title: Text(m.name),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    RankBadge(score: m.score),
                    ScoreButton(label: '+1', onTap: () => ref.read(classProvider.notifier).changeScore(cls.uid, g.uid, m.uid, 1)),
                    ScoreButton(label: '-1', onTap: () => ref.read(classProvider.notifier).changeScore(cls.uid, g.uid, m.uid, -1)),
                  ]),
                )),
          ]).toList())),
    ]);
  }

  Widget _buildGroupTab(Classroom cls) {
    return Column(children: [
      _AddGroupForm(cls: cls),
      const Divider(),
      Expanded(child: ListView(children: cls.groups.map((g) => ListTile(
            title: Text(g.name),
            subtitle: Text('人数: ${g.memberCount} | 总分: ${g.totalScore.toStringAsFixed(1)}'),
          )).toList())),
    ]);
  }
}

class _AddMemberForm extends ConsumerStatefulWidget {
  final Classroom cls;
  const _AddMemberForm({required this.cls});

  @override
  ConsumerState<_AddMemberForm> createState() => _AddMemberFormState();
}

class _AddMemberFormState extends ConsumerState<_AddMemberForm> {
  final _nameCtrl = TextEditingController();
  String? _selectedGroupUid;

  @override
  void initState() {
    super.initState();
    final groups = widget.cls.groups;
    if (groups.isNotEmpty) _selectedGroupUid = groups.first.uid;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.cls.groups;
    return Row(children: [
      Expanded(child: TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '姓名'))),
      const SizedBox(width: 8),
      DropdownButton<String>(
        value: _selectedGroupUid,
        hint: const Text('小组'),
        items: groups.map((g) => DropdownMenuItem(value: g.uid, child: Text(g.name))).toList(),
        onChanged: (v) => setState(() => _selectedGroupUid = v),
      ),
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: () {
          if (_nameCtrl.text.isEmpty || _selectedGroupUid == null) return;
          ref.read(classProvider.notifier).addMember(_selectedGroupUid!, _nameCtrl.text);
          _nameCtrl.clear();
        },
      ),
    ]);
  }
}

class _AddGroupForm extends ConsumerStatefulWidget {
  final Classroom cls;
  const _AddGroupForm({required this.cls});

  @override
  ConsumerState<_AddGroupForm> createState() => _AddGroupFormState();
}

class _AddGroupFormState extends ConsumerState<_AddGroupForm> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '小组名'))),
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: () {
          if (_nameCtrl.text.isEmpty) return;
          ref.read(classProvider.notifier).addGroup(_nameCtrl.text);
          _nameCtrl.clear();
        },
      ),
    ]);
  }
}