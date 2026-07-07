import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'excel_service.dart';

/// 文件服务 — 仅负责文件夹选择和 xlsx 模板导出/导入
/// v1.26: 移除所有 JSON 序列化功能，积分数据仅存在于 xlsx
class FileService {
  String? _lastSelectedFolder;
  String? get lastSelectedFolder => _lastSelectedFolder;

  Future<String> get _defaultDir async =>
      '${(await getApplicationDocumentsDirectory()).path}/灵动课堂';

  Future<String> getWorkingDir() async =>
      _lastSelectedFolder ?? await _defaultDir;

  Future<void> setWorkingDir(String path) async {
    _lastSelectedFolder = path;
    final d = Directory(path);
    if (!await d.exists()) await d.create(recursive: true);
  }

  /// 选择文件夹
  Future<String?> pickFolder() async {
    final r = await FilePicker.platform.getDirectoryPath();
    if (r != null) await setWorkingDir(r);
    return r;
  }

  // ==================== xlsx 模板导出（兼容 Android） ====================

  /// 导出学生名单模板
  /// Android: 优先 FilePicker.saveFile，降级写入公共 Downloads 目录
  Future<File?> exportMemberTemplate() async {
    final tempDir = await _defaultDir;
    final tempPath = '$tempDir/学生名单模板.xlsx';
    await Directory(tempDir).create(recursive: true);
    await ExcelService.exportMemberTemplate(tempPath);

    // 方案1：FilePicker.saveFile
    try {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: '保存学生名单模板',
        fileName: '学生名单模板.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (savePath != null) {
        final source = File(tempPath);
        if (await source.exists()) {
          await source.copy(savePath);
          return File(savePath);
        }
      }
    } catch (_) {}

    // 方案2：写入公共 Downloads 目录（Android 降级）
    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        final destPath = '${downloadsDir.path}/学生名单模板.xlsx';
        final source = File(tempPath);
        if (await source.exists()) {
          await source.copy(destPath);
          return File(destPath);
        }
      }
    } catch (_) {}

    // 方案3：返回临时文件
    final source = File(tempPath);
    if (await source.exists()) return source;
    return null;
  }

  /// 导出题库模板
  Future<File?> exportQuestionTemplate() async {
    final tempDir = await _defaultDir;
    final tempPath = '$tempDir/题库模板.xlsx';
    await Directory(tempDir).create(recursive: true);
    await ExcelService.exportQuestionTemplate(tempPath);

    try {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: '保存题库模板',
        fileName: '题库模板.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (savePath != null) {
        final source = File(tempPath);
        if (await source.exists()) {
          await source.copy(savePath);
          return File(savePath);
        }
      }
    } catch (_) {}

    try {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        final destPath = '${downloadsDir.path}/题库模板.xlsx';
        final source = File(tempPath);
        if (await source.exists()) {
          await source.copy(destPath);
          return File(destPath);
        }
      }
    } catch (_) {}

    final source = File(tempPath);
    if (await source.exists()) return source;
    return null;
  }
}
