import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';
import '../models/sync_models.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});
  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final s = ref.watch(syncProvider);
    IconData ic;
    Color c;
    String t;
    switch (s.status) {
      case SyncStatus.idle:
        ic = Icons.cloud_outlined;
        c = Colors.grey;
        t = '未连接';
      case SyncStatus.online:
        ic = Icons.cloud_done;
        c = Colors.green;
        t = '在线';
      case SyncStatus.offline:
        ic = Icons.cloud_off;
        c = Colors.red;
        t = '离线';
      case SyncStatus.syncing:
        ic = Icons.sync;
        c = Colors.blue;
        t = '同步中';
      case SyncStatus.error:
        ic = Icons.cloud_off;
        c = Colors.red;
        t = '错误';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ic, size: 16, color: c),
        const SizedBox(width: 4),
        Text(t, style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: c)),
      ],
    );
  }
}
