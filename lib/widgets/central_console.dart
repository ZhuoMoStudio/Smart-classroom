import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_provider.dart';
import '../services/audio_engine.dart';
import '../widgets/toast_overlay.dart';

class CentralConsole extends ConsumerStatefulWidget {
  final VoidCallback? onSave;
  final VoidCallback? onLoad;
  final VoidCallback? onSync;
  final VoidCallback? onSettings;
  final VoidCallback? onPickFolder;
  final VoidCallback? onImportRoster;
  final VoidCallback? onExportScores;
  final VoidCallback? onImportScores;
  final VoidCallback? onExportMemberTemplate;
  final VoidCallback? onExportQuestionTemplate;

  const CentralConsole({
    super.key,
    this.onSave,
    this.onLoad,
    this.onSync,
    this.onSettings,
    this.onPickFolder,
    this.onImportRoster,
    this.onExportScores,
    this.onImportScores,
    this.onExportMemberTemplate,
    this.onExportQuestionTemplate,
  });

  @override
  ConsumerState<CentralConsole> createState() => _CentralConsoleState();
}

class _CentralConsoleState extends ConsumerState<CentralConsole> {
  final _newClassNameCtrl = TextEditingController();
  bool _showAddClass = false;
  bool _showMenu = false;

  @override
  void dispose() {
    _newClassNameCtrl.dispose();
    super.dispose();
  }

  void _addClass() {
    final name = _newClassNameCtrl.text.trim();
    if (name.isEmpty) return;
    ref.read(classProvider.notifier).addClass(name);
    _newClassNameCtrl.clear();
    setState(() => _showAddClass = false);
    AudioEngine().playAddMember();
    ToastOverlay.show(context, '已创建班级: $name');
  }

  void _deleteClassDialog(String uid, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除班级'),
        content: Text('确定要删除班级「$name」吗？\n该班级下的所有小组和成员数据将被移除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              ref.read(classProvider.notifier).deleteClass(uid);
              Navigator.pop(ctx);
              AudioEngine().playDeleteMember();
              ToastOverlay.show(context, '已删除班级: $name');
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = ref.watch(classProvider);
    final theme = Theme.of(context);
    final classrooms = cs.classrooms;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      color: theme.colorScheme.surfaceContainerHighest,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 班级选择
            Container(
              constraints: const BoxConstraints(maxWidth: 140),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: DropdownButton<String>(
                value: cs.selectedClass?.uid,
                hint: const Text('选择班级', style: TextStyle(fontSize: 13)),
                isDense: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                items: [
                  for (final c in classrooms)
                    DropdownMenuItem(
                      value: c.uid,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(c.name, overflow: TextOverflow.ellipsis),
                          ),
                          if (classrooms.length > 1)
                            GestureDetector(
                              onTap: () => _deleteClassDialog(c.uid, c.name),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(Icons.close, size: 14, color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
                onChanged: (uid) {
                  if (uid != null) {
                    ref.read(classProvider.notifier).selectClass(uid);
                    AudioEngine().playClick();
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              tooltip: '添加班级',
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _showAddClass = !_showAddClass),
            ),
            if (_showAddClass)
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _newClassNameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: '班级名称',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  ),
                  onSubmitted: (_) => _addClass(),
                ),
              ),
            const SizedBox(width: 4),
            Container(
                width: 1,
                height: 24,
                color: theme.colorScheme.outline.withOpacity(0.2)),
            // 主要功能按钮
            _btn(Icons.folder_open, '选择文件夹', widget.onPickFolder),
            _btn(Icons.save, '保存', widget.onSave),
            _btn(Icons.file_open, '加载', widget.onLoad),
            _btn(Icons.cloud_sync, '同步', widget.onSync),
            _btn(Icons.settings, '设置', widget.onSettings),
            Container(
                width: 1,
                height: 24,
                color: theme.colorScheme.outline.withOpacity(0.2)),
            // 更多菜单
            IconButton(
              icon: Icon(_showMenu ? Icons.close : Icons.more_horiz, size: 20),
              tooltip: '更多操作',
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _showMenu = !_showMenu),
            ),
            if (_showMenu) ..._buildMoreMenu(theme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMoreMenu(ThemeData theme) {
    return [
      _menuBtn(Icons.person_add_alt, '导入名单', widget.onImportRoster),
      _menuBtn(Icons.upload, '导入积分', widget.onImportScores),
      _menuBtn(Icons.download, '导出积分', widget.onExportScores),
      _menuBtn(Icons.note_add, '名单模板', widget.onExportMemberTemplate),
      _menuBtn(Icons.quiz, '题库模板', widget.onExportQuestionTemplate),
    ];
  }

  Widget _btn(IconData icon, String tip, VoidCallback? cb) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tip,
      visualDensity: VisualDensity.compact,
      onPressed: () {
        AudioEngine().playClick();
        cb?.call();
      },
    );
  }

  Widget _menuBtn(IconData icon, String label, VoidCallback? cb) {
    return InkWell(
      onTap: () {
        AudioEngine().playClick();
        cb?.call();
        setState(() => _showMenu = false);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
