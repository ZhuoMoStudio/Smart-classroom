import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_classroom/app.dart';
import 'package:smart_classroom/services/storage_service.dart';

void main() {
  testWidgets('应用能启动并渲染首屏', (WidgetTester tester) async {
    // 旧版测试直接 pumpWidget(const SmartClassroomApp())，缺 ProviderScope。
    // SmartClassroomApp 是 ConsumerStatefulWidget，build 里会 ref.watch(settingsProvider)，
    // 没有 ProviderScope 会直接抛异常 —— 所以这个测试一直是红的。
    // 而 CI 从来不跑测试，于是没人发现仓库里唯一的测试是失败的。
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final storage = StorageService();
    await storage.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageServiceProvider.overrideWith((ref) => storage)],
        child: const SmartClassroomApp(),
      ),
    );

    // 引导状态未完成 -> 首先渲染的是引导页，而不是 HomeScreen。
    // 这里只断言应用根节点已挂载，不依赖具体页面，避免把引导页的文案写进测试。
    expect(find.byType(SmartClassroomApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
