import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../services/textbook_repo_service.dart';

/// 本地教材索引服务
///
/// 在本地保存教材的目录结构和书籍名称索引，用户下载后才可查看。
/// 索引文件结构：
/// ```json
/// {
///   "version": 2,
///   "updatedAt": "2026-07-04T...",
///   "directories": [
///     {"name": "小学", "path": "小学", "children": [
///       {"name": "语文", "path": "小学/语文", "children": [
///         {"name": "人教版", "path": "小学/语文/人教版", "children": []}
///       ]}
///     ]}
///   ],
///   "files": [
///     {"name": "...pdf", "path": "...", "size": 12345, "downloadUrl": "..."}
///   ],
///   "downloaded": {
///     "小学/语文/人教版/xxx.pdf": "/local/path/xxx.pdf"
///   }
/// }
/// ```
class TextbookIndexService {
  static const String _indexFileName = 'textbook_index.json';
  static const String _downloadDirName = 'textbooks';

  static Map<String, dynamic>? _cache;

  /// 获取索引文件路径
  static Future<String> _getIndexPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_indexFileName';
  }

  /// 获取教材下载目录
  static Future<String> getDownloadDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$_downloadDirName';
    final d = Directory(path);
    if (!await d.exists()) await d.create(recursive: true);
    return path;
  }

  // ==================== 索引加载/保存 ====================

  /// 加载索引
  static Future<Map<String, dynamic>> loadIndex() async {
    if (_cache != null) return _cache!;

    try {
      final path = await _getIndexPath();
      final file = File(path);
      if (!await file.exists()) {
        _cache = {'version': 2, 'directories': [], 'files': [], 'downloaded': {}};
        return _cache!;
      }
      final content = await file.readAsString(encoding: utf8);
      _cache = jsonDecode(content) as Map<String, dynamic>;
      return _cache!;
    } catch (e) {
      _cache = {'version': 2, 'directories': [], 'files': [], 'downloaded': {}};
      return _cache!;
    }
  }

  /// 保存索引
  static Future<void> saveIndex() async {
    if (_cache == null) return;
    try {
      final path = await _getIndexPath();
      _cache!['updatedAt'] = DateTime.now().toIso8601String();
      final file = File(path);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(_cache),
        encoding: utf8,
      );
    } catch (e) {
      debugPrint('保存教材索引失败: $e');
    }
  }

  /// 更新索引（从远程拉取目录结构）
  static Future<void> updateFromRemote({
    void Function(String status)? onStatus,
  }) async {
    final index = await loadIndex();
    final dirs = <Map<String, dynamic>>[];
    final files = <Map<String, dynamic>>[];

    onStatus?.call('正在获取教材目录...');

    // 获取根级目录
    try {
      final rootItems = await TextbookRepoService.fetchContents('');
      final newDirs = <Map<String, dynamic>>[];

      for (final item in rootItems) {
        if (item.type == 'dir') {
          final children = await _buildDirTree(item);
          newDirs.add({
            'name': item.name,
            'path': item.path,
            'children': children,
          });
        } else if (item.isPdf && !item.isSplitFile) {
          files.add({
            'name': item.name,
            'path': item.path,
            'size': item.size,
            'downloadUrl': item.downloadUrl,
          });
        }
      }

      index['directories'] = newDirs;
      index['files'] = files;
      _cache = index;
      await saveIndex();
      onStatus?.call('教材目录已更新');
    } catch (e) {
      onStatus?.call('更新失败: $e');
    }
  }

  /// 递归构建目录树（限制深度）
  static Future<List<Map<String, dynamic>>> _buildDirTree(
    TextbookItem item, {
    int depth = 0,
    int maxDepth = 3,
  }) async {
    if (depth >= maxDepth) return [];

    final children = <Map<String, dynamic>>[];
    try {
      final subItems = await TextbookRepoService.fetchContents(item.path);
      for (final sub in subItems) {
        if (sub.type == 'dir') {
          final subChildren = await _buildDirTree(sub, depth: depth + 1);
          children.add({
            'name': sub.name,
            'path': sub.path,
            'children': subChildren,
          });
        } else if (sub.isPdf && !sub.isSplitFile) {
          // 文件作为叶子节点
          children.add({
            'name': sub.name,
            'path': sub.path,
            'size': sub.size,
            'downloadUrl': sub.downloadUrl,
            '_isFile': true,
          });
        }
      }
    } catch (_) {}
    return children;
  }

  // ==================== 查询方法 ====================

  /// 获取目录树
  static List<Map<String, dynamic>> getDirectories() {
    final index = _cache;
    if (index == null) return [];
    return List<Map<String, dynamic>>.from(index['directories'] ?? []);
  }

  /// 获取所有PDF文件
  static List<Map<String, dynamic>> getAllFiles() {
    final index = _cache;
    if (index == null) return [];
    return List<Map<String, dynamic>>.from(index['files'] ?? []);
  }

  /// 获取指定目录下的文件和子目录
  static (List<Map<String, dynamic>>, List<Map<String, dynamic>>)
      getContents(String path) {
    final dirs = getDirectories();
    final files = getAllFiles();

    // 如果path为空，返回根级
    if (path.isEmpty) {
      return (dirs, files);
    }

    // 查找匹配的目录
    final subDirs = <Map<String, dynamic>>[];
    final subFiles = <Map<String, dynamic>>[];

    for (final dir in dirs) {
      if (dir['path'] == path) {
        final children = dir['children'] as List? ?? [];
        for (final child in children) {
          if (child['_isFile'] == true) {
            subFiles.add(child);
          } else {
            subDirs.add(child);
          }
        }
        return (subDirs, subFiles);
      }
    }

    // 递归查找
    _findInDirs(dirs, path, subDirs, subFiles);
    return (subDirs, subFiles);
  }

  static void _findInDirs(
    List<Map<String, dynamic>> dirs,
    String targetPath,
    List<Map<String, dynamic>> subDirs,
    List<Map<String, dynamic>> subFiles,
  ) {
    for (final dir in dirs) {
      if (dir['path'] == targetPath) {
        final children = dir['children'] as List? ?? [];
        for (final child in children) {
          if (child['_isFile'] == true) {
            subFiles.add(child);
          } else {
            subDirs.add(child);
          }
        }
        return;
      }
      final children = dir['children'] as List? ?? [];
      if (children.isNotEmpty) {
        _findInDirs(
          children.cast<Map<String, dynamic>>(),
          targetPath,
          subDirs,
          subFiles,
        );
      }
    }
  }

  // ==================== 下载管理 ====================

  /// 标记文件已下载
  static Future<void> markDownloaded(
      String path, String localPath) async {
    final index = await loadIndex();
    final downloaded = index['downloaded'] as Map<String, dynamic>? ?? {};
    downloaded[path] = localPath;
    index['downloaded'] = downloaded;
    _cache = index;
    await saveIndex();
  }

  /// 检查文件是否已下载
  static bool isDownloaded(String path) {
    final index = _cache;
    if (index == null) return false;
    final downloaded = index['downloaded'] as Map<String, dynamic>? ?? {};
    final localPath = downloaded[path]?.toString();
    if (localPath == null) return false;
    return File(localPath).existsSync();
  }

  /// 获取已下载文件路径
  static String? getDownloadedPath(String path) {
    final index = _cache;
    if (index == null) return null;
    final downloaded = index['downloaded'] as Map<String, dynamic>? ?? {};
    final localPath = downloaded[path]?.toString();
    if (localPath == null) return null;
    if (File(localPath).existsSync()) return localPath;
    return null;
  }

  /// 获取所有已下载的教材
  static List<(String name, String path, String localPath)> getDownloadedBooks() {
    final index = _cache;
    if (index == null) return [];
    final downloaded = index['downloaded'] as Map<String, dynamic>? ?? {};
    final result = <(String, String, String)>[];
    for (final entry in downloaded.entries) {
      final localPath = entry.value.toString();
      if (File(localPath).existsSync()) {
        final name = entry.key.split('/').last;
        result.add((name, entry.key, localPath));
      }
    }
    return result;
  }

  /// 获取下载统计
  static (int, int) getDownloadStats() {
    final index = _cache;
    if (index == null) return (0, 0);
    final files = index['files'] as List? ?? [];
    final downloaded = index['downloaded'] as Map<String, dynamic>? ?? {};
    return (downloaded.length, files.length);
  }
}