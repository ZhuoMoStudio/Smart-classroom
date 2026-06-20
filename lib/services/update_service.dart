import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static const _owner = 'ZhuoMoStudio';
  static const _repo = 'Smart-classroom';

  static Future<String> getCurrentVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  static Future<String?> getLatestVersion() async {
    try {
      final r = await http.get(
        Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'});
      if (r.statusCode == 200) return jsonDecode(r.body)['tag_name']?.toString().replaceAll('v', '');
    } catch (_) {} return null;
  }

  static String downloadUrl(String v) => 'https://github.com/$_owner/$_repo/releases/tag/v$v';

  static Future<UpdateResult> check() async {
    final cur = await getCurrentVersion();
    final lat = await getLatestVersion();
    if (lat == null) return UpdateResult(hasUpdate: false, message: '无法获取更新信息');
    return UpdateResult(hasUpdate: _cmp(cur, lat) < 0, currentVersion: cur,
        latestVersion: lat, downloadUrl: downloadUrl(lat));
  }

  static int _cmp(String a, String b) {
    final ap = a.split('.').map(int.parse).toList();
    final bp = b.split('.').map(int.parse).toList();
    for (int i=0;i<3;i++) {
      final av = i<ap.length?ap[i]:0, bv = i<bp.length?bp[i]:0;
      if (av!=bv) return av.compareTo(bv);
    } return 0;
  }
}

class UpdateResult {
  final bool hasUpdate;
  final String? currentVersion, latestVersion, downloadUrl, message;
  const UpdateResult({required this.hasUpdate, this.currentVersion,
      this.latestVersion, this.downloadUrl, this.message});
}
