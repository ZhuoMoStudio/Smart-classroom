import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';
import '../providers/settings_provider.dart';
import '../models/sync_models.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final sync = ref.watch(syncProvider);
    final settings = ref.watch(settingsProvider);

    // 如果 WebDAV 未配置，显示未配置状态
    final bool configured = settings.webdavUsername.isNotEmpty &&
        settings.webdavUrl.isNotEmpty &&
        settings.webdavUrl.startsWith('http');

    IconData ic;
    Color c;
    String label;
    String? subtitle;

    switch (sync.status) {
      case SyncStatus.idle:
        ic = Icons.cloud_outlined;
        c = Colors.grey;
        label = configured ? '未同步' : '未配置';
        subtitle = sync.lastSyncTime != null
            ? '上次: ${_format(sync.lastSyncTime!)}'
            : null;
      case SyncStatus.online:
        ic = Icons.cloud_done;
        c = Colors.green;
        label = '已同步';
        subtitle = sync.lastSyncTime != null
            ? _format(sync.lastSyncTime!)
            : null;
      case SyncStatus.offline:
        ic = Icons.cloud_off;
        c = Colors.orange;
        label = '离线';
        subtitle = sync.lastSyncTime != null
            ? '上次: ${_format(sync.lastSyncTime!)}'
            : null;
      case SyncStatus.syncing:
        ic = Icons.sync;
        c = Colors.blue;
        label = '同步中...';
        subtitle = sync.message;
      case SyncStatus.error:
        ic = Icons.cloud_off;
        c = Colors.red;
        label = '同步失败';
        subtitle = sync.message;
    }

    return Tooltip(
      message: subtitle ?? label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ic, size: 16, color: c),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(ctx)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: c, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _format(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
