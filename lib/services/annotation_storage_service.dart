import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Offset, Color;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/pdf_annotation.dart';

/// 标注持久化存储服务
///
/// 支持两种存储模式：
/// 1. alongside（与PDF同目录，以 .annot.json 后缀保存）
/// 2. appPrivate（保存在应用私有目录，按PDF文件名索引）
class AnnotationStorageService {
  static const String _storageModeKey = 'annotation_storage_mode';
  static const String _annotDirName = 'pdf_annotations';
  static const String _indexFileName = 'annotation_index.json';

  // ==================== 存储模式 ====================

  /// 获取当前存储模式
  static Future<String> getStorageMode() async {
    // 默认 alongside 模式
    final prefs = await SharedPreferencesHelper.getInstance();
    return prefs.getString(_storageModeKey) ?? 'alongside';
  }

  /// 设置存储模式
  static Future<void> setStorageMode(String mode) async {
    final prefs = await SharedPreferencesHelper.getInstance();
    await prefs.setString(_storageModeKey, mode);
  }

  // ==================== 路径计算 ====================

  /// 获取标注文件路径（根据当前模式）
  static Future<String> getAnnotationPath({
    required String pdfPath,
    String? pdfUrl,
  }) async {
    final mode = await getStorageMode();

    if (mode == 'appPrivate') {
      // 应用私有目录
      final dir = await _getPrivateAnnotDir();
      final name = pdfUrl != null
          ? _safeFileName(pdfUrl)
          : '${_safeFileName(pdfPath)}.annot.json';
      return '$dir/$name';
    } else {
      // 与PDF同目录
      final file = File(pdfPath);
      final dir = file.parent.path;
      final name = '${file.uri.pathSegments.last}.annot.json';
      return '$dir/$name';
    }
  }

