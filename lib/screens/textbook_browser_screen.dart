import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/gh_proxy_service.dart';
import '../services/textbook_repo_service.dart';
import '../services/file_service.dart';
import '../widgets/toast_overlay.dart';
import '../theme/route_utils.dart';
import '../theme/design_tokens.dart';
import 'pdf_reader_screen.dart';

/// 教材浏览器 — 自动按年级/学科/版本分类 + 本地优先
class TextbookBrowserScreen extends ConsumerStatefulWidget {
  const TextbookBrowserScreen({super.key});
  @override
  ConsumerState<TextbookBrowserScreen> createState() => _TBSState();
}

class _TBSState extends ConsumerState<TextbookBrowserScreen> {
  List<TextbookItem> _items = [];
  bool _isLoading = true;
  String _currentPath = '';
  String _errorMessage = '';
  final List<String> _pathStack = [];
  // 本地教材缓存
  List<File> _localPdfs = [];
  String _localPath = '';

  @override
  void initState() {
    super.initState();
    _loadLocalFirst();
  }

  /// 优先加载本地教材
  Future<void> _loadLocalFirst() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final fp = ref.read(fileServiceProvider);
      _localPath = await fp.getWorkingDir();
      final dir = Directory(_localPath);
      if (await dir.exists()) {
        final files = <File>[];
        await for (final e in dir.list()) {
          if (e is File && e.path.endsWith('.pdf')) files.add(e);
        }
        _localPdfs = files;
      }
    } catch (_) {}
    // 然后请求远程目录
    _loadDirectory('');
  }

  Future<void> _loadDirectory(String path) async {
    final cm = ref.read(settingsProvider);
    final useMirror = cm.downloadSource == 'mirror';
    try {
      final items = await TextbookRepoService.fetchContents(path);
      if (mounted) setState(() { _items = items; _isLoading = false; _currentPath = path; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = '加载失败: $e'; });
    }
  }

  void _navigateInto(TextbookItem item) {
    if (item.type != 'dir') return;
    _pathStack.add(_currentPath);
    _loadDirectory(item.path);
  }

  Future<void> _navigateBack() async {
    if (_pathStack.isEmpty) return;
    _loadDirectory(_pathStack.removeLast());
  }

  void _openPdf(TextbookItem item) {
    if (item.downloadUrl == null) { ToastOverlay.show(context, '无法获取下载链接'); return; }
    final cm = ref.read(settingsProvider);
    final useMirror = cm.downloadSource == 'mirror';
    // 使用代理或官方源
    final url = useMirror ? GhProxyService.toProxyUrl(item.downloadUrl!) : item.downloadUrl!;
    Navigator.push(context, slideFadePageRoute(PdfReaderScreen(
      title: item.name, networkUrl: url, initialPage: 1,
    )));
  }

  void _openLocalPdf(File file) {
    Navigator.push(context, slideFadePageRoute(PdfReaderScreen(
      title: file.path.split('/').last, localFilePath: file.path, initialPage: 1,
    )));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRoot = _currentPath.isEmpty && _pathStack.isEmpty;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _pathStack.isNotEmpty ? _navigateBack() : Navigator.pop(context),
        ),
        title: Text(_currentPath.isEmpty ? (isRoot ? '教材' : _currentPath.split('/').last) : _currentPath.split('/').last),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => _loadDirectory(_currentPath)),
          if (isRoot) IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: '本地教材',
            onPressed: () => _showLocalPdfs(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(_errorMessage, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  FilledButton.icon(icon: const Icon(Icons.refresh), label: const Text('重试'), onPressed: () => _loadDirectory(_currentPath)),
                ]))
              : _items.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.folder_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('此目录为空', style: TextStyle(color: Colors.grey[600])),
                      if (isRoot && _localPdfs.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(icon: const Icon(Icons.folder_open), label: Text('本地教材 (${_localPdfs.length})'), onPressed: _showLocalPdfs),
                      ],
                    ]))
                  : ListView.builder(
                      itemCount: _items.length + (isRoot && _localPdfs.isNotEmpty ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        // 第一个显示本地入口
                        if (isRoot && _localPdfs.isNotEmpty && i == 0) {
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: Icon(Icons.folder, color: Colors.green.shade600, size: 32),
                              title: Text('本地教材', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                              subtitle: Text('${_localPdfs.length} 个文件'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _showLocalPdfs,
                            ),
                          );
                        }
                        final idx = isRoot && _localPdfs.isNotEmpty ? i - 1 : i;
                        if (idx >= _items.length) return const SizedBox.shrink();
                        final item = _items[idx];
                        if (item.type == 'dir') {
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: Icon(Icons.folder, color: Colors.amber.shade700, size: 32),
                              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _navigateInto(item),
                            ),
                          );
                        } else if (item.isPdf && !item.isSplitFile) {
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: Container(width: 40, height: 40,
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 24)),
                              title: Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              subtitle: item.size != null ? Text('${(item.size! / 1024 / 1024).toStringAsFixed(1)} MB', style: const TextStyle(fontSize: 12)) : null,
                              trailing: const Icon(Icons.download, color: Colors.blue, size: 20),
                              onTap: () => _openPdf(item),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
    );
  }

  void _showLocalPdfs() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        if (_localPdfs.isEmpty) {
          return SizedBox(height: 200, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.folder_off, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('暂无本地教材', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text('下载后会自动保存在工作目录', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ])));
        }
        return DraggableScrollableSheet(
          initialChildSize: 0.6, minChildSize: 0.3, maxChildSize: 0.9, expand: false,
          builder: (ctx, sc) => Column(children: [
            Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              Text('本地教材 (${_localPdfs.length})', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ])),
            const Divider(height: 1),
            Expanded(child: ListView.builder(
              controller: sc, itemCount: _localPdfs.length,
              itemBuilder: (ctx, i) {
                final f = _localPdfs[i];
                final name = f.path.split('/').last;
                final size = f.lengthSync();
                return ListTile(
                  leading: Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Icon(Icons.picture_as_pdf, color: Colors.green.shade700, size: 20)),
                  title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  subtitle: Text(size > 0 ? '${(size / 1024 / 1024).toStringAsFixed(1)} MB' : '', style: const TextStyle(fontSize: 11)),
                  onTap: () { Navigator.pop(ctx); _openLocalPdf(f); },
                );
              },
            )),
          ]),
        );
      },
    );
  }
}
