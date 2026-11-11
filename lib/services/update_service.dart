import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// 自动更新检查服务
///
/// 从 GitHub Releases API 获取最新版本信息。
/// 仓库: https://github.com/ZhuoMoStudio/Smart-classroom
///
/// 三个容易踩的点，都已在这里处理：
///  1. **请求必须带超时**。旧实现没有超时，网络半死不活时启动页会一直挂着，
///     老师只看到「打开就卡住」。
///  2. **tag 里的 `v` 只能去掉开头那一个**。`replaceAll('v', '')` 会把
///     `v1.2.0-v2` 之类的 tag 变成 `1.2.0-2`，比较结果随之出错。
///  3. **版本比较要看全部分段**。`1.10` 与 `1.9` 必须比较数字而不是字符串。
class UpdateService {
  static const String _owner = 'ZhuoMoStudio';
  static const String _repo = 'Smart-classroom';
  static const String _repoUrl =
      'https://github.com/ZhuoMoStudio/Smart-classroom';

  /// GitHub API 在国内经常很慢，超过这个时间就当作「无法检查」，
  /// 由调用方静默降级（绝不能影响启动）。
  static const Duration _timeout = Duration(seconds: 8);

  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return normalizeVersion(info.version);
  }

  /// 去掉开头的 `v`/`V`，并去掉 `+build` 后缀。
  static String normalizeVersion(String raw) {
    var v = raw.trim();
    if (v.startsWith('v') || v.startsWith('V')) {
      v = v.substring(1);
    }
    final plus = v.indexOf('+');
    if (plus >= 0) v = v.substring(0, plus);
    return v;
  }

  static Future<http.Response?> _fetchLatestRelease() async {
    try {
      return await http.get(
        Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/latest'),
        headers: const {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'SmartClassroom',
        },
      ).timeout(_timeout);
    } catch (e) {
      debugPrint('检查更新请求失败：$e');
      return null;
    }
  }

  static Future<String?> getLatestVersion() async {
    final r = await _fetchLatestRelease();
    if (r == null || r.statusCode != 200) return null;
    try {
      final tag = jsonDecode(utf8.decode(r.bodyBytes))['tag_name']?.toString();
      if (tag == null || tag.isEmpty) return null;
      return normalizeVersion(tag);
    } catch (e) {
      debugPrint('解析 Release 失败：$e');
      return null;
    }
  }

  /// 获取最新发布的下载页 URL
  static Future<String?> getLatestDownloadUrl() async {
    final r = await _fetchLatestRelease();
    if (r != null && r.statusCode == 200) {
      try {
        final data = jsonDecode(utf8.decode(r.bodyBytes));
        final url = data['html_url']?.toString();
        if (url != null && url.isNotEmpty) return url;
      } catch (e) {
        debugPrint('解析 Release 失败：$e');
      }
    }
    // 降级：返回仓库主页（用户可手动查看 releases）
    return _repoUrl;
  }

  /// 仓库的「最新版本」页面。用 latest 而不是具体 tag：
  /// 老师点「前往下载」时总会落到最新一版，不会因为客户端缓存了旧 tag 而扑空。
  static String get releasePageUrl => '$_repoUrl/releases/latest';

  /// 某个具体版本的 tag 页面（仅用于展示/日志）。
  static String releaseUrl(String version) =>
      '$_repoUrl/releases/tag/v${normalizeVersion(version)}';

  /// 检查更新
  static Future<UpdateResult> check() async {
    final cur = await getCurrentVersion();
    final lat = await getLatestVersion();

    if (lat == null) {
      return const UpdateResult(hasUpdate: false, message: '无法获取更新信息，请检查网络连接');
    }

    final hasUpdate = compareVersions(cur, lat) < 0;
    return UpdateResult(
      hasUpdate: hasUpdate,
      currentVersion: cur,
      latestVersion: lat,
      downloadUrl: hasUpdate ? releasePageUrl : null,
      message: hasUpdate ? '发现新版本 v$lat' : '已是最新版本',
    );
  }

  /// 语义化版本比较：逐段按数字比，缺失段按 0 处理。
  /// 返回 <0 表示 [a] 比 [b] 旧，0 相同，>0 表示更新。
  static int compareVersions(String a, String b) {
    final ap = _segments(a);
    final bp = _segments(b);
    final len = ap.length > bp.length ? ap.length : bp.length;
    for (var i = 0; i < len; i++) {
      final av = i < ap.length ? ap[i] : 0;
      final bv = i < bp.length ? bp[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }

  /// `1.32.2` -> [1, 32, 2]；非数字段（如 `-beta.1`）按 0 处理。
  static List<int> _segments(String version) {
    final core = normalizeVersion(version).split('-').first;
    return core.split('.').map((s) => int.tryParse(s) ?? 0).toList();
  }
}

class UpdateResult {
  final bool hasUpdate;
  final String? currentVersion;
  final String? latestVersion;
  final String? downloadUrl;
  final String? message;

  const UpdateResult({
    required this.hasUpdate,
    this.currentVersion,
    this.latestVersion,
    this.downloadUrl,
    this.message,
  });
}
