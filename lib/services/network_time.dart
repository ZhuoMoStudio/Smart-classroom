import 'dart:convert';
import 'package:http/http.dart' as http;

/// 网络时间获取服务 — 多 API 备选 + HTTP Date header 降级
class NetworkTimeService {
  // API 列表（按可靠性排序）
  static const _timeApis = <String>[
    'https://worldtimeapi.org/api/timezone/Etc/UTC',
    'https://www.timeapi.io/api/Time/current/zone?timeZone=UTC',
    'https://timeapi.io/api/Time/current/zone?timeZone=UTC',
    // 用普通 HTTP 请求的 Date header 作为最后备选
    'https://www.baidu.com',
    'https://www.google.com',
  ];

  static Future<DateTime?> getNetworkTime() async {
    for (final url in _timeApis) {
      try {
        final r = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 5));

        // 尝试 JSON API
        if (r.statusCode == 200 && r.headers['content-type']?.contains('json') == true) {
          final body = jsonDecode(r.body);
          // worldtimeapi.org
          final utcStr = body['utc_datetime'] as String?;
          if (utcStr != null) return DateTime.parse(utcStr);
          // timeapi.io
          final datetimeStr = body['datetime'] as String?;
          if (datetimeStr != null) return DateTime.parse(datetimeStr);
        }

        // 备选：从 Date header 解析
        final dateHeader = r.headers['date'];
        if (dateHeader != null) {
          final parsed = HttpDate.parse(dateHeader);
          if (parsed != null) return parsed;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}

/// 简单 HTTP Date 解析
class HttpDate {
  static DateTime? parse(String dateStr) {
    try {
      // HTTP date format: "Thu, 01 Jan 2024 12:00:00 GMT"
      return DateTime.parse(dateStr.replaceAll(RegExp(r'^[A-Z][a-z]{2},\s*'), '')
          .replaceAll('GMT', '')
          .trim());
    } catch (_) {
      return null;
    }
  }
}
