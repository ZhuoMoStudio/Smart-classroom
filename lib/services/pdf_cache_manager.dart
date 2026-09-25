import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_log.dart';
import 'gh_proxy_service.dart';

/// PDF 文件缓存管理器
///
/// 存储位置的演进（这是为「跨设备读取、减少重复下载」做的改动）：
/// 早期只把 PDF 缓存在**应用私有目录**（`<appDocs>/pdf_cache`），
/// 换一台设备就是一片空白，同一本教材要重下；老师也无从把自己下过的教材
/// 拷到另一台机器上。
///
/// 现在优先存到**工作区的 `课本/` 目录**：
///   - 它在老师自己的数据文件夹里，跟着文件夹一起跨设备
///     （无论是用网盘客户端同步、还是手动拷 U 盘）；
///   - 文件名可读（原名 + URL 哈希），不是缓存目录里的一堆乱码；
///   - 旧缓存会在首次设置工作区时**惰性搬迁**过来，已经下过的不用重下。
class PdfCacheManager {
  static PdfCacheManager? _instance;
  factory PdfCacheManager() => _instance ??= PdfCacheManager._();
  PdfCacheManager._();

  String? _storeDir;
  String? _resolvedDir;
  bool _migrated = false;

  final Map<String, DownloadState> _downloadStates = {};

  /// 由 DataService 在工作区就绪后注入，例如 `<工作区>/课本`
  void setStoreDir(String? dir) {
    if (dir == null || dir.isEmpty || dir == _storeDir) return;
    _storeDir = dir;
    _resolvedDir = null; // 下次访问重新解析
    _migrated = false; // 允许对新目录再做一次搬迁
    AppLog.info('课本', '课本存储目录已设为 $dir');
  }

  /// 旧的私有缓存目录（用于惰性搬迁与兼容查找）
  Future<String> get _legacyDir async =>
      '${(await getApplicationDocumentsDirectory()).path}/pdf_cache';

  /// 当前生效的缓存根目录
  Future<String> get cacheDirectory async {
    if (_resolvedDir != null) return _resolvedDir!;
    final target = _storeDir ?? await _legacyDir;
    final dir = Directory(target);
    if (!await dir.exists()) {
      try {
        await dir.create(recursive: true);
      } catch (e, st) {
        // 工作区不可写时退回私有目录，保证功能不因此完全失效
        AppLog.error('课本', '无法创建工作区课本目录，回退到私有缓存', e, st);
        final legacy = Directory(await _legacyDir);
        if (!await legacy.exists()) await legacy.create(recursive: true);
        _resolvedDir = legacy.path;
        return _resolvedDir!;
      }
    }
    _resolvedDir = dir.path;
    await _migrateLegacyIfNeeded();
    return _resolvedDir!;
  }

  /// 把旧私有缓存里的 PDF 搬到工作区，避免重复下载。
  Future<void> _migrateLegacyIfNeeded() async {
    if (_migrated) return;
    _migrated = true;

    final legacyPath = await _legacyDir;
    final current = _resolvedDir;
    if (current == null || current == legacyPath) return;

    final legacy = Directory(legacyPath);
    if (!await legacy.exists()) return;

    int moved = 0;
    try {
      await for (final e in legacy.list()) {
        if (e is! File || !e.path.toLowerCase().endsWith('.pdf')) continue;
        final dest = File(p.join(current, p.basename(e.path)));
        if (await dest.exists()) continue;
        try {
          await e.rename(dest.path);
          moved++;
        } catch (_) {
          // 跨分区时 rename 可能失败，退化为复制
          try {
            await e.copy(dest.path);
            await e.delete();
            moved++;
          } catch (_) {}
        }
      }
    } catch (e, st) {
      AppLog.error('课本', '搬迁旧缓存失败', e, st);
    }

    if (moved > 0) {
      AppLog.info('课本', '已把 $moved 份旧缓存课本搬到工作区，跨设备可直接读取');
    }
  }

  /// 根据 URL 生成缓存文件路径
  Future<String> _cachePathForUrl(String url) async {
    final hash = sha256.convert(utf8.encode(url)).toString();
    // 从 URL 中提取原始文件名作为前缀，方便人工识别
    final base = p.basenameWithoutExtension(Uri.decodeFull(url));
    final originalName = base.isNotEmpty ? base : 'document';
    final safeName =
        originalName.replaceAll(RegExp(r'[^\w\u4e00-\u9fff]'), '_');
    final dir = await cacheDirectory;
    return p.join(dir, '${safeName}_$hash.pdf');
  }

