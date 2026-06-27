import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

class WebDavFile {
  final String name;
  final String path;
  final int size;
  final DateTime lastModified;
  final bool isDirectory;

  const WebDavFile({
    required this.name,
    required this.path,
    this.size = 0,
    required this.lastModified,
    this.isDirectory = false,
  });
}

class WebDavClientService {
  final Dio _dio = Dio(
    BaseOptions(connectTimeout: const Duration(seconds: 10)),
  );
  bool _connected = false;

  bool get isConnected => _connected;

  Future<bool> connect({
    required String url,
    required String username,
    required String password,
  }) async {
    try {
      _dio.options.baseUrl = url.endsWith('/') ? url : '$url/';
      _dio.options.headers['Authorization'] =
          'Basic ${base64Encode(utf8.encode('$username:$password'))}';
      final resp = await _dio.request(
        '/',
        options: Options(method: 'PROPFIND'),
      );
      _connected = resp.statusCode == 207;
      return _connected;
    } catch (_) {
      _connected = false;
      return false;
    }
  }

  Future<List<WebDavFile>> listFiles(String remotePath) async {
    if (!_connected) return [];
    try {
      final resp = await _dio.request(
        remotePath,
        options: Options(method: 'PROPFIND', headers: {'Depth': '1'}),
      );
      if (resp.statusCode != 207) return [];
      return _parseMultiStatus(resp.data.toString(), remotePath);
    } catch (_) {
      return [];
    }
  }

  Future<void> uploadFile(String localPath, String remotePath) async {
    final file = File(localPath);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    await _dio.put(remotePath, data: bytes);
  }

  Future<void> downloadFile(String remotePath, String localPath) async {
    final resp = await _dio.get(
      remotePath,
      options: Options(responseType: ResponseType.bytes),
    );
    await File(localPath).writeAsBytes(resp.data);
  }

  Future<void> deleteFile(String remotePath) async {
    await _dio.delete(remotePath);
  }

  Future<WebDavFile?> getFileInfo(String remotePath) async {
    try {
      final files = await listFiles(remotePath);
      return files.isNotEmpty ? files.first : null;
    } catch (_) {
      return null;
    }
  }

  /// 解析 HTTP 日期格式（如 "Thu, 01 Jan 2024 12:00:00 GMT"）为 DateTime
  DateTime? _parseHttpDate(String dateStr) {
    try {
      // 处理格式: "Thu, 01 Jan 2024 12:00:00 GMT"
      final cleaned = dateStr.trim();
      // 去掉星期前缀和尾部的时区
      final withoutDay = cleaned.replaceFirst(
        RegExp(r'^[A-Z][a-z]{2},\s*'),
        '',
      );
      final withoutTz = withoutDay.replaceAll(RegExp(r'\s+[A-Z]{2,5}$'), '');
      return DateTime.tryParse(withoutTz);
    } catch (_) {
      return null;
    }
  }

  List<WebDavFile> _parseMultiStatus(String xml, String basePath) {
    final files = <WebDavFile>[];
    final responses = xml.split('<D:response>').skip(1);
    for (final part in responses) {
      final hrefMatch = RegExp(r'<D:href>(.*?)</D:href>').firstMatch(part);
      final nameMatch = RegExp(
        r'<D:displayname>(.*?)</D:displayname>',
      ).firstMatch(part);
      final sizeMatch = RegExp(
        r'<D:getcontentlength>(.*?)</D:getcontentlength>',
      ).firstMatch(part);
      final dateMatch = RegExp(
        r'<D:getlastmodified>(.*?)</D:getlastmodified>',
      ).firstMatch(part);
      final collMatch = RegExp(r'<D:collection/>').firstMatch(part);

      if (hrefMatch == null) continue;
      final href = hrefMatch.group(1)!.trim();
      final name =
          nameMatch?.group(1)?.trim() ??
          href.split('/').where((s) => s.isNotEmpty).last;
      final size = int.tryParse(sizeMatch?.group(1) ?? '0') ?? 0;
      DateTime lm = DateTime.now();
      if (dateMatch != null) {
        lm = _parseHttpDate(dateMatch.group(1)!) ?? DateTime.now();
      }
      files.add(
        WebDavFile(
          name: name,
          path: href,
          size: size,
          lastModified: lm,
          isDirectory: collMatch != null,
        ),
      );
    }
    return files;
  }
}
