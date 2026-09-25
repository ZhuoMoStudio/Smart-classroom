import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_log.dart';
import 'excel_service.dart';

/// 文件服务 — 文件夹选择与 xlsx 模板导出
///
/// 约定（与调用方 home_screen 的 _doTmpl 保持一致）：
///   - 成功 → 返回写好的 File，其 path 是**真实位置**（用户选的，或工作区）
///   - 用户取消 → 返回 null
///   - 失败 → **抛出异常**，让调用方显示真实原因，而不是假装成功
class FileService {
  String? _lastSelectedFolder;
  String? get lastSelectedFolder => _lastSelectedFolder;

  /// 工作区根目录。由 DataService 在工作区就绪后注入，
  /// 这样导出失败时的兜底位置落在老师自己的数据文件夹里，
  /// 而不是应用私有目录 —— 后者在文件管理器里根本找不到。
  void setWorkingDir(String path) => _lastSelectedFolder = path;

  Future<String> getWorkingDir() async =>
      _lastSelectedFolder ?? (await getApplicationDocumentsDirectory()).path;

  /// 选择文件夹
  Future<String?> pickFolder() async {
    final r = await FilePicker.platform.getDirectoryPath();
    if (r != null) setWorkingDir(r);
    return r;
  }

  // ==================== 模板导出 ====================

  /// 导出学生名单模板
  Future<File?> exportMemberTemplate() => _export(
        fileName: '学生名单模板.xlsx',
        dialogTitle: '保存学生名单模板',
        build: (path) => ExcelService.exportMemberTemplate(path),
      );

  /// 导出题库模板
  Future<File?> exportQuestionTemplate() => _export(
        fileName: '题库模板.xlsx',
        dialogTitle: '保存题库模板',
        build: (path) => ExcelService.exportQuestionTemplate(path),
      );

  /// 通用导出流程。
  ///
  /// 关键修复：**把字节直接交给 FilePicker.saveFile**，
  /// 而不是先写临时文件、再 File.copy() 到它返回的路径。
  ///
  /// 后者在 Android 11+ 上必然出问题：saveFile 返回的是 Storage Access
  /// Framework 的写入位置，直接用 dart:io 的 File 去 copy 往往没有权限；
  /// 而旧实现把这个异常 `catch (_) {}` 吞掉，接着尝试写
  /// `/storage/emulated/0/Download`（在分区存储下同样不可写，又被吞掉），
  /// 最后悄悄返回应用私有目录里的临时文件 ——
  /// 老师看到「模板已导出」，但在文件管理器里哪里都找不到。
  /// file_picker 的文档明确说：移动端应把 bytes 交给它，由它完成写入。
  Future<File?> _export({
    required String fileName,
    required String dialogTitle,
    required Future<File> Function(String path) build,
  }) async {
    // 1) 先在可写的位置生成 xlsx
    final baseDir = await getWorkingDir();
    final localPath = p.join(baseDir, fileName);
    await Directory(baseDir).create(recursive: true);
    await build(localPath);

    final bytes = await File(localPath).readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('生成的模板为空，请检查磁盘空间');
    }

    // 2) 交给系统「另存为」。移动端由 file_picker 自己写字节，可靠。
    try {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: bytes,
      );
      if (savePath == null) {
        // 返回 null 表示用户取消，不是失败 —— 调用方据此不提示即可
        AppLog.info('导出', '用户取消了 $fileName 的保存');
        return null;
      }
      AppLog.info('导出', '$fileName 已保存到 $savePath');
      return File(savePath);
    } on Exception catch (e, st) {
      // 不吞异常。另存为失败时退回工作区，并把真实路径返回给调用方。
      AppLog.warn('导出', '$fileName 另存为失败，回退到工作区：$e');
      AppLog.error('导出', '另存为异常', e, st);
    }

    // 3) 兜底：文件已经在工作区目录里了，把它当作成功并返回其真实路径。
    final fallback = File(localPath);
    if (await fallback.exists()) {
      return fallback;
    }
    throw Exception('模板写入失败：$localPath');
  }

  /// 供界面判断「这个路径是不是落在我给他选的显式位置」。
  /// 用于给出更准确的提示语。
  Future<bool> isInsideWorkingDir(String path) async {
    final dir = await getWorkingDir();
    return p.isWithin(dir, path) || p.equals(dir, p.dirname(path));
  }

  /// 把 Uint8List 直接交给系统另存为，供将来其它导出功能复用。
  Future<File?> saveBytesAs({
    required Uint8List bytes,
    required String fileName,
    String? dialogTitle,
  }) async {
    try {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle ?? '保存 $fileName',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [p.extension(fileName).replaceFirst('.', '')],
        bytes: bytes,
      );
      return savePath == null ? null : File(savePath);
    } on Exception catch (e) {
      AppLog.warn('导出', 'saveBytesAs 失败：$e');
      return null;
    }
  }
}
