import 'dart:ui' show Offset;
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

// ====================================================================
// 数据模型
// ====================================================================

/// 一笔笔画的数据模型
class AnnotationStroke {
  final List<Offset> points;
  final Color color;
  final double thickness;
  final bool isEraser;
  /// 所属图层ID
  final String layerId;

  const AnnotationStroke({
    required this.points,
    required this.color,
    required this.thickness,
    this.isEraser = false,
    this.layerId = 'default',
  });

  AnnotationStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? thickness,
    bool? isEraser,
    String? layerId,
  }) =>
      AnnotationStroke(
        points: points ?? this.points,
        color: color ?? this.color,
        thickness: thickness ?? this.thickness,
        isEraser: isEraser ?? this.isEraser,
        layerId: layerId ?? this.layerId,
      );
}

/// 标注图层
class AnnotationLayer {
  final String id;
  String name;
  bool visible;
  bool locked;
  final List<AnnotationStroke> strokes;

  AnnotationLayer({
    required this.id,
    required this.name,
    this.visible = true,
    this.locked = false,
    List<AnnotationStroke>? strokes,
  }) : strokes = strokes ?? [];

  bool get hasContent => strokes.isNotEmpty;

  AnnotationLayer copyWith({
    String? name,
    bool? visible,
    bool? locked,
    List<AnnotationStroke>? strokes,
  }) =>
      AnnotationLayer(
        id: id,
        name: name ?? this.name,
        visible: visible ?? this.visible,
        locked: locked ?? this.locked,
        strokes: strokes ?? this.strokes,
      );
}

/// 每页的标注数据（含图层）
class PageAnnotations {
  final int pageNumber;
  final List<AnnotationLayer> layers;
  final int activeLayerIndex;

  const PageAnnotations({
    required this.pageNumber,
    this.layers = const [],
    this.activeLayerIndex = 0,
  });

  /// 获取当前有效图层（可见且未锁定）
  AnnotationLayer? get activeLayer {
    if (layers.isEmpty) return null;
    final idx = activeLayerIndex.clamp(0, layers.length - 1);
    final layer = layers[idx];
    if (!layer.locked) return layer;
    // 如果当前图层锁定，找第一个未锁定的可见图层
    for (final l in layers) {
      if (!l.locked && l.visible) return l;
    }
    return null;
  }

  /// 获取所有可见图层的笔迹（用于渲染）
  List<AnnotationStroke> get visibleStrokes {
    return layers
        .where((l) => l.visible)
        .expand((l) => l.strokes)
        .toList();
  }

  PageAnnotations copyWith({
    List<AnnotationLayer>? layers,
    int? activeLayerIndex,
  }) =>
      PageAnnotations(
        pageNumber: pageNumber,
        layers: layers ?? this.layers,
        activeLayerIndex: activeLayerIndex ?? this.activeLayerIndex,
      );
}

/// 蒙层方向
enum MaskDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
  centerOut,
  clickReveal,
}

/// 蒙层状态
class MaskState {
  final bool enabled;
  final double progress; // 0.0 ~ 1.0
  final MaskDirection direction;

  const MaskState({
    this.enabled = false,
    this.progress = 0.0,
    this.direction = MaskDirection.leftToRight,
  });

  bool get isFullyRevealed => progress >= 1.0;
  bool get isFullyCovered => progress <= 0.0;

  MaskState copyWith({
    bool? enabled,
    double? progress,
    MaskDirection? direction,
  }) =>
      MaskState(
        enabled: enabled ?? this.enabled,
        progress: progress ?? this.progress,
        direction: direction ?? this.direction,
      );
}

/// 标注模式
enum AnnotMode { pen, arrow }

// ====================================================================
// 标注控制器
// ====================================================================

/// 标注控制器 — 管理所有页面的笔迹、图层和蒙层
class AnnotationController extends ChangeNotifier {
  final Map<int, PageAnnotations> _pages = {};
  AnnotationStroke? _currentStroke;
  int _currentPage = 1;
  int _layerCounter = 1;

