/// 计时器的自定义时长解析。
///
/// 支持三种写法（帮助文档里承诺过的都在这里）：
///   - `1.5`      → 1.5 分钟 = 90 秒（小数分钟）
///   - `1:30`     → 1 分 30 秒
///   - `1:30:00`  → 1 小时 30 分
///
/// 旧实现用 `int.tryParse` 逐段解析，`1.5` 会直接变成 0，
/// 于是「支持小数分钟」这句写在帮助页上的话从来没有成立过。
class DurationInput {
  const DurationInput._();

  /// 返回秒数；无法解析或非正数时返回 0（调用方据此拒绝启动）。
  static int parseSeconds(String input) {
    final text = input.trim();
    if (text.isEmpty) return 0;

    final parts = text.split(':');
    if (parts.length == 1) {
      final minutes = double.tryParse(text);
      if (minutes == null || minutes.isNaN || minutes.isInfinite) return 0;
      return _roundPositive(minutes * 60);
    }

    if (parts.length == 2) {
      final minutes = double.tryParse(parts[0].trim()) ?? 0;
      final seconds = double.tryParse(parts[1].trim()) ?? 0;
      return _roundPositive(minutes * 60 + seconds);
    }

    if (parts.length == 3) {
      final hours = double.tryParse(parts[0].trim()) ?? 0;
      final minutes = double.tryParse(parts[1].trim()) ?? 0;
      final seconds = double.tryParse(parts[2].trim()) ?? 0;
      return _roundPositive(hours * 3600 + minutes * 60 + seconds);
    }

    return 0;
  }

  static int _roundPositive(double seconds) {
    if (seconds.isNaN || seconds.isInfinite || seconds <= 0) return 0;
    return seconds.round();
  }

  /// 把秒数格式化成 `时:分:秒` 便于回显（小时为 0 时省略）。
  static String format(int seconds) {
    if (seconds <= 0) return '0:00';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
  }
}
