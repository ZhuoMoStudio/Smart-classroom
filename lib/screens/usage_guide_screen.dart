import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// 使用文档 / 快速上手指南
class UsageGuideScreen extends StatelessWidget {
  const UsageGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('使用指南')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section(theme, '📚 快速开始',
            '1. 首次使用：完成引导页，了解基本功能\n'
            '2. 选择/创建班级：点击工具栏班级下拉菜单\n'
            '3. 导入学生名单：点击「更多」→「导入名单」\n'
            '4. 开始课堂互动：使用抽取、计时、积分等功能'),
          _section(theme, '🎲 随机抽取',
            '• 点击圆形「抽!」按钮随机抽取学生/小组\n'
            '• 抽取时伴有滚动动画和音效\n'
            '• 选定后可立即加减分\n'
            '• 支持锁定小组，抽取结果不重复'),
          _section(theme, '📝 题库管理',
            '• 使用 Excel 模板导入题库（支持风险题）\n'
            '• 混合模式：从所有题库中随机选题\n'
            '• 已答题目自动标记（删除线）\n'
            '• 支持一键重置已答状态'),
          _section(theme, '⏱ 计时器',
            '• 支持预设时间（可自定义）\n'
            '• 支持小数分钟输入（如 1.5 = 90秒）\n'
            '• 最后 10 秒红色警告 + 音效提醒\n'
            '• 双击时间显示可同步网络时间'),
          _section(theme, '🏆 积分与排行',
            '• 个人榜/小组榜双模式切换\n'
            '• 段位系统：青铜→白银→黄金→...→王者\n'
            '• 前 3 名高亮显示\n'
            '• 支持锁定选手高亮追踪'),
          _section(theme, '📖 教材阅读',
            '• 点击左上角「教材」浏览开源教材仓库\n'
            '• 点击文件后才开始下载（按需加载）\n'
            '• 支持 PDF 标注：笔刷/橡皮擦/颜色/粗细\n'
            '• 标注模式下 PDF 禁止翻页，避免冲突'),
          _section(theme, '☁️ 云端同步 (WebDAV)',
            '• 推荐使用坚果云，注册后在安全设置创建第三方应用密码\n'
            '• 在设置页填写：服务器地址、用户名、密码\n'
            '• 数据按年级/学科自动分类存储（英文路径）\n'
            '• 支持自动同步/手动同步'),
          _section(theme, '💾 数据管理',
            '• 自动保存：每隔 30 秒自动存档\n'
            '• U盘备份：插入 U 盘后自动检测数据路径\n'
            '• 手动导出：支持导出积分/名单/题库\n'
            '• 智能清理：只保留最近存档，节省空间'),
          _section(theme, '🎨 自定义设置',
            '• 音效开关：抽取/加减分/计时音效独立控制\n'
            '• 触感反馈：按钮振动独立开关\n'
            '• 深色模式/24小时制\n'
            '• 课堂大屏模式：超大按钮 + 高对比度'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(ThemeData theme, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
          const Divider(height: 24),
        ],
      ),
    );
  }
}
