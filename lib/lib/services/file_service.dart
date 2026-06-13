import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import '../models/question_bank.dart';
import '../utils/file_name_utils.dart';

class FileService {
  String? _lastSelectedFolder;

  String? get lastSelectedFolder => _lastSelectedFolder;

  Future<String> get _defaultDir async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/灵动课堂';
  }

  Future<String> getWorkingDir() async => _lastSelectedFolder ?? await _defaultDir;

  Future<void> setWorkingDir(String path) async {
    _lastSelectedFolder = path;
    final dir = Directory(path);
    if (!await dir.exists()) await dir.create(recursive: true);
  }

  Future<String?> pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) await setWorkingDir(result);
    return result;
  }

  Future<File> saveJson(AppData data, {String? customName}) async {
    final dir = await getWorkingDir();
    final dirObj = Directory(dir);
    if (!await dirObj.exists()) await dirObj.create(recursive: true);
    final fileName = customName ?? generateFileName();
    final file = File('$dir/$fileName');
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data.toJson());
    await file.writeAsString(jsonStr, encoding: utf8);
    return file;
  }

  Future<AppData?> loadJsonFromPath(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    final content = await file.readAsString(encoding: utf8);
    final json = jsonDecode(content) as Map<String, dynamic>;
    return AppData.fromJson(json);
  }

  Future<AppData?> pickAndLoadJson() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.single.path;
    if (path == null) return null;
    return loadJsonFromPath(path);
  }

  Future<List<File>> listArchives(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];
    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) files.add(entity);
    }
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  Future<void> cleanArchives(String dirPath, {int keepRecent = 4, int keepOldest = 1}) async {
    final files = await listArchives(dirPath);
    if (files.length <= keepRecent + keepOldest) return;
    final toDelete = files.sublist(keepRecent, files.length - keepOldest);
    for (final f in toDelete) {
      await f.delete();
    }
  }

  Future<File> exportToZip(AppData data) async {
    final dir = await getWorkingDir();
    final jsonFile = await saveJson(data, customName: 'export_${generateFileName()}');
    final zipPath = '${jsonFile.path}.zip';
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    await encoder.addFile(jsonFile);
    await encoder.close();
    return File(zipPath);
  }
}