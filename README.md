# 灵动课堂 (Smart Classroom)

课堂互动管理工具，支持本地存储与云端同步双模式。

## 功能
- 班级/小组/成员三层管理
- 随机抽取（个人/小组）
- 题库管理（CSV 导入）
- 倒计时器
- 排行榜（段位系统）
- WebDAV 云端同步（坚果云/Nextcloud 等）
- 手动检查更新（从 GitHub Release）

## 技术栈
Flutter 3.x + Dart + Riverpod + Material Design 3

## 快速开始
1. `flutter pub get`
2. `flutter run`

## 构建
- Android: `flutter build apk --release --split-per-abi`
- Windows: `flutter build windows --release`

## 更新机制
在设置页面点击「检查更新」，应用会从 GitHub Release 获取最新版本号，
比对后若有新版本弹出对话框，用户确认后跳转下载页面。

## 云端同步
支持 WebDAV 协议，默认配置坚果云。
在设置中配置服务器地址、用户名、密码即可使用。