  /// 兼容查找：工作区没有时，再到旧私有缓存里找一次
  Future<String?> _legacyPathIfExists(String url) async {
    final hash = sha256.convert(utf8.encode(url)).toString();
    final base = p.basenameWithoutExtension(Uri.decodeFull(url));
    final safeName = (base.isNotEmpty ? base : 'document')
        .replaceAll(RegExp(r'[^\w\u4e00-\u9fff]'), '_');
    final legacy = File(p.join(await _legacyDir, '${safeName}_$hash.pdf'));
    if (await legacy.exists() && await legacy.length() > 0) return legacy.path;
    return null;
  }

  /// 检查是否已缓存
  Future<bool> isCached(String url) async =>
      (await getCachedPath(url)) != null;

  /// 获取已缓存文件的路径（不下载）
  Future<String?> getCachedPath(String url) async {
    final path = await _cachePathForUrl(url);
    final file = File(path);
    if (await file.exists() && await file.length() > 0) return path;

    final legacy = await _legacyPathIfExists(url);
    if (legacy != null) return legacy;
    return null;
  }

  /// 下载并缓存 PDF 文件
  ///
  /// [url] 原始 GitHub raw URL
  /// [onProgress] 下载进度回调 (receivedBytes, totalBytes)
  /// [onStatus] 状态变更回调
  ///
  /// 返回本地文件路径
  Future<String> downloadAndCache(
    String url, {
    void Function(int received, int total)? onProgress,
    void Function(DownloadState state)? onStatus,
    int mirrorIndex = 0,
  }) async {
    final cachePath = await _cachePathForUrl(url);

    // 优先返回已有文件（含旧缓存）
    final existing = await getCachedPath(url);
    if (existing != null) {
      onStatus?.call(DownloadState.completed);
      return existing;
    }

    _downloadStates[url] = DownloadState.downloading;
    onStatus?.call(DownloadState.downloading);

    final proxyUrls = GhProxyService.toProxyUrls(url);

    for (int i = mirrorIndex; i < proxyUrls.length; i++) {
      final tempFile = File('$cachePath.tmp');
      try {
        final proxyUrl = proxyUrls[i];
        final client = http.Client();
        try {
          final request = http.Request('GET', Uri.parse(proxyUrl));
          request.headers.addAll({
            'User-Agent': 'SmartClassroom/1.0',
            'Accept': '*/*',
          });

          final response =
              await client.send(request).timeout(const Duration(seconds: 120));
          if (response.statusCode != 200) continue;

          final totalBytes = response.contentLength ?? 0;
          int receivedBytes = 0;
          final sink = tempFile.openWrite();
          try {
            await for (final chunk in response.stream) {
              receivedBytes += chunk.length;
              sink.add(chunk);
              onProgress?.call(receivedBytes, totalBytes);
            }
          } finally {
            await sink.close();
          }

          // 验证下载完整性：少收了就是坏文件，换下一个镜像
          if (totalBytes > 0 && receivedBytes < totalBytes) {
            await tempFile.delete();
            AppLog.warn('课本', '下载不完整（$receivedBytes/$totalBytes），换镜像重试');
            continue;
          }

          await tempFile.rename(cachePath);
          _downloadStates[url] = DownloadState.completed;
          onStatus?.call(DownloadState.completed);
          AppLog.info('课本', '已保存到 ${p.basename(cachePath)}');
          return cachePath;
        } finally {
          client.close();
        }
      } catch (e) {
        // 清理半截文件，避免下次被误判为「已缓存」
        try {
          if (await tempFile.exists()) await tempFile.delete();
        } catch (_) {}
        continue;
      }
    }

    _downloadStates[url] = DownloadState.failed;
    onStatus?.call(DownloadState.failed);
    throw PdfCacheException('所有下载源均失败: $url');
  }

  /// 获取下载状态
  DownloadState getDownloadState(String url) =>
      _downloadStates[url] ?? DownloadState.idle;

  /// 删除指定缓存
  Future<void> removeCache(String url) async {
    final path = await getCachedPath(url);
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  /// 获取所有缓存文件列表
  Future<List<FileSystemEntity>> listAllCaches() async {
    final dir = Directory(await cacheDirectory);
    if (!await dir.exists()) return [];
    return dir.listSync();
  }

  /// 清理所有缓存（只清当前生效目录）
  Future<void> clearAllCaches() async {
    final dir = Directory(await cacheDirectory);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _resolvedDir = null;
    _migrated = false;
    _downloadStates.clear();
  }

  /// 获取缓存目录总大小（字节）
  Future<int> getCacheSize() async {
    final dir = Directory(await cacheDirectory);
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) total += await entity.length();
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
