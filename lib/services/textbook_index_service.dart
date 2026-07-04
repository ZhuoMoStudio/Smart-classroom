import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// 教材索引服务 — 解析 embedded JSON，提供三层次（学段→科目→版本）浏览
class TextbookIndexService {
  static Map<String, Map<String, Map<String, List<Map<String, String>>>>>? _cache;

  /// 从 embedded assets 加载教材索引
  static Future<void> load() async {
    if (_cache != null) return;
    final jsonStr = await rootBundle.loadString('assets/textbook_index.json');
    final Map<String, dynamic> raw = jsonDecode(jsonStr);
    _cache = {};
    raw.forEach((stage, subjects) {
      _cache![stage] = {};
      (subjects as Map<String, dynamic>).forEach((subject, versions) {
        _cache![stage]![subject] = {};
        (versions as Map<String, dynamic>).forEach((version, files) {
          _cache![stage]![subject]![version] =
              (files as List).map((f) => {
                    'n': f['n'] as String,
                    'p': f['p'] as String,
                  }).toList();
        });
      });
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
        !_cache![stage]!.containsKey(subject)) return [];
    return _cache![stage]![subject]!.keys.toList()..sort();
  }

  /// 获取某个版本的所有文件
  static List<Map<String, String>> getFiles(
      String stage, String subject, String version) {
    if (_cache == null || !_cache!.containsKey(stage) ||
        !_cache![stage]!.containsKey(subject) ||
        !_cache![stage]![subject]!.containsKey(version)) return [];
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
    return 'https://raw.githubusercontent.com/TapXWorld/ChinaTextbook/master/$filePath';
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
