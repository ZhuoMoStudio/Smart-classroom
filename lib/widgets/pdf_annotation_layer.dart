import 'package:flutter/material.dart';

import '../services/pdf_annotation_store.dart';

/// 绘制已提交的批注笔迹。
///
/// 输入坐标是 72dpi 页面空间，[scale] 是「屏幕上的一页宽 / 页面实际宽」，
/// 也就是 pdfrx 的缩放比。乘上它之后就落到屏幕坐标系。
class AnnotationPainter extends CustomPainter {
  final List<AnnotationStroke> strokes;
  final double scale;

  const AnnotationPainter({required this.strokes, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      final color = Color(s.colorValue);
      final strokeWidth = (s.width * scale).clamp(0.5, 400.0);

      // 单点：点一下就是想点个点，画成圆点而不是看不见的零长度线
      if (s.points.length == 1) {
        final o = s.points.first;
        canvas.drawCircle(
          Offset(o.dx * scale, o.dy * scale),
          strokeWidth / 2,
          Paint()..color = color,
        );
        continue;
      }

      final path = Path()
        ..moveTo(s.points.first.dx * scale, s.points.first.dy * scale);
      for (int i = 1; i < s.points.length; i++) {
        path.lineTo(s.points[i].dx * scale, s.points[i].dy * scale);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.scale != scale;
}

/// 覆盖在单页之上的一层批注层。
///
/// 它同时承担两件事：显示这一页的笔迹，以及在批注模式下接收手势。
///
/// 为什么把「正在画的那一笔」放在自己的 State 里而不是交给上层：
/// 页面叠加层是由 `PdfViewer` 在构建时调用的，手势每移动一次都去
/// `setState` 上层，就会每帧重建整个 PdfViewer —— 手写会明显掉帧。
/// 放在这里，则只有这一小块重绘；抬笔时才把整笔交给上层一次。
class PageAnnotationOverlay extends StatefulWidget {
  /// 页码（pdfrx 的 PdfPage.pageNumber，从 1 开始）
  final int pageNumber;

  /// 页面在 72dpi 下的宽高（来自 pdfrx 的 PdfPage）
  final double pageWidth;
  final double pageHeight;

  /// 屏幕上一页的宽高，用于推导缩放比
  final double viewWidth;
  final double viewHeight;

  final List<AnnotationStroke> strokes;
  final bool annotating;
  final bool erasing;
  final int penColor;
  final double penWidth;

  final void Function(AnnotationStroke stroke) onStrokeCommitted;
  final void Function(Offset pagePoint) onErase;

  const PageAnnotationOverlay({
    super.key,
    required this.pageNumber,
    required this.pageWidth,
    required this.pageHeight,
    required this.viewWidth,
    required this.viewHeight,
    required this.strokes,
    required this.annotating,
    required this.erasing,
    required this.penColor,
    required this.penWidth,
    required this.onStrokeCommitted,
    required this.onErase,
  });

  @override
  State<PageAnnotationOverlay> createState() => _PageAnnotationOverlayState();
}

class _PageAnnotationOverlayState extends State<PageAnnotationOverlay> {
  /// 本页正在画的这一笔
  List<Offset>? _drawing;

  /// 已交上去、但上层还没回传给我们的笔迹。
  /// 保留它是为了避免「抬笔那一帧笔迹消失」的闪烁。
  final List<AnnotationStroke> _pending = [];

  double get _scale =>
      widget.pageWidth <= 0 ? 1.0 : widget.viewWidth / widget.pageWidth;

  @override
  void didUpdateWidget(covariant PageAnnotationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 上层把新的 strokes 传回来了，本地缓存里那些已经出现的就可以丢掉。
    // AnnotationStroke 没有重写 ==，所以 contains 走的是同一性比较 ——
    // 上层传回来的正是我们交出去的那个实例。
    if (_pending.isNotEmpty) {
      _pending.removeWhere(widget.strokes.contains);
    }
  }

  Offset _toPage(Offset local) =>
      Offset(local.dx / _scale, local.dy / _scale);

  void _commitPoints(List<Offset>? pts) {
    if (pts == null || pts.isEmpty) {
      setState(() => _drawing = null);
      return;
    }
    final stroke = AnnotationStroke(
      pageNumber: widget.pageNumber,
      colorValue: widget.penColor,
      width: widget.penWidth,
      points: List<Offset>.unmodifiable(pts),
    );
    setState(() {
      _drawing = null;
      _pending.add(stroke);
    });
    widget.onStrokeCommitted(stroke);
  }

  @override
  Widget build(BuildContext context) {
    final all = <AnnotationStroke>[...widget.strokes, ..._pending];
    final drawing = _drawing;
    if (drawing != null) {
      all.add(AnnotationStroke(
        pageNumber: widget.pageNumber,
        colorValue: widget.penColor,
        width: widget.penWidth,
        points: drawing,
      ));
    }

    final layer = CustomPaint(
      size: Size(widget.viewWidth, widget.viewHeight),
      painter: AnnotationPainter(strokes: all, scale: _scale),
    );

    if (!widget.annotating) return layer;

    // 批注模式下接管手势。
    // pdfrx 的文档明确说：放在叠加层里的 GestureDetector 会「吃掉」手势，
    // 因此 viewer 不会同时平移；调用方还会把 panEnabled 一并关掉，
    // 双保险，避免笔画与页面滚动互相打架。
    //
    // 注意这里用 onTapUp 而不是 onTapDown 来画单点：
    // onTapDown 在拖拽开始时也会先触发一次，导致每一笔的开头多出一个杂点。
    // Tap 与 Pan 在手势竞技场里互斥 —— 一旦移动超过 slop，tap 会被取消
    // 并走 onTapCancel，两者不会同时生效。
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) {
        if (widget.erasing) return;
        setState(() => _drawing = [_toPage(d.localPosition)]);
      },
      onPanUpdate: (d) {
        if (widget.erasing) {
          widget.onErase(_toPage(d.localPosition));
          return;
        }
        final pts = _drawing;
        if (pts == null) return;
        setState(() => pts.add(_toPage(d.localPosition)));
      },
      onPanEnd: (_) => _commitPoints(_drawing),
      onPanCancel: () => _commitPoints(_drawing),
      onTapUp: (d) {
        final pagePoint = _toPage(d.localPosition);
        if (widget.erasing) {
          widget.onErase(pagePoint);
        } else {
          _commitPoints([pagePoint]);
        }
      },
      child: layer,
    );
  }
}
