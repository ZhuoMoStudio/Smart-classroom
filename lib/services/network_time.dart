import 'dart:convert';
import 'package:http/http.dart' as http;

class NetworkTimeService {
  /// 从 timeapi.io 获取网络时间
  ///
  /// 优先解析 JSON 响应体中的 [datetime] 字段（ISO8601/RFC3339），
  /// 降级解析 HTTP Date 头。
  static Future<DateTime?> getNetworkTime() async {
    try {
      final r = await http
          .get(Uri.parse(
              'https://www.timeapi.io/api/Time/current/zone?timeZone=UTC'))
          .timeout(const Duration(seconds: 5));

      if (r.statusCode == 200) {
        try {
          final body = jsonDecode(r.body);
          // timeapi.io JSON 字段为小写 datetime（非驼峰 dateTime）
          final datetimeStr = body['datetime'] as String?;
          if (datetimeStr != null) {
            return DateTime.parse(datetimeStr).toUtc();
          }
        } catch (_) {}

        // 降级：解析 HTTP Date 头
        final dateHeader = r.headers['date'];
        if (dateHeader != null) {
          return _parseHttpDate(dateHeader);
        }
      }
    } catch (_) {}
    return null;
  }

  /// 解析 RFC7231/HTTP Date 头格式
  static DateTime? _parseHttpDate(String dateStr) {
    try {
      const months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
        'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
        'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      final regex = RegExp(
          r'^\w+,\s+(\d+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+GMT\$');
      final match = regex.firstMatch(dateStr.trim());
      if (match == null) return null;
      final day = int.parse(match.group(1)!);
      final monthName = match.group(2)!;
      final year = int.parse(match.group(3)!);
      final month = months[monthName];
      if (month == null) return null;
      return DateTime.utc(
        year, month, day,
        int.parse(match.group(4)!),
        int.parse(match.group(5)!),
        int.parse(match.group(6)!),
      );
    } catch (_) {
      return null;
    }
  }
}
