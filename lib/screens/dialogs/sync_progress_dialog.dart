import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sync_provider.dart';

class SyncProgressDialog extends ConsumerWidget {
  const SyncProgressDialog({super.key});
  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final s = ref.watch(syncProvider);
    return AlertDialog(
      title: const Text('云端同步'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: s.progress),
          const SizedBox(height: 12),
          Text(s.message ?? '准备中...'),
          if (s.lastSyncTime != null) Text('上次同步: ${s.lastSyncTime}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
