# 灵动课堂 (Smart Classroom) v1.22

课堂互动管理工具 — 教师专用，多端适配，苹果透明磨砂玻璃拟态设计。

## ✨ 核心功能

- **班级/小组/成员** 三层管理架构，积分段位系统（青铜→王者）
- **随机抽取** 个人 & 小组，带动画滚动效果
- **题库管理** Excel 导入/导出，支持风险题标识
- **积分系统** 段位等级，实时排行
- **倒计时器** 预设快速启动，低时间告警
- **嵌入式教材仓库** 1905本教材离线浏览，学段→科目→版本三层次筛选
- **PDF全屏阅读** 批注、翻页、缩放、页码跳转
- **独立悬浮批注系统** 不嵌入PDF、独立顶层Overlay图层
- **WebDAV云同步** 坚果云/Nextcloud，防抖自动保存
- **本地存档** 自动保存 + U盘检测 + 智能清理

## 🎨 设计系统

**苹果透明磨砂玻璃拟态风（Frosted Glass Neumorphism）**

### 全局规范
- 全部工具栏、弹窗、卡片、导航栏启用半透明毛玻璃模糊（BackdropFilter + ImageFilter.blur）
- 大圆角 20px 统一曲率，极浅柔和阴影
- 纯白底色 #F8F9FC + 淡蓝主题 #5E7EFF 通透色调
- 无粗线条、无厚重色块、无花哨装饰
- 文字层级清晰：主文深灰 #1C1C1E、辅助浅灰 #8E8E93

### 希沃教学一体机 16:9 布局
- 左侧常驻竖向磨砂工具栏（72px固定窄边）
- 中间超大主画布区域
- 右侧完全留白（投屏规范）

### 手机竖屏
- 透明沉浸式状态栏
- 底部可滑动磨砂工具栏
- 全屏PDF展示，无挤压遮挡

## 🖥️ 多端支持

| 平台 | 支持 | 安装方式 |
|------|------|---------|
| Android | ✅ 全功能 | APK (arm64/arm32/x86_64) |
| Windows | ✅ 全功能 | ZIP绿色版 / Setup.exe安装包 |

## 🏗️ 技术架构

- **Flutter 3.44** + **Dart 3.7**
- **状态管理**: Riverpod 2.6 (StateNotifier + Provider)
- **PDF渲染**: pdfrx 1.x
- **云端同步**: webdav_plus 1.x
- **数据导入**: excel 3.x / file_picker 10.x
- **设计系统**: iOS Frosted Glass 自定义令牌

## 🔧 构建

```bash
# Android
flutter build apk --release --split-per-abi

# Windows
flutter build windows --release
```

CI自动构建（GitHub Actions）：Android APK (3 ABIs) + Windows ZIP + Setup.exe

## 📄 许可

MIT + Commons Clause — 严禁商用
