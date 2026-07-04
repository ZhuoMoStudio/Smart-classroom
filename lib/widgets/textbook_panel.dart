import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../services/textbook_index_service.dart';
import '../services/pdf_cache_manager.dart';
import '../services/gh_proxy_service.dart';
import '../providers/settings_provider.dart';
import '../theme/design_tokens.dart';
import '../theme/route_utils.dart';
import '../screens/pdf_reader_screen.dart';
import 'toast_overlay.dart';

/// 教材面板 — 内嵌三层次浏览（学段→科目→版本）
/// 数据来源：assets/textbook_index.json（embedded）
/// 支持：浏览/搜索/下载/导入外部PDF
class TextbookPanel extends ConsumerStatefulWidget {
  const TextbookPanel({super.key});
  @override
  ConsumerState<TextbookPanel> createState() => _TextbookPanelState();
}

class _TextbookPanelState extends ConsumerState<TextbookPanel> {
  bool _loaded = false;
  String _error = '';

  // 浏览状态
  String? _selectedStage;
  String? _selectedSubject;
  String? _selectedVersion;
  final List<String> _breadcrumbs = [];

  // 搜索
  bool _searchMode = false;
  final TextEditingController _searchCtrl = TextEditingController();
  List<TextbookFileInfo> _searchResults = [];

