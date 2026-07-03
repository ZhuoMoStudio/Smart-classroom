# 灵动课堂 (Smart Classroom) v1.0.4

课堂互动管理工具 — 教师专用，多端适配，极简设计。

## ✨ 核心功能

- **班级/小组/成员** 三层管理架构
- **随机抽取** 个人 & 小组，带动画滚动效果
- **题库管理** Excel 导入/导出，支持风险题标识
- **积分系统** 段位等级（青铜→王者），实时排行
- **倒计时器** 预设快速启动，低时间告警
- **教材浏览器** 对接 GitHub 开源教材仓库，国内加速
- **WebDAV 云同步** 坚果云 / Nextcloud，全英文路径
- **本地存档** 自动保存 + U盘检测 + 智能清理

## 🎨 设计系统

**iOS 18 / macOS Sonoma 极简统一设计**

### 手机端
- 磨砂玻璃毛玻璃卡片（`frostWhite` 半透白 + 0.5px 细边）
- 大圆角 20px 统一曲率
- 低饱和柔和配色（品牌色浅蓝 `#6B8EFF`）
- SF Pro 风格字体层级
- 轻薄柔和投影，无硬阴影
- iOS 风格 NavigationBar（透明 + 10px 标签）

### 桌面端 (Windows/macOS)
- 纯白基底 `#F8F9FC`
- 亚克力半透明窗口质感
- 极简扁平卡片投影
- 16:9 多窗口分层布局

### 教学大屏 (100寸希沃)
- 高对比暖色背景 `<#FFF8F0`
- 80px 大触控热区 + 20px 防掌误触
- 无悬停反馈，纯触控优化
- 课堂/备课模式一键切换

## 📋 技术栈

```
Flutter 3.44  |  Dart 3.7  |  Riverpod 2.6  |  Material Design 3
webdav_plus   |  excel (xlsx)  |  pdfrx  |  file_picker  |  audioplayers
```

## 🚀 快速开始

```bash
flutter pub get
flutter run
```

## 📱 构建

### Android APK（按 CPU 架构拆分）
```bash
flutter build apk --release --split-per-abi \
  --build-name=1.0.4 --build-number=1
```

### Windows 桌面
```bash
flutter build windows --release
```

## ☁️ 云端同步

支持 **WebDAV 协议**，默认配置坚果云。

1. 注册 [坚果云](https://www.jianguoyun.com/signup)
2. 在「安全设置」中创建第三方应用专用密码
3. 在软件设置中填入服务器地址、用户名、密码
4. 数据按年级/学科自动使用英文目录存储（grade-1~12, math, chinese...）

## 📦 更新机制

设置页 → 「检查更新」→ 从 GitHub Release 获取最新版本号。
若有新版本，弹窗确认后跳转下载页。

## 📄 许可

CC BY-NC 4.0 — 仅限非商业用途
