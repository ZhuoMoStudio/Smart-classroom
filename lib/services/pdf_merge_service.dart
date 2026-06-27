import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// PDF 分卷文件自动合并服务
///
/// ChinaTextbook 仓库中大于 50MB 的 PDF 文件被拆分为 .1 .2 .3 等分卷。
/// 此服务自动检测并合并分卷文件为完整 PDF。
///
/// 工作原理：
/// - Go 版 mergePDFs 的逻辑是：扫描目录中所有包含 ".pdf." 的文件名，
///   按 baseName 分组，排序后顺序拼接二进制数据，生成完整 PDF。
/// - 本 Dart 实现完全复刻 Go 版本逻辑。
class PdfMergeService {
  /// 扫描目录并自动合并所有分卷文件
  ///
  /// [directoryPath] 包含 PDF 文件的目录路径
  ///
  /// 返回被合并后的基础文件路径列表
  static Future<List<String>> mergeAllInDirectory(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return [];

    // 收集所有分卷文件：文件名中包含 ".pdf." 的文件
    // 例如: "语文必修上册.pdf.1" → baseName = "语文必修上册.pdf"
    final splitFiles = <String, List<String>>{};

    await for (final entity in dir.list(recursive: true)) {
      if (entity is! File) continue;
      final fileName = p.basename(entity.path);

      if (fileName.contains('.pdf.')) {
        // 提取基础文件名
        final splitIndex = fileName.indexOf('.pdf.');
        final baseName = '${fileName.substring(0, splitIndex)}.pdf';
        final basePath = p.join(p.dirname(entity.path), baseName);

        splitFiles.putIfAbsent(basePath, () => []);
        splitFiles[basePath]!.add(entity.path);
      }
    }

    final mergedPaths = <String>[];

    for (final entry in splitFiles.entries) {
      final basePath = entry.key;
      final parts = entry.value..sort(); // 按文件名排序确保顺序正确

      try {
        await _mergeFiles(basePath, parts);
        mergedPaths.add(basePath);
      } catch (e) {
        // 合并失败，跳过
        debugPrint('PDF merge failed for $basePath: $e');
      }
    }

    return mergedPaths;
  }

  /// 合并分卷文件
  ///
  /// [basePath] 合并后的输出文件路径
  /// [parts] 分卷文件路径列表（已排序）
  static Future<void> _mergeFiles(String basePath, List<String> parts) async {
    final mergedFile = File(basePath);

    // 如果合并后的文件已存在且比所有分卷都新，跳过
    if (await mergedFile.exists()) {
      final mergedTime = await mergedFile.lastModified();
      bool allOlder = true;
      for (final part in parts) {
        final partFile = File(part);
        if ((await partFile.lastModified()).isAfter(mergedTime)) {
          allOlder = false;
          break;
        }
      }
      if (allOlder) return; // 已是最新
    }

    final sink = mergedFile.openWrite();
    try {
      for (final part in parts) {
        final partFile = File(part);
        if (!await partFile.exists()) continue;
        final bytes = await partFile.readAsBytes();
        sink.add(bytes);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    // 合并成功后删除分卷文件
    for (final part in parts) {
      try {
        await File(part).delete();
      } catch (_) {}
    }
  }

  /// 判断文件是否为分卷文件
  static bool isSplitFile(String fileName) {
    return fileName.contains('.pdf.');
  }

  /// 从分卷文件名中提取基础文件名
  ///
  /// "语文必修上册.pdf.1" → "语文必修上册.pdf"
  static String? getBaseName(String fileName) {
    if (!fileName.contains('.pdf.')) return null;
    final splitIndex = fileName.indexOf('.pdf.');
    return '${fileName.substring(0, splitIndex)}.pdf';
  }
}
