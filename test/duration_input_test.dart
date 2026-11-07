import 'package:flutter_test/flutter_test.dart';
import 'package:smart_classroom/services/duration_input.dart';

/// 帮助页承诺了「1.5 = 90 秒」，旧实现用 int.tryParse 逐段解析，
/// 小数分钟会直接变成 0（点确认毫无反应）。这里把三种写法都钉住。
void main() {
  group('parseSeconds', () {
    test('小数分钟', () {
      expect(DurationInput.parseSeconds('1.5'), 90);
      expect(DurationInput.parseSeconds('0.5'), 30);
      expect(DurationInput.parseSeconds('0.1'), 6);
      expect(DurationInput.parseSeconds('10'), 600);
    });

    test('分:秒', () {
      expect(DurationInput.parseSeconds('1:30'), 90);
      expect(DurationInput.parseSeconds('0:45'), 45);
      expect(DurationInput.parseSeconds('12:00'), 720);
    });

    test('时:分:秒', () {
      expect(DurationInput.parseSeconds('1:30:00'), 5400);
      expect(DurationInput.parseSeconds('0:00:30'), 30);
      expect(DurationInput.parseSeconds('01:02:03'), 3723);
    });

    test('空串、乱写、非正数都返回 0', () {
      expect(DurationInput.parseSeconds(''), 0);
      expect(DurationInput.parseSeconds('   '), 0);
      expect(DurationInput.parseSeconds('abc'), 0);
      expect(DurationInput.parseSeconds('0'), 0);
      expect(DurationInput.parseSeconds('-5'), 0);
      expect(DurationInput.parseSeconds('1:2:3:4'), 0);
    });

    test('小数秒四舍五入', () {
      expect(DurationInput.parseSeconds('0:0.5'), 1);
      expect(DurationInput.parseSeconds('1.001'), 60);
    });
  });

  group('format', () {
    test('小时为 0 时省略', () {
      expect(DurationInput.format(90), '1:30');
      expect(DurationInput.format(5400), '1:30:00');
      expect(DurationInput.format(0), '0:00');
    });
  });
}
