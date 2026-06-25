import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// USB / 可移动存储自动检测服务
/// 优先扫描可移动磁盘中的 data 文件夹，找不到则允许用户手动指定
class UsbDetector {
  // ==================== 平台检测 ====================
  static bool get isDesktop =>
      !defaultTargetPlatform.toString().contains('android') &&
      !defaultTargetPlatform.toString().contains('ios');

  static bool get isWindows =>
      defaultTargetPlatform == TargetPlatform.windows;

  static bool get isLinux =>
      defaultTargetPlatform == TargetPlatform.linux;

  /// 获取默认数据目录
  static Future<String> getDefaultDataDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/灵动课堂数据';
  }

  // ==================== U盘检测: Windows ====================
  /// 扫描 Windows 上所有可移动磁盘的 data 文件夹
  static Future<String?> scanWindowsUsbDataFolder() async {
    if (!isWindows) return null;
    try {
      // 尝试 D: 到 Z: 盘
      for (var drive in List.generate(22, (i) => '${String.fromCharCode(68 + i)}:\\')) {
        final dataFolder = Directory('$drive${Platform.pathSeparator}data');
        if (await dataFolder.exists()) {
          return dataFolder.path;
        }
      }
    } catch (_) {}
    return null;
  }

  /// 扫描 Windows 上所有可移动磁盘
  static Future<List<String>> scanWindowsRemovableDrives() async {
    if (!isWindows) return [];
    final drives = <String>[];
    try {
      for (var drive in List.generate(22, (i) => '${String.fromCharCode(68 + i)}:\\')) {
        final dir = Directory(drive);
        if (await dir.exists()) {
          drives.add(drive);
        }
      }
    } catch (_) {}
    return drives;
  }

  // ==================== U盘检测: Linux ====================
  static Future<String?> scanLinuxUsbDataFolder() async {
    if (!isLinux) return null;
    try {
      // 扫描 /media 和 /mnt 下的挂载点
      final mediaDir = Directory('/media');
      if (await mediaDir.exists()) {
        await for (final userDir in mediaDir.list()) {
          if (userDir is Directory) {
            await for (final mount in userDir.list()) {
              if (mount is Directory) {
                final dataFolder = Directory('${mount.path}/data');
                if (await dataFolder.exists()) {
                  return dataFolder.path;
                }
              }
            }
          }
        }
      }
      final mntDir = Directory('/mnt');
      if (await mntDir.exists()) {
        await for (final entity in mntDir.list()) {
          if (entity is Directory) {
            final dataFolder = Directory('${entity.path}/data');
            if (await dataFolder.exists()) {
              return dataFolder.path;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  // ==================== 统一扫描入口 ====================
  /// 返回 U 盘中 data 文件夹的路径，找不到返回 null
  static Future<String?> findUsbDataFolder() async {
    if (isWindows) return scanWindowsUsbDataFolder();
    if (isLinux) return scanLinuxUsbDataFolder();
    return null;
  }

  /// 获取数据目录（优先 USB，其次用户指定，最后默认）
  static Future<String> resolveDataDir(String? userSpecifiedPath) async {
    // 1. 用户指定了路径
    if (userSpecifiedPath != null && userSpecifiedPath.isNotEmpty) {
      final dir = Directory(userSpecifiedPath);
      if (await dir.exists()) return userSpecifiedPath;
    }

    // 2. 自动扫描 USB
    final usbPath = await findUsbDataFolder();
    if (usbPath != null) return usbPath;

    // 3. 默认本地路径
    return getDefaultDataDir();
  }
}
