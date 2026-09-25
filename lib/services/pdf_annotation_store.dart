import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Offset;

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'app_log.dart';

/// 一条手写笔迹。
///
/// 坐标全部是 **72dpi 页面空间**的点（pdfrx 里 `PdfPage.width/height` 的单位）。
///
/// 这个选择就是「翻页与缩放都不位移」的机制本身：
/// - 不依赖屏幕坐标 → 换设备、改缩放、翻回上一页，笔迹都落在同一处；
/// - 不写进 PDF 文件 → 老师的教材原件永远不被改动。
class AnnotationStroke {
  final int pageNumber;

  /// 0xAARRGGBB
  final int colorValue;
  final double width;
  final List<Offset> points;

  const AnnotationStroke({
    required this.pageNumber,
    required this.colorValue,
    required this.width,
    required this.points,
  });

  AnnotationStroke copyWith({List<Offset>? points}) => AnnotationStroke(
        pageNumber: pageNumber,
        colorValue: colorValue,
        width: width,
        points: points ?? this.points,
      );

  Map<String, dynamic> toJson() => {
        'p': pageNumber,
        'c': colorValue,
        'w': width,
        // 压成 [[x,y],...] 而不是 {"x":..,"y":..}，体积差一倍以上
        'pts': [
          for (final o in points)
            [
              double.parse(o.dx.toStringAsFixed(2)),
              double.parse(o.dy.toStringAsFixed(2)),
            ],
        ],
      };

  static AnnotationStroke? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final page = raw['p'];
    final color = raw['c'];
    final w = raw['w'];
    final pts = raw['pts'];
    if (page is! int || color is! int) return null;
    if (pts is! List) return null;
    final points = <Offset>[];
    for (final pt in pts) {
      if (pt is List && pt.length >= 2) {
        final x = (pt[0] as num?)?.toDouble();
        final y = (pt[1] as num?)?.toDouble();
        if (x != null && y != null) points.add(Offset(x, y));
      }
    }
    if (points.isEmpty) return null;
    return AnnotationStroke(
      pageNumber: page,
      colorValue: color,
      width: (w as num?)?.toDouble() ?? 2.0,
      points: points,
    );
  }
}

/// 一个文档的全部批注。
class AnnotationDoc {
  final String docId;
  final String sourceName;

  /// 按添加顺序保存。撤销 = 移除最后一条，因此顺序有意义。
  final List<AnnotationStroke> strokes;

  AnnotationDoc({
    required this.docId,
    required this.sourceName,
    List<AnnotationStroke>? strokes,
  }) : strokes = strokes ?? <AnnotationStroke>[];

  List<AnnotationStroke> forPage(int pageNumber) =>
      strokes.where((s) => s.pageNumber == pageNumber).toList();

  Map<String, dynamic> toJson() => {
        'v': 1,
        'doc': sourceName,
        'strokes': [for (final s in strokes) s.toJson()],
      };

  static AnnotationDoc fromJson(String docId, Object? raw) {
    if (raw is! Map) {
      return AnnotationDoc(docId: docId, sourceName: docId);
    }
    final name = (raw['doc'] as String?) ?? docId;
    final list = raw['strokes'];
    final strokes = <AnnotationStroke>[];
    if (list is List) {
      for (final item in list) {
        final s = AnnotationStroke.fromJson(item);
        if (s != null) strokes.add(s);
      }
    }
    return AnnotationDoc(docId: docId, sourceName: name, strokes: strokes);
  }
}

/// 批注的持久化。
///
/// 放在工作区的 `数据存档/批注/` 下，每个文档一个 JSON。
/// 选择 JSON 而不是塞进 xlsx：笔迹是应用内部数据，
/// 没有「让老师用 Excel 打开编辑」的需求，JSON 是最贴合的格式；
/// 而积分/名单继续用 xlsx，因为那两样老师本来就要用 Excel 处理。
class PdfAnnotationStore {
  final String docId;
  final Directory? _dir;
  final AnnotationDoc _doc;

  PdfAnnotationStore._(this.docId, this._dir, this._doc);

  AnnotationDoc get doc => _doc;
  List<AnnotationStroke> get strokes => _doc.strokes;
  bool get hasUnsavedChanges => _dirty;
  bool _dirty = false;

