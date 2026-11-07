# CI 静态分析与测试报告

本文件由 CI 的 verify job 自动生成，请勿手工编辑。

- 生成时间：2026-11-07 15:40:40Z
- 触发：push @ main
- 提交：`16ec5b55d137fda8212770d9013a3cf71a824f99`
- Flutter：Flutter 3.44.9 • channel stable • https://github.com/flutter/flutter.git
- `flutter analyze` 退出码：0
- `flutter test` 退出码：0

## flutter analyze

```text
Analyzing Smart-classroom...                                    
No issues found! (ran in 14.7s)
```

## flutter test

```text
00:00 +0: loading /home/runner/work/Smart-classroom/Smart-classroom/test/update_service_test.dart
00:00 +0: /home/runner/work/Smart-classroom/Smart-classroom/test/update_service_test.dart: 版本号归一化 去掉开头的 v
00:00 +1: /home/runner/work/Smart-classroom/Smart-classroom/test/update_service_test.dart: 版本号归一化 只去掉开头那一个 v，不误伤中间字符
00:00 +2: /home/runner/work/Smart-classroom/Smart-classroom/test/update_service_test.dart: 版本号归一化 去掉构建号后缀
00:00 +3: /home/runner/work/Smart-classroom/Smart-classroom/test/update_service_test.dart: 版本比较 逐段按数字比较，1.10 大于 1.9
00:00 +4: /home/runner/work/Smart-classroom/Smart-classroom/test/update_service_test.dart: 版本比较 缺失段按 0 处理
00:00 +5: /home/runner/work/Smart-classroom/Smart-classroom/test/update_service_test.dart: 版本比较 当前版本低于最新版本时返回负数
00:00 +6: /home/runner/work/Smart-classroom/Smart-classroom/test/update_service_test.dart: 版本比较 非法段不会让比较抛异常
00:00 +7: /home/runner/work/Smart-classroom/Smart-classroom/test/update_service_test.dart: 版本比较 预发布后缀只比较主版本
00:00 +8: /home/runner/work/Smart-classroom/Smart-classroom/test/update_service_test.dart: 下载页地址使用 v 前缀
00:03 +9: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +10: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +11: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +12: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +13: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +14: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +15: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +16: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +17: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +18: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +19: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +20: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +21: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +22: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +23: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +24: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +25: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +26: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +27: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +28: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:03 +29: /home/runner/work/Smart-classroom/Smart-classroom/test/widget_test.dart: 应用能启动并渲染首屏
00:04 +30: /home/runner/work/Smart-classroom/Smart-classroom/test/settings_test.dart: SettingsState JSON 往返序列化保留所有字段
00:04 +31: /home/runner/work/Smart-classroom/Smart-classroom/test/settings_test.dart: SettingsState JSON 空 JSON 回退到默认值
00:04 +32: /home/runner/work/Smart-classroom/Smart-classroom/test/settings_test.dart: SettingsState JSON 字段类型不对时逐项回退，不抛异常
00:04 +33: /home/runner/work/Smart-classroom/Smart-classroom/test/settings_test.dart: SettingsNotifier 落盘 update 后新建 notifier 能读回
00:04 +34: /home/runner/work/Smart-classroom/Smart-classroom/test/settings_test.dart: SettingsNotifier 落盘 存档损坏时用默认值启动
读取设置失败，使用默认值：FormatException: Unexpected character (at character 3)
{ 这不是 JSON
  ^

00:04 +35: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: extractGradeClass 从文件名识别年级班级 年级+阿拉伯数字班级
00:05 +36: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: extractGradeClass 从文件名识别年级班级 年级+中文数字班级
00:05 +37: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: extractGradeClass 从文件名识别年级班级 高中简称
00:05 +38: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: extractGradeClass 从文件名识别年级班级 小学全称带括号（归一化会去掉括号）
00:05 +39: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: extractGradeClass 从文件名识别年级班级 只有班级没有年级
00:05 +40: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: extractGradeClass 从文件名识别年级班级 全角数字按半角处理
00:05 +41: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: extractGradeClass 从文件名识别年级班级 识别不出时返回双 null
00:05 +42: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: identityKey 分组键 三年二班 与 3年2班 归一为同一组
00:05 +43: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: identityKey 分组键 全角与半角数字归一为同一组
00:05 +44: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: identityKey 分组键 高一年级3班 与 高一3班 归一为同一组
00:05 +45: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: identityKey 分组键 初二年级2班 与 初二2班 归一为同一组
00:05 +46: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: identityKey 分组键 关键：高一年级3班 不能与 一年级3班 同组（否则会误删另一个年级）
00:05 +47: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: identityKey 分组键 关键：初中二年级2班 不能与 二年级2班 同组
00:05 +48: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: identityKey 分组键 「初中二年级」这类夹了「中」的写法要保留学段前缀
00:05 +49: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: identityKey 分组键 识别不出时带 ? 前缀，便于保留策略跳过淘汰
00:05 +50: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: pathSegment 供云同步目录使用（必须是纯 ASCII） 年级前缀映射成 ASCII
00:05 +51: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: pathSegment 供云同步目录使用（必须是纯 ASCII） 「小学」前缀会被丢掉，只剩年级数字
00:05 +52: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: pathSegment 供云同步目录使用（必须是纯 ASCII） 纯数字年级班级保持原样
00:05 +53: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: pathSegment 供云同步目录使用（必须是纯 ASCII） 识别不出时落到 _unsorted
00:05 +54: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: pathSegment 供云同步目录使用（必须是纯 ASCII） 结果不含 WebDAV 禁止的字符，也不含非 ASCII
00:05 +55: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: planRetention 保留策略（最旧 1 份 + 最新 5 份） 7 份：保留 6、淘汰中间那 1 份
00:05 +56: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: planRetention 保留策略（最旧 1 份 + 最新 5 份） 恰好 6 份：一份都不淘汰
00:05 +57: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: planRetention 保留策略（最旧 1 份 + 最新 5 份） 少于 6 份：一份都不淘汰
00:05 +58: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: planRetention 保留策略（最旧 1 份 + 最新 5 份） 最旧的一份始终被保留（这就是「最初始的那一份」）
00:05 +59: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: planRetention 保留策略（最旧 1 份 + 最新 5 份） 最新的一份始终被保留
00:05 +60: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: planRetention 保留策略（最旧 1 份 + 最新 5 份） 不同年级/班级互不影响
00:05 +61: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: planRetention 保留策略（最旧 1 份 + 最新 5 份） 三年二班 与 3年2班 混排时视为同一组
00:05 +62: /home/runner/work/Smart-classroom/Smart-classroom/test/roster_manager_test.dart: planRetention 保留策略（最旧 1 份 + 最新 5 份） 识别不出年级班级的文件永不淘汰
00:05 +63: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: RankSystem.getRank 0 分是倔强青铜 V
00:05 +64: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: RankSystem.getRank 每个大段位内部从 V 递增到 I（以倔强青铜为例）
00:05 +65: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: RankSystem.getRank 跨过 50 分进入秩序白银
00:05 +66: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: RankSystem.getRank 小数分向下取整，49.9 仍属倔强青铜 I
00:05 +67: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: RankSystem.getRank 负分被夹到 0，不产生越界段位
00:05 +68: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: RankSystem.getRank 290 分是至尊星耀 I，300 分起进入最强王者
00:05 +69: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: RankSystem.getRank 350 分及以上封顶荣耀王者，level 不再增长
00:05 +70: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: 模型派生值 Group.totalScore 是成员分数之和
00:05 +71: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: 模型派生值 Classroom.allMembers 展开全部小组
00:05 +72: /home/runner/work/Smart-classroom/Smart-classroom/test/rank_system_test.dart: 模型派生值 Member.copyWith 不改 uid，只改传入字段
00:05 +73: /home/runner/work/Smart-classroom/Smart-classroom/test/duration_input_test.dart: parseSeconds 小数分钟
00:05 +74: /home/runner/work/Smart-classroom/Smart-classroom/test/duration_input_test.dart: parseSeconds 分:秒
00:05 +75: /home/runner/work/Smart-classroom/Smart-classroom/test/duration_input_test.dart: parseSeconds 时:分:秒
00:05 +76: /home/runner/work/Smart-classroom/Smart-classroom/test/duration_input_test.dart: parseSeconds 空串、乱写、非正数都返回 0
00:05 +77: /home/runner/work/Smart-classroom/Smart-classroom/test/duration_input_test.dart: parseSeconds 小数秒四舍五入
00:05 +78: /home/runner/work/Smart-classroom/Smart-classroom/test/duration_input_test.dart: format 小时为 0 时省略
00:06 +79: /home/runner/work/Smart-classroom/Smart-classroom/test/gh_proxy_service_test.dart: 原始地址只在候选末尾兜底
00:06 +80: /home/runner/work/Smart-classroom/Smart-classroom/test/gh_proxy_service_test.dart: 镜像优先时，原始地址仍在最后
00:06 +81: /home/runner/work/Smart-classroom/Smart-classroom/test/gh_proxy_service_test.dart: 非 raw 地址原样返回，不拼接镜像
00:06 +82: /home/runner/work/Smart-classroom/Smart-classroom/test/gh_proxy_service_test.dart: 单镜像转换可指定序号且不越界
00:06 +83: /home/runner/work/Smart-classroom/Smart-classroom/test/gh_proxy_service_test.dart: 镜像列表不含已知失效域名
00:06 +84: /home/runner/work/Smart-classroom/Smart-classroom/test/score_history_test.dart: peekLast 只看不取
00:06 +85: /home/runner/work/Smart-classroom/Smart-classroom/test/score_history_test.dart: undoLast 取出最新一条，并支持连续撤销
00:06 +86: /home/runner/work/Smart-classroom/Smart-classroom/test/score_history_test.dart: 记录按时间倒序（最新在前）
00:06 +87: /home/runner/work/Smart-classroom/Smart-classroom/test/score_history_test.dart: 超过上限后丢弃最旧的，防止内存无限增长
00:06 +88: /home/runner/work/Smart-classroom/Smart-classroom/test/score_history_test.dart: recentRecords 只暴露最近 50 条
00:06 +89: /home/runner/work/Smart-classroom/Smart-classroom/test/score_history_test.dart: clear 之后队列为空
00:06 +90: /home/runner/work/Smart-classroom/Smart-classroom/test/score_history_test.dart: delta 正负判断
00:06 +91: All tests passed!
```
