import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Canvas, Paint, StrokeCap, StrokeJoin, MaskFilter, BlurStyle, Size, Offset, Rect;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfrx/pdfrx.dart';
import '../services/pdf_cache_manager.dart';
import '../services/pdf_merge_service.dart';
import '../services/annotation_storage_service.dart';
import '../widgets/toast_overlay.dart';
import '../widgets/pdf_annotation.dart';
import '../widgets/pdf_mask_layer.dart';
import '../theme/design_tokens.dart';

/// PDF 阅读器 — 支持标注（图层、蒙层、持久化）
class PdfReaderScreen extends ConsumerStatefulWidget {
  final String? title;
  final int initialPage;
  final String? networkUrl;
  final String? localFilePath;
  const PdfReaderScreen({
    super.key,
    this.title,
    this.initialPage = 1,
    this.networkUrl,
    this.localFilePath,
  });
  @override
  ConsumerState<PdfReaderScreen> createState() => _State();
}

class _State extends ConsumerState<PdfReaderScreen> {
  final PdfViewerController _ctrl = PdfViewerController();
  final TextEditingController _pageInput = TextEditingController();
  final AnnotationController _annotCtrl = AnnotationController();
  String? _fp;
  Uint8List? _fileBytes;
  bool _loading = true;
  String _status = '准备中...';
  double _progress = 0;
  int _total = 0;
  int _cur = 1;
  bool _showCtrl = true;
  bool _annotMode = false;
  bool _showLayerPanel = false;
  bool _showMaskPanel = false;
  Timer? _hideTimer;
  bool _saved = true;
  String? _pdfUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _saveAnnotations();
    _pageInput.dispose();
    _hideTimer?.cancel();
    _annotCtrl.dispose();
    super.dispose();
  }

  void _resetHide() {
    _hideTimer?.cancel();
    setState(() => _showCtrl = true);
    _hideTimer = Timer(
      const Duration(seconds: 5),
      () {
        if (mounted && !_annotMode) setState(() => _showCtrl = false);
      },
    );
  }

  // ==================== 文件加载 ====================

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _status = '准备中...';
      _progress = 0;
    });
    try {
      String? fp;
      if (widget.localFilePath != null) {
        fp = widget.localFilePath;
        _status = '打开本地文件...';
        _pdfUrl = fp;
      } else if (widget.networkUrl != null) {
        _pdfUrl = widget.networkUrl;
        final cm = PdfCacheManager();
        final cached = await cm.getCachedPath(widget.networkUrl!);
        if (cached != null) {
          fp = cached;
          _status = '从缓存加载';
        } else {
          _status = '下载中...';
          fp = await cm.downloadAndCache(
            widget.networkUrl!,
            onProgress: (r, t) {
              if (mounted && t > 0)
                setState(() => _progress = r / t);
            },
            onStatus: (s) {
              if (mounted) {
                setState(() {
                  switch (s) {
                    case DownloadState.downloading:
                      _status = '下载中...';
                    case DownloadState.completed:
                      _status = '完成...';
                    case DownloadState.failed:
                      _status = '失败';
                    default:
                      break;
                  }
                });
              }
            },
          );
        }
        await PdfMergeService.mergeAllInDirectory(Directory(fp).parent.path);
      }
      if (fp == null || !await File(fp!).exists()) throw Exception('无法加载');
      _fp = fp;
      _fileBytes = await File(fp!).readAsBytes();

      // 加载已有的标注数据
      await _loadAnnotations();

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _status = '失败: $e';
      });
      if (mounted) ToastOverlay.show(context, '加载失败', type: ToastType.error);
    }
  }

  // ==================== 标注持久化 ====================

  Future<void> _loadAnnotations() async {
    if (_fp == null) return;
    try {
      final data = await AnnotationStorageService.loadAnnotations(
        pdfPath: _fp!,
        pdfUrl: _pdfUrl,
      );
      if (data != null && data.isNotEmpty) {
        _annotCtrl.loadFromData(data);
        _saved = true;
      }
    } catch (e) {
      debugPrint('加载标注失败: $e');
    }
  }

  Future<void> _saveAnnotations() async {
    if (_fp == null || _annotCtrl.isEmpty) return;
    if (_saved) return;
    try {
      await AnnotationStorageService.saveAnnotations(
        pdfPath: _fp!,
        pdfUrl: _pdfUrl,
        pages: _annotCtrl.allPages,
      );
    } catch (e) {
      debugPrint('保存标注失败: $e');
    }
  }

  void _markDirty() {
    _saved = false;
  }

  // ==================== 页面导航 ====================

  void _goPage() {
    final p = int.tryParse(_pageInput.text.trim());
    if (p == null || p < 1 || p > _total) {
      ToastOverlay.show(context, '请输入 1-$_total');
      return;
    }
    _ctrl.goToPage(pageNumber: p);
    _pageInput.clear();
    FocusScope.of(context).unfocus();
    setState(() => _cur = p);
    _resetHide();
  }

  Future<void> _openLocal() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (r == null || r.files.isEmpty) return;
    final p = r.files.single.path;
    if (p == null) return;
    // 保存当前标注
    await _saveAnnotations();
    setState(() {
      _fp = p;
      _loading = false;
      _annotCtrl.loadFromData({});
      _showLayerPanel = false;
      _showMaskPanel = false;
    });
    _loadAnnotations();
  }

  // ==================== 构建 ====================

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_loading)
            _loadingView(ctx)
          else if (_fp != null && _fileBytes != null)
            _pdfView()
          else
            _errorView(ctx),

          // 控制栏
          if (_showCtrl && !_loading) _topBar(ctx),
          if (_showCtrl && !_loading) _bottomBar(ctx),

          // 点击显示控制栏
          if (!_showCtrl && !_loading)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _resetHide,
              ),
            ),

          // 标注工具栏
          if (_annotMode && !_loading)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnnotationToolbar(
                      controller: _annotCtrl,
                      onClose: () {
                        setState(() {
                          _annotMode = false;
                          _showLayerPanel = false;
                          _showMaskPanel = false;
                        });
                        _resetHide();
                      },
                      onOpenLayers: () {
                        setState(() {
                          _showLayerPanel = !_showLayerPanel;
                          _showMaskPanel = false;
                        });
                      },
                      onOpenMask: () {
                        setState(() {
                          _showMaskPanel = !_showMaskPanel;
                          _showLayerPanel = false;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // 图层面板
                    if (_showLayerPanel)
                      LayerPanel(
                        controller: _annotCtrl,
                        onClose: () =>
                            setState(() => _showLayerPanel = false),
                      ),
                    // 蒙层面板
                    if (_showMaskPanel)
                      MaskControlPanel(
                        controller: _annotCtrl,
                        onClose: () =>
                            setState(() => _showMaskPanel = false),
                      ),
                  ],
                ),
              ),
            ),

          // 标注模式提示
          if (_annotMode && !_loading)
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _annotCtrl.isPenMode
                          ? '✏️ 笔模式 | 图层: ${_annotCtrl.activeLayerName ?? "默认"}'
                          : '👆 箭头模式（可滚动）',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pdfView() {
    return Stack(
      children: [
        // PDF 页面
        GestureDetector(
          onTap: _annotMode && _annotCtrl.isArrowMode ? null : _resetHide,
          child: PdfViewer.data(
            _fileBytes!,
            sourceName: widget.title ?? 'document.pdf',
            controller: _ctrl,
            initialPageNumber: widget.initialPage,
            params: PdfViewerParams(
              scrollByMouseWheel: 1.0,
              pagePaintCallbacks: [
                (Canvas canvas, Rect rect, PdfPage page) {
                  _renderAnnotations(page.pageNumber, canvas, rect.size);
                },
              ],
              onViewerReady: (doc, ctrl) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _total = doc.pages.length;
                      _cur = ctrl.pageNumber ?? widget.initialPage;
                    });
                    if (widget.initialPage > 1) {
                      ctrl.goToPage(pageNumber: widget.initialPage);
                    }
                    _resetHide();
                  }
                });
              },
              onPageChanged: (pn) {
                if (mounted) setState(() => _cur = pn ?? 1);
                _annotCtrl.setPage(pn ?? 1);
              },
            ),
          ),
        ),

        // 蒙层渲染
        if (_annotMode)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _annotCtrl.maskState.direction ==
                  MaskDirection.clickReveal,
              child: MaskPaintLayer(
                controller: _annotCtrl,
                currentPage: _cur,
                viewSize: Size.infinite,
              ),
            ),
          ),

        // 标注手势层：笔模式下捕获绘制
        if (_annotMode && _annotCtrl.isPenMode)
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (e) {
                _annotCtrl.setPage(_cur);
                _annotCtrl.startStroke(e.position);
              },
              onPointerMove: (e) {
                if (_annotCtrl.currentDrawingStroke != null) {
                  _annotCtrl.addPoint(e.position);
                }
              },
              onPointerUp: (e) {
                _annotCtrl.endStroke();
                _markDirty();
              },
            ),
          ),

        // 蒙层点击揭示手势
        if (_annotMode &&
            _annotCtrl.maskState.enabled &&
            _annotCtrl.maskState.direction == MaskDirection.clickReveal)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (details) {
                _annotCtrl.revealAtPoint(
                  details.localPosition,
                  details.localPosition == Offset.zero
                      ? const Size(400, 600)
                      : Size.infinite,
                );
                _markDirty();
              },
            ),
          ),

        // 蒙层进度控制手势（拖动模式）
        if (_annotMode &&
            _annotCtrl.maskState.enabled &&
            _annotCtrl.maskState.direction != MaskDirection.clickReveal)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragUpdate: (d) {
                if (_annotCtrl.maskState.direction ==
                        MaskDirection.topToBottom ||
                    _annotCtrl.maskState.direction ==
                        MaskDirection.bottomToTop) {
                  final h = context.size?.height ?? 600;
                  final progress =
                      (d.localPosition.dy / h).clamp(0.0, 1.0);
                  _annotCtrl.setMaskProgress(
                    _annotCtrl.maskState.direction ==
                            MaskDirection.topToBottom
                        ? progress
                        : 1.0 - progress,
                  );
                }
              },
              onHorizontalDragUpdate: (d) {
                if (_annotCtrl.maskState.direction ==
                        MaskDirection.leftToRight ||
                    _annotCtrl.maskState.direction ==
                        MaskDirection.rightToLeft) {
                  final w = context.size?.width ?? 400;
                  final progress =
                      (d.localPosition.dx / w).clamp(0.0, 1.0);
                  _annotCtrl.setMaskProgress(
                    _annotCtrl.maskState.direction ==
                            MaskDirection.leftToRight
                        ? progress
                        : 1.0 - progress,
                  );
                }
              },
            ),
          ),
      ],
    );
  }

  /// 使用 pagePaintCallbacks 渲染标注
  void _renderAnnotations(int pageNumber, Canvas canvas, Size size) {
    final strokes = _annotCtrl.getStrokesForPage(pageNumber);
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;

      // 荧光笔效果：半透明 + 宽笔触
      final isHighlighter = stroke.color.alpha < 200;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = isHighlighter
            ? stroke.thickness * 3
            : stroke.thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter =
            isHighlighter ? const MaskFilter.blur(BlurStyle.normal, 2) : null;

      // 荧光笔下层背景（黄色半透明填充）
      if (isHighlighter) {
        final bgPaint = Paint()
          ..color = stroke.color.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke.thickness * 6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        for (int i = 0; i < stroke.points.length - 1; i++) {
          canvas.drawLine(stroke.points[i], stroke.points[i + 1], bgPaint);
        }
      }

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  // ==================== UI 组件 ====================

  Widget _topBar(BuildContext ctx) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _showCtrl ? 1 : 0,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black87, Colors.black54, Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(ctx).padding.top + 4,
            left: 8,
            right: 8,
            bottom: 8,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () {
                  _saveAnnotations();
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title ?? '教材阅读',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 标注切换
              IconButton(
                icon: Icon(
                  _annotMode ? Icons.edit_off : Icons.edit,
                  color: _annotMode ? Colors.yellowAccent : Colors.white70,
                  size: 24,
                ),
                tooltip: _annotMode ? '退出标注' : '标注',
                onPressed: () {
                  setState(() => _annotMode = !_annotMode);
                  _resetHide();
                },
              ),
              // 保存标注
              if (_annotMode && !_saved)
                IconButton(
                  icon: const Icon(Icons.save, color: Colors.greenAccent, size: 22),
                  tooltip: '保存标注',
                  onPressed: () {
                    _saveAnnotations().then((_) {
                      if (mounted) {
                        setState(() => _saved = true);
                        ToastOverlay.show(context, '标注已保存',
                            type: ToastType.success);
                      }
                    });
                  },
                ),
              IconButton(
                icon: const Icon(Icons.folder_open, color: Colors.white70, size: 24),
                onPressed: _openLocal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext ctx) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _showCtrl ? 1 : 0,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Colors.black54, Colors.black87],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 8,
            bottom: MediaQuery.of(ctx).padding.bottom + 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left, color: Colors.white, size: 28),
                onPressed: () {
                  if (_cur > 1) _ctrl.goToPage(pageNumber: _cur - 1);
                  _resetHide();
                },
              ),
              GestureDetector(
                onTap: () {
                  _pageInput.text = _cur.toString();
                  showDialog(
                    context: ctx,
                    builder: (c) => AlertDialog(
                      title: const Text('跳转到页码'),
                      content: TextField(
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        controller: _pageInput,
                        decoration: InputDecoration(
                          hintText: '输入页码 (1-$_total)',
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (_) {
                          Navigator.pop(c);
                          _goPage();
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('取消'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(c);
                            _goPage();
                          },
                          child: const Text('跳转'),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_cur / $_total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right, color: Colors.white, size: 28),
                onPressed: () {
                  if (_cur < _total) {
                    _ctrl.goToPage(pageNumber: _cur + 1);
                  }
                  _resetHide();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loadingView(BuildContext ctx) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: _progress > 0 ? _progress : null,
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(_status,
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          if (_progress > 0) ...[
            const SizedBox(height: 12),
            Text('${(_progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white54, fontSize: 14)),
          ],
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消返回',
                style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _errorView(BuildContext ctx) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          Text(_status,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                label: const Text('重试',
                    style: TextStyle(color: Colors.white70)),
                onPressed: _load,
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.folder_open, color: Colors.white70),
                label: const Text('本地文件',
                    style: TextStyle(color: Colors.white70)),
                onPressed: _openLocal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