  /// 取某一页的笔迹。
  ///
  /// 这个方法放在 store 上，而不是让调用方去 `store.doc.forPage(...)`：
  /// 阅读器只需要「给定页码拿到笔迹」，暴露内部的 AnnotationDoc 是多此一举。
  /// （第一版就是漏了这一层，导致 pdf_reader_screen 里 `store.forPage(...)`
  /// 编译不过、整个 Build & Release 变红，测试也跟着编译失败。）
  List<AnnotationStroke> forPage(int pageNumber) => _doc.forPage(pageNumber);

  /// 用文档来源名生成稳定的 docId。
  /// 两份同名教材在不同目录下会被视为同一份 —— 这是刻意的：
  /// 老师看到的是「同一本书」，批注跟着书走更符合直觉。
  static String docIdOf(String sourceName) {
    final digest = sha1.convert(utf8.encode(sourceName));
    return digest.toString().substring(0, 16);
  }

  /// 打开（或新建）某个文档的批注。
  ///
  /// [archiveDir] 通常是工作区的 `数据存档`；为 null 时退化为仅内存模式，
  /// 这样即使老师没设置工作目录，批注功能本身也能用（只是不落盘）。
  static Future<PdfAnnotationStore> open({
    required String sourceName,
    String? archiveDir,
  }) async {
    final docId = docIdOf(sourceName);
    Directory? dir;
    if (archiveDir != null && archiveDir.isNotEmpty) {
      try {
        dir = Directory(p.join(archiveDir, '批注'));
        if (!await dir.exists()) await dir.create(recursive: true);
      } catch (e, st) {
        AppLog.error('批注', '创建批注目录失败', e, st);
        dir = null;
      }
    }

    AnnotationDoc doc;
    if (dir == null) {
      doc = AnnotationDoc(docId: docId, sourceName: sourceName);
    } else {
      final f = File(p.join(dir.path, '$docId.json'));
      try {
        if (await f.exists()) {
          doc = AnnotationDoc.fromJson(
              docId, jsonDecode(await f.readAsString()));
          AppLog.info('批注', '已载入 ${doc.strokes.length} 条笔迹（$sourceName）');
        } else {
          doc = AnnotationDoc(docId: docId, sourceName: sourceName);
        }
      } catch (e, st) {
        // 损坏的批注文件不能让阅读器直接打不开，退回空批注并留痕
        AppLog.error('批注', '读取批注失败，将以空批注继续', e, st);
        doc = AnnotationDoc(docId: docId, sourceName: sourceName);
      }
    }

    return PdfAnnotationStore._(docId, dir, doc);
  }

  void add(AnnotationStroke stroke) {
    _doc.strokes.add(stroke);
    _dirty = true;
  }

  /// 撤销最后一条（跨页全局撤销，符合「撤销刚才那一笔」的直觉）
  AnnotationStroke? undoLast() {
    if (_doc.strokes.isEmpty) return null;
    _dirty = true;
    return _doc.strokes.removeLast();
  }

  int clearPage(int pageNumber) {
    final before = _doc.strokes.length;
    _doc.strokes.removeWhere((s) => s.pageNumber == pageNumber);
    final removed = before - _doc.strokes.length;
    if (removed > 0) _dirty = true;
    return removed;
  }

  int clearAll() {
    final n = _doc.strokes.length;
    if (n > 0) {
      _doc.strokes.clear();
      _dirty = true;
    }
    return n;
  }

  /// 橡皮：删除所有「有点落在该位置附近」的笔迹。
  /// [position] 与 [radius] 都用 72dpi 页面空间（与笔迹同一坐标系）。
  int eraseAt(int pageNumber, Offset position, double radius) {
    final before = _doc.strokes.length;
    _doc.strokes.removeWhere((s) {
      if (s.pageNumber != pageNumber) return false;
      for (final pt in s.points) {
        if ((pt - position).distance <= radius) return true;
      }
      return false;
    });
    final removed = before - _doc.strokes.length;
    if (removed > 0) _dirty = true;
    return removed;
  }

  Future<void> save() async {
    final dir = _dir;
    if (dir == null) {
      _dirty = false;
      return;
    }
    try {
      final f = File(p.join(dir.path, '$docId.json'));
      // 先写临时文件再改名，避免中途崩溃留下半截 JSON
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(jsonEncode(_doc.toJson()), flush: true);
      await tmp.rename(f.path);
      _dirty = false;
    } catch (e, st) {
      AppLog.error('批注', '保存批注失败', e, st);
    }
  }

  int get strokeCount => _doc.strokes.length;
}
