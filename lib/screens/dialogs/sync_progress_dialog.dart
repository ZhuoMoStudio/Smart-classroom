import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sync_provider.dart';
import '../../providers/settings_provider.dart';

class SyncProgressDialog extends ConsumerWidget {
  const SyncProgressDialog({super.key});
  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final s = ref.watch(syncProvider);
    final settings = ref.watch(settingsProvider);

    String strategyLabel;
    switch (settings.syncStrategy) {
      case 'upload_only':
        strategyLabel = '仅上传';
        break;
      case 'download_first':
        strategyLabel = '下载优先';
        break;
      default:
        strategyLabel = '双向同步';
    }

    return AlertDialog(
      title: const Text('云端同步'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Text('策略: $strategyLabel',
                style: Theme.of(ctx)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey)),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: s.progress),
          const SizedBox(height: 12),
          Text(s.message ?? '准备中...'),
          if (s.lastSyncTime != null) ...[
            const SizedBox(height: 4),
            Text('上次同步: ${s.lastSyncTime}',
                style: Theme.of(ctx)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey)),
          ],
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
