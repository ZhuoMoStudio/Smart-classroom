import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// 音效资源完整性测试。
///
/// 背景：仓库里的 11 个 `.wav` 曾经全是 5 字节的 `RIFF\n` 残片 ——
/// 能通过 `flutter build`，能被打进 APK，运行时 `audioplayers` 抛异常
/// 又被 `catch (_) {}` 吞掉，于是「有音效」这件事在真机上从未成立过。
/// 构建过程不会校验资源内容，所以这条只能由测试来兜。
void main() {
  final soundDir = Directory('assets/sounds');

  test('音效目录存在且包含全部预期文件', () {
    expect(soundDir.existsSync(), isTrue,
        reason: 'assets/sounds 目录缺失，pubspec 的 assets 声明会指向空目录');

    const expected = <String>[
      'add_member.wav',
      'click.wav',
      'delete_member.wav',
      'draw_result.wav',
      'draw_roll.wav',
      'draw_start.wav',
      'score_down.wav',
      'score_up.wav',
      'sync_complete.wav',
      'sync_fail.wav',
      'timer_end.wav',
    ];

    final actual = soundDir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.wav'))
        .toSet();

    expect(actual, containsAll(expected));
  });

  group('每个 wav 都是可播放的 PCM 文件', () {
    final files = soundDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.wav'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      test(file.uri.pathSegments.last, () {
        final bytes = file.readAsBytesSync();
        final wav = WavInfo.parse(bytes);

        expect(bytes.length, greaterThan(1024),
            reason: '过短，基本可以断定是占位残片');
        expect(wav, isNotNull, reason: '不是合法的 RIFF/WAVE 文件');

        final info = wav!;
        expect(info.audioFormat, 1, reason: '必须是未压缩 PCM');
        expect(info.channels, 1);
        expect(info.sampleRate, 22050);
        expect(info.bitsPerSample, 16);
        expect(info.duration, greaterThan(const Duration(milliseconds: 30)));
        expect(info.peak, greaterThan(0.05),
            reason: '整段静音等于没有音效');
      });
    }
  });
}

/// 最小 WAV 解析：只读测试需要的字段。
class WavInfo {
  final int audioFormat;
  final int channels;
  final int sampleRate;
  final int bitsPerSample;
  final int dataBytes;
  final double peak;

  const WavInfo({
    required this.audioFormat,
    required this.channels,
    required this.sampleRate,
    required this.bitsPerSample,
    required this.dataBytes,
    required this.peak,
  });

  Duration get duration {
    final bytesPerSecond = sampleRate * channels * (bitsPerSample ~/ 8);
    if (bytesPerSecond == 0) return Duration.zero;
    return Duration(
      microseconds: (dataBytes / bytesPerSecond * 1000000).round(),
    );
  }

  static WavInfo? parse(Uint8List bytes) {
    if (bytes.length < 44) return null;
    final data = ByteData.sublistView(bytes);

    String tag(int offset) =>
        String.fromCharCodes(bytes.sublist(offset, offset + 4));
    if (tag(0) != 'RIFF' || tag(8) != 'WAVE') return null;

    int? audioFormat, channels, sampleRate, bitsPerSample;
    int? dataOffset, dataBytes;

    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final id = tag(offset);
      final size = data.getUint32(offset + 4, Endian.little);
      final body = offset + 8;

      if (id == 'fmt ' && body + 16 <= bytes.length) {
        audioFormat = data.getUint16(body, Endian.little);
        channels = data.getUint16(body + 2, Endian.little);
        sampleRate = data.getUint32(body + 4, Endian.little);
        bitsPerSample = data.getUint16(body + 14, Endian.little);
      } else if (id == 'data') {
        dataOffset = body;
        dataBytes = size;
      }

      // chunk 按偶数字节对齐
      offset = body + size + (size.isOdd ? 1 : 0);
    }

    if (audioFormat == null ||
        channels == null ||
        sampleRate == null ||
        bitsPerSample == null ||
        dataOffset == null ||
        dataBytes == null) {
      return null;
    }

    final end = (dataOffset + dataBytes).clamp(0, bytes.length);
    var peak = 0;
    for (var i = dataOffset; i + 1 < end; i += 2) {
      final v = data.getInt16(i, Endian.little).abs();
      if (v > peak) peak = v;
    }

    return WavInfo(
      audioFormat: audioFormat,
      channels: channels,
      sampleRate: sampleRate,
      bitsPerSample: bitsPerSample,
      dataBytes: dataBytes,
      peak: peak / 32767,
    );
  }
}
