import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// 自动更新检查服务
///
/// 从 GitHub Releases API 获取最新版本信息。
/// 仓库: https://github.com/ZhuoMoStudio/Smart-classroom
class UpdateService {
  static const String _owner = 'ZhuoMoStudio';
  static const String _repo = 'Smart-classroom';
  static const String _repoUrl = 'https://github.com/ZhuoMoStudio/Smart-classroom';

  static Future<String> getCurrentVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  static Future<String?> getLatestVersion() async {
    try {
      final r = await http.get(
        Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/latest'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'SmartClassroom/1.0',
        },
      );
      if (r.statusCode == 200) {
        final tag = jsonDecode(r.body)['tag_name']?.toString() ?? '';
        return tag.replaceAll('v', '');
      }
    } catch (_) {}
    return null;
  }

  /// 获取最新发布的下载 URL
  static Future<String?> getLatestDownloadUrl() async {
    try {
      final r = await http.get(
        Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        return data['html_url']?.toString();
      }
    } catch (_) {}
    return null;
  }

  static String releaseUrl(String version) =>
      '$_repoUrl/releases/tag/v$version';

  /// 检查更新
  static Future<UpdateResult> check() async {
    final cur = await getCurrentVersion();
    final lat = await getLatestVersion();

    if (lat == null) {
      return UpdateResult(
        hasUpdate: false,
        message: '无法获取更新信息，请检查网络连接',
      );
    }

    final hasUpdate = _compareVersions(cur, lat) < 0;
    return UpdateResult(
      hasUpdate: hasUpdate,
      currentVersion: cur,
      latestVersion: lat,
      downloadUrl: hasUpdate ? releaseUrl(lat) : null,
      message: hasUpdate ? '发现新版本 v$lat' : '已是最新版本',
    );
  }

  static int _compareVersions(String a, String b) {
    final ap = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final bp = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final len = ap.length > bp.length ? ap.length : bp.length;
    for (int i = 0; i < len; i++) {
      final av = i < ap.length ? ap[i] : 0;
      final bv = i < bp.length ? bp[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
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
