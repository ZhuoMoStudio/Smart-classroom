import 'package:webdav_client/webdav_client.dart' as wc;
import 'dart:io';

class WebDavClientService {
  late wc.WebDavClient _c; bool _connected = false;
  bool get isConnected => _connected;

  Future<bool> connect({required String url, required String username, required String password}) async {
    try {
      _c = wc.WebDavClient(url, user: username, password: password, timeout: const Duration(seconds: 10));
      await _c.readDir('/'); _connected = true; return true;
    } catch (_) { _connected = false; return false; }
  }

  Future<List<wc.WebDavFile>> listFiles(String rp) async { if (!_connected) return []; return await _c.readDir(rp); }

  Future<void> uploadFile(String lp, String rp) async {
    final f = File(lp); if (!await f.exists()) return; await _c.write(rp, await f.readAsBytes());
  }

  Future<void> downloadFile(String rp, String lp) async {
    await File(lp).writeAsBytes(await _c.read(rp));
  }

  Future<void> deleteFile(String rp) async { await _c.delete(rp); }

  Future<wc.WebDavFile?> getFileInfo(String rp) async {
    try { final fs = await _c.readDir(rp); if (fs.isNotEmpty) return fs.first; } catch (_) {} return null;
  }
}
