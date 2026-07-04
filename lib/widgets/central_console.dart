import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_provider.dart';
import '../services/audio_engine.dart';
import '../widgets/toast_overlay.dart';
import '../theme/design_tokens.dart';

/// 桌面端控制台 — 统一的功能入口
///
/// 使用回调方式避免持有 WidgetRef，简化接口：
/// - onFileAction：文件相关（文件夹/保存/加载）
/// - onSync：云端同步
/// - onSettings：设置
/// - onImportExport：数据导入导出（弹出底部菜单）
class CentralConsole extends ConsumerStatefulWidget {
  final VoidCallback? onSave;
  final VoidCallback? onLoad;
  final VoidCallback? onPickFolder;
  final VoidCallback? onSync;
  final VoidCallback? onSettings;
  final VoidCallback? onImportRoster;
  final VoidCallback? onImportScores;
  final VoidCallback? onExportScores;
  final VoidCallback? onExportMemberTemplate;
  final VoidCallback? onExportQuestionTemplate;

  const CentralConsole({
    super.key,
    this.onSave,
    this.onLoad,
    this.onPickFolder,
    this.onSync,
    this.onSettings,
    this.onImportRoster,
    this.onImportScores,
    this.onExportScores,
    this.onExportMemberTemplate,
    this.onExportQuestionTemplate,
  });

  @override
  ConsumerState<CentralConsole> createState() => _CentralConsoleState();
}

class _CentralConsoleState extends ConsumerState<CentralConsole> {
  final _newClassNameCtrl = TextEditingController();
  bool _showAddClass = false;

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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
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

  /// 显示导入导出底部菜单
  void _showImportExportSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.import_export, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('数据导入/导出', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 导入组
              _sheetGroup('导入', [
                _sheetItem(Icons.person_add_alt, '导入学生名单', widget.onImportRoster),
                _sheetItem(Icons.upload_file, '导入积分数据', widget.onImportScores),
              ]),
              const Divider(height: 1, indent: 56),
              // 导出组
              _sheetGroup('导出', [
                _sheetItem(Icons.download, '导出积分数据', widget.onExportScores),
                _sheetItem(Icons.note_add, '导出名单模板', widget.onExportMemberTemplate),
                _sheetItem(Icons.quiz_outlined, '导出题库模板', widget.onExportQuestionTemplate),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 8, bottom: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _sheetItem(IconData icon, String label, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () {
        Navigator.pop(context); // 关闭底部菜单
        onTap?.call();
      },
      dense: true,
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  ),
                  onSubmitted: (_) => _addClass(),
                ),
              ),
            const SizedBox(width: 4),
            // 分割线
            Container(width: 1, height: 24, color: theme.colorScheme.outline.withOpacity(0.2)),
            const SizedBox(width: 2),
            // 核心功能按钮（紧凑排列）
            _btn(Icons.folder_open, '选择文件夹', widget.onPickFolder),
            _btn(Icons.save, '保存', widget.onSave),
            _btn(Icons.file_open, '加载', widget.onLoad),
            _btn(Icons.import_export, '导入/导出', _showImportExportSheet),
            _btn(Icons.cloud_sync, '同步', widget.onSync),
            _btn(Icons.settings, '设置', widget.onSettings),
          ],
        ),
      ),
    );
  }

  Widget _btn(IconData icon, String tip, VoidCallback? cb) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        minimumSize: const Size(32, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
        AudioEngine().playClick();
        cb?.call();
      },
    );
  }
}