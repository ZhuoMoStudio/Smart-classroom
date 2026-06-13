import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sync_provider.dart';

class SyncProgressDialog extends ConsumerWidget {
  const SyncProgressDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    return AlertDialog(
      title: const Text('云端同步'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        LinearProgressIndicator(value: syncState.progress),
        const SizedBox(height: 12),
        Text(syncState.message ?? '准备中...'),
        if (syncState.lastSyncTime != null) Text('上次同步: ${syncState.lastSyncTime}'),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
    );
  }
}