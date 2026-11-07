import 'package:flutter_test/flutter_test.dart';
import 'package:smart_classroom/services/network_time.dart';

/// `HttpDate` 是「三个 JSON 授时站全挂」时唯一的兜底，
/// 而旧实现用 `DateTime.parse` 解析 IMF-fixdate，格式永远对不上，
/// 于是这条兜底从未成功过。这里把三种 RFC 9110 格式都钉住。
void main() {
  group('IMF-fixdate（主流格式）', () {
    test('解析出正确的 UTC 时间', () {
      final t = HttpDate.parse('Sun, 06 Nov 1994 08:49:37 GMT');
      expect(t, DateTime.utc(1994, 11, 6, 8, 49, 37));
      expect(t!.isUtc, isTrue);
    });

    test('一位数日期与前后空白', () {
      final t = HttpDate.parse('  Sun, 6 Nov 1994 08:49:37 GMT  ');
      expect(t, DateTime.utc(1994, 11, 6, 8, 49, 37));
    });

    test('月份大小写不敏感', () {
      expect(
        HttpDate.parse('Sun, 06 nov 1994 08:49:37 GMT'),
        DateTime.utc(1994, 11, 6, 8, 49, 37),
      );
    });

    test('十二月的边界', () {
      expect(
        HttpDate.parse('Tue, 31 Dec 2024 23:59:59 GMT'),
        DateTime.utc(2024, 12, 31, 23, 59, 59),
      );
    });
  });

  group('RFC 850 与 asctime 兼容', () {
    test('RFC 850 两位年份按 50 年窗口解释', () {
      expect(
        HttpDate.parse('Sunday, 06-Nov-94 08:49:37 GMT'),
        DateTime.utc(1994, 11, 6, 8, 49, 37),
      );
      expect(
        HttpDate.parse('Sunday, 06-Nov-24 08:49:37 GMT'),
        DateTime.utc(2024, 11, 6, 8, 49, 37),
      );
    });

    test('asctime 格式', () {
      expect(
        HttpDate.parse('Sun Nov  6 08:49:37 1994'),
        DateTime.utc(1994, 11, 6, 8, 49, 37),
      );
    });
  });

  group('非法输入不崩溃', () {
    test('空串、垃圾串、越界字段都返回 null', () {
      expect(HttpDate.parse(''), isNull);
      expect(HttpDate.parse('not a date'), isNull);
      expect(HttpDate.parse('Sun, 06 Xxx 1994 08:49:37 GMT'), isNull);
      expect(HttpDate.parse('Sun, 06 Nov 1994 25:49:37 GMT'), isNull);
      expect(HttpDate.parse('Sun, 32 Nov 1994 08:49:37 GMT'), isNull);
    });

    test('ISO-8601 走兜底解析', () {
      expect(
        HttpDate.parse('2024-11-06T08:49:37Z'),
        DateTime.utc(2024, 11, 6, 8, 49, 37),
      );
    });
  });
}
