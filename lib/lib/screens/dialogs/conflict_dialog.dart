import 'package:flutter/material.dart';
import '../../models/sync_models.dart';

class ConflictDialog extends StatelessWidget {
  final ConflictInfo conflict;
  const ConflictDialog({super.key, required this.conflict});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('同步冲突'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('文件 "${conflict.itemName}" 存在冲突'),
        const SizedBox(height: 8),
        ListTile(leading: const Icon(Icons.phone_android), title: const Text('本地版本'), subtitle: Text(conflict.localVersion)),
        ListTile(leading: const Icon(Icons.cloud), title: const Text('云端版本'), subtitle: Text(conflict.remoteVersion)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, 'local'), child: const Text('保留本地')),
        TextButton(onPressed: () => Navigator.pop(context, 'remote'), child: const Text('保留云端')),
        TextButton(onPressed: () => Navigator.pop(context, 'cancel'), child: const Text('跳过')),
      ],
    );
  }
}