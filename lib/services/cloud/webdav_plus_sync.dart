import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:webdav_plus/webdav_plus.dart';
import '../../providers/settings_provider.dart';
import '../storage_service.dart';

/// WebDAV Plus 云同步服务
///
/// 使用 webdav_plus (MIT) 替代自行实现的 dio 方案。
/// 不持有 Ref，所有数据通过参数传入。
/// 这样避免 ProviderRef / WidgetRef 类型不兼容问题。
class WebdavPlusSyncService {
  const WebdavPlusSyncService();

  /// 安全的文件名：移除 \\ / : * ? " < > |
  static String safeName(String name) {
    return name.replaceAll(RegExp(r'[\\\\/:*?\"<>|]'), '_').trim();
  }

  /// 构建远程路径
  static String remotePath(SettingsState settings, String fileName) {
    final base = settings.remoteFolder.replaceAll(RegExp(r'/+$'), '');
    final parts = <String>[base];

    if (settings.currentGrade != null && settings.currentGrade!.isNotEmpty) {
      parts.add(safeName(settings.currentGrade!));
    }
    if (settings.currentSubject != null &&
        settings.currentSubject!.isNotEmpty) {
      parts.add(safeName(settings.currentSubject!));
    }
    parts.add(safeName(fileName));
    return parts.join('/');
  }

  /// 创建 WebDAV 客户端
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
      final remotePath = WebdavPlusSyncService.remotePath(settings, fileName);
      final file = File(localPath);
      if (!await file.exists()) return false;

      final bytes = await file.readAsBytes();
      await client.put(remotePath, bytes);
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
      final remotePath = WebdavPlusSyncService.remotePath(settings, fileName);
      final bytes = await client.get(remotePath);
      return bytes;
    } catch (_) {
      return null;
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
      final remotePath =
          WebdavPlusSyncService.remotePath(settings, fileName);
      await client.delete(remotePath);
      return true;
    } catch (_) {
      return false;
    }
  }
}
