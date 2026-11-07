/// GitHub 文件下载加速代理服务
///
/// 教材仓库（TapXWorld/ChinaTextbook）的 PDF 托管在 GitHub raw 上，
/// 国内直连经常超时，因此提供若干公共加速镜像作为备选。
///
/// 两个曾经的坑：
///  1. **镜像列表从未被真正验证过**。旧代码里的 `ghproxy.net` / `mirror.ghproxy.com`
///     早已不可用（TLS 握手超时 / 连接被重置），而下载逻辑又会先试「原始 URL」，
///     于是镜像开关看上去存在、实际永远走不到能用的那一个。现在只保留实测可用的源。
///  2. **`resolveRawUrl` 里的 for 循环是假的**：它在第一次迭代就 return，
///     后面的镜像永远不会被尝试。真正的多源回退在 [candidates] 里。
class GhProxyService {
  static const String githubRaw = 'https://raw.githubusercontent.com';

  /// 公共加速镜像，按实测可用性排序（2026-11 验证）。
  /// 镜像随时可能失效，因此下载逻辑必须允许逐个回退到原始 URL。
  static const List<String> mirrors = <String>[
    'https://gh-proxy.com',
    'https://ghfast.top',
  ];

  /// 是否为需要加速的 GitHub raw 地址。
  static bool isRawGithubUrl(String url) => url.startsWith('$githubRaw/');

  /// 返回按优先级排列的候选下载地址。
  ///
  /// [useMirror] 为 true 时镜像优先、原始地址兜底；否则反过来。
  /// 非 GitHub raw 地址原样返回，绝不拼接（否则会得到 `mirror/https://其他站点/...`）。
  static List<String> candidates(String url, {bool useMirror = false}) {
    if (!isRawGithubUrl(url)) return <String>[url];
    final proxied = mirrors.map((m) => '$m/$url').toList(growable: false);
    return useMirror ? <String>[...proxied, url] : <String>[url, ...proxied];
  }

  /// 把 GitHub raw URL 转成单个代理 URL（用于只需要一个地址的场景）。
  static String toProxyUrl(String rawUrl, {int mirrorIndex = 0}) {
    if (!isRawGithubUrl(rawUrl)) return rawUrl;
    final i = mirrorIndex.clamp(0, mirrors.length - 1);
    return '${mirrors[i]}/$rawUrl';
  }
}
