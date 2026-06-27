import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'gh_proxy_service.dart';

/// PDF 文件缓存管理器
///
/// - 自动下载并永久缓存 PDF 文件到应用数据目录
/// - 按文件 URL 的 SHA256 哈希值作为唯一缓存标识
/// - 二次打开时优先读取本地缓存
/// - 支持下载进度回调
class PdfCacheManager {
  static PdfCacheManager? _instance;
  factory PdfCacheManager() => _instance ??= PdfCacheManager._();
  PdfCacheManager._();

  String? _cacheDir;
  final Map<String, DownloadState> _downloadStates = {};

  /// 缓存根目录
  Future<String> get cacheDirectory async {
    _cacheDir ??=
        '${(await getApplicationDocumentsDirectory()).path}/pdf_cache';
    final dir = Directory(_cacheDir!);
    if (!await dir.exists()) await dir.create(recursive: true);
    return _cacheDir!;
  }

  /// 根据 URL 生成缓存文件路径
  Future<String> _cachePathForUrl(String url) async {
    final hash = sha256.convert(utf8.encode(url)).toString();
    // 从 URL 中提取原始文件名作为前缀，方便人工识别
    final originalName =
        p.basenameWithoutExtension(url).isNotEmpty
            ? p.basenameWithoutExtension(url)
            : 'document';
    final safeName = originalName.replaceAll(
      RegExp(r'[^\w\u4e00-\u9fff]'),
      '_',
    );
    final dir = await cacheDirectory;
    return '$dir/${safeName}_$hash.pdf';
  }

  /// 检查是否已缓存
  Future<bool> isCached(String url) async {
    final path = await _cachePathForUrl(url);
    final file = File(path);
    return await file.exists() && await file.length() > 0;
  }

  /// 获取缓存文件路径（不下载）
  Future<String?> getCachedPath(String url) async {
    final path = await _cachePathForUrl(url);
    final file = File(path);
    if (await file.exists() && await file.length() > 0) {
      return path;
    }
    return null;
  }

  /// 下载并缓存 PDF 文件
  ///
  /// [url] 原始 GitHub raw URL
  /// [onProgress] 下载进度回调 (receivedBytes, totalBytes)
  /// [onStatus] 状态变更回调
  ///
  /// 返回本地缓存文件路径
  Future<String> downloadAndCache(
    String url, {
    void Function(int received, int total)? onProgress,
    void Function(DownloadState state)? onStatus,
    int mirrorIndex = 0,
  }) async {
    final cachePath = await _cachePathForUrl(url);

    // 优先返回缓存
    if (await isCached(url)) {
      onStatus?.call(DownloadState.completed);
      return cachePath;
    }

    // 更新状态
    _downloadStates[url] = DownloadState.downloading;
    onStatus?.call(DownloadState.downloading);

    final proxyUrls = GhProxyService.toProxyUrls(url);

    // 从指定镜像索引开始尝试
    for (int i = mirrorIndex; i < proxyUrls.length; i++) {
      try {
        final proxyUrl = proxyUrls[i];
        final file = File(cachePath);
        final tempPath = '$cachePath.tmp';

        final client = http.Client();
        try {
          final request = http.Request('GET', Uri.parse(proxyUrl));
          request.headers.addAll({
            'User-Agent': 'SmartClassroom/1.0',
            'Accept': '*/*',
          });

          final response = await client
              .send(request)
              .timeout(const Duration(seconds: 120));

          if (response.statusCode != 200) {
            // 尝试下一个镜像
            continue;
          }

          final totalBytes = response.contentLength ?? 0;
          int receivedBytes = 0;
          final tempFile = File(tempPath);
          final sink = tempFile.openWrite();

          await for (final chunk in response.stream) {
            receivedBytes += chunk.length;
            sink.add(chunk);
            onProgress?.call(receivedBytes, totalBytes);
          }

          await sink.close();

          // 验证下载完整性
          if (totalBytes > 0 && receivedBytes < totalBytes) {
            await tempFile.delete();
            continue;
          }

          // 下载完成，重命名为正式缓存文件
          await tempFile.rename(cachePath);

          _downloadStates[url] = DownloadState.completed;
          onStatus?.call(DownloadState.completed);
          return cachePath;
        } finally {
          client.close();
        }
      } catch (e) {
        // 尝试下一个镜像
        continue;
      }
    }

    // 所有镜像都失败
    _downloadStates[url] = DownloadState.failed;
    onStatus?.call(DownloadState.failed);
    throw PdfCacheException('所有加速镜像均下载失败: $url');
  }

  /// 获取下载状态
  DownloadState getDownloadState(String url) =>
      _downloadStates[url] ?? DownloadState.idle;

  /// 删除指定缓存
  Future<void> removeCache(String url) async {
    final path = await _cachePathForUrl(url);
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  /// 获取所有缓存文件列表
  Future<List<FileSystemEntity>> listAllCaches() async {
    final dir = Directory(await cacheDirectory);
    if (!await dir.exists()) return [];
    return dir.listSync();
  }

  /// 清理所有缓存
  Future<void> clearAllCaches() async {
    final dir = Directory(await cacheDirectory);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _downloadStates.clear();
  }

  /// 获取缓存目录总大小（字节）
  Future<int> getCacheSize() async {
    final dir = Directory(await cacheDirectory);
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}

/// 下载状态枚举
enum DownloadState { idle, downloading, completed, failed }

/// PDF 缓存异常
class PdfCacheException implements Exception {
  final String message;
  const PdfCacheException(this.message);

  @override
  String toString() => 'PdfCacheException: $message';
}
