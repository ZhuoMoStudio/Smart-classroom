import 'package:flutter_test/flutter_test.dart';
import 'package:smart_classroom/services/update_service.dart';

void main() {
  group('版本号归一化', () {
    test('去掉开头的 v', () {
      expect(UpdateService.normalizeVersion('v1.32.2'), '1.32.2');
      expect(UpdateService.normalizeVersion('V2.0'), '2.0');
    });

    test('只去掉开头那一个 v，不误伤中间字符', () {
      // 旧实现用 replaceAll 把任意位置的 v 都删掉
      expect(UpdateService.normalizeVersion('v1.2.0-v2'), '1.2.0-v2');
    });

    test('去掉构建号后缀', () {
      expect(UpdateService.normalizeVersion('1.32.2+2'), '1.32.2');
      expect(UpdateService.normalizeVersion('v1.32.2+2'), '1.32.2');
    });
  });

  group('版本比较', () {
    test('逐段按数字比较，1.10 大于 1.9', () {
      expect(UpdateService.compareVersions('1.10.0', '1.9.0'), greaterThan(0));
    });

    test('缺失段按 0 处理', () {
      expect(UpdateService.compareVersions('1.2', '1.2.0'), 0);
      expect(UpdateService.compareVersions('1.2.1', '1.2'), greaterThan(0));
    });

    test('当前版本低于最新版本时返回负数', () {
      expect(UpdateService.compareVersions('1.32.1', '1.32.2'), lessThan(0));
    });

    test('非法段不会让比较抛异常', () {
      expect(() => UpdateService.compareVersions('1.x.0', '1.0.0'), returnsNormally);
      expect(UpdateService.compareVersions('1.x.0', '1.0.0'), 0);
    });

    test('预发布后缀只比较主版本', () {
      expect(UpdateService.compareVersions('1.2.3-beta.1', '1.2.3'), 0);
    });
  });

  test('下载页地址使用 v 前缀', () {
    expect(
      UpdateService.releaseUrl('1.32.2'),
      'https://github.com/ZhuoMoStudio/Smart-classroom/releases/tag/v1.32.2',
    );
    expect(
      UpdateService.releaseUrl('v1.32.2'),
      'https://github.com/ZhuoMoStudio/Smart-classroom/releases/tag/v1.32.2',
    );
  });
}
