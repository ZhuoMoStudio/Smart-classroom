import 'package:flutter_test/flutter_test.dart';
import 'package:smart_classroom/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    // 基础冒烟测试
    await tester.pumpWidget(
      const SmartClassroomApp(),
    );
    expect(find.byType(SmartClassroomApp), findsOneWidget);
  });
}
