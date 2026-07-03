/// GitHub 文件下载加速代理服务
///
/// 根据 downloadSource 设置切换 GitHub 官方源或国内镜像。
/// 内置多个国内镜像源，支持轮询。
class GhProxyService {
  // GitHub API 和 raw 前缀
  static const String githubApi = 'https://api.github.com';
  static const String githubRaw = 'https://raw.githubusercontent.com';

  // 国内镜像源列表（按优先级排序）
  static const List<String> mirrorApi = [
    'https://ghproxy.net',
    'https://mirror.ghproxy.com',
    'https://gh-proxy.com',
  ];

  // 教材仓库信息
  static const String textbookOwner = 'TapXWorld';
  static const String textbookRepo = 'ChinaTextbook';
  static const String textbookBranch = 'main';

  /// 根据设置决定是否使用镜像
  static String resolveRawUrl(String rawUrl, {bool useMirror = true}) {
    if (!useMirror) return rawUrl;
    if (!rawUrl.startsWith(githubRaw)) return rawUrl;
    for (final m in mirrorApi) {
      try {
        return '$m/$rawUrl';
      } catch (_) {
        continue;
      }
    }
    return rawUrl;
  }

  /// 获取教材目录列表的 API URL
  static String textbookContentsUrl(String path, {bool useMirror = true}) {
    final apiUrl = '$githubApi/repos/$textbookOwner/$textbookRepo/contents/$path';
    if (!useMirror) return apiUrl;
    return '$githubApi/repos/$textbookOwner/$textbookRepo/contents/$path';
  }

  /// 获取教材文件的下载 URL
  static String textbookDownloadUrl(String path, {bool useMirror = true}) {
    final rawUrl = '$githubRaw/$textbookOwner/$textbookRepo/$textbookBranch/$path';
    return resolveRawUrl(rawUrl, useMirror: useMirror);
  }

  /// 获取更新检查的 API URL
  static String releaseApiUrl({bool useMirror = true}) {
    return '$githubApi/repos/ZhuoMoStudio/Smart-classroom/releases/latest';
  }

  /// 将 GitHub raw URL 转为代理 URL
  static String toProxyUrl(String rawUrl, {int mirrorIndex = 0}) {
    if (!rawUrl.startsWith(githubRaw)) return rawUrl;
    final mirror = mirrorApi[mirrorIndex.clamp(0, mirrorApi.length - 1)];
    return '$mirror/$rawUrl';
  }

  /// 获取多个代理 URL（用于重试）
  static List<String> toProxyUrls(String rawUrl) {
    if (!rawUrl.startsWith(githubRaw)) return [rawUrl];
    return [rawUrl, ...mirrorApi.map((m) => '$m/$rawUrl')];
  }
}
