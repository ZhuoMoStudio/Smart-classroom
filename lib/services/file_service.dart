import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import '../models/question_bank.dart';
import '../utils/file_name_utils.dart';
import 'excel_service.dart';
import 'usb_detector.dart';
import 'roster_smart_manager.dart';

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

  /// 自动检测并设置 USB data 文件夹为工作目录
  Future<String?> autoDetectUsb() async {
    final usbPath = await UsbDetector.findUsbDataFolder();
    if (usbPath != null) {
      await setWorkingDir(usbPath);
      return usbPath;
    }
    return null;
  }

  /// 解析数据目录（USB 优先 → 用户指定 → 默认）
  Future<String> resolveDataDir(String? userPath) async {
    final path = await UsbDetector.resolveDataDir(userPath);
    await setWorkingDir(path);
    return path;
  }

  Future<String?> pickFolder() async {
    final r = await FilePicker.platform.getDirectoryPath();
    if (r != null) await setWorkingDir(r);
    return r;
  }

  // ==================== JSON 保存/加载 ====================
  Future<File> saveJson(AppData data, {String? customName}) async {
    final dir = await getWorkingDir();
    final d = Directory(dir);
    if (!await d.exists()) await d.create(recursive: true);
    final f = File('$dir/${customName ?? generateFileName()}');
    await f.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data.toJson()),
      encoding: utf8,
    );
    return f;
  }

  Future<AppData?> loadJsonFromPath(String path) async {
    final f = File(path);
    if (!await f.exists()) return null;
    return AppData.fromJson(jsonDecode(await f.readAsString(encoding: utf8)));
  }

  Future<AppData?> pickAndLoadJson() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (r == null || r.files.isEmpty) return null;
    final p = r.files.single.path;
    if (p == null) return null;
    return loadJsonFromPath(p);
  }

  // ==================== Excel 模板导出 ====================
  /// 导出学生名单模板到工作目录
  Future<File> exportMemberTemplate() async {
    final dir = await getWorkingDir();
    final path = '$dir/学生名单模板.xlsx';
    return ExcelService.exportMemberTemplate(path);
  }

  /// 导出题库模板到工作目录
  Future<File> exportQuestionTemplate() async {
    final dir = await getWorkingDir();
    final path = '$dir/题库模板.xlsx';
    return ExcelService.exportQuestionTemplate(path);
  }

  // ==================== Excel 积分导入/导出 ====================
  /// 导出积分到 Excel
  Future<File> exportScores(AppData data) async {
    final dir = await getWorkingDir();
    final path = '$dir/积分数据_${_timestamp()}.xlsx';
    return ExcelService.exportScores(data.classrooms, path);
  }

  /// 从 Excel 导入积分
  Future<Map<String, Map<String, Map<String, double>>>> importScores() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (r == null || r.files.isEmpty) {
      throw Exception('未选择文件');
    }
    final p = r.files.single.path;
    if (p == null) throw Exception('文件路径无效');
    return ExcelService.importScores(p);
  }

  // ==================== 文件列表管理 ====================
  Future<List<File>> listArchives(String dirPath) async {
    final d = Directory(dirPath);
    if (!await d.exists()) return [];
    final files = <File>[];
    await for (final e in d.list()) {
      if (e is File && e.path.endsWith('.json')) files.add(e);
    }
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  Future<void> cleanArchives(
    String dirPath, {
    int keepRecent = 4,
    int keepOldest = 1,
  }) async {
    final files = await listArchives(dirPath);
    if (files.length <= keepRecent + keepOldest) return;

    // 保留最近的 keepRecent 个和最早的 keepOldest 个，删除中间
    final toDelete = files.sublist(keepRecent, files.length - keepOldest);
    for (final f in toDelete) {
      await f.delete();
    }
  }

  /// 自动清理：
  /// - JSON: 保留最近 5 个和最远 1 个
  /// - xlsx 名单: 按年级班级分组，每组保留最初始 1 个 + 最近 5 个
  /// - xlsx 题库: 全部保留
  Future<void> autoCleanup(String dirPath) async {
    final d = Directory(dirPath);
    if (!await d.exists()) return;

    // JSON 文件：保留最近 5 个 + 最远 1 个
    final jsonFiles = <File>[];
    await for (final e in d.list()) {
      if (e is File && e.path.endsWith('.json')) jsonFiles.add(e);
    }
    jsonFiles.sort(
      (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
    );
    if (jsonFiles.length > 6) {
      final keep = <File>{};
      keep.addAll(jsonFiles.take(5));
      keep.add(jsonFiles.last);
      for (final f in jsonFiles) {
        if (!keep.contains(f)) await f.delete();
      }
    }

    // xlsx 文件：使用名单智能识别清理
    await RosterSmartManager.smartCleanup(dirPath);
  }

  Future<File> exportToZip(AppData data) async {
    final dir = await getWorkingDir();
    final jf = await saveJson(data, customName: 'export_${generateFileName()}');
    final zp = '${jf.path}.zip';
    final enc = ZipFileEncoder();
    enc.create(zp);
    await enc.addFile(jf);
    await enc.close();
    return File(zp);
  }

  String _timestamp() {
    final n = DateTime.now();
    return '${n.year}-${_p(n.month)}-${_p(n.day)}_${_p(n.hour)}-${_p(n.minute)}-${_p(n.second)}';
  }

  String _p(int n) => n.toString().padLeft(2, '0');
}
