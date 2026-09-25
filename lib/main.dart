import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/app_log.dart';
import 'services/storage_service.dart';

void main() {
  // 兜底捕获：此前的应用没有任何全局错误处理，
  // 异步异常会被静默丢弃 —— 老师看到的是「按钮点了没反应」，
  // 而开发者手上连一行可查的记录都没有。
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 1) 框架层错误：build / layout / paint 里抛出的异常，以及手势回调里的同步异常
      FlutterError.onError = (FlutterErrorDetails details) {
        AppLog.error(
          'Flutter',
          details.exceptionAsString(),
          details.exception,
          details.stack,
        );
        FlutterError.presentError(details);
      };

      // 2) 引擎层错误：平台通道与根 isolate 里未被捕获的异步异常。
      //    返回 true 表示「已处理」，避免进程被直接结束。
      //    用 dart:ui 而非 Binding 上的转发属性，是为了不依赖某个 Flutter 版本
      //    才引入的便捷访问器。
      ui.PlatformDispatcher.instance.onError =
          (Object error, StackTrace stack) {
        AppLog.error('引擎', '未捕获异常', error, stack);
        return true;
      };

      // 3) 渲染失败时的替代界面。
      //    默认实现是灰块，老师只会看到一片灰、什么也报不出来；
      //    这里把原因直接显示出来，并写进日志。外层必须包 Directionality，
      //    因为错误界面常常发生在 MaterialApp 之外，那里没有文本方向上下文。
      ErrorWidget.builder = (FlutterErrorDetails details) {
        AppLog.error(
          '错误界面',
          details.exceptionAsString(),
          details.exception,
          details.stack,
        );
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            color: const Color(0xFFF8F9FC),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            child: Text(
              '界面渲染出错\n${details.exceptionAsString()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
            ),
          ),
        );
      };

      final storage = StorageService();
      await storage.init();

      AppLog.info('启动', '灵动课堂启动');

      runApp(
        ProviderScope(
          overrides: [storageServiceProvider.overrideWith((ref) => storage)],
          child: const SmartClassroomApp(),
        ),
      );
    },
    // 4) 最外层兜底：前面三层都漏掉的错误
    (Object error, StackTrace stack) {
      AppLog.error('未捕获', 'zone 内未处理异常', error, stack);
    },
  );
}
