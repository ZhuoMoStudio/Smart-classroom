import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/textbook_repo_service.dart';
import '../services/textbook_index_service.dart';
import '../services/pdf_cache_manager.dart';
import '../theme/design_tokens.dart';
import '../theme/route_utils.dart';
import '../screens/pdf_reader_screen.dart';
import 'toast_overlay.dart';
import 'glass_panel.dart';

/// 教材面板 — 内部组件，集成在主页中
///
/// 显示本地保存的教材目录索引，用户点击后才下载 PDF。
/// 不直接访问浏览器，所有目录信息缓存在本地。
class TextbookPanel extends ConsumerStatefulWidget {
  const TextbookPanel({super.key});

  @override
  ConsumerState<TextbookPanel> createState() => _TextbookPanelState();
}

class _TextbookPanelState extends ConsumerState<TextbookPanel> {
  List<Map<String, dynamic>> _currentDirs = [];
  List<Map<String, dynamic>> _currentFiles = [];
  final List<String> _pathStack = [];
  String _currentPath = '';
  bool _isLoading = false;
  bool _isUpdating = false;
  String _statusMessage = '';
  int _updatingProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadLocalIndex();
  }

  /// 加载本地索引
  Future<void> _loadLocalIndex() async {
    await TextbookIndexService.loadIndex();
    _refreshContents();
  }

  /// 刷新当前目录内容
  void _refreshContents() {
    final (dirs, files) = TextbookIndexService.getContents(_currentPath);
    if (!mounted) return;
    setState(() {
      _currentDirs = dirs;
      _currentFiles = files;
    });
  }

  /// 进入子目录
  void _navigateInto(Map<String, dynamic> dir) {
    _pathStack.add(_currentPath);
    setState(() {
      _currentPath = dir['path'] as String;
    });
    _refreshContents();
  }

  /// 返回上级目录
  void _navigateBack() {
    if (_pathStack.isEmpty) return;
    setState(() {
      _currentPath = _pathStack.removeLast();
    });
    _refreshContents();
  }

  /// 更新索引
  Future<void> _updateIndex() async {
    setState(() {
      _isUpdating = true;
      _statusMessage = '正在获取教材目录...';
    });

    await TextbookIndexService.updateFromRemote(
      onStatus: (msg) {
        if (mounted) setState(() => _statusMessage = msg);
      },
    );

    if (mounted) {
      setState(() {
        _isUpdating = false;
      });
      _refreshContents();
      ToastOverlay.show(context, '教材目录已更新');
    }
  }

  /// 下载并打开教材
  Future<void> _downloadAndOpen(Map<String, dynamic> fileItem) async {
    final path = fileItem['path'] as String;
    final name = fileItem['name'] as String;
    final downloadUrl = fileItem['downloadUrl'] as String?;

    // 检查是否已下载
    final existingPath = TextbookIndexService.getDownloadedPath(path);
    if (existingPath != null) {
      _openPdf(name, localPath: existingPath);
      return;
    }

    if (downloadUrl == null || downloadUrl.isEmpty) {
      ToastOverlay.show(context, '无法获取下载链接', type: ToastType.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cm = PdfCacheManager();
      final useMirror = ref.read(settingsProvider).downloadSource == 'mirror';
      final url = useMirror
          ? GhProxyService.toProxyUrl(downloadUrl)
          : downloadUrl;

      final localPath = await cm.downloadAndCache(
        url,
        onProgress: (received, total) {
          if (mounted && total > 0) {
            setState(() {
              _statusMessage =
                  '下载中... ${(received / 1024 / 1024).toStringAsFixed(1)}MB / ${(total / 1024 / 1024).toStringAsFixed(1)}MB';
            });
          }
        },
        onStatus: (state) {
          if (mounted) {
            setState(() {
              switch (state) {
                case DownloadState.downloading:
                  _statusMessage = '下载中...';
                case DownloadState.completed:
                  _statusMessage = '下载完成';
                case DownloadState.failed:
                  _statusMessage = '下载失败';
                default:
                  break;
              }
            });
          }
        },
      );

      // 记录下载
      await TextbookIndexService.markDownloaded(path, localPath);
      await TextbookIndexService.saveIndex();

      if (mounted) {
        setState(() => _isLoading = false);
        _openPdf(name, localPath: localPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastOverlay.show(context, '下载失败: $e', type: ToastType.error);
      }
    }
  }

  void _openPdf(String title, {required String localPath}) {
    Navigator.push(
      context,
      slideFadePageRoute(
        PdfReaderScreen(
          title: title,
          localFilePath: localPath,
          initialPage: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRoot = _currentPath.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // 返回按钮
              if (!isRoot)
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: _navigateBack,
                ),
              Icon(
                isRoot ? Icons.menu_book : Icons.folder,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRoot
                      ? '教材仓库'
                      : _currentPath.split('/').last,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // 更新按钮
              _isUpdating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: '更新目录',
                      visualDensity: VisualDensity.compact,
                      onPressed: _updateIndex,
                    ),
            ],
          ),
        ),

        // 状态信息
        if (_statusMessage.isNotEmpty && _isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                const SizedBox(width: 8),
                Text(
                  _statusMessage,
                  style: theme.textTheme.caption,
                ),
              ],
            ),
          ),

        // 下载统计
        if (isRoot && !_isLoading) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildDownloadStats(theme),
          ),
          const SizedBox(height: 4),
        ],

        const Divider(height: 1),

        // 内容区
        Expanded(
          child: _buildContent(theme),
        ),
      ],
    );
  }

  Widget _buildDownloadStats(ThemeData theme) {
    final (downloaded, total) = TextbookIndexService.getDownloadStats();
    return Row(
      children: [
        Icon(Icons.download_done, size: 14, color: Colors.green.shade400),
        const SizedBox(width: 4),
        Text(
          '已下载 $downloaded / $total 本',
          style: theme.textTheme.caption?.copyWith(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        const Spacer(),
        if (total == 0)
          Text(
            '请点击右上角刷新获取目录',
            style: theme.textTheme.caption?.copyWith(fontSize: 11),
          ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    final isEmpty = _currentDirs.isEmpty && _currentFiles.isEmpty;

    if (_isUpdating && isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 12),
            Text(
              _statusMessage.isEmpty ? '正在更新目录...' : _statusMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              '暂无教材目录',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右上角刷新获取教材目录',
              style: theme.textTheme.caption,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('刷新目录'),
              onPressed: _updateIndex,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      children: [
        // 目录项
        ..._currentDirs.map((dir) => _buildDirTile(dir, theme)),
        // 文件项
        ..._currentFiles.map((file) => _buildFileTile(file, theme)),
      ],
    );
  }

  Widget _buildDirTile(Map<String, dynamic> dir, ThemeData theme) {
    final name = dir['name'] as String? ?? '';
    final childCount = (dir['children'] as List?)?.length ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.folder, color: Colors.amber.shade700, size: 20),
        ),
        title: Text(
          name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: childCount > 0
            ? Text('$childCount 项', style: const TextStyle(fontSize: 11))
            : null,
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () => _navigateInto(dir),
      ),
    );
  }

  Widget _buildFileTile(Map<String, dynamic> file, ThemeData theme) {
    final name = file['name'] as String? ?? '';
    final path = file['path'] as String? ?? '';
    final size = file['size'] as int? ?? 0;
    final isDownloaded = TextbookIndexService.isDownloaded(path);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      elevation: 0,
      color: isDownloaded
          ? Colors.green.withOpacity(0.05)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDownloaded
                ? Colors.green.withOpacity(0.12)
                : Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isDownloaded ? Icons.picture_as_pdf : Icons.download,
            color: isDownloaded ? Colors.green.shade700 : Colors.red.shade400,
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDownloaded ? Colors.green.shade800 : null,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: size > 0
            ? Text(
                '${(size / 1024 / 1024).toStringAsFixed(1)} MB${isDownloaded ? ' • 已下载' : ''}',
                style: const TextStyle(fontSize: 11),
              )
            : null,
        trailing: isDownloaded
            ? Icon(Icons.check_circle, size: 18, color: Colors.green.shade400)
            : const Icon(Icons.download, size: 18, color: Colors.blue),
        onTap: () => _downloadAndOpen(file),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}