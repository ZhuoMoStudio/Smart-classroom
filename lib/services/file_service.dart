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

  Future<String> get _defaultDir async =>
      '${(await getApplicationDocumentsDirectory()).path}/灵动课堂';
  Future<String> getWorkingDir() async => _lastSelectedFolder ?? await _defaultDir;

  Future<void> setWorkingDir(String path) async {
    _lastSelectedFolder = path;
    final d = Directory(path); if (!await d.exists()) await d.create(recursive: true);
  }

  Future<String?> pickFolder() async {
    final r = await FilePicker.getDirectoryPath();
    if (r != null) await setWorkingDir(r); return r;
  }

  Future<File> saveJson(AppData data, {String? customName}) async {
    final dir = await getWorkingDir();
    final d = Directory(dir); if (!await d.exists()) await d.create(recursive: true);
    final f = File('$dir/${customName ?? generateFileName()}');
    await f.writeAsString(const JsonEncoder.withIndent('  ').convert(data.toJson()), encoding: utf8);
    return f;
  }

  Future<AppData?> loadJsonFromPath(String path) async {
    final f = File(path); if (!await f.exists()) return null;
    return AppData.fromJson(jsonDecode(await f.readAsString(encoding: utf8)));
  }

  Future<AppData?> pickAndLoadJson() async {
    final r = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (r == null || r.files.isEmpty) return null;
    final p = r.files.single.path; if (p == null) return null;
    return loadJsonFromPath(p);
  }

  Future<List<File>> listArchives(String dirPath) async {
    final d = Directory(dirPath); if (!await d.exists()) return [];
    final files = <File>[];
    await for (final e in d.list()) { if (e is File && e.path.endsWith('.json')) files.add(e); }
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  Future<void> cleanArchives(String dirPath, {int keepRecent=4, int keepOldest=1}) async {
    final files = await listArchives(dirPath);
    if (files.length <= keepRecent + keepOldest) return;
    for (final f in files.sublist(keepRecent, files.length - keepOldest)) { await f.delete(); }
  }

  Future<File> exportToZip(AppData data) async {
    final dir = await getWorkingDir();
    final jf = await saveJson(data, customName: 'export_${generateFileName()}');
    final zp = '${jf.path}.zip';
    final enc = ZipFileEncoder(); enc.create(zp); await enc.addFile(jf); await enc.close();
    return File(zp);
  }
}
