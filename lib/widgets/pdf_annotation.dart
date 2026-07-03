import 'dart:ui' show Offset;
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// 一笔笔画的数据模型
class AnnotationStroke {
  final List<Offset> points;
  final Color color;
  final double thickness;

  const AnnotationStroke({
    required this.points,
    required this.color,
    required this.thickness,
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

/// 标注控制器 — 管理所有页面的笔迹
class AnnotationController extends ChangeNotifier {
  final Map<int, PageAnnotations> _pages = {};
  AnnotationStroke? _currentStroke;
  int _currentPage = 1;

  // 当前笔刷设置
  Color penColor = const Color(0xFFE74C3C);
  double penThickness = 3.0;
  bool isEraser = false;

  // 节流优化：最多每20ms通知一次，减少频繁重绘
  int _lastNotify = 0;
  static const int _throttleMs = 20;

  @override
  void notifyListeners() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastNotify < _throttleMs && _currentStroke != null) return;
    _lastNotify = now;
    super.notifyListeners();
  }

  // 预设笔刷粗细
  static const List<double> thicknessPresets = [1.0, 2.0, 3.0, 5.0, 8.0];

  // 预设笔刷颜色
  static const List<Color> penColors = [
    Color(0xFFE74C3C), // 红
    Color(0xFF3498DB), // 蓝
    Color(0xFF2ECC71), // 绿
    Color(0xFFF39C12), // 橙
    Color(0xFF9B59B6), // 紫
    Color(0xFF1ABC9C), // 青
    Color(0xFF34495E), // 黑
    Color(0xFFE91E63), // 粉
  ];

  int get currentPage => _currentPage;
  List<AnnotationStroke> get currentStrokes =>
      _pages[_currentPage]?.strokes ?? [];

  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void startStroke(Offset point) {
    if (isEraser) {
      _eraseAt(point);
      return;
    }
    _currentStroke = AnnotationStroke(
      points: [point],
      color: penColor,
      thickness: penThickness,
    );
  }

  void addPoint(Offset point) {
    if (_currentStroke == null) return;
    _currentStroke = _currentStroke!.copyWith(
      points: [..._currentStroke!.points, point],
    );
    notifyListeners();
  }

  void endStroke() {
    if (_currentStroke == null) return;
    final strokes = [...currentStrokes, _currentStroke!];
    _pages[_currentPage] = PageAnnotations(
      pageNumber: _currentPage,
      strokes: strokes,
    );
    _currentStroke = null;
    // 结束时强制刷新
    _lastNotify = 0;
    super.notifyListeners();
  }

  void _eraseAt(Offset point) {
    final existing = currentStrokes;
    if (existing.isEmpty) return;

    final remaining = <AnnotationStroke>[];
    for (final stroke in existing) {
      // 检查点是否在笔画附近（擦除半径 = thickness + 10）
      final eraseRadius = stroke.thickness + 10.0;
      bool nearStroke = false;
      for (final sp in stroke.points) {
        if ((sp - point).distance < eraseRadius) {
          nearStroke = true;
          break;
        }
      }
      if (!nearStroke) {
        remaining.add(stroke);
      }
    }
    _pages[_currentPage] = PageAnnotations(
      pageNumber: _currentPage,
      strokes: remaining,
    );
    notifyListeners();
  }

  void undoLastStroke() {
    final strokes = currentStrokes;
    if (strokes.isEmpty) return;
    _pages[_currentPage] = PageAnnotations(
      pageNumber: _currentPage,
      strokes: strokes.sublist(0, strokes.length - 1),
    );
    notifyListeners();
  }

  void clearPage() {
    _pages.remove(_currentPage);
    notifyListeners();
  }

  /// 获取当前正在画的笔迹（用于实时显示）
  AnnotationStroke? get currentDrawingStroke => _currentStroke;

  /// 获取某页的所有笔迹（包括正在画的）
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

  const AnnotationToolbar({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.level2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 第一行：颜色选择
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...AnnotationController.penColors.map((c) {
                    final selected = !controller.isEraser && controller.penColor == c;
                    return GestureDetector(
                      onTap: () {
                        controller.isEraser = false;
                        controller.penColor = c;
                        controller.notifyListeners();
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: selected
                              ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 6)]
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  // 橡皮擦
                  _toolBtn(
                    icon: Icons.auto_fix_high,
                    selected: controller.isEraser,
                    onTap: () {
                      controller.isEraser = !controller.isEraser;
                      controller.notifyListeners();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 第二行：粗细滑块 + 预设
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...AnnotationController.thicknessPresets.map((t) {
                    final selected = !controller.isEraser &&
                        controller.penThickness == t;
                    return GestureDetector(
                      onTap: () {
                        controller.penThickness = t;
                        controller.notifyListeners();
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: selected
                              ? controller.penColor.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Container(
                            width: t * 2,
                            height: t * 2,
                            decoration: BoxDecoration(
                              color: controller.isEraser
                                  ? Colors.grey
                                  : controller.penColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 6),
                  // 粗细滑条
                  SizedBox(
                    width: 60,
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      ),
                      child: Slider(
                        value: controller.penThickness,
                        min: 0.5,
                        max: 12.0,
                        divisions: 23,
                        label: controller.penThickness.toStringAsFixed(1),
                        onChanged: (v) {
                          controller.penThickness = v;
                          controller.notifyListeners();
                        },
                      ),
                    ),
                  ),
                  // 粗细预览
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: Container(
                      width: controller.penThickness.clamp(1, 24),
                      height: controller.penThickness.clamp(1, 24),
                      decoration: BoxDecoration(
                        color: controller.isEraser ? Colors.grey : controller.penColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 第三行：操作按钮
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionBtn(Icons.undo, '撤销', () => controller.undoLastStroke()),
                  const SizedBox(width: 6),
                  _actionBtn(Icons.delete_sweep, '清页', () => controller.clearPage()),
                  const SizedBox(width: 6),
                  _actionBtn(Icons.close, '完成', onClose),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _toolBtn({required IconData icon, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: selected ? Colors.blue.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: selected ? Colors.blue : Colors.grey),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return TextButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