  /// 获取应用私有标注目录
  static Future<String> _getPrivateAnnotDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = '${docsDir.path}/$_annotDirName';
    final d = Directory(dir);
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    return dir;
  }

  /// 将标注转换为可序列化Map
  static Map<String, dynamic> _strokeToJson(AnnotationStroke stroke) {
    return {
      'points': stroke.points
          .map((p) => {'dx': p.dx, 'dy': p.dy})
          .toList(),
      'color': stroke.color.value,
      'thickness': stroke.thickness,
      'isEraser': stroke.isEraser,
    };
  }

  static AnnotationStroke _strokeFromJson(Map<String, dynamic> json) {
    return AnnotationStroke(
      points: (json['points'] as List)
          .map((p) => Offset(
                (p['dx'] as num).toDouble(),
                (p['dy'] as num).toDouble(),
              ))
          .toList(),
      color: Color(json['color'] as int),
      thickness: (json['thickness'] as num).toDouble(),
      isEraser: json['isEraser'] as bool? ?? false,
    );
  }

  /// 将图层数据转换为可序列化Map
  static Map<String, dynamic> _layerToJson(AnnotationLayer layer) {
    return {
      'id': layer.id,
      'name': layer.name,
      'visible': layer.visible,
      'locked': layer.locked,
      'strokes': layer.strokes.map(_strokeToJson).toList(),
    };
  }

  static AnnotationLayer _layerFromJson(Map<String, dynamic> json) {
    return AnnotationLayer(
      id: json['id'] as String? ?? _uuid(),
      name: json['name'] as String? ?? '图层',
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      strokes: (json['strokes'] as List?)
              ?.map((s) => _strokeFromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 将页面标注数据转换为可序列化Map
  static Map<String, dynamic> _pageAnnotToJson(PageAnnotations page) {
    return {
      'pageNumber': page.pageNumber,
      'activeLayerIndex': page.activeLayerIndex,
      'layers': page.layers.map(_layerToJson).toList(),
    };
  }

  static PageAnnotations _pageAnnotFromJson(Map<String, dynamic> json) {
    return PageAnnotations(
      pageNumber: json['pageNumber'] as int,
      activeLayerIndex: json['activeLayerIndex'] as int? ?? 0,
      layers: (json['layers'] as List?)
              ?.map((l) => _layerFromJson(l as Map<String, dynamic>))
              .toList() ??
          [AnnotationLayer(id: _uuid(), name: '图层 1')],
    );
  }

  // ==================== 保存标注 ====================

  /// 保存所有页面的标注数据
  static Future<bool> saveAnnotations({
    required String pdfPath,
    String? pdfUrl,
    required Map<int, PageAnnotations> pages,
  }) async {
    try {
      final annotPath = await getAnnotationPath(pdfPath: pdfPath, pdfUrl: pdfUrl);

      final data = {
        'version': 2,
        'pdfPath': pdfPath,
        'savedAt': DateTime.now().toIso8601String(),
        'pages': pages.values.map(_pageAnnotToJson).toList(),
      };

      final file = File(annotPath);
      await file.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
        encoding: utf8,
      );

      // 更新索引（appPrivate模式下需要）
      final mode = await getStorageMode();
      if (mode == 'appPrivate') {
        await _updateIndex(pdfPath, annotPath);
      }

      return true;
    } catch (e) {
      debugPrint('保存标注失败: $e');
      return false;
    }
  }

  // ==================== 加载标注 ====================

  /// 加载所有页面的标注数据
  static Future<Map<int, PageAnnotations>?> loadAnnotations({
    required String pdfPath,
    String? pdfUrl,
  }) async {
    try {
      final annotPath = await getAnnotationPath(pdfPath: pdfPath, pdfUrl: pdfUrl);
      final file = File(annotPath);

      if (!await file.exists()) return null;

      final content = await file.readAsString(encoding: utf8);
      final data = jsonDecode(content) as Map<String, dynamic>;

      final pages = <int, PageAnnotations>{};
      final pagesList = data['pages'] as List? ?? [];
      for (final p in pagesList) {
        final page = _pageAnnotFromJson(p as Map<String, dynamic>);
        pages[page.pageNumber] = page;
      }

      return pages;
    } catch (e) {
      debugPrint('加载标注失败: $e');
      return null;
    }
  }

  // ==================== 索引管理（appPrivate模式） ====================

  /// 更新索引文件
  static Future<void> _updateIndex(String pdfPath, String annotPath) async {
    try {
      final dir = await _getPrivateAnnotDir();
      final indexFile = File('$dir/$_indexFileName');

      Map<String, dynamic> index = {};
      if (await indexFile.exists()) {
        final content = await indexFile.readAsString(encoding: utf8);
        index = jsonDecode(content) as Map<String, dynamic>;
      }

      index[pdfPath] = {
        'annotPath': annotPath,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await indexFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(index),
        encoding: utf8,
      );
    } catch (e) {
      debugPrint('更新索引失败: $e');
    }
  }

  /// 获取所有已标注的PDF列表
  static Future<List<String>> getAnnotatedPdfList() async {
    try {
      final dir = await _getPrivateAnnotDir();
      final indexFile = File('$dir/$_indexFileName');

      if (!await indexFile.exists()) return [];

      final content = await indexFile.readAsString(encoding: utf8);
      final index = jsonDecode(content) as Map<String, dynamic>;
      return index.keys.toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== 工具方法 ====================

  /// 安全文件名
  static String _safeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  static int _counter = DateTime.now().microsecondsSinceEpoch;
  static String _uuid() => 'layer_${++_counter}';

  /// 删除标注文件
  static Future<bool> deleteAnnotations({
    required String pdfPath,
    String? pdfUrl,
  }) async {
    try {
      final annotPath = await getAnnotationPath(pdfPath: pdfPath, pdfUrl: pdfUrl);
      final file = File(annotPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 检查某PDF是否有标注
  static Future<bool> hasAnnotations({
    required String pdfPath,
    String? pdfUrl,
  }) async {
    final annotPath = await getAnnotationPath(pdfPath: pdfPath, pdfUrl: pdfUrl);
    return await File(annotPath).exists();
  }
}

/// 简易SharedPreferences封装（避免直接依赖）
class SharedPreferencesHelper {
  static final Map<String, dynamic> _memory = {};
  static SharedPreferencesHelper? _instance;

  factory SharedPreferencesHelper.getInstance() => _instance ??= SharedPreferencesHelper._();
  SharedPreferencesHelper._();

  String getString(String key, [String defaultValue = '']) {
    return _memory[key]?.toString() ?? defaultValue;
  }

  Future<void> setString(String key, String value) async {
    _memory[key] = value;
  }
}


