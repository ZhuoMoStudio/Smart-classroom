import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';
import '../models/sync_models.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    IconData icon;
    Color color;
    String text;
    switch (syncState.status) {
      case SyncStatus.idle: icon = Icons.cloud_outlined; color = Colors.grey; text = '未连接';
      case SyncStatus.online: icon = Icons.cloud_done; color = Colors.green; text = '在线';
      case SyncStatus.offline: icon = Icons.cloud_off; color = Colors.red; text = '离线';
      case SyncStatus.syncing: icon = Icons.sync; color = Colors.blue; text = '同步中';
      case SyncStatus.error: icon = Icons.cloud_off; color = Colors.red; text = '错误';
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
    ]);
  }
}