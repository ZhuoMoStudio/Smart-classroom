import 'package:flutter_test/flutter_test.dart';
import 'package:smart_classroom/services/gh_proxy_service.dart';

/// 教材 PDF 走 GitHub raw 下载，国内需要镜像兜底。
/// 这里钉住两件事：
///   1. 非 raw 地址绝不能被拼上镜像前缀（否则直接 404）；
///   2. 镜像优先/原始优先的顺序正确，且原始地址始终在候选里兜底。
void main() {
  const raw =
      'https://raw.githubusercontent.com/TapXWorld/ChinaTextbook/main/a.pdf';

  test('原始地址只在候选末尾兜底', () {
    final c = GhProxyService.candidates(raw);
    expect(c.first, raw);
    expect(c.length, GhProxyService.mirrors.length + 1);
    expect(c.skip(1).every((u) => GhProxyService.mirrors.any((m) => u.startsWith(m))),
        isTrue);
  });

  test('镜像优先时，原始地址仍在最后', () {
    final c = GhProxyService.candidates(raw, useMirror: true);
    expect(c.first, startsWith(GhProxyService.mirrors.first));
    expect(c.last, raw);
  });

  test('非 raw 地址原样返回，不拼接镜像', () {
    const other = 'https://example.com/textbook.pdf';
    expect(GhProxyService.candidates(other), [other]);
    expect(GhProxyService.candidates(other, useMirror: true), [other]);
    expect(GhProxyService.toProxyUrl(other), other);
  });

  test('单镜像转换可指定序号且不越界', () {
    expect(
      GhProxyService.toProxyUrl(raw, mirrorIndex: 1),
      '${GhProxyService.mirrors[1]}/$raw',
    );
    expect(
      GhProxyService.toProxyUrl(raw, mirrorIndex: 99),
      '${GhProxyService.mirrors.last}/$raw',
    );
  });

  test('镜像列表不含已知失效域名', () {
    expect(GhProxyService.mirrors, isNot(contains('https://mirror.ghproxy.com')));
    expect(GhProxyService.mirrors, isNot(contains('https://ghproxy.net')));
    expect(GhProxyService.mirrors, isNotEmpty);
  });
}
