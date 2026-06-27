/// GitHub 文件下载加速代理服务
///
/// 将 GitHub raw 原始链接通过国内加速镜像代理，确保国内无需翻墙即可下载。
/// 代理源优先级：ghproxy > gh-proxy (gitcode 镜像)
///
/// 遵循 MIT 协议
class GhProxyService {
  // GitHub raw 原始链接前缀
  static const String _githubRawPrefix = 'https://raw.githubusercontent.com/';

  // 代理镜像列表（按优先级排序）
  static const List<String> _proxyMirrors = [
    'https://ghproxy.net/',
    'https://mirror.ghproxy.com/',
    'https://gh-proxy.com/',
  ];

  /// 将 GitHub raw URL 转换为代理 URL
  ///
  /// 例：https://raw.githubusercontent.com/TapXWorld/ChinaTextbook/main/xxx.pdf
  ///  →  https://ghproxy.net/https://raw.githubusercontent.com/TapXWorld/ChinaTextbook/main/xxx.pdf
  static String toProxyUrl(String rawUrl, {int mirrorIndex = 0}) {
    if (!rawUrl.startsWith(_githubRawPrefix)) {
      // 不是 GitHub raw 链接，直接返回
      return rawUrl;
    }
    final mirror =
        _proxyMirrors[mirrorIndex.clamp(0, _proxyMirrors.length - 1)];
    return '$mirror$rawUrl';
  }

  /// 获取多个代理 URL（用于轮询重试）
  static List<String> toProxyUrls(String rawUrl) {
    if (!rawUrl.startsWith(_githubRawPrefix)) return [rawUrl];
    return _proxyMirrors.map((m) => '$m$rawUrl').toList();
  }

  /// 判断 URL 是否为 GitHub raw 链接
  static bool isGithubRawUrl(String url) {
    return url.startsWith(_githubRawPrefix);
  }

  /// 从 GitHub raw URL 中提取仓库信息
  ///
  /// 返回 (owner, repo, branch, filePath)
  static (String, String, String, String)? parseGithubRawUrl(String url) {
    if (!url.startsWith(_githubRawPrefix)) return null;
    final parts = url.substring(_githubRawPrefix.length).split('/');
    if (parts.length < 4) return null;
    return (parts[0], parts[1], parts[2], parts.sublist(3).join('/'));
  }

  /// 构建 ChinaTextbook 仓库中的文件 raw URL
  ///
  /// [filePath] 相对于仓库根目录的路径，如 "高中/语文/必修上册.pdf"
  static String chinaTextbookRawUrl(String filePath) {
    return 'https://raw.githubusercontent.com/TapXWorld/ChinaTextbook/main/$filePath';
  }

  /// 构建 ChinaTextbook 仓库 API URL（用于获取文件列表）
  static String chinaTextbookApiUrl({String path = ''}) {
    return 'https://api.github.com/repos/TapXWorld/ChinaTextbook/contents/$path';
  }
}
