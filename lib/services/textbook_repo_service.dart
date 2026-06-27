import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'gh_proxy_service.dart';

/// 教材仓库文件/目录项
class TextbookItem {
  final String name;
  final String path;
  final String type; // 'file' or 'dir'
  final int? size;
  final String? downloadUrl;
  final List<TextbookItem>? children;

  const TextbookItem({
    required this.name,
    required this.path,
    required this.type,
    this.size,
    this.downloadUrl,
    this.children,
  });

  /// 是否为 PDF 文件
  bool get isPdf => name.toLowerCase().endsWith('.pdf') && type == 'file';

  /// 是否为分卷文件
  bool get isSplitFile => name.contains('.pdf.');

  factory TextbookItem.fromJson(Map<String, dynamic> json) {
    return TextbookItem(
      name: json['name']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      type: json['type']?.toString() ?? 'file',
      size:
          json['size'] is int
              ? json['size']
              : int.tryParse(json['size']?.toString() ?? ''),
      downloadUrl: json['download_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'path': path,
    'type': type,
    'size': size,
    'download_url': downloadUrl,
  };
}

/// ChinaTextbook 教材仓库服务
///
/// 使用 GitHub API 获取教材目录和文件列表，
/// 通过 ghproxy 加速 raw 文件下载。
///
/// TapXWorld/ChinaTextbook 是纯静态文件仓库（无后端 JSON 接口），
/// 使用 Git Trees API（recursive=1）高效获取全量文件树，
/// 降级使用 Contents API 逐层获取。
class TextbookRepoService {
  static const String _owner = 'TapXWorld';
  static const String _repo = 'ChinaTextbook';
  static const String _ref = 'main';

  static const String _apiBase =
      'https://api.github.com/repos/$_owner/$_repo/contents';

  // 缓存目录结构（避免频繁请求 GitHub API）
  static Map<String, List<TextbookItem>> _dirCache = {};
  // 全量文件树缓存（Tree API 结果）
  static List<TextbookItem>? _allFilesCache;

  /// 获取指定路径下的文件和目录列表
  ///
  /// [path] 仓库中的相对路径，空字符串表示根目录
  static Future<List<TextbookItem>> fetchContents(String path) async {
    // 检查缓存
    final cached = _dirCache[path];
    if (cached != null) return cached;

    final url = path.isEmpty ? _apiBase : '$_apiBase/$path';

    try {
      // GitHub API 在国内可能被限制，使用代理或直接请求
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'SmartClassroom/1.0',
              'Accept': 'application/vnd.github.v3+json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(response.body);
      final items =
          jsonList
              .map(
                (item) => TextbookItem.fromJson(item as Map<String, dynamic>),
              )
              .toList();

      // 排序：目录在前，文件在后；同类按名称排序
      items.sort((a, b) {
        if (a.type == b.type) return a.name.compareTo(b.name);
        return a.type == 'dir' ? -1 : 1;
      });

      _dirCache[path] = items;
      return items;
    } catch (e) {
      return [];
    }
  }

  /// 递归获取所有 PDF 文件
  ///
  /// [path] 起始路径
  /// [maxDepth] 最大递归深度
  static Future<List<TextbookItem>> fetchAllPdfs({
    String path = '',
    int maxDepth = 3,
    void Function(int found)? onProgress,
  }) async {
    final pdfs = <TextbookItem>[];
    await _fetchPdfsRecursive(path, pdfs, 0, maxDepth, onProgress);
    return pdfs;
  }

  static Future<void> _fetchPdfsRecursive(
    String path,
    List<TextbookItem> pdfs,
    int depth,
    int maxDepth,
    void Function(int)? onProgress,
  ) async {
    if (depth > maxDepth) return;

    final items = await fetchContents(path);
    for (final item in items) {
      if (item.isPdf && !item.isSplitFile) {
        pdfs.add(item);
        onProgress?.call(pdfs.length);
      } else if (item.type == 'dir') {
        await _fetchPdfsRecursive(
          item.path,
          pdfs,
          depth + 1,
          maxDepth,
          onProgress,
        );
      }
    }
  }

  /// 获取教材文件的代理下载 URL
  ///
  /// 将 GitHub raw URL 转为 ghproxy 代理 URL
  static String getProxyDownloadUrl(String rawUrl) {
    return GhProxyService.toProxyUrl(rawUrl);
  }

  /// 使用 Git Trees API（recursive=1）获取全量文件树
  static Future<List<TextbookItem>> _fetchFullTree() async {
    if (_allFilesCache != null) return _allFilesCache!;

    final url =
        'https://api.github.com/repos/$_owner/$_repo/git/trees/$_ref?recursive=1';

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'SmartClassroom/1.0',
              'Accept': 'application/vnd.github.v3+json',
            },
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body);
      final List<dynamic> tree = body['tree'] ?? [];

      final items =
          tree
              .where((item) => item['type'] == 'blob' || item['type'] == 'tree')
              .map((item) {
                final path = item['path']?.toString() ?? '';
                final name = path.split('/').last;
                final type = item['type'] == 'tree' ? 'dir' : 'file';
                final size = item['size'] as int?;
                final downloadUrl =
                    type == 'file'
                        ? 'https://raw.githubusercontent.com/$_owner/$_repo/$_ref/$path'
                        : null;
                return TextbookItem(
                  name: name,
                  path: path,
                  type: type,
                  size: size,
                  downloadUrl: downloadUrl,
                );
              })
              .toList();

      _allFilesCache = items;
      return items;
    } catch (e) {
      return [];
    }
  }

  /// 从全量树中按路径前缀过滤出指定目录的直接子项
  static Future<List<TextbookItem>> fetchContentsFromTree(
    String dirPath,
  ) async {
    final allItems = await _fetchFullTree();
    if (allItems.isEmpty) {
      return fetchContents(dirPath);
    }

    final prefix = dirPath.isEmpty ? '' : '$dirPath/';
    final directChildren =
        allItems.where((item) {
          if (item.path == dirPath) return false;
          if (prefix.isEmpty) {
            return !item.path.contains('/');
          }
          return item.path.startsWith(prefix) &&
              item.path.substring(prefix.length).split('/').length == 1;
        }).toList();

    directChildren.sort((a, b) {
      if (a.type == b.type) return a.name.compareTo(b.name);
      return a.type == 'dir' ? -1 : 1;
    });

    _dirCache[dirPath] = directChildren;
    return directChildren;
  }

  /// 从全量树中获取所有 PDF 文件（最高效方式）
  static Future<List<TextbookItem>> fetchAllPdfsFromTree({
    void Function(int found)? onProgress,
  }) async {
    final allItems = await _fetchFullTree();
    if (allItems.isEmpty) {
      return fetchAllPdfs(onProgress: onProgress);
    }

    final pdfs =
        allItems
            .where(
              (item) =>
                  item.type == 'file' &&
                  item.name.toLowerCase().endsWith('.pdf') &&
                  !item.name.contains('.pdf.'),
            )
            .toList();

    onProgress?.call(pdfs.length);
    return pdfs;
  }

  /// 清除缓存
  static void clearCache() {
    _dirCache.clear();
    _allFilesCache = null;
  }
}