  // 当前模式
  AnnotMode mode = AnnotMode.pen;

  // 笔刷设置
  Color penColor = const Color(0xFFE74C3C);
  double penThickness = 3.0;

  // 荧光笔模式
  bool highlighterMode = false;
  Color highlighterColor = const Color(0x40FFEB3B);

  // 橡皮擦设置
  double eraserSize = 20.0;

  // 蒙层状态
  MaskState maskState = const MaskState();

  // 节流
  int _lastNotify = 0;
  static const int _throttleMs = 16;

  // Undo/Redo 栈
  final List<_UndoAction> _undoStack = [];
  final List<_UndoAction> _redoStack = [];
  static const int _maxUndo = 50;

  // 预设
  static const List<double> thicknessPresets = [1.0, 2.0, 3.0, 5.0, 8.0];
  static const List<double> eraserPresets = [10.0, 20.0, 30.0, 50.0];
  static const List<Color> penColors = [
    Color(0xFFE74C3C),
    Color(0xFF3498DB),
    Color(0xFF2ECC71),
    Color(0xFFF39C12),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFF34495E),
    Color(0xFFE91E63),
  ];
  static const List<Color> highlighterColors = [
    Color(0x40FFEB3B),
    Color(0x407CFF7C),
    Color(0x4080D8FF),
    Color(0x40FFB3B3),
    Color(0x40D0A0FF),
  ];

  // ==================== 页面管理 ====================

  int get currentPage => _currentPage;
  bool get isPenMode => mode == AnnotMode.pen;
  bool get isArrowMode => mode == AnnotMode.arrow;

  void setPage(int page) {
    _currentPage = page;
    _ensurePage(page);
  }

  /// 确保页面有默认图层
  void _ensurePage(int page) {
    if (!_pages.containsKey(page)) {
      _pages[page] = PageAnnotations(
        pageNumber: page,
        layers: [AnnotationLayer(id: _newLayerId(), name: '图层 1')],
      );
    }
  }

  PageAnnotations? get currentPageAnnot => _pages[_currentPage];

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

  // ==================== 笔画绘制 ====================

  void startStroke(Offset point) {
    if (!isPenMode) return;
    _ensurePage(_currentPage);
    final page = _pages[_currentPage]!;
    final layer = page.activeLayer;
    if (layer == null) return;

    _currentStroke = AnnotationStroke(
      points: [point],
      color: highlighterMode ? highlighterColor : penColor,
      thickness: penThickness,
      layerId: layer.id,
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
    _ensurePage(_currentPage);
    final page = _pages[_currentPage]!;
    final layerIdx = page.layers.indexWhere(
      (l) => l.id == _currentStroke!.layerId,
    );
    if (layerIdx < 0) {
      _currentStroke = null;
      return;
    }

    final targetLayer = page.layers[layerIdx];
    if (targetLayer.locked) {
      _currentStroke = null;
      return;
    }

    final updatedLayer = targetLayer.copyWith(
      strokes: [...targetLayer.strokes, _currentStroke!],
    );
    final updatedLayers = [...page.layers];
    updatedLayers[layerIdx] = updatedLayer;

    _pages[_currentPage] = page.copyWith(layers: updatedLayers);

    // 记录撤销
    _undoStack.add(_UndoAction(
      pageNumber: _currentPage,
      layerIndex: layerIdx,
      previousStrokes: targetLayer.strokes,
      newStrokes: updatedLayer.strokes,
    ));
    if (_undoStack.length > _maxUndo) _undoStack.removeAt(0);
    _redoStack.clear();

    _currentStroke = null;
    _lastNotify = 0;
    super.notifyListeners();
  }

  AnnotationStroke? get currentDrawingStroke => _currentStroke;

  // ==================== 图层管理 ====================

  int get layerCount => _pages[_currentPage]?.layers.length ?? 1;
  List<AnnotationLayer> get currentLayers =>
      _pages[_currentPage]?.layers ?? [];
  int get activeLayerIndex => _pages[_currentPage]?.activeLayerIndex ?? 0;

  /// 获取当前页面活动图层名称
  String? get activeLayerName {
    final layers = currentLayers;
    final idx = activeLayerIndex.clamp(0, layers.length - 1);
    return layers.isNotEmpty ? layers[idx].name : null;
  }

  /// 添加新图层
  void addLayer({String? name}) {
    _ensurePage(_currentPage);
    final page = _pages[_currentPage]!;
    final layer = AnnotationLayer(
      id: _newLayerId(),
      name: name ?? '图层 ${++_layerCounter}',
    );
    _pages[_currentPage] = page.copyWith(
      layers: [...page.layers, layer],
      activeLayerIndex: page.layers.length,
    );
    notifyListeners();
  }

  /// 删除图层
  void removeLayer(int index) {
    final page = _pages[_currentPage];
    if (page == null || page.layers.length <= 1) return;
    final layers = [...page.layers];
    layers.removeAt(index);
    final newIdx = index.clamp(0, layers.length - 1);
    _pages[_currentPage] = page.copyWith(
      layers: layers,
      activeLayerIndex: newIdx,
    );
    notifyListeners();
  }

  /// 切换图层可见性
  void toggleLayerVisibility(int index) {
    final page = _pages[_currentPage];
    if (page == null || index >= page.layers.length) return;
    final layers = [...page.layers];
    layers[index] = layers[index].copyWith(visible: !layers[index].visible);
    _pages[_currentPage] = page.copyWith(layers: layers);
    notifyListeners();
  }

  /// 切换图层锁定
  void toggleLayerLock(int index) {
    final page = _pages[_currentPage];
    if (page == null || index >= page.layers.length) return;
    final layers = [...page.layers];
    layers[index] = layers[index].copyWith(locked: !layers[index].locked);
    _pages[_currentPage] = page.copyWith(layers: layers);
    notifyListeners();
  }

  /// 上移图层
  void moveLayerUp(int index) {
    if (index >= layerCount - 1) return;
    _moveLayer(index, index + 1);
  }

  /// 下移图层
  void moveLayerDown(int index) {
    if (index <= 0) return;
    _moveLayer(index, index - 1);
  }

  void _moveLayer(int from, int to) {
    final page = _pages[_currentPage];
    if (page == null) return;
    final layers = [...page.layers];
    final layer = layers.removeAt(from);
    layers.insert(to, layer);
    _pages[_currentPage] = page.copyWith(
      layers: layers,
      activeLayerIndex: to,
    );
    notifyListeners();
  }

  /// 切换活动图层
  void setActiveLayer(int index) {
    final page = _pages[_currentPage];
    if (page == null || index >= page.layers.length) return;
    _pages[_currentPage] = page.copyWith(activeLayerIndex: index);
    notifyListeners();
  }

  /// 重命名图层
  void renameLayer(int index, String newName) {
    final page = _pages[_currentPage];
    if (page == null || index >= page.layers.length) return;
    final layers = [...page.layers];
    layers[index] = layers[index].copyWith(name: newName);
    _pages[_currentPage] = page.copyWith(layers: layers);
    notifyListeners();
  }

  // ==================== Undo / Redo ====================

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void undo() {
    if (_undoStack.isEmpty) return;
    final action = _undoStack.removeLast();
    _applyUndoAction(action, undo: true);
    _redoStack.add(action);
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final action = _redoStack.removeLast();
    _applyUndoAction(action, undo: false);
    _undoStack.add(action);
    notifyListeners();
  }

  void _applyUndoAction(_UndoAction action, {required bool undo}) {
    _ensurePage(action.pageNumber);
    final page = _pages[action.pageNumber]!;
    if (action.layerIndex >= page.layers.length) return;
    final layers = [...page.layers];
    layers[action.layerIndex] = layers[action.layerIndex].copyWith(
      strokes: undo ? action.previousStrokes : action.newStrokes,
    );
    _pages[action.pageNumber] = page.copyWith(layers: layers);
  }

  // ==================== 橡皮擦 ====================

  void eraseAt(Offset point) {
    _ensurePage(_currentPage);
    final page = _pages[_currentPage]!;
    bool changed = false;
    final layers = page.layers.map((layer) {
      if (layer.locked) return layer;
      final remaining = <AnnotationStroke>[];
      final erased = <AnnotationStroke>[];
      for (final stroke in layer.strokes) {
        final radius = eraserSize;
        bool hit = false;
        for (final sp in stroke.points) {
          if ((sp - point).distance < radius) {
            hit = true;
            break;
          }
        }
        if (hit) {
          erased.add(stroke);
          changed = true;
        } else {
          remaining.add(stroke);
        }
      }
      if (erased.isNotEmpty) {
        _undoStack.add(_UndoAction(
          pageNumber: _currentPage,
          layerIndex: layers.indexOf(layer),
          previousStrokes: layer.strokes,
          newStrokes: remaining,
        ));
        if (_undoStack.length > _maxUndo) _undoStack.removeAt(0);
        _redoStack.clear();
      }
      return layer.copyWith(strokes: remaining);
    }).toList();

    if (changed) {
      _pages[_currentPage] = page.copyWith(layers: layers);
      notifyListeners();
    }
  }

  void clearActiveLayer() {
    _ensurePage(_currentPage);
    final page = _pages[_currentPage]!;
    final idx = page.activeLayerIndex.clamp(0, page.layers.length - 1);
    final layer = page.layers[idx];
    if (layer.locked || layer.strokes.isEmpty) return;

    _undoStack.add(_UndoAction(
      pageNumber: _currentPage,
      layerIndex: idx,
      previousStrokes: layer.strokes,
      newStrokes: [],
    ));
    if (_undoStack.length > _maxUndo) _undoStack.removeAt(0);
    _redoStack.clear();

    final layers = [...page.layers];
    layers[idx] = layer.copyWith(strokes: []);
    _pages[_currentPage] = page.copyWith(layers: layers);
    notifyListeners();
  }

  void clearPage() {
    _ensurePage(_currentPage);
    final page = _pages[_currentPage]!;
    final layers = page.layers.map((layer) {
      if (layer.locked) return layer;
      _undoStack.add(_UndoAction(
        pageNumber: _currentPage,
        layerIndex: page.layers.indexOf(layer),
        previousStrokes: layer.strokes,
        newStrokes: [],
      ));
      if (_undoStack.length > _maxUndo) _undoStack.removeAt(0);
      _redoStack.clear();
      return layer.copyWith(strokes: []);
    }).toList();
    _pages[_currentPage] = page.copyWith(layers: layers);
    notifyListeners();
  }

  // ==================== 蒙层管理 ====================

  void toggleMask() {
    maskState = maskState.copyWith(enabled: !maskState.enabled);
    notifyListeners();
  }

  void setMaskProgress(double progress) {
    maskState = maskState.copyWith(
      progress: progress.clamp(0.0, 1.0),
      enabled: true,
    );
    notifyListeners();
  }

  void setMaskDirection(MaskDirection direction) {
    maskState = maskState.copyWith(direction: direction);
    notifyListeners();
  }

  /// 点击揭示模式下，点击位置揭示一部分
  void revealAtPoint(Offset point, Size viewSize) {
    if (!maskState.enabled ||
        maskState.direction != MaskDirection.clickReveal) {
      return;
    }
    // 点击位置周边半径 80px 范围揭示
    final revealRadius = 80.0 / viewSize.width;
    final newProgress = (maskState.progress + 0.05).clamp(0.0, 1.0);
    maskState = maskState.copyWith(progress: newProgress);
    notifyListeners();
  }

  // ==================== 数据导出/导入 ====================

  /// 获取所有页面的标注数据（用于持久化）
  Map<int, PageAnnotations> get allPages => Map.from(_pages);

  /// 批量设置页面标注数据（用于从持久化加载）
  void loadFromData(Map<int, PageAnnotations> pages) {
    _pages.clear();
    _pages.addAll(pages);
    _undoStack.clear();
    _redoStack.clear();
    // 计算最大图层编号
    for (final page in pages.values) {
      for (final layer in page.layers) {
        final match = RegExp(r'图层\s*(\d+)').firstMatch(layer.name);
        if (match != null) {
          final num = int.tryParse(match.group(1) ?? '0') ?? 0;
          if (num >= _layerCounter) _layerCounter = num + 1;
        }
      }
    }
    notifyListeners();
  }

  /// 是否没有任何标注
  bool get isEmpty {
    for (final page in _pages.values) {
      for (final layer in page.layers) {
        if (layer.strokes.isNotEmpty) return false;
      }
    }
    return true;
  }

  // ==================== 获取渲染数据 ====================

  /// 获取某页所有可见笔迹（用于Canvas渲染）
  List<AnnotationStroke> getStrokesForPage(int page) {
    final pageAnnot = _pages[page];
    if (pageAnnot == null) return [];

    final strokes = pageAnnot.visibleStrokes;

    // 如果当前正在画的在这一页，也加上
    if (page == _currentPage && _currentStroke != null) {
      return [...strokes, _currentStroke!];
    }
    return strokes;
  }

  /// 获取某页蒙层裁剪区域
  Rect? getMaskClipRect(int page, Size viewSize) {
    if (!maskState.enabled || maskState.isFullyRevealed) return null;
    if (page != _currentPage) return null;

    final progress = maskState.progress;

    switch (maskState.direction) {
      case MaskDirection.leftToRight:
        return Rect.fromLTWH(0, 0, viewSize.width * progress, viewSize.height);
      case MaskDirection.rightToLeft:
        return Rect.fromLTWH(
          viewSize.width * (1 - progress),
          0,
          viewSize.width * progress,
          viewSize.height,
        );
      case MaskDirection.topToBottom:
        return Rect.fromLTWH(0, 0, viewSize.width, viewSize.height * progress);
      case MaskDirection.bottomToTop:
        return Rect.fromLTWH(
          0,
          viewSize.height * (1 - progress),
          viewSize.width,
          viewSize.height * progress,
        );
      case MaskDirection.centerOut:
        final cx = viewSize.width / 2;
        final cy = viewSize.height / 2;
        final w = viewSize.width * progress;
        final h = viewSize.height * progress;
        return Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
      case MaskDirection.clickReveal:
        // 渐进式整体揭示
        return Rect.fromLTWH(0, 0, viewSize.width, viewSize.height);
    }
  }

  /// 获取蒙层覆盖区域（未被揭示的部分）
  List<Rect> getMaskOverlayRects(int page, Size viewSize) {
    if (!maskState.enabled || maskState.isFullyRevealed || page != _currentPage) {
      return [];
    }

    if (maskState.direction == MaskDirection.clickReveal) {
      // 点击模式：整体半透明遮罩，progress越高越透明
      return [Rect.fromLTWH(0, 0, viewSize.width, viewSize.height)];
    }

    final revealRect = getMaskClipRect(page, viewSize);
    if (revealRect == null || revealRect == Rect.zero) {
      return [Rect.fromLTWH(0, 0, viewSize.width, viewSize.height)];
    }

    // 返回revealRect以外的区域
    final full = Rect.fromLTWH(0, 0, viewSize.width, viewSize.height);
    final overlays = <Rect>[];

    // 上
    if (revealRect.top > 0) {
      overlays.add(Rect.fromLTWH(0, 0, viewSize.width, revealRect.top));
    }
    // 下
    if (revealRect.bottom < viewSize.height) {
      overlays.add(
        Rect.fromLTWH(
          0,
          revealRect.bottom,
          viewSize.width,
          viewSize.height - revealRect.bottom,
        ),
      );
    }
    // 左
    if (revealRect.left > 0) {
      overlays.add(
        Rect.fromLTWH(0, revealRect.top, revealRect.left, revealRect.height),
      );
    }
    // 右
    if (revealRect.right < viewSize.width) {
      overlays.add(
        Rect.fromLTWH(
          revealRect.right,
          revealRect.top,
          viewSize.width - revealRect.right,
          revealRect.height,
        ),
      );
    }

    return overlays;
  }

  /// 获取蒙层透明度（点击模式用）
  double get maskOpacity {
    if (!maskState.enabled) return 0.0;
    if (maskState.direction == MaskDirection.clickReveal) {
      return (1.0 - maskState.progress).clamp(0.0, 1.0) * 0.7;
    }
    return 0.0;
  }

  // ==================== 内部工具 ====================

  String _newLayerId() => 'layer_${DateTime.now().microsecondsSinceEpoch}_${++_layerCounter}';

  @override
  void dispose() {
    _pages.clear();
    _undoStack.clear();
    _redoStack.clear();
    super.dispose();
  }
}

