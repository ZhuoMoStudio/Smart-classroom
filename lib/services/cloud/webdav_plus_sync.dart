import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webdav_plus/webdav_plus.dart';
import '../../providers/settings_provider.dart';
import '../storage_service.dart';

/// WebDAV Plus 云同步服务
///
/// 使用 webdav_plus (MIT) 替代自行实现的 dio 方案。
/// 同步子目录结构：/<应用名称>/<年级>/<学科>/<班级>/
/// 或简化：/<应用名称>/data/
class WebdavPlusSyncService {
  final Ref _ref;

  const WebdavPlusSyncService(this._ref);

  /// 安全的文件名：移除 \ / : * ? " < > |
  static String safeName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }

  /// 构建远程路径
  /// 结构：/SmartClassroom/<grade>/<subject>/<className>/
  Future<String> _remotePath(String fileName) async {
    final settings = _ref.read(settingsProvider);
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
  Future<WebdavClient> _createClient() async {
    final settings = _ref.read(settingsProvider);
    final password =
        await _ref.read(storageServiceProvider).getSecure('webdav_password') ??
        '';

    final client = WebdavClient.withCredentials(
      settings.webdavUsername,
      password,
    );
    client.setBaseUrl(settings.webdavUrl);

    return client;
  }

  /// 测试连接
  Future<bool> testConnection() async {
    try {
      final client = await _createClient();
      final settings = _ref.read(settingsProvider);
      // 尝试列出远程目录
      await client.list(settings.remoteFolder);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 上传文件到 WebDAV
  Future<bool> uploadFile(String localPath, String fileName) async {
    try {
      final client = await _createClient();
      final remotePath = await _remotePath(fileName);
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
  Future<Uint8List?> downloadFile(String remoteFileName) async {
    try {
      final client = await _createClient();
      final remotePath = await _remotePath(remoteFileName);
      final bytes = await client.get(remotePath);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// 列出远程文件
  Future<List<DavResource>> listFiles() async {
    try {
      final client = await _createClient();
      final settings = _ref.read(settingsProvider);
      return await client.list(settings.remoteFolder);
    } catch (_) {
      return [];
    }
  }

  /// 创建远程目录
  Future<bool> createRemoteDir(String dirPath) async {
    try {
      final client = await _createClient();
      final settings = _ref.read(settingsProvider);
      final fullPath =
          '${settings.remoteFolder.replaceAll(RegExp(r'/+$'), '')}/$dirPath';
      await client.createDirectory(fullPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 删除远程文件
  Future<bool> deleteRemoteFile(String fileName) async {
    try {
      final client = await _createClient();
      final remotePath = await _remotePath(fileName);
      await client.delete(remotePath);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 同步：上传本地最新存档
  Future<bool> syncUpload(String localFilePath, String fileName) async {
    return uploadFile(localFilePath, fileName);
  }

  /// 同步：下载远程最新存档
  Future<Uint8List?> syncDownload(String fileName) async {
    return downloadFile(fileName);
  }
}
