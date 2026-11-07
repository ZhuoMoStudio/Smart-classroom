import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'toast_overlay.dart';

/// Android 11+ 的「所有文件访问」（MANAGE_EXTERNAL_STORAGE）。
///
/// 应用把数据放在老师自选的工作目录里，而老师十有八九选在
/// `Download/...` 这类公共目录。Android 11 起分区存储生效：
/// 没有这个权限，`dart:io` 写公共目录会直接
/// `PathAccessException ... errno = 13`。
/// 读偶尔还能过（部分 ROM 放宽），写一定失败 —— 表现为
/// 「导出失败」「积分没保存」，但界面上的保存指示器仍可能是绿的。
///
/// 应用是 GitHub 侧载分发，不走 Play 商店对 MANAGE_EXTERNAL_STORAGE 的审核。
class StorageAccess {
  const StorageAccess._();

  static bool get isAndroid => Platform.isAndroid;

  /// 该路径是否位于公共存储（需要额外权限）。
  static bool needsAllFiles(String? path) {
    if (!isAndroid || path == null || path.isEmpty) return false;
    return path.startsWith('/storage/') || path.startsWith('/sdcard');
  }

  static Future<bool> isGranted() async {
    if (!isAndroid) return true;
    final status = await Permission.manageExternalStorage.status;
    return status.isGranted;
  }

  /// 申请权限。系统会跳到「所有文件访问」设置页，用户手动打开。
  static Future<bool> request() async {
    if (!isAndroid) return true;
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }
}

/// 如果没有权限就弹框引导用户去开。返回最终是否已授权。
Future<bool> ensureStorageAccess(
  BuildContext context, {
  required String? workspacePath,
}) async {
  if (!StorageAccess.needsAllFiles(workspacePath)) return true;
  if (await StorageAccess.isGranted()) return true;
  if (!context.mounted) return false;

  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('需要「所有文件访问」权限'),
      content: const Text(
        '工作目录在公共存储里（例如 Download）。\n\n'
        'Android 11 以后，应用必须获得「所有文件访问」才能把名单和积分写回这个目录，'
        '否则会报 Permission denied（errno 13），表现为导出失败、积分没保存。\n\n'
        '点「去授权」后，在系统页面里打开「允许访问所有文件」再返回。',
        style: TextStyle(fontSize: 13, height: 1.6),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('稍后'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('去授权'),
        ),
      ],
    ),
  );

  if (go != true) return false;

  final granted = await StorageAccess.request();
  if (!context.mounted) return granted;
  ToastOverlay.show(
    context,
    granted ? '已获得文件访问权限' : '未获得权限，工作目录将无法写入',
    type: granted ? ToastType.success : ToastType.error,
    duration: const Duration(seconds: 4),
  );
  return granted;
}
