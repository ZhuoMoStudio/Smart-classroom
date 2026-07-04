import 'dart:ui' show Offset;
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// 一笔笔画的数据模型
class AnnotationStroke {
  final List<Offset> points;
  final Color color;
  final double thickness;
  final bool isEraser;

  const AnnotationStroke({
    required this.points,
    required this.color,
    required this.thickness,
    this.isEraser = false,
  });

  AnnotationStroke copyWith({List<Offset>? points}) =>
      AnnotationStroke(points: points ?? this.points, color: color, thickness: thickness);
}

/// 每页的标注数据
class PageAnnotations {
  final int pageNumber;
  final List<AnnotationStroke> strokes;

  const PageAnnotations({required this.pageNumber, this.strokes = const []});

  PageAnnotations copyWith({List<AnnotationStroke>? strokes}) =>
      PageAnnotations(pageNumber: pageNumber, strokes: strokes ?? this.strokes);
}

/// 标注模式
enum AnnotMode { pen, arrow }

/// 标注控制器 — 管理所有页面的笔迹，跨页标注支持
class AnnotationController extends ChangeNotifier {
  final Map<int, PageAnnotations> _pages = {};
  AnnotationStroke? _currentStroke;
  int _currentPage = 1;
  // 当前模式
  AnnotMode mode = AnnotMode.pen;
  // 笔刷设置
  Color penColor = const Color(0xFFE74C3C);
  double penThickness = 3.0;
  // 橡皮擦设置
  double eraserSize = 20.0;
  // 节流
  int _lastNotify = 0;
  static const int _throttleMs = 16; // ~60fps

  static const List<double> thicknessPresets = [1.0, 2.0, 3.0, 5.0, 8.0];
  static const List<double> eraserPresets = [10.0, 20.0, 30.0, 50.0];
  static const List<Color> penColors = [
    Color(0xFFE74C3C), Color(0xFF3498DB), Color(0xFF2ECC71),
    Color(0xFFF39C12), Color(0xFF9B59B6), Color(0xFF1ABC9C),
    Color(0xFF34495E), Color(0xFFE91E63),
  ];

  bool get isPenMode => mode == AnnotMode.pen;
  bool get isArrowMode => mode == AnnotMode.arrow;

  int get currentPage => _currentPage;
  List<AnnotationStroke> get currentStrokes => _pages[_currentPage]?.strokes ?? [];

  void setPage(int page) { _currentPage = page; }

  void toggleMode() {
    mode = mode == AnnotMode.pen ? AnnotMode.arrow : AnnotMode.pen;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastNotify < _throttleMs && _currentStroke != null) return;
    _lastNotify = now;
    super.notifyListeners();
  }

  void startStroke(Offset point) {
    if (!isPenMode) return;
    _currentStroke = AnnotationStroke(
      points: [point], color: penColor, thickness: penThickness,
    );
  }

  void addPoint(Offset point) {
    if (_currentStroke == null) return;
    _currentStroke = _currentStroke!.copyWith(points: [..._currentStroke!.points, point]);
    notifyListeners();
  }

  void endStroke() {
    if (_currentStroke == null) return;
    final strokes = [...currentStrokes, _currentStroke!];
    _pages[_currentPage] = PageAnnotations(pageNumber: _currentPage, strokes: strokes);
    _currentStroke = null;
    _lastNotify = 0;
    super.notifyListeners();
  }

  /// 橡皮擦：擦除某点附近的笔迹
  void eraseAt(Offset point) {
    final existing = currentStrokes;
    if (existing.isEmpty) return;
    final remaining = <AnnotationStroke>[];
    for (final stroke in existing) {
      final radius = eraserSize;
      bool hit = false;
      for (final sp in stroke.points) {
        if ((sp - point).distance < radius) { hit = true; break; }
      }
      if (!hit) remaining.add(stroke);
    }
    _pages[_currentPage] = PageAnnotations(pageNumber: _currentPage, strokes: remaining);
    notifyListeners();
  }

  void undoLastStroke() {
    final strokes = currentStrokes;
    if (strokes.isEmpty) return;
    _pages[_currentPage] = PageAnnotations(pageNumber: _currentPage, strokes: strokes.sublist(0, strokes.length - 1));
    notifyListeners();
  }

  void clearPage() {
    _pages.remove(_currentPage);
    notifyListeners();
  }

  AnnotationStroke? get currentDrawingStroke => _currentStroke;

  /// 获取某页所有笔迹（包括正在画的），支持跨页
  List<AnnotationStroke> getStrokesForPage(int page) {
    final strokes = _pages[page]?.strokes ?? [];
    if (page == _currentPage && _currentStroke != null) {
      return [...strokes, _currentStroke!];
    }
    return strokes;
  }
}

