import 'dart:io';
import 'package:path/path.dart' as p;

/// 名单文件智能识别服务
///
/// 从 xlsx 文件名中自动提取年级、班级信息，
/// 相同年级班级的名单只保留最初始 1 个 + 最近 5 个。
class RosterSmartManager {
  /// 从文件名提取年级和班级信息
  ///
  /// 例： "三年级1班_学生名单.xlsx" → ("三年级", "1班")
  ///      "高一3班_名单.xlsx"       → ("高一", "3班")
  static (String?, String?) extractGradeClass(String fileName) {
    final name = p.basenameWithoutExtension(fileName);
    final cleaned = name.replaceAll(RegExp(r'[_\-\s]+'), '');

    // 匹配模式：N年级M班 / N年M班 / 高一N班 / 初一N班 等
    final patterns = [
      RegExp(r'(.*?(?:年级|年|级))(\d+班)'),
      RegExp(r'(高[一二三]|初[一二三]|小[一二三四五六])(\d+班)'),
      RegExp(r'(\d+)年(?:级)?(\d+班)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(cleaned);
      if (match != null && match.groupCount >= 2) {
        return (match.group(1) ?? '', match.group(2) ?? '');
      }
    }

    return (null, null);
  }

  /// 构建文件唯一标识（年级_班级）
  static String buildGradeClassKey(String fileName) {
    final (grade, cls) = extractGradeClass(fileName);
    if (grade != null && cls != null) {
      return '${grade}_$cls';
    }
    // 无法识别则用完整文件名作为 key
    return p.basenameWithoutExtension(fileName);
  }

  /// 执行智能清理
  ///
  /// 规则：
  /// - 相同年级班级的名单：保留最初始 1 个 + 最近 5 个
  /// - 无法识别年级班级的名单：保留最近 5 个
  /// - 题库文件：全部保留
  static Future<void> smartCleanup(String dirPath) async {
    final d = Directory(dirPath);
    if (!await d.exists()) return;

    // 收集所有 xlsx
    final xlsxFiles = <File>[];
    await for (final e in d.list()) {
      if (e is File && e.path.toLowerCase().endsWith('.xlsx')) {
        xlsxFiles.add(e);
      }
    }

    // 分类：名单 vs 题库
    final rosters = <File>[];
    final questions = <File>[];

    for (final f in xlsxFiles) {
      final name = p.basenameWithoutExtension(f.path).toLowerCase();
      if (name.contains('名单') ||
          name.contains('学生') ||
          name.contains('roster') ||
          name.contains('积分') ||
          name.contains('score')) {
        rosters.add(f);
      } else {
        questions.add(f); // 题库全部保留
      }
    }

    // 按年级班级分组
    final rosterGroups = <String, List<File>>{};
    for (final f in rosters) {
      final key = buildGradeClassKey(p.basename(f.path));
      rosterGroups.putIfAbsent(key, () => []);
      rosterGroups[key]!.add(f);
    }

    // 每组名单保留策略
    for (final entry in rosterGroups.entries) {
      final files = entry.value;
      if (files.length <= 2) continue; // 只有 1-2 个文件，全保留

      // 按修改时间排序（最新的在前）
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      // 保留：最初始（最旧的 1 个）+ 最近 5 个
      final keep = <File>{};
      keep.addAll(files.take(5)); // 最近 5 个
      keep.add(files.last); // 最旧的 1 个

      // 删除其余
      for (final f in files) {
        if (!keep.contains(f)) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
    }
  }
}