/// 撤销操作记录
class _UndoAction {
  final int pageNumber;
  final int layerIndex;
  final List<AnnotationStroke> previousStrokes;
  final List<AnnotationStroke> newStrokes;

  const _UndoAction({
    required this.pageNumber,
    required this.layerIndex,
    required this.previousStrokes,
    required this.newStrokes,
  });
}

// ====================================================================
// 图层管理面板
// ====================================================================

/// 图层管理面板 — 浮层形式
class LayerPanel extends StatelessWidget {
  final AnnotationController controller;
  final VoidCallback onClose;

  const LayerPanel({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final layers = controller.currentLayers;
        final activeIdx = controller.activeLayerIndex;

        return Container(
          width: 260,
          constraints: const BoxConstraints(maxHeight: 360),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.level2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  const Icon(Icons.layers, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '图层管理',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  // 添加图层
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    tooltip: '添加图层',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => controller.addLayer(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose,
                  ),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 6),
              // 图层列表
              Flexible(
                child: layers.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('暂无图层', textAlign: TextAlign.center),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: layers.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final layer = layers[i];
                          final isActive = i == activeIdx;
                          return _LayerTile(
                            index: i,
                            layer: layer,
                            isActive: isActive,
                            canMoveUp: i < layers.length - 1,
                            canMoveDown: i > 0,
                            onTap: () => controller.setActiveLayer(i),
                            onToggleVisible: () =>
                                controller.toggleLayerVisibility(i),
                            onToggleLock: () =>
                                controller.toggleLayerLock(i),
                            onMoveUp: () => controller.moveLayerUp(i),
                            onMoveDown: () => controller.moveLayerDown(i),
                            onDelete: () => controller.removeLayer(i),
                            onRename: (name) =>
                                controller.renameLayer(i, name),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 单个图层行
class _LayerTile extends StatelessWidget {
  final int index;
  final AnnotationLayer layer;
  final bool isActive;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onTap;
  final VoidCallback onToggleVisible;
  final VoidCallback onToggleLock;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;
  final ValueChanged<String> onRename;

  const _LayerTile({
    required this.index,
    required this.layer,
    required this.isActive,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onTap,
    required this.onToggleVisible,
    required this.onToggleLock,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            // 可见性
            IconButton(
              icon: Icon(
                layer.visible ? Icons.visibility : Icons.visibility_off,
                size: 16,
                color: layer.visible
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              visualDensity: VisualDensity.compact,
              onPressed: onToggleVisible,
            ),
            // 锁定
            IconButton(
              icon: Icon(
                layer.locked ? Icons.lock : Icons.lock_open,
                size: 14,
                color: layer.locked ? Colors.orange : theme.colorScheme.outline,
              ),
              visualDensity: VisualDensity.compact,
              onPressed: onToggleLock,
            ),
            // 名称（可点击选择）
            GestureDetector(
              onTap: onTap,
              onDoubleTap: () => _showRenameDialog(context),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 80),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  layer.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: layer.locked ? Colors.orange : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const Spacer(),
            // 上移
            IconButton(
              icon: const Icon(Icons.arrow_upward, size: 14),
              visualDensity: VisualDensity.compact,
              onPressed: canMoveUp ? onMoveUp : null,
              color: canMoveUp ? null : theme.colorScheme.outline.withOpacity(0.3),
            ),
            // 下移
            IconButton(
              icon: const Icon(Icons.arrow_downward, size: 14),
              visualDensity: VisualDensity.compact,
              onPressed: canMoveDown ? onMoveDown : null,
              color: canMoveDown
                  ? null
                  : theme.colorScheme.outline.withOpacity(0.3),
            ),
            // 删除
            if (!layer.hasContent)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 14),
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                color: Colors.red.shade300,
              ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: layer.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名图层', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入图层名称',
            isDense: true,
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) onRename(v.trim());
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isNotEmpty) onRename(v);
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// PDF 标注工具栏（重写版 — 集成图层和蒙层）
// ====================================================================

/// PDF 标注工具栏
class AnnotationToolbar extends StatelessWidget {
  final AnnotationController controller;
  final VoidCallback onClose;
  final VoidCallback? onOpenLayers;
  final VoidCallback? onOpenMask;

  const AnnotationToolbar({
    super.key,
    required this.controller,
    required this.onClose,
    this.onOpenLayers,
    this.onOpenMask,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isPen = controller.isPenMode;
        final theme = Theme.of(context);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.level2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ========== 第一行：模式 + 颜色 ==========
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 笔/箭头模式切换
                  _modeBtn(Icons.edit, '笔', isPen, () {
                    controller.mode = AnnotMode.pen;
                  }),
                  const SizedBox(width: 4),
                  _modeBtn(Icons.pan_tool, '箭头', !isPen, () {
                    controller.mode = AnnotMode.arrow;
                  }),
                  const SizedBox(width: 4),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(width: 6),
                  // 荧光笔切换
                  _toggleBtn(
                    Icons.highlight,
                    '荧光笔',
                    controller.highlighterMode,
                    () {
                      controller.highlighterMode = !controller.highlighterMode;
                      controller.notifyListeners();
                    },
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(width: 6),
                  // 颜色选择（笔模式）/ 荧光笔颜色
                  if (isPen && !controller.highlighterMode)
                    ...AnnotationController.penColors.map(
                      (c) => _colorDot(c, controller.penColor == c, () {
                        controller.penColor = c;
                        controller.notifyListeners();
                      }),
                    ),
                  if (controller.highlighterMode)
                    ...AnnotationController.highlighterColors.map(
                      (c) => _colorDot(c, controller.highlighterColor == c, () {
                        controller.highlighterColor = c;
                        controller.notifyListeners();
                      }, isHighlighter: true),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // ========== 第二行：粗细 + 操作 ==========
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 粗细预设
                  ...AnnotationController.thicknessPresets.map(
                    (t) => _thicknessDot(t, controller.penThickness == t, () {
                      controller.penThickness = t;
                      controller.notifyListeners();
                    }),
                  ),
                  // 粗细滑条
                  SizedBox(
                    width: 80,
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 5),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 10),
                      ),
                      child: Slider(
                        value: controller.penThickness,
                        min: 0.5,
                        max: 12.0,
                        divisions: 23,
                        onChanged: (v) {
                          controller.penThickness = v;
                          controller.notifyListeners();
                        },
                      ),
                    ),
                  ),
                  // 粗细预览
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    child: Container(
                      width: controller.penThickness.clamp(1, 20),
                      height: controller.penThickness.clamp(1, 20),
                      decoration: BoxDecoration(
                        color: controller.highlighterMode
                            ? controller.highlighterColor
                            : controller.penColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(width: 4),
                  // 图层管理
                  _iconBtn(
                    Icons.layers,
                    '图层',
                    onOpenLayers ?? () {},
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  // 蒙层
                  _iconBtn(
                    controller.maskState.enabled
                        ? Icons.mask
                        : Icons.mask_outlined,
                    controller.maskState.enabled ? '关闭蒙层' : '蒙层',
                    onOpenMask ?? () {},
                    color: controller.maskState.enabled
                        ? Colors.purple
                        : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(width: 4),
                  // 撤销
                  _iconBtn(
                    Icons.undo,
                    '撤销',
                    controller.canUndo ? controller.undo : null,
                  ),
                  const SizedBox(width: 2),
                  // 重做
                  _iconBtn(
                    Icons.redo,
                    '重做',
                    controller.canRedo ? controller.redo : null,
                  ),
                  const SizedBox(width: 4),
                  // 清屏
                  _ClearSlider(onClear: controller.clearPage),
                  const SizedBox(width: 4),
                  // 橡皮擦大小
                  _EraserSizeBtn(controller: controller),
                  const SizedBox(width: 4),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(width: 4),
                  // 完成
                  _iconBtn(Icons.close, '退出', onClose),
                ],
              ),
            ],
          ),
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
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.blue : Colors.grey,
                  fontWeight: selected ? FontWeight.w600 : null)),
        ]),
      ),
    );
  }

