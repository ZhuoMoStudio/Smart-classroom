import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/toast_overlay.dart';

/// Android 11+ 的「所有文件访问」（MANAGE_EXTERNAL_STORAGE）。
///
/// 应用把数据放在老师自选的工作目录里，而老师十有八九选在
/// `Download/...` 这类公共目录。Android 11 起分区存储生效：
/// 没有这个权限，`dart:io` 写公共目录会直接
/// `PathAccessException ... errno = 13`。
///
/// 这里的所有平台调用都做了兜底：ROM 差异、插件缺失、权限页打不开，
/// 都不能让启动流程崩掉。判断「到底能不能写」以 [probeWritable] 的实测为准，
/// 而不是只信权限 API —— 有些 ROM 会返回 granted 但实际仍拒绝写入。
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
    try {
      final status = await Permission.manageExternalStorage.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('读取文件访问权限失败：$e');
      return false;
    }
  }

  /// 申请权限。系统会跳到「所有文件访问」设置页，用户手动打开。
  /// 返回的是「调用后是否已授权」，用户从设置页返回时可能仍需要再点一次。
  static Future<bool> request() async {
    if (!isAndroid) return true;
    try {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('申请文件访问权限失败：$e');
      return false;
    }
  }

  /// 打开系统里本应用的设置页（权限页打不开时的兜底）。
  static Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('打开应用设置失败：$e');
    }
  }

  /// 实测工作目录能不能写：写一个临时文件再删掉。
  ///
  /// 这比只看权限状态可靠：分区存储、只读挂载、SD 卡拔出、
  /// 目录被系统重建等情况下，权限是 granted 但写入仍会失败。
  static Future<bool> probeWritable(String? dirPath) async {
    if (dirPath == null || dirPath.isEmpty) return false;
    final probe = File('$dirPath/.write_probe');
    try {
      // 目录还没建（首次启动、刚选完工作区）时先建，再写探测文件
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// 引导用户开启「所有文件访问」。返回最终是否可写。
Future<bool> ensureStorageAccess(
  BuildContext context, {
  required String? workspacePath,
}) async {
  if (workspacePath == null || workspacePath.isEmpty) return false;
  // 先实测：能写就不用打扰用户（哪怕权限 API 说没授权）
  if (await StorageAccess.probeWritable(workspacePath)) return true;

  if (!context.mounted) return false;

  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('需要「所有文件访问」权限'),
      content: const Text(
        '工作目录在公共存储里（例如 Download）。\n\n'
        'Android 11 以后，应用必须获得「所有文件访问」才能把名单和积分写回这个目录，'
        '否则导出会失败、积分也不会落盘。\n\n'
        '点「去授权」→ 在系统页面里打开「允许访问所有文件」→ 返回应用。',
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

  await StorageAccess.request();
  if (!context.mounted) return false;

  // 从设置页回来后立刻复测，给一个明确结论
  final ok = await StorageAccess.probeWritable(workspacePath);
  if (!context.mounted) return ok;
  ToastOverlay.show(
    context,
    ok ? '已获得文件访问权限，现在可以正常保存' : '仍未获得权限，请到系统设置 → 应用 → 特殊权限 里打开',
    type: ok ? ToastType.success : ToastType.error,
    duration: const Duration(seconds: 4),
  );
  return ok;
}
