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

/// HTTP Date 头解析（RFC 9110 §5.6.7 的 IMF-fixdate）。
///
/// 旧实现把 `Thu, 01 Jan 2024 12:00:00 GMT` 去掉星期与 `GMT` 后交给
/// `DateTime.parse`，而它只接受 ISO-8601；于是这条「服务器 Date 头」备选
/// 实际上**从来没有成功过一次**，三个 JSON 时间站全挂时就只能返回 null。
/// 现在按 RFC 自己拆字段，并保留两个过时格式的兼容（RFC 850 / asctime）。
class HttpDate {
  /// 月份缩写表（大小写不敏感）。
  static const List<String> _months = [
    'jan', 'feb', 'mar', 'apr', 'may', 'jun',
    'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
  ];

  /// IMF-fixdate: `Sun, 06 Nov 1994 08:49:37 GMT`
  static final RegExp _imf = RegExp(
    r'^[A-Za-z]{3},\s+(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+'
    r'(\d{2}):(\d{2}):(\d{2})\s+GMT$',
  );

  /// RFC 850: `Sunday, 06-Nov-94 08:49:37 GMT`
  static final RegExp _rfc850 = RegExp(
    r'^[A-Za-z]+,\s+(\d{2})-([A-Za-z]{3})-(\d{2})\s+'
    r'(\d{2}):(\d{2}):(\d{2})\s+GMT$',
  );

  /// asctime: `Sun Nov  6 08:49:37 1994`
  static final RegExp _asctime = RegExp(
    r'^[A-Za-z]{3}\s+([A-Za-z]{3})\s+(\d{1,2})\s+'
    r'(\d{2}):(\d{2}):(\d{2})\s+(\d{4})$',
  );

  static DateTime? parse(String dateStr) {
    final s = dateStr.trim();

    final imf = _imf.firstMatch(s);
    if (imf != null) {
      return _build(
        year: int.parse(imf.group(3)!),
        month: imf.group(2)!,
        day: int.parse(imf.group(1)!),
        hour: int.parse(imf.group(4)!),
        minute: int.parse(imf.group(5)!),
        second: int.parse(imf.group(6)!),
      );
    }

    final rfc850 = _rfc850.firstMatch(s);
    if (rfc850 != null) {
      final yy = int.parse(rfc850.group(3)!);
      // 两位年份：RFC 9110 建议按 50 年窗口解释
      final year = yy < 70 ? 2000 + yy : 1900 + yy;
      return _build(
        year: year,
        month: rfc850.group(2)!,
        day: int.parse(rfc850.group(1)!),
        hour: int.parse(rfc850.group(4)!),
        minute: int.parse(rfc850.group(5)!),
        second: int.parse(rfc850.group(6)!),
      );
    }

    final asctime = _asctime.firstMatch(s);
    if (asctime != null) {
      return _build(
        year: int.parse(asctime.group(6)!),
        month: asctime.group(1)!,
        day: int.parse(asctime.group(2)!),
        hour: int.parse(asctime.group(3)!),
        minute: int.parse(asctime.group(4)!),
        second: int.parse(asctime.group(5)!),
      );
    }

    // 兜底：某些服务端会直接返回 ISO-8601
    return DateTime.tryParse(s);
  }

  static DateTime? _build({
    required int year,
    required String month,
    required int day,
    required int hour,
    required int minute,
    required int second,
  }) {
    final m = _months.indexOf(month.toLowerCase());
    if (m < 0) return null;
    if (day < 1 || day > 31) return null;
    if (hour > 23 || minute > 59 || second > 60) return null;
    return DateTime.utc(year, m + 1, day, hour, minute, second);
  }
}