  Widget _toggleBtn(IconData icon, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.amber.withOpacity(0.15) : null,
          borderRadius: BorderRadius.circular(8),
          border: selected ? Border.all(color: Colors.amber.withOpacity(0.4)) : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: selected ? Colors.amber.shade700 : Colors.grey,
        ),
      ),
    );
  }

  Widget _colorDot(Color color, bool selected, VoidCallback onTap,
      {bool isHighlighter = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: Colors.white, width: 2.5)
              : isHighlighter
                  ? Border.all(color: Colors.grey.withOpacity(0.3))
                  : null,
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)]
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, size: 12, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _thicknessDot(double thickness, bool selected, VoidCallback onTap) {
    final color = controller.highlighterMode
        ? controller.highlighterColor
        : controller.penColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 18,
        height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Container(
            width: thickness.clamp(2, 16),
            height: thickness.clamp(2, 16),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback? onTap,
      {Color? color}) {
    return IconButton(
      icon: Icon(icon, size: 16, color: color),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      style: IconButton.styleFrom(
        minimumSize: const Size(28, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ====================================================================
// 橡皮擦大小按钮
// ====================================================================

class _EraserSizeBtn extends StatelessWidget {
  final AnnotationController controller;
  const _EraserSizeBtn({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEraserPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.auto_fix_high, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text('擦${controller.eraserSize.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ),
    );
  }

  void _showEraserPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('橡皮擦大小', style: TextStyle(fontSize: 16)),
        content: SizedBox(
          width: 260,
          height: 60,
          child: Column(children: [
            Slider(
              value: controller.eraserSize,
              min: 5,
              max: 80,
              divisions: 15,
              label: '${controller.eraserSize.toStringAsFixed(0)}px',
              onChanged: (v) {
                controller.eraserSize = v;
                controller.notifyListeners();
              },
            ),
            Text('${controller.eraserSize.toStringAsFixed(0)}px',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('确定'),
          )
        ],
      ),
    );
  }
}

// ====================================================================
// 滑条确认清屏
// ====================================================================

class _ClearSlider extends StatefulWidget {
  final VoidCallback onClear;
  const _ClearSlider({required this.onClear});

  @override
  State<_ClearSlider> createState() => _ClearSliderState();
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
          value: _value,
          min: 0,
          max: 1.0,
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