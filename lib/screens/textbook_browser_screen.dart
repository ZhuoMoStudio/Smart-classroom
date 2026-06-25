import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/textbook_repo_service.dart';
import '../services/gh_proxy_service.dart';
import '../widgets/toast_overlay.dart';
import 'pdf_reader_screen.dart';

/// 教材仓库浏览器
///
/// 浏览 GitHub ChinaTextbook 仓库中的教材目录，
/// 点击教材 PDF 自动下载并通过 pdfrx 打开。
/// 所有 GitHub raw 链接通过 ghproxy 加速。
class TextbookBrowserScreen extends ConsumerStatefulWidget {
  const TextbookBrowserScreen({super.key});

  @override
  ConsumerState<TextbookBrowserScreen> createState() =>
      _TextbookBrowserScreenState();
}

class _TextbookBrowserScreenState extends ConsumerState<TextbookBrowserScreen> {
  List<TextbookItem> _items = [];
  bool _isLoading = true;
  String _currentPath = '';
  String _errorMessage = '';
  // 导航路径栈
  final List<String> _pathStack = [];

  @override
  void initState() {
    super.initState();
    _loadDirectory('');
  }

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _currentPath = path;
    });

    try {
      final items = await TextbookRepoService.fetchContents(path);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '加载目录失败: $e';
        });
        ToastOverlay.show(context, _errorMessage);
      }
    }
  }

  void _navigateInto(TextbookItem item) {
    if (item.type != 'dir') return;
    _pathStack.add(_currentPath);
    _loadDirectory(item.path);
  }

  Future<void> _navigateBack() async {
    if (_pathStack.isEmpty) return;
    final parentPath = _pathStack.removeLast();
    _loadDirectory(parentPath);
  }

  void _openPdf(TextbookItem item) {
    if (item.downloadUrl == null) {
      ToastOverlay.show(context, '无法获取下载链接');
      return;
    }

    // 通过 ghproxy 加速
    final proxyUrl = GhProxyService.toProxyUrl(item.downloadUrl!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfReaderScreen(
          title: item.name,
          networkUrl: item.downloadUrl, // 传入原始 URL，缓存管理会自动使用代理
          initialPage: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_pathStack.isNotEmpty) {
              _navigateBack();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(_currentPath.isEmpty ? '教材仓库' : _currentPath),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadDirectory(_currentPath),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索全部 PDF',
            onPressed: _searchAllPdfs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在加载教材目录...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(_errorMessage,
                          style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('重试'),
                        onPressed: () => _loadDirectory(_currentPath),
                      ),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? const Center(child: Text('此目录为空'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        if (item.type == 'dir') {
                          return _buildDirectoryItem(item, theme);
                        } else if (item.isPdf && !item.isSplitFile) {
                          return _buildPdfItem(item, theme);
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
    );
  }

  Widget _buildDirectoryItem(TextbookItem item, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(Icons.folder, color: Colors.amber.shade700, size: 32),
        title: Text(item.name,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateInto(item),
      ),
    );
  }

  Widget _buildPdfItem(TextbookItem item, ThemeData theme) {
    final sizeText = item.size != null
        ? '${(item.size! / 1024 / 1024).toStringAsFixed(1)} MB'
        : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 24),
        ),
        title: Text(item.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: sizeText.isNotEmpty
            ? Text(sizeText, style: const TextStyle(fontSize: 12))
            : null,
        trailing: const Icon(Icons.download, color: Colors.blue),
        onTap: () => _openPdf(item),
      ),
    );
  }

  /// 搜索并显示所有 PDF 文件
  Future<void> _searchAllPdfs() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final pdfs = await TextbookRepoService.fetchAllPdfs(
        onProgress: (count) {},
      );
      TextbookRepoService.clearCache();

      Navigator.pop(context); // 关闭 loading

      if (!mounted) return;

      if (pdfs.isEmpty) {
        ToastOverlay.show(context, '未找到 PDF 文件');
        return;
      }

      // 显示 PDF 列表
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (ctx, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          '全部教材 (${pdfs.length} 本)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: pdfs.length,
                      itemBuilder: (ctx, index) {
                        final item = pdfs[index];
                        final sizeText = item.size != null
                            ? '${(item.size! / 1024 / 1024).toStringAsFixed(1)} MB'
                            : '';
                        return ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.picture_as_pdf,
                                color: Colors.red.shade700, size: 20),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            '${item.path}$sizeText',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () {
                            Navigator.pop(ctx); // 关闭 bottom sheet
                            _openPdf(item);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      Navigator.pop(context); // 关闭 loading
      ToastOverlay.show(context, '搜索失败: $e');
    }
  }
}
