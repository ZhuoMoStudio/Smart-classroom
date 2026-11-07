import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// 教材索引服务 — 解析 embedded JSON，提供三层次（学段→科目→版本）浏览
class TextbookIndexService {
  static Map<String, Map<String, Map<String, List<Map<String, String>>>>>? _cache;

  /// 从 embedded assets 加载教材索引。
  ///
  /// 对数据形状做**防御性**解析：应用只认「学段/科目/版本/[文件]」三层，
  /// 但索引是从上游教材仓库整理的，历史上出现过四层节点（多了一层分类），
  /// 旧实现直接 `(files as List)`，于是整份索引加载失败 ——
  /// 界面上就是「加载教材索引失败」，教材页全空。
  /// 现在：多出来的层级用「上级 / 下级」合并成版本名，结构不对的条目跳过，
  /// 单个坏节点不会拖垮整份索引。
  static Future<void> load() async {
    if (_cache != null) return;
    final jsonStr = await rootBundle.loadString('assets/textbook_index.json');
    final raw = jsonDecode(jsonStr);
    final cache = <String, Map<String, Map<String, List<Map<String, String>>>>>{};
    if (raw is! Map) {
      _cache = cache;
      return;
    }

    raw.forEach((stage, subjects) {
      final stageName = stage.toString();
      // `_未分类` 是维护脚本的隔离区，不作为学段展示
      if (stageName.startsWith('_') || subjects is! Map) return;

      final stageMap = <String, Map<String, List<Map<String, String>>>>{};
      subjects.forEach((subject, versions) {
        if (versions is! Map) return;
        final flat = <String, List<Map<String, String>>>{};
        _flattenVersions(flat, '', versions);
        if (flat.isNotEmpty) stageMap[subject.toString()] = flat;
      });
      if (stageMap.isNotEmpty) cache[stageName] = stageMap;
    });

    _cache = cache;
  }

  /// 把任意深度的「版本 → 文件」压平成「版本名 → [文件]」。
  static void _flattenVersions(
    Map<String, List<Map<String, String>>> out,
    String prefix,
    Map versions,
  ) {
    versions.forEach((key, value) {
      final name = prefix.isEmpty ? key.toString() : '$prefix / $key';
      if (value is List) {
        final files = <Map<String, String>>[];
        for (final item in value) {
          if (item is Map && item['n'] is String && item['p'] is String) {
            files.add({'n': item['n'] as String, 'p': item['p'] as String});
          }
        }
        if (files.isNotEmpty) out[name] = files;
      } else if (value is Map) {
        _flattenVersions(out, name, value);
      }
    });
  }

  /// 获取所有学段
  static List<String> getStages() {
    if (_cache == null) return [];
    return _cache!.keys.toList()..sort();
  }

  /// 获取某学段下的所有科目
  static List<String> getSubjects(String stage) {
    if (_cache == null || !_cache!.containsKey(stage)) return [];
    return _cache![stage]!.keys.toList()..sort();
  }

  /// 获取某学段+科目下的所有版本
  static List<String> getVersions(String stage, String subject) {
    if (_cache == null || !_cache!.containsKey(stage) ||
        !_cache![stage]!.containsKey(subject)) {
      return [];
    }
    return _cache![stage]![subject]!.keys.toList()..sort();
  }

  /// 获取某个版本的所有文件
  static List<Map<String, String>> getFiles(
      String stage, String subject, String version) {
    if (_cache == null || !_cache!.containsKey(stage) ||
        !_cache![stage]!.containsKey(subject) ||
        !_cache![stage]![subject]!.containsKey(version)) {
      return [];
    }
    return _cache![stage]![subject]![version]!;
  }

  /// 搜索教材（按名称模糊匹配）
  static List<TextbookFileInfo> search(String query) {
    if (_cache == null || query.isEmpty) return [];
    final q = query.toLowerCase();
    final results = <TextbookFileInfo>[];
    for (final stage in _cache!.keys) {
      for (final subject in _cache![stage]!.keys) {
        for (final version in _cache![stage]![subject]!.keys) {
          for (final file in _cache![stage]![subject]![version]!) {
            if (file['n']!.toLowerCase().contains(q) ||
                stage.toLowerCase().contains(q) ||
                subject.toLowerCase().contains(q) ||
                version.toLowerCase().contains(q)) {
              results.add(TextbookFileInfo(
                name: file['n']!,
                path: file['p']!,
                stage: stage,
                subject: subject,
                version: version,
              ));
            }
          }
        }
      }
    }
    // 限制结果数量
    results.sort((a, b) => a.name.compareTo(b.name));
    return results.take(50).toList();
  }

  /// 获取下载 URL
  static String getDownloadUrl(String filePath) {
    // 路径里有中文、全角括号、`&`、`：` 等字符，直接拼进 URI 会让
    // Uri.parse 抛 "Illegal percent encoding"（尤其是含 `%` 或全角符号时）。
    // 按段做百分号编码，得到纯 ASCII 的 URL；缓存文件名那边再解回来。
    final encoded = filePath
        .split('/')
        .where((s) => s.isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');
    return 'https://raw.githubusercontent.com/TapXWorld/ChinaTextbook/master/$encoded';
  }

  /// 获取统计信息
  static Map<String, int> getStats() {
    if (_cache == null) return {'stages': 0, 'subjects': 0, 'versions': 0, 'files': 0};
    int subjects = 0, versions = 0, files = 0;
    for (final s in _cache!.keys) {
      subjects += _cache![s]!.length;
      for (final sub in _cache![s]!.keys) {
        versions += _cache![s]![sub]!.length;
        for (final ver in _cache![s]![sub]!.keys) {
          files += _cache![s]![sub]![ver]!.length;
        }
      }
    }
    return {'stages': _cache!.length, 'subjects': subjects, 'versions': versions, 'files': files};
  }
}

class TextbookFileInfo {
  final String name;
  final String path;
  final String stage;
  final String subject;
  final String version;

  const TextbookFileInfo({
    required this.name,
    required this.path,
    required this.stage,
    required this.subject,
    required this.version,
  });

  String get downloadUrl =>
      'https://raw.githubusercontent.com/TapXWorld/ChinaTextbook/master/$path';
}
