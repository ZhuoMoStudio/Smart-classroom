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
  Future<void> Function()? onUseAppDir,
}) async {
  if (workspacePath == null || workspacePath.isEmpty) return false;
  // 先实测：能写就不用打扰用户（哪怕权限 API 说没授权）
  if (await StorageAccess.probeWritable(workspacePath)) return true;

  if (!context.mounted) return false;

  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('工作目录无法读写'),
      content: const Text(
        '工作目录在公共存储里（例如 Download）。\n\n'
        'Android 11 以后，应用必须获得「所有文件访问」才能读写这个目录，'
        '否则会报 Permission denied（errno 13），表现为导出失败、积分没保存、日志导不出。\n\n'
        '不想授权也可以点「改用应用目录」：数据改存到应用自己的目录，不需要任何权限，'
        '但文件管理器里看不到。',
        style: TextStyle(fontSize: 13, height: 1.6),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'later'),
          child: const Text('稍后'),
        ),
        if (onUseAppDir != null)
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'appdir'),
            child: const Text('改用应用目录'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, 'grant'),
          child: const Text('去授权'),
        ),
      ],
    ),
  );

  if (choice == 'appdir' && onUseAppDir != null) {
    await onUseAppDir();
    if (!context.mounted) return true;
    ToastOverlay.show(context, '已改用应用目录，数据仍会正常保存',
        type: ToastType.success);
    return true;
  }
  if (choice != 'grant') return false;

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
