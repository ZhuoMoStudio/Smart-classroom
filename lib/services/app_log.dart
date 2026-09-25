import 'dart:async';
import 'dart:io';

/// 运行日志 —— 让「拉取错误日志」第一次成为可能。
///
/// 背景：此前的应用没有任何错误上报，没有 `FlutterError.onError`，
/// 也没有 `PlatformDispatcher.onError`，落盘日志更是不存在。
/// 结果有两个：
///   1. 出问题时老师手上没有任何可回溯的信息，只能说「就是不对」；
///   2. 大量 `catch (_) {}` 把真实故障彻底吞掉，
///      例如积分保存失败、名单读取失败，全都静默发生。
/// 这个服务把「发生了什么」落到工作区的 `数据存档/运行日志.log`，
/// 老师可以把它导出发给维护者，维护者才谈得上定位。
///
/// 设计取舍：
/// - 用同步追加写。日志频率极低（不是逐帧），换来的是崩溃前最后几行一定会落盘，
///   异步缓冲在崩溃场景下往往什么都留不下 —— 而对日志来说「崩溃前那几行」正是全部价值。
/// - 工作区尚未确定时（启动早期）先在内存里攒着，设置好目录后一次性补写。
/// - 单个文件超过 [_rotateBytes] 就轮转，最多保留 3 个，不会撑爆老师的磁盘。
class AppLog {
  AppLog._();

  static const int _maxMemoryLines = 500;
  static const int _maxPendingLines = 2000;
  static const int _rotateBytes = 512 * 1024;

  /// 轮转时保留的历史文件个数（加上当前文件共 3 个）
  static const int _keepRotated = 2;

  static const String fileName = '运行日志.log';

  /// 供界面直接展示的近期日志
  static final List<String> _memory = <String>[];

  /// 目录尚未确定时先攒着，避免丢掉启动阶段的错误
  static final List<String> _pending = <String>[];

  static Directory? _dir;
  static bool _writeFailed = false;

  /// 工作区确定后调用，把启动阶段攒下的日志一并落盘。
  static void setLogDirectory(String? path) {
    if (path == null || path.isEmpty) return;
    try {
      final d = Directory(path);
      if (!d.existsSync()) d.createSync(recursive: true);
      _dir = d;
      _writeFailed = false;
      _flushPending();
    } catch (e) {
      _writeFailed = true;
    }
  }

  static List<String> get recent => List.unmodifiable(_memory);

  static String get recentText => _memory.isEmpty ? '（暂无日志）' : _memory.join('\n');

  static void info(String tag, String message) => _add('INFO', tag, message);

  static void warn(String tag, String message) => _add('WARN', tag, message);

  static void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stack,
  ]) {
    final buffer = StringBuffer(message);
    if (error != null) buffer.write(' | $error');
    _add('ERROR', tag, buffer.toString());
    if (stack != null) _appendLine(_format('TRACE', tag, stack.toString()));
  }

  static void _add(String level, String tag, String message) =>
      _appendLine(_format(level, tag, message));

  static String _format(String level, String tag, String message) {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    String three(int v) => v.toString().padLeft(3, '0');
    final ts = '${n.year}-${two(n.month)}-${two(n.day)} '
        '${two(n.hour)}:${two(n.minute)}:${two(n.second)}.${three(n.millisecond)}';
    return '[$ts] [$level] [$tag] $message';
  }

  static void _appendLine(String line) {
    _memory.add(line);
    if (_memory.length > _maxMemoryLines) _memory.removeAt(0);

    _pending.add(line);
    if (_pending.length > _maxPendingLines) _pending.removeAt(0);

    if (_dir != null && !_writeFailed) _flushPending();
  }

  static void _flushPending() {
    if (_dir == null || _pending.isEmpty || _writeFailed) return;
    final lines = List<String>.from(_pending);
    _pending.clear();
    try {
      final f = File('${_dir!.path}/$fileName');
      _rotateIfNeeded(f);
      f.writeAsStringSync('${lines.join('\n')}\n', mode: FileMode.append);
    } catch (_) {
      // 写日志失败时绝不能抛出去，否则日志本身成了新的故障源
      _writeFailed = true;
      _pending.clear();
    }
  }

  static void _rotateIfNeeded(File f) {
    try {
      if (!f.existsSync() || f.lengthSync() < _rotateBytes) return;
      final base = _dir!.path;
      for (int i = _keepRotated; i >= 1; i--) {
        final from = File('$base/$fileName.$i');
        if (!from.existsSync()) continue;
        if (i == _keepRotated) {
          from.deleteSync();
        } else {
          from.renameSync('$base/$fileName.${i + 1}');
        }
      }
      f.renameSync('$base/$fileName.1');
    } catch (_) {
      // 轮转失败不影响继续写
    }
  }

  static File? get logFile => _dir == null ? null : File('${_dir!.path}/$fileName');

  /// 把日志导出到指定路径（供「导出日志」入口使用）。
  /// 优先导出磁盘上的完整日志；磁盘上没有（例如工作区未配置）时退回内存缓冲。
  static Future<File> exportTo(String outputPath) async {
    final f = File(outputPath);
    await f.create(recursive: true);
    final onDisk = logFile;
    if (onDisk != null && onDisk.existsSync()) {
      await onDisk.copy(outputPath);
    } else {
      await f.writeAsString(recentText, flush: true);
    }
    return f;
  }

  static void clear() {
    _memory.clear();
    _pending.clear();
    try {
      final f = logFile;
      if (f != null && f.existsSync()) f.deleteSync();
    } catch (_) {}
  }
}
