import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';
import '../services/pdf_annotation_store.dart';
import '../services/pdf_cache_manager.dart';
import '../services/pdf_merge_service.dart';
import '../services/workspace_service.dart';
import '../widgets/pdf_annotation_layer.dart';
import '../widgets/toast_overlay.dart';

/// PDF 阅读器 —— 含独立悬浮批注系统。
///
/// 批注的实现方式（这一点是刻意选的）：
/// 完全不写入 PDF 文件本身，而是用 pdfrx 的 `pageOverlaysBuilder`
/// 在每一页**之上**叠一层绘制图层。笔迹以 72dpi 页面坐标存在独立的
/// JSON 里，因此：
///   - 老师的教材原件永远不被改动；
///   - 翻页、缩放、换设备，笔迹都落在同一处，不会位移。
///
/// 这正好对应旧版引导页上那句「独立悬浮批注，不嵌入PDF，翻页不位移」——
/// 而 v1.23 把这套功能整块删掉之后，这句话还挂在引导页上很久。
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
  String? _fp;
  Uint8List? _fileBytes;
  bool _loading = true;
  String _status = '准备中...';
  double _progress = 0;
  int _total = 0;
  int _cur = 1;
  bool _showCtrl = true;
  Timer? _hideTimer;

  // ---- 批注 ----
  PdfAnnotationStore? _store;
  bool _annotating = false;
  bool _erasing = false;
  int _penColor = _penPalette[0];
  double _penWidth = 2.5;
  Timer? _saveTimer;

  /// 笔色：在白色教材页与深色扫描页上都要看得清
  static const List<int> _penPalette = [
    0xFFE53935, // 红
    0xFF1E88E5, // 蓝
    0xFF43A047, // 绿
    0xFFFB8C00, // 橙
    0xFF212121, // 近黑
  ];
  static const List<double> _penWidths = [1.5, 2.5, 5.0];

  /// 缓存 PdfViewerParams。
  ///
  /// pdfrx 的 PdfViewerParams 重写了 ==，且会比较各个 builder 的**闭包同一性**。
  /// 如果每帧都新建一个 params（画一笔就 setState 一次），参数永远「不相等」，
  /// pdfrx 就可能认为布局参数变了并重载文档 —— 那会让手写卡到无法使用。
  /// 因此这里只在批注模式切换时重建 params；
  /// 各个 builder 内部读取的都是 this 上的当前字段，仍能反映最新状态。
  PdfViewerParams? _cachedParams;
  bool? _cachedAnnotating;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageInput.dispose();
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    // 退出时尽量把未落盘的笔迹写掉
    _store?.save();
    super.dispose();
  }

  void _resetHide() {
    _hideTimer?.cancel();
    if (!mounted) return;
    setState(() => _showCtrl = true);
    // 批注模式下不自动隐藏工具栏，否则老师正在写字时工具栏会消失
    if (_annotating) return;
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showCtrl = false);
    });
  }

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
      } else if (widget.networkUrl != null) {
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
              if (mounted && t > 0) setState(() => _progress = r / t);
            },
            onStatus: (s) {
              if (mounted) {
                setState(() {
                  switch (s) {
                    case DownloadState.downloading:
                      _status = '下载中...';
                    case DownloadState.completed:
                      _status = '下载完成';
                    case DownloadState.failed:
                      _status = '下载失败';
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
      if (fp == null || !await File(fp).exists()) throw Exception('无法加载');
      _fp = fp;
      _fileBytes = await File(fp).readAsBytes();
      await _openStore();
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _status = '失败: $e';
      });
      if (mounted) ToastOverlay.show(context, '加载失败', type: ToastType.error);
    }
  }

  /// 打开（或新建）本文档的批注
  Future<void> _openStore() async {
    final name =
        widget.title ?? (_fp == null ? 'document.pdf' : p.basename(_fp!));
    final archiveDir = ref.read(workspaceServiceProvider).archivePath;
    try {
      _store = await PdfAnnotationStore.open(
        sourceName: name,
        archiveDir: archiveDir,
      );
      if (archiveDir == null && mounted) {
        ToastOverlay.show(context, '未设置工作目录，批注仅在本次会话内有效',
            type: ToastType.warning);
      }
    } catch (e) {
      if (mounted) {
        ToastOverlay.show(context, '批注初始化失败: $e', type: ToastType.error);
      }
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () => _store?.save());
  }

  void _goPage() {
    final target = int.tryParse(_pageInput.text.trim());
    if (target == null || target < 1 || target > _total) {
      ToastOverlay.show(context, '请输入 1-$_total');
      return;
    }
    _ctrl.goToPage(pageNumber: target);
    _pageInput.clear();
    FocusScope.of(context).unfocus();
    setState(() => _cur = target);
    _resetHide();
  }

  Future<void> _openLocal() async {
    final r = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (r == null || r.files.isEmpty) return;
    final path = r.files.single.path;
    if (path == null) return;
    _store?.save();
    _store = null;
    setState(() {
      _fp = path;
      _loading = false;
    });
    await _openStore();
    if (mounted) setState(() {});
  }

  // ==================== 批注操作 ====================

  void _toggleAnnotating() {
    setState(() {
      _annotating = !_annotating;
      if (!_annotating) _erasing = false;
    });
    _resetHide();
    if (_annotating) {
      ToastOverlay.show(context, '批注模式：可直接在页面上书写；此模式下不会翻页',
          type: ToastType.info);
    } else {
      _store?.save();
    }
  }

  void _undo() {
    final removed = _store?.undoLast();
    if (removed == null) {
      ToastOverlay.show(context, '没有可撤销的笔迹');
      return;
    }
    _scheduleSave();
    setState(() {});
    ToastOverlay.show(context, '已撤销第 ${removed.pageNumber} 页的一笔');
  }

  void _clearPage() {
    final n = _store?.clearPage(_cur) ?? 0;
    if (n == 0) {
      ToastOverlay.show(context, '第 $_cur 页没有笔迹');
      return;
    }
    _scheduleSave();
    setState(() {});
    ToastOverlay.show(context, '已清除第 $_cur 页的 $n 处笔迹',
        type: ToastType.warning);
  }

  // ==================== 构建 ====================

  PdfViewerParams _viewerParams() {
    if (_cachedParams != null && _cachedAnnotating == _annotating) {
      return _cachedParams!;
    }
    _cachedAnnotating = _annotating;
    _cachedParams = PdfViewerParams(
      scrollByMouseWheel: 1.0,
      // 批注模式下关掉平移与缩放：一是让手势完全归批注层，
      // 二是避免「想写字结果页面在滚」这种最恼人的体验。
      panEnabled: !_annotating,
      scaleEnabled: !_annotating,
      onViewerReady: (doc, ctrl) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _total = doc.pages.length;
            _cur = ctrl.pageNumber ?? widget.initialPage;
          });
          if (widget.initialPage > 1) {
            ctrl.goToPage(pageNumber: widget.initialPage);
          }
          _resetHide();
        });
      },
      onPageChanged: (pn) {
        if (mounted) setState(() => _cur = pn ?? 1);
      },
      pageOverlaysBuilder: _buildPageOverlay,
    );
    return _cachedParams!;
  }

  /// 每一页之上叠一层批注层。
  ///
  /// 注意：**即使不在批注模式也要返回覆盖层**，否则已画的笔迹就看不见了。
  /// 缩放比直接由「屏幕上一页的宽 / 页面 72dpi 宽」得出，
  /// 因此不需要依赖 controller 的坐标换算接口，少一层版本兼容风险。
  List<Widget> _buildPageOverlay(
    BuildContext context,
    Rect pageRect,
    PdfPage page,
  ) {
    final store = _store;
    if (store == null) return const <Widget>[];

    final pageWidth = page.width.toDouble();
    final scale = pageWidth <= 0 ? 1.0 : pageRect.width / pageWidth;
    // 橡皮半径按屏幕视觉取 12px，换算回页面空间
    final eraseRadius = 12.0 / (scale <= 0 ? 1.0 : scale);
    final pageNumber = page.pageNumber;

    return <Widget>[
      PageAnnotationOverlay(
        key: ValueKey<int>(pageNumber),
        pageNumber: pageNumber,
        pageWidth: pageWidth,
        pageHeight: page.height.toDouble(),
        viewWidth: pageRect.width,
        viewHeight: pageRect.height,
        strokes: store.forPage(pageNumber),
        annotating: _annotating,
        erasing: _erasing,
        penColor: _penColor,
        penWidth: _penWidth,
        onStrokeCommitted: (stroke) {
          _store?.add(stroke);
          _scheduleSave();
          setState(() {});
        },
        onErase: (pagePoint) {
          final removed =
              _store?.eraseAt(pageNumber, pagePoint, eraseRadius) ?? 0;
          if (removed > 0) {
            _scheduleSave();
            setState(() {});
          }
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        if (_loading)
          _loadingView(ctx)
        else if (_fp != null && _fileBytes != null)
          _pdfView()
        else
          _errorView(ctx),
        if (_showCtrl && !_loading) _topBar(ctx),
        if (_showCtrl && !_loading && _annotating) _annotationBar(ctx),
        if (_showCtrl && !_loading) _bottomBar(ctx),
        if (!_showCtrl && !_loading)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _resetHide,
            ),
          ),
      ]),
    );
  }

  Widget _pdfView() => GestureDetector(
        onTap: _resetHide,
        child: PdfViewer.data(
          _fileBytes!,
          sourceName: widget.title ?? 'document.pdf',
          controller: _ctrl,
          initialPageNumber: widget.initialPage,
          params: _viewerParams(),
        ),
      );

  Widget _topBar(BuildContext ctx) => Positioned(
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
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title ?? '教材阅读',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_store != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '${_store!.strokeCount} 处批注',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.folder_open,
                    color: Colors.white70, size: 24),
                onPressed: _openLocal,
              ),
            ]),
          ),
        ),
      );

  /// 批注工具栏
  Widget _annotationBar(BuildContext ctx) => Positioned(
        left: 0,
        right: 0,
        bottom: 76,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.78),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              _toolChip(
                icon: Icons.edit,
                label: '笔',
                active: !_erasing,
                onTap: () => setState(() => _erasing = false),
              ),
              _toolChip(
                icon: Icons.auto_fix_normal,
                label: '橡皮',
                active: _erasing,
                onTap: () => setState(() => _erasing = true),
              ),
              const _VDivider(),
              for (final c in _penPalette)
                GestureDetector(
                  onTap: () => setState(() {
                    _penColor = c;
                    _erasing = false;
                  }),
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _penColor == c ? Colors.white : Colors.white24,
                        width: _penColor == c ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              const _VDivider(),
              for (final w in _penWidths)
                GestureDetector(
                  onTap: () => setState(() {
                    _penWidth = w;
                    _erasing = false;
                  }),
                  child: Container(
                    width: 30,
                    height: 26,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color:
                          _penWidth == w ? Colors.white24 : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      width: 16,
                      height: w * 1.6,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              const _VDivider(),
              _toolChip(icon: Icons.undo, label: '撤销', onTap: _undo),
              _toolChip(
                  icon: Icons.layers_clear, label: '清本页', onTap: _clearPage),
            ],
          ),
        ),
      );

  Widget _toolChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: active ? Colors.white24 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: active ? Colors.white : Colors.white70),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: active ? Colors.white : Colors.white70)),
          ]),
        ),
      );

  Widget _bottomBar(BuildContext ctx) => Positioned(
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
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                icon: Icon(_annotating ? Icons.close : Icons.edit_note,
                    color: _annotating ? Colors.amber : Colors.white, size: 24),
                tooltip: _annotating ? '退出批注' : '批注',
                onPressed: _toggleAnnotating,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.arrow_left,
                    color: Colors.white, size: 28),
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
                                  border: const OutlineInputBorder()),
                              onSubmitted: (_) {
                                Navigator.pop(c);
                                _goPage();
                              },
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(c),
                                  child: const Text('取消')),
                              FilledButton(
                                  onPressed: () {
                                    Navigator.pop(c);
                                    _goPage();
                                  },
                                  child: const Text('跳转')),
                            ],
                          ));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '$_cur / $_total',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right,
                    color: Colors.white, size: 28),
                onPressed: () {
                  if (_cur < _total) _ctrl.goToPage(pageNumber: _cur + 1);
                  _resetHide();
                },
              ),
            ]),
          ),
        ),
      );

  Widget _loadingView(BuildContext ctx) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
                value: _progress > 0 ? _progress : null,
                color: Colors.white,
                strokeWidth: 3),
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
                  style: TextStyle(color: Colors.white54))),
        ]),
      );

  Widget _errorView(BuildContext ctx) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          Text(_status,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(mainAxisSize: MainAxisSize.min, children: [
            OutlinedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                label: const Text('重试',
                    style: TextStyle(color: Colors.white70)),
                onPressed: _load),
            const SizedBox(width: 12),
            OutlinedButton.icon(
                icon: const Icon(Icons.folder_open, color: Colors.white70),
                label: const Text('本地文件',
                    style: TextStyle(color: Colors.white70)),
                onPressed: _openLocal),
          ]),
        ]),
      );
}

class _VDivider extends StatelessWidget {
  const _VDivider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 20,
        color: Colors.white24,
        margin: const EdgeInsets.symmetric(horizontal: 2),
      );
}
