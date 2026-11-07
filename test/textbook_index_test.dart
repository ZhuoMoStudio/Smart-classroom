import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_classroom/services/textbook_index_service.dart';

/// 教材索引是「学段 / 科目 / 版本 / [文件]」四层 JSON。
///
/// 维护脚本曾把一段**四层**数据搬进 `_未分类`（多了一层分类），
/// 而应用按三层强转，运行时抛
/// `type '_Map<String,dynamic>' is not subtype of type 'List<dynamic>'`，
/// 整份索引加载失败、教材页全空。构建不会校验 assets 的结构，只能靠测试。
void main() {
  late Map<String, dynamic> data;

  setUpAll(() {
    final raw = File('assets/textbook_index.json').readAsStringSync();
    data = jsonDecode(raw) as Map<String, dynamic>;
  });

  test('顶层是对象，且至少包含小学/初中/高中', () {
    expect(data, isA<Map<String, dynamic>>());
    expect(data.keys, containsAll(<String>['小学', '初中', '高中']));
  });

  test('每个学段都符合 科目/版本/[文件] 三层结构', () {
    final problems = <String>[];

    data.forEach((stage, subjects) {
      if (subjects is! Map) {
        problems.add('$stage: 学段节点不是对象');
        return;
      }
      (subjects).forEach((subject, versions) {
        if (versions is! Map) {
          problems.add('$stage/$subject: 科目节点不是对象');
          return;
        }
        (versions).forEach((version, files) {
          if (files is! List) {
            problems.add('$stage/$subject/$version: 版本节点不是列表，'
                '实际为 ${files.runtimeType}');
            return;
          }
          for (final f in files) {
            if (f is! Map || f['n'] is! String || f['p'] is! String) {
              problems.add('$stage/$subject/$version: 文件条目缺少 n/p');
              break;
            }
          }
        });
      });
    });

    expect(problems, isEmpty, reason: problems.take(10).join('\n'));
  });

  test('教材总数不低于 1900，且路径不为空', () {
    var total = 0;
    var emptyPath = 0;
    data.forEach((_, subjects) {
      (subjects as Map).forEach((_, versions) {
        (versions as Map).forEach((_, files) {
          for (final f in (files as List)) {
            total++;
            if ((f as Map)['p'] == '') emptyPath++;
          }
        });
      });
    });
    expect(total, greaterThanOrEqualTo(1900));
    expect(emptyPath, 0);
  });

  test('下载地址把中文路径编码成 ASCII', () {
    final url = TextbookIndexService.getDownloadUrl(
        '初中（五·四学制）/数学/鲁教版-山东教育出版社/义务教育教科书（五·四学制）·数学七年级.pdf');
    expect(RegExp(r'[^\x00-\x7F]').hasMatch(url), isFalse,
        reason: 'URL 里不该有非 ASCII 字符');
    expect(Uri.parse(url).pathSegments.last,
        '义务教育教科书（五·四学制）·数学七年级.pdf');
  });
}
