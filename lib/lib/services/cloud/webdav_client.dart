import 'package:webdav_client/webdav_client.dart' as wc;
import 'dart:io';

class WebDavClientService {
  late wc.WebDavClient _client;
  bool _connected = false;

  bool get isConnected => _connected;

  Future<bool> connect({
    required String url,
    required String username,
    required String password,
  }) async {
    try {
      _client = wc.WebDavClient(url, user: username, password: password, timeout: const Duration(seconds: 10));
      await _client.readDir('/');
      _connected = true;
      return true;
    } catch (_) {
      _connected = false;
      return false;
    }
  }

  Future<List<wc.WebDavFile>> listFiles(String remotePath) async {
    if (!_connected) return [];
    return await _client.readDir(remotePath);
  }

  Future<void> uploadFile(String localPath, String remotePath) async {
    final file = File(localPath);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    await _client.write(remotePath, bytes);
  }

  Future<void> downloadFile(String remotePath, String localPath) async {
    final bytes = await _client.read(remotePath);
    final file = File(localPath);
    await file.writeAsBytes(bytes);
  }

  Future<void> deleteFile(String remotePath) async {
    await _client.delete(remotePath);
  }

  Future<wc.WebDavFile?> getFileInfo(String remotePath) async {
    try {
      final files = await _client.readDir(remotePath);
      if (files.isNotEmpty) return files.first;
    } catch (_) {}
    return null;
  }
}