  // 下载
  bool _downloading = false;
  String _downloadStatus = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      await TextbookIndexService.load();
      if (mounted) setState(() => _loaded = true);
    } catch (e) {
      if (mounted) setState(() {
        _loaded = true;
        _error = '加载教材索引失败: $e';
      });
    }
  }

  // ==================== 浏览导航 ====================

  void _selectStage(String stage) {
    setState(() {
      _selectedStage = stage;
      _selectedSubject = null;
      _selectedVersion = null;
      _breadcrumbs.add(stage);
    });
  }

  void _selectSubject(String subject) {
    setState(() {
      _selectedSubject = subject;
      _selectedVersion = null;
      _breadcrumbs.add(subject);
    });
  }

  void _selectVersion(String version) {
    setState(() {
      _selectedVersion = version;
      _breadcrumbs.add(version);
    });
  }

  void _goBack() {
    if (_breadcrumbs.isEmpty) return;
    setState(() {
      _breadcrumbs.removeLast();
      if (_breadcrumbs.isEmpty) {
        _selectedStage = null;
        _selectedSubject = null;
        _selectedVersion = null;
      } else if (_selectedVersion != null) {
        _selectedVersion = null;
      } else if (_selectedSubject != null) {
        _selectedSubject = null;
      } else {
        _selectedStage = null;
      }
    });
  }

  void _reset() {
    setState(() {
      _selectedStage = null;
      _selectedSubject = null;
      _selectedVersion = null;
      _breadcrumbs.clear();
      _searchMode = false;
      _searchCtrl.clear();
      _searchResults = [];
    });
  }

  // ==================== 搜索 ====================

  void _doSearch(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searchResults = TextbookIndexService.search(query));
  }

  // ==================== 下载 ====================

  Future<void> _downloadAndOpen({
    required String name,
    required String filePath,
    String? downloadUrl,
  }) async {
    final url = downloadUrl ?? TextbookIndexService.getDownloadUrl(filePath);
    setState(() {
      _downloading = true;
      _downloadStatus = '正在下载 $name...';
    });

    try {
      final cm = PdfCacheManager();
      final useMirror =
          ref.read(settingsProvider).downloadSource == 'mirror';
      final finalUrl = useMirror ? GhProxyService.toProxyUrl(url) : url;

      final localPath = await cm.downloadAndCache(finalUrl,
          onProgress: (r, t) {
            if (mounted && t > 0) {
              setState(() =>
                  _downloadStatus = '下载中 ${(r / 1024 / 1024).toStringAsFixed(1)}MB / ${(t / 1024 / 1024).toStringAsFixed(1)}MB');
            }
          },
          onStatus: (s) {
            if (mounted) {
              setState(() {
                switch (s) {
                  case DownloadState.downloading:
                    _downloadStatus = '下载中...';
                  case DownloadState.completed:
                    _downloadStatus = '下载完成';
                  case DownloadState.failed:
                    _downloadStatus = '下载失败';
                  default:
                    break;
                }
              });
            }
          });

      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadStatus = '';
        });
        Navigator.push(
          context,
          slideFadePageRoute(PdfReaderScreen(
            title: name,
            localFilePath: localPath,
          )),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadStatus = '';
        });
        ToastOverlay.show(context, '下载失败: $e', type: ToastType.error);
      }
    }
  }

  // ==================== 导入外部PDF ====================

  Future<void> _importExternalPdf() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (r == null || r.files.isEmpty) return;
    final path = r.files.single.path;
    if (path == null) return;
    if (!mounted) return;
    Navigator.push(
      context,
      slideFadePageRoute(PdfReaderScreen(
        title: r.files.single.name,
        localFilePath: path,
      )),
    );
  }

  // ==================== 构建界面 ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // 标题栏
        _buildHeader(theme),
        const Divider(height: 1),
        // 状态信息
        if (_downloading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5)),
                const SizedBox(width: 8),
                Text(_downloadStatus, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        // 面包屑导航
        if (_breadcrumbs.isNotEmpty) _buildBreadcrumbs(theme),
        // 错误提示
        if (_error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error, style: TextStyle(color: Colors.red.shade400)),
          ),
        // 主内容
        Expanded(child: _buildContent(theme)),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // 返回按钮
          if (_breadcrumbs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              visualDensity: VisualDensity.compact,
              onPressed: _goBack,
            ),
          Icon(Icons.menu_book, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _searchMode ? '搜索教材' : '教材仓库',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          // 搜索切换
          IconButton(
            icon: Icon(_searchMode ? Icons.close : Icons.search, size: 18),
            tooltip: _searchMode ? '关闭搜索' : '搜索',
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                setState(() => _searchMode = !_searchMode),
          ),
          // 重置
          if (_breadcrumbs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.home, size: 18),
              tooltip: '返回首页',
              visualDensity: VisualDensity.compact,
              onPressed: _reset,
            ),
          // 导入外部PDF
          IconButton(
            icon: const Icon(Icons.file_open, size: 18),
            tooltip: '导入外部PDF',
            visualDensity: VisualDensity.compact,
            onPressed: _importExternalPdf,
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _breadcrumbs.asMap().entries.map((entry) {
            final i = entry.key;
            final crumb = entry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (i > 0)
                  Icon(Icons.chevron_right, size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.3)),
                GestureDetector(
                  onTap: () {
                    // 点击面包屑回到对应层级
                    while (_breadcrumbs.length > i + 1) _goBack();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      crumb.length > 12 ? '${crumb.substring(0, 12)}...' : crumb,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: i == _breadcrumbs.length - 1
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: i == _breadcrumbs.length - 1
                            ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    // 搜索模式
    if (_searchMode) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '搜索教材名称、科目、版本...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          _doSearch('');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _doSearch,
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchCtrl.text.isEmpty
                          ? '输入关键词搜索教材'
                          : '未找到匹配的教材',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _searchResults.length,
                    itemBuilder: (ctx, i) {
                      final r = _searchResults[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.picture_as_pdf,
                                size: 16, color: Colors.red),
                          ),
                          title: Text(r.name, style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${r.stage} › ${r.subject} › ${r.version}',
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _downloadAndOpen(
                              name: r.name, filePath: r.path),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    // 文件列表（已选到版本层级）
    if (_selectedStage != null &&
        _selectedSubject != null &&
        _selectedVersion != null) {
      return _buildFileList(theme);
    }

    // 版本选择（已选到科目层级）
    if (_selectedStage != null && _selectedSubject != null) {
      return _buildVersionList(theme);
    }

    // 科目选择（已选到学段层级）
    if (_selectedStage != null) {
      return _buildSubjectList(theme);
    }

    // 学段选择（根层级）
    return _buildStageList(theme);
  }

  Widget _buildStageList(ThemeData theme) {
    final stages = TextbookIndexService.getStages();
    final stats = TextbookIndexService.getStats();

    if (stages.isEmpty && _error.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('教材索引加载中...', style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 统计
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.library_books, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '共 ${stats['stages']} 个学段 · ${stats['subjects']} 个科目 · ${stats['files']} 本教材',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
        // 学段列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: stages.length,
            itemBuilder: (ctx, i) {
              final stage = stages[i];
              final subjects = TextbookIndexService.getSubjects(stage);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _iconColorForStage(stage).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.school,
                        color: _iconColorForStage(stage), size: 20),
                  ),
                  title: Text(stage, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${subjects.length} 个科目',
                      style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => _selectStage(stage),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectList(ThemeData theme) {
    final subjects = TextbookIndexService.getSubjects(_selectedStage!);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: subjects.length,
      itemBuilder: (ctx, i) {
        final subject = subjects[i];
        final versions = TextbookIndexService.getVersions(
            _selectedStage!, subject);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _subjectIconColor(subject).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_subjectIcon(subject),
                  color: _subjectIconColor(subject), size: 18),
            ),
            title: Text(subject, style: const TextStyle(fontSize: 14)),
            subtitle: Text('${versions.length} 个版本',
                style: const TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => _selectSubject(subject),
          ),
        );
      },
    );
  }

  Widget _buildVersionList(ThemeData theme) {
    final versions =
        TextbookIndexService.getVersions(_selectedStage!, _selectedSubject!);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: versions.length,
      itemBuilder: (ctx, i) {
        final version = versions[i];
        final files =
            TextbookIndexService.getFiles(_selectedStage!, _selectedSubject!, version);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.library_books,
                  color: Colors.blue, size: 18),
            ),
            title: Text(version, style: const TextStyle(fontSize: 13)),
            subtitle: Text('${files.length} 本教材',
                style: const TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => _selectVersion(version),
          ),
        );
      },
    );
  }

  Widget _buildFileList(ThemeData theme) {
    final files = TextbookIndexService.getFiles(
        _selectedStage!, _selectedSubject!, _selectedVersion!);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: files.length,
      itemBuilder: (ctx, i) {
        final file = files[i];
        final name = file['n']!;
        final path = file['p']!;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 2),
          child: ListTile(
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.picture_as_pdf,
                  color: Colors.red, size: 18),
            ),
            title: Text(name, style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.download, size: 18, color: Colors.blue),
            onTap: () => _downloadAndOpen(name: name, filePath: path),
          ),
        );
      },
    );
  }

  // ==================== 辅助 ====================

  Color _iconColorForStage(String stage) {
    if (stage.contains('小学')) return Colors.orange;
    if (stage.contains('初中')) return Colors.blue;
    if (stage.contains('高中')) return Colors.purple;
    if (stage.contains('大学')) return Colors.teal;
    return Colors.grey;
  }

  Color _subjectIconColor(String subject) {
    if (subject.contains('语文') || subject.contains('道德')) return Colors.red;
    if (subject.contains('数学')) return Colors.blue;
    if (subject.contains('英语')) return Colors.green;
    if (subject.contains('物理') || subject.contains('化学') ||
        subject.contains('生物') || subject.contains('科学')) return Colors.teal;
    if (subject.contains('历史') || subject.contains('地理')) return Colors.brown;
    if (subject.contains('音乐') || subject.contains('美术') ||
        subject.contains('艺术')) return Colors.pink;
    if (subject.contains('体育')) return Colors.orange;
    return Colors.grey;
  }

  IconData _subjectIcon(String subject) {
    if (subject.contains('语文') || subject.contains('道德')) return Icons.abc;
    if (subject.contains('数学')) return Icons.functions;
    if (subject.contains('英语')) return Icons.language;
    if (subject.contains('物理')) return Icons.biotech;
    if (subject.contains('化学')) return Icons.science;
    if (subject.contains('生物') || subject.contains('科学')) return Icons.eco;
    if (subject.contains('历史')) return Icons.history;
    if (subject.contains('地理')) return Icons.public;
    if (subject.contains('音乐')) return Icons.music_note;
    if (subject.contains('美术') || subject.contains('艺术')) return Icons.palette;
    if (subject.contains('体育')) return Icons.directions_run;
    if (subject.contains('信息') || subject.contains('技术')) return Icons.computer;
    return Icons.book;
  }
}