/// PDF 标注工具栏
class AnnotationToolbar extends StatelessWidget {
  final AnnotationController controller;
  final VoidCallback onClose;
  const AnnotationToolbar({super.key, required this.controller, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isPen = controller.isPenMode;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.level2,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // 模式切换行
            Row(mainAxisSize: MainAxisSize.min, children: [
              _modeBtn(Icons.edit, '笔', isPen, () => controller.mode = AnnotMode.pen),
              const SizedBox(width: 4),
              _modeBtn(Icons.pan_tool, '箭头', !isPen, () => controller.mode = AnnotMode.arrow),
              const SizedBox(width: 8),
              if (isPen) ...[
                // 颜色
                ...AnnotationController.penColors.map((c) => GestureDetector(
                  onTap: () { controller.penColor = c; controller.notifyListeners(); },
                  child: Container(
                    width: 24, height: 24, margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: c, shape: BoxShape.circle,
                      border: controller.penColor == c ? Border.all(color: Colors.white, width: 2) : null,
                    ),
                    child: controller.penColor == c ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                  ),
                )),
                const SizedBox(width: 6),
                // 粗细预设
                ...AnnotationController.thicknessPresets.map((t) => GestureDetector(
                  onTap: () { controller.penThickness = t; controller.notifyListeners(); },
                  child: Container(
                    width: 20, height: 20, margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: controller.penThickness == t ? controller.penColor.withOpacity(0.15) : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(child: Container(width: t.clamp(2, 18), height: t.clamp(2, 18),
                      decoration: BoxDecoration(color: controller.penColor, shape: BoxShape.circle))),
                  ),
                )),
                // 粗细滑条
                SizedBox(width: 50, child: SliderTheme(data: SliderThemeData(
                  trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                ), child: Slider(
                  value: controller.penThickness, min: 0.5, max: 12.0, divisions: 23,
                  onChanged: (v) { controller.penThickness = v; controller.notifyListeners(); },
                ))),
                // 预览
                Container(width: 20, height: 20, alignment: Alignment.center,
                  child: Container(width: controller.penThickness.clamp(1, 20), height: controller.penThickness.clamp(1, 20),
                    decoration: BoxDecoration(color: controller.penColor, shape: BoxShape.circle))),
              ],
            ]),
            const SizedBox(height: 6),
            // 操作行
            Row(mainAxisSize: MainAxisSize.min, children: [
              _actionBtn(Icons.undo, '撤销', controller.undoLastStroke),
              const SizedBox(width: 4),
              // 清屏：滑条确认
              _ClearSlider(onClear: controller.clearPage),
              const SizedBox(width: 4),
              // 橡皮擦大小
              GestureDetector(
                onTap: () => _showEraserPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.auto_fix_high, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('擦${controller.eraserSize.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ]),
                ),
              ),
              const SizedBox(width: 4),
              _actionBtn(Icons.close, '完成', onClose),
            ]),
          ]),
        );
      },
    );
  }

  Widget _modeBtn(IconData icon, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.withOpacity(0.12) : null,
          borderRadius: BorderRadius.circular(8),
          border: selected ? Border.all(color: Colors.blue.withOpacity(0.3)) : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: selected ? Colors.blue : Colors.grey),
          const SizedBox(width: 2),
          Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.blue : Colors.grey, fontWeight: selected ? FontWeight.w600 : null)),
        ]),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return TextButton.icon(
      icon: Icon(icon, size: 14), label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    );
  }

  void _showEraserPicker(BuildContext context) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text('橡皮擦大小', style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 260, height: 60,
        child: Column(children: [
          Slider(
            value: controller.eraserSize, min: 5, max: 80, divisions: 15,
            label: '${controller.eraserSize.toStringAsFixed(0)}px',
            onChanged: (v) { controller.eraserSize = v; controller.notifyListeners(); },
          ),
          Text('${controller.eraserSize.toStringAsFixed(0)}px', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('确定'))],
    ));
  }
}

/// 滑条确认清屏
class _ClearSlider extends StatefulWidget {
  final VoidCallback onClear;
  const _ClearSlider({required this.onClear});
  @override State<_ClearSlider> createState() => _ClearSliderState();
}

class _ClearSliderState extends State<_ClearSlider> {
  double _value = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          activeTrackColor: _value > 0.95 ? Colors.red : Colors.grey,
          inactiveTrackColor: Colors.grey.withOpacity(0.2),
        ),
        child: Slider(
          value: _value, min: 0, max: 1.0,
          onChanged: (v) => setState(() => _value = v),
          onChangeEnd: (v) {
            if (v > 0.95) {
              widget.onClear();
              setState(() => _value = 0);
            } else {
              setState(() => _value = 0);
            }
          },
        ),
      ),
    );
  }
}
