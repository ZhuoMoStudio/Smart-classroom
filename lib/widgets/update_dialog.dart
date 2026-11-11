import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_log.dart';
import '../services/update_service.dart';
import 'toast_overlay.dart';

/// 检查更新并展示结果。
///
/// 原则：**不管检查成不成功，都要有一个能点的下载入口。**
/// GitHub API 在部分网络下拿不到，旧实现这种情况直接说「无法获取更新信息」，
/// 老师就卡住了；现在至少可以跳到仓库的 releases/latest 手动下载。
Future<void> checkForUpdates(
  BuildContext context, {
  bool alwaysShow = false,
  VoidCallback? onSkip,
}) async {
  final result = await UpdateService.check();
  if (!context.mounted) return;
  if (!result.hasUpdate && !alwaysShow) return;

  await showUpdateDialog(
    context,
    result,
    onSkip: result.hasUpdate ? onSkip : null,
  );
}

Future<void> showUpdateDialog(
  BuildContext context,
  UpdateResult result, {
  VoidCallback? onSkip,
}) async {
  final latest = result.latestVersion;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(result.hasUpdate ? '发现新版本' : '检查更新'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.hasUpdate) ...[
            Text('当前版本：${result.currentVersion ?? '未知'}'),
            const SizedBox(height: 4),
            Text(
              '最新版本：${latest ?? '未知'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              '前往仓库下载页获取新版安装包。\n'
              'Android 直接覆盖安装；Windows 下载便携版 exe 即可。',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ] else
            Text(
              result.message ?? '暂时无法获取版本信息，可直接前往下载页查看。',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
        ],
      ),
      actions: [
        if (onSkip != null)
          TextButton(
            onPressed: () {
              onSkip();
              Navigator.pop(ctx);
            },
            child: const Text('跳过此版本'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('关闭'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await openDownloadPage(context);
          },
          child: const Text('前往下载'),
        ),
      ],
    ),
  );
}

/// 打开仓库的 releases/latest。
Future<void> openDownloadPage(BuildContext context) async {
  final uri = Uri.parse(UpdateService.releasePageUrl);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    AppLog.warn('更新', '打开下载页失败：$e');
    if (context.mounted) {
      ToastOverlay.show(
        context,
        '无法打开浏览器，请手动访问：${UpdateService.releasePageUrl}',
        type: ToastType.error,
        duration: const Duration(seconds: 6),
      );
    }
  }
}
