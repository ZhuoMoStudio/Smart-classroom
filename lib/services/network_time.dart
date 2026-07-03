import 'dart:convert';
import 'package:http/http.dart' as http;

/// 网络时间获取服务 — 多 API 备选
class NetworkTimeService {
  static const _apis = [
    'https://www.timeapi.io/api/Time/current/zone?timeZone=UTC',
    'https://worldtimeapi.org/api/timezone/Etc/UTC',
    'https://timeapi.io/api/Time/current/zone?timeZone=UTC',
  ];

  static Future<DateTime?> getNetworkTime() async {
    for (final url in _apis) {
      try {
        final r = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 5));
        if (r.statusCode == 200) {
          final body = jsonDecode(r.body);
          // timeapi.io
          final datetimeStr = body['datetime'] as String?;
          if (datetimeStr != null) {
            return DateTime.parse(datetimeStr);
          }
          // worldtimeapi.org
          final utcStr = body['utc_datetime'] as String?;
          if (utcStr != null) {
            return DateTime.parse(utcStr);
          }
        }
      } catch (_) {
        continue; // 尝试下一个 API
      }
    }
    return null; // 全部失败
  }
}
