import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  // 请修改为你的实际仓库
  static const String _repoOwner = 'ZhuoMoStudio';
  static const String _repoName = 'Smart-classroom';

  /// 获取当前应用版本
  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// 从 GitHub Release 获取最新版本号
  static Future<String?> getLatestVersionFromGitHub() async {
    try {
      final url = Uri.parse('https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest');
      final response = await http.get(url, headers: {'Accept': 'application/vnd.github.v3+json'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['tag_name']?.toString().replaceAll('v', '');
      }
    } catch (_) {}
    return null;
  }

  /// 获取最新 Release 的下载页面 URL
  static String getReleaseDownloadUrl(String version) {
    return 'https://github.com/$_repoOwner/$_repoName/releases/tag/v$version';
  }

  /// 检查更新
  static Future<UpdateCheckResult> checkForUpdate() async {
    final current = await getCurrentVersion();
    final latest = await getLatestVersionFromGitHub();
    if (latest == null) return UpdateCheckResult(hasUpdate: false, message: '无法获取更新信息');
    final hasUpdate = _compareVersions(current, latest) < 0;
    return UpdateCheckResult(
      hasUpdate: hasUpdate,
      currentVersion: current,
      latestVersion: latest,
      downloadUrl: getReleaseDownloadUrl(latest),
    );
  }

  static int _compareVersions(String a, String b) {
    final aParts = a.split('.').map(int.parse).toList();
    final bParts = b.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      final av = i < aParts.length ? aParts[i] : 0;
      final bv = i < bParts.length ? bParts[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }
}

class UpdateCheckResult {
  final bool hasUpdate;
  final String? currentVersion;
  final String? latestVersion;
  final String? downloadUrl;
  final String? message;

  const UpdateCheckResult({
    required this.hasUpdate,
    this.currentVersion,
    this.latestVersion,
    this.downloadUrl,
    this.message,
  });
}