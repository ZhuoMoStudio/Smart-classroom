import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfrx/pdfrx.dart';
import '../services/pdf_cache_manager.dart';
import '../services/pdf_merge_service.dart';
import '../services/gh_proxy_service.dart';
import '../widgets/toast_overlay.dart';

class PdfReaderScreen extends ConsumerStatefulWidget {
  final String? title;
  final int initialPage;
  final String? networkUrl;
  final String? localFilePath;
  const PdfReaderScreen({super.key, this.title, this.initialPage=1, this.networkUrl, this.localFilePath});
  @override ConsumerState<PdfReaderScreen> createState() => _State();
}

class _State extends ConsumerState<PdfReaderScreen> {
  final PdfViewerController _ctrl = PdfViewerController();
  final TextEditingController _pageInput = TextEditingController();
  String? _fp;
  bool _loading = true;
  String _status = '准备中...';
  double _progress = 0;
  int _total = 0;
  int _cur = 1;
  bool _showCtrl = true;
  Timer? _hideTimer;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _pageInput.dispose(); _hideTimer?.cancel(); super.dispose(); }

  void _resetHide() { _hideTimer?.cancel(); setState(() => _showCtrl = true); _hideTimer = Timer(const Duration(seconds:5), () { if(mounted) setState(() => _showCtrl=false); }); }

  Future<void> _load() async {
    setState(() { _loading=true; _status='准备中...'; _progress=0; });
    try {
      String? fp;
      if (widget.localFilePath != null) {
        fp = widget.localFilePath; _status = '打开本地文件...';
      } else if (widget.networkUrl != null) {
        final cm = PdfCacheManager();
        final cached = await cm.getCachedPath(widget.networkUrl!);
        if (cached != null) { fp=cached; _status='从缓存加载'; }
        else {
          _status='下载中（加速节点）...';
          fp = await cm.downloadAndCache(widget.networkUrl!, onProgress:(r,t){ if(mounted&&t>0) setState((){ _progress=r/t; _status='下载 ${(r/1048576).toStringAsFixed(1)} MB'; }); }, onStatus:(s){ if(mounted) setState((){ switch(s){ case DownloadState.downloading: _status='下载中...'; case DownloadState.completed: _status='完成...'; case DownloadState.failed: _status='失败'; default: break; } }); });
        }
        await PdfMergeService.mergeAllInDirectory(Directory(fp).parent.path);
      }
      if (fp==null||!await File(fp).exists()) throw Exception('无法加载');
      _fp=fp; setState(()=>_loading=false);
    } catch(e) {
      setState((){ _loading=false; _status='失败: $e'; });
      if(mounted) ToastOverlay.show(context, '加载失败: $e');
    }
  }

  void _goPage() {
    final p = int.tryParse(_pageInput.text.trim());
    if(p==null||p<1||p>_total){ ToastOverlay.show(context, '请输入 1-$_total'); return; }
    _ctrl.goToPage(pageNumber:p); _pageInput.clear(); FocusScope.of(context).unfocus(); setState(()=>_cur=p); _resetHide();
  }

  Future<void> _openLocal() async {
    final r = await FilePicker.platform.pickFiles(type:FileType.custom, allowedExtensions:['pdf']);
    if(r==null||r.files.isEmpty) return;
    final p = r.files.single.path; if(p==null) return;
    setState((){ _fp=p; _loading=false; });
  }

  @override Widget build(BuildContext ctx) {
    return Scaffold(backgroundColor:Colors.black, body:Stack(children:[
      if(_loading) _loadingView(ctx) else if(_fp!=null) _pdfView() else _errorView(ctx),
      if(_showCtrl&&!_loading) _topBar(ctx),
      if(_showCtrl&&!_loading) _bottomBar(ctx),
      if(!_showCtrl) Positioned.fill(child:GestureDetector(behavior:HitTestBehavior.translucent, onTap:_resetHide)),
    ]));
  }

  Widget _pdfView() => GestureDetector(onTap:_resetHide, child: PdfViewer.file(_fp!, controller:_ctrl, initialPageNumber:widget.initialPage, params:PdfViewerParams(scrollByMouseWheel:true, onViewerReady:(doc,ctrl){ WidgetsBinding.instance.addPostFrameCallback((_){ if(mounted){ setState((){ _total=doc.pages.length; _cur=ctrl.pageNumber??widget.initialPage; }); if(widget.initialPage>1) ctrl.goToPage(pageNumber:widget.initialPage); _resetHide(); } }); }), onPageChanged:(pn){ if(mounted) setState(()=>_cur=pn??1); }));

  Widget _topBar(BuildContext ctx) => Positioned(top:0,left:0,right:0, child: AnimatedOpacity(duration:const Duration(milliseconds:300), opacity:_showCtrl?1:0, child:Container(decoration:const BoxDecoration(gradient:LinearGradient(colors:[Colors.black87,Colors.black54,Colors.transparent], begin:Alignment.topCenter, end:Alignment.bottomCenter)), padding:EdgeInsets.only(top:MediaQuery.of(ctx).padding.top+4,left:8,right:8,bottom:8), child:Row(children:[
    IconButton(icon:const Icon(Icons.arrow_back,color:Colors.white,size:28), onPressed:()=>Navigator.pop(ctx)),
    const SizedBox(width:8),
    Expanded(child:Text(widget.title??'教材阅读', style:const TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.w500), overflow:TextOverflow.ellipsis)),
    IconButton(icon:const Icon(Icons.folder_open,color:Colors.white70,size:24), onPressed:_openLocal),
  ])))));

  Widget _bottomBar(BuildContext ctx) => Positioned(bottom:0,left:0,right:0, child: AnimatedOpacity(duration:const Duration(milliseconds:300), opacity:_showCtrl?1:0, child:Container(decoration:const BoxDecoration(gradient:LinearGradient(colors:[Colors.transparent,Colors.black54,Colors.black87], begin:Alignment.topCenter, end:Alignment.bottomCenter)), padding:EdgeInsets.only(left:12,right:12,top:8,bottom:MediaQuery.of(ctx).padding.bottom+8), child:Row(mainAxisAlignment:MainAxisAlignment.center, children:[
    IconButton(icon:const Icon(Icons.arrow_left,color:Colors.white,size:28), onPressed:(){ if(_cur>1) _ctrl.goToPage(pageNumber:_cur-1); _resetHide(); }),
    GestureDetector(onTap:(){ _pageInput.text=_cur.toString(); showDialog(context:ctx, builder:(c)=>AlertDialog(title:const Text('跳转到页码'), content:TextField(autofocus:true, keyboardType:TextInputType.number, controller:_pageInput, decoration:InputDecoration(hintText:'输入页码 (1-$_total)', border:const OutlineInputBorder()), onSubmitted:(_){ Navigator.pop(c); _goPage(); }), actions:[TextButton(onPressed:()=>Navigator.pop(c), child:const Text('取消')), FilledButton(onPressed:(){ Navigator.pop(c); _goPage(); }, child:const Text('跳转'))])); }, child:Container(padding:const EdgeInsets.symmetric(horizontal:16,vertical:6), decoration:BoxDecoration(color:Colors.white24, borderRadius:BorderRadius.circular(20)), child:Text('$_cur / $_total', style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.w500)))),
    IconButton(icon:const Icon(Icons.arrow_right,color:Colors.white,size:28), onPressed:(){ if(_cur<_total) _ctrl.goToPage(pageNumber:_cur+1); _resetHide(); }),
  ])))));

  Widget _loadingView(BuildContext ctx) => Center(child:Column(mainAxisSize:MainAxisSize.min, children:[
    SizedBox(width:48,height:48, child:CircularProgressIndicator(value:_progress>0?_progress:null, color:Colors.white, strokeWidth:3)),
    const SizedBox(height:24), Text(_status, style:const TextStyle(color:Colors.white70,fontSize:16)),
    if(_progress>0) ...[const SizedBox(height:12), Text('${(_progress*100).toStringAsFixed(0)}%', style:const TextStyle(color:Colors.white54,fontSize:14))],
    const SizedBox(height:32), TextButton(onPressed:()=>Navigator.pop(ctx), child:const Text('取消返回', style:TextStyle(color:Colors.white54))),
  ]));

  Widget _errorView(BuildContext ctx) => Center(child:Column(mainAxisSize:MainAxisSize.min, children:[
    const Icon(Icons.error_outline, color:Colors.redAccent, size:64), const SizedBox(height:16),
    Text(_status, style:const TextStyle(color:Colors.white70,fontSize:16), textAlign:TextAlign.center), const SizedBox(height:24),
    Row(mainAxisSize:MainAxisSize.min, children:[
      OutlinedButton.icon(icon:const Icon(Icons.refresh,color:Colors.white70), label:const Text('重试', style:TextStyle(color:Colors.white70)), onPressed:_load),
      const SizedBox(width:12),
      OutlinedButton.icon(icon:const Icon(Icons.folder_open,color:Colors.white70), label:const Text('本地文件', style:TextStyle(color:Colors.white70)), onPressed:_openLocal),
    ]),
  ]));
}
