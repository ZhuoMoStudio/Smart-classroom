import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_provider.dart';
import '../services/audio_engine.dart';

class CentralConsole extends ConsumerWidget {
  final VoidCallback? onSave, onLoad, onSync, onSettings, onPickFolder;
  const CentralConsole({super.key, this.onSave, this.onLoad, this.onSync, this.onSettings, this.onPickFolder});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final cs = ref.watch(classProvider); final t = Theme.of(ctx);
    return Material(elevation: 6, borderRadius: BorderRadius.circular(20),
      color: t.colorScheme.surfaceContainerHighest,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          DropdownButton<String>(value: cs.selectedClass?.uid, hint: const Text('选择班级'),
            items: cs.classrooms.map((c) => DropdownMenuItem(value: c.uid, child: Text(c.name))).toList(),
            onChanged: (uid) { if (uid != null) ref.read(classProvider.notifier).selectClass(uid); },
            underline: const SizedBox()),
          const SizedBox(width: 8),
          _btn(Icons.folder_open, '选择文件夹', onPickFolder),
          _btn(Icons.save, '保存', onSave), _btn(Icons.file_open, '加载', onLoad),
          _btn(Icons.cloud_sync, '同步', onSync), _btn(Icons.settings, '设置', onSettings),
        ])));
  }

  IconButton _btn(IconData ic, String tip, VoidCallback? cb) => IconButton(
    icon: Icon(ic), tooltip: tip,
    onPressed: () { AudioEngine().playClick(); cb?.call(); });
}
