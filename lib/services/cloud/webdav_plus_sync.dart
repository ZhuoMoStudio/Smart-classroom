import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:webdav_plus/webdav_plus.dart';
import '../../providers/settings_provider.dart';
import '../storage_service.dart';

/// WebDAV Plus 云同步服务
/// v1.30: 增加下载和文件列表功能
class WebdavPlusSyncService {
  const WebdavPlusSyncService();

  static String safeName(String name) {
    return name.replaceAll(RegExp(r'[\\\\/:*?\"<>|]'), '_').trim();
  }

  static String remotePath(SettingsState settings, String fileName) {
    final base = settings.remoteFolder.replaceAll(RegExp(r'/+$'), '');
    final parts = <String>[base];
    parts.add(safeName(fileName));
    return parts.join('/');
  }

  static Future<WebdavClient> createClient(
    SettingsState settings,
    String password,
  ) async {
    final client = WebdavClient.withCredentials(
      settings.webdavUsername,
      password,
    );
    client.setBaseUrl(settings.webdavUrl);
    return client;
  }

  /// 测试连接
  Future<bool> testConnection({
    required SettingsState settings,
    required String password,
  }) async {
    try {
      final client = await createClient(settings, password);
      try {
        await client.list('/');
      } catch (_) {
        return false;
      }
      try {
        await client.createDirectory(settings.remoteFolder);
      } catch (_) {}
      await client.list(settings.remoteFolder);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 上传文件到 WebDAV
  Future<bool> uploadFile({
    required String localPath,
    required String fileName,
    required SettingsState settings,
    required String password,
  }) async {
    try {
      final client = await createClient(settings, password);
      final rp = WebdavPlusSyncService.remotePath(settings, fileName);
      final file = File(localPath);
      if (!await file.exists()) return false;
      final bytes = await file.readAsBytes();
      await client.put(rp, bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 从 WebDAV 下载文件
  Future<Uint8List?> downloadFile({
    required String fileName,
    required SettingsState settings,
    required String password,
  }) async {
    try {
      final client = await createClient(settings, password);
      final rp = WebdavPlusSyncService.remotePath(settings, fileName);
      final bytes = await client.get(rp);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// 列出远程目录文件
  Future<List<String>> listRemoteFiles({
    required String dirName,
    required SettingsState settings,
    required String password,
  }) async {
    try {
      final client = await createClient(settings, password);
      final fullPath =
          '${settings.remoteFolder.replaceAll(RegExp(r'/+$'), '')}/$dirName';
      final resources = await client.list(fullPath);
      return resources
          .where((r) => !r.isDirectory)
          .map((r) => r.name)
          .where((n) => n.endsWith('.xlsx'))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 列出远程文件
  Future<List<DavResource>> listFiles({
    required SettingsState settings,
    required String password,
  }) async {
    try {
      final client = await createClient(settings, password);
      return await client.list(settings.remoteFolder);
    } catch (_) {
      return [];
    }
  }

  /// 创建远程目录
  Future<bool> createRemoteDir({
    required String dirPath,
    required SettingsState settings,
    required String password,
  }) async {
    try {
      final client = await createClient(settings, password);
      final fullPath =
          '${settings.remoteFolder.replaceAll(RegExp(r'/+$'), '')}/$dirPath';
      await client.createDirectory(fullPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 删除远程文件
  Future<bool> deleteRemoteFile({
    required String fileName,
    required SettingsState settings,
    required String password,
  }) async {
    try {
      final client = await createClient(settings, password);
      final rp = WebdavPlusSyncService.remotePath(settings, fileName);
      await client.delete(rp);
      return true;
    } catch (_) {
      return false;
    }
  }
}
