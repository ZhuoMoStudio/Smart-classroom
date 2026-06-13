import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_provider.dart';
import '../services/audio_engine.dart';

class CentralConsole extends ConsumerWidget {
  final VoidCallback? onSave, onLoad, onSync, onSettings, onPickFolder;

  const CentralConsole({super.key, this.onSave, this.onLoad, this.onSync, this.onSettings, this.onPickFolder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classState = ref.watch(classProvider);
    final theme = Theme.of(context);
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          DropdownButton<String>(
            value: classState.selectedClass?.uid,
            hint: const Text('选择班级'),
            items: classState.classrooms.map((c) => DropdownMenuItem(value: c.uid, child: Text(c.name))).toList(),
            onChanged: (uid) { if (uid != null) ref.read(classProvider.notifier).selectClass(uid); },
            underline: const SizedBox(),
          ),
          const SizedBox(width: 8),
          _iconBtn(Icons.folder_open, '选择本地文件夹', onPickFolder),
          _iconBtn(Icons.save, '保存数据', onSave),
          _iconBtn(Icons.file_open, '加载存档', onLoad),
          _iconBtn(Icons.cloud_sync, '云端同步', onSync),
          _iconBtn(Icons.settings, '设置', onSettings),
        ]),
      ),
    );
  }

  IconButton _iconBtn(IconData icon, String tooltip, VoidCallback? onPressed) => IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: () { AudioEngine().playClick(); onPressed?.call(); },
      );
}