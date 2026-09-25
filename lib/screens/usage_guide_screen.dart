import 'package:flutter/material.dart';

/// 使用文档 / 快速上手指南
///
/// 这份文档要与实际实现一致。旧版本里写着「U盘备份：插入 U 盘后自动检测数据路径」，
/// 而对应的 UsbDetector 从未被任何地方调用过（是个孤儿文件），
/// 功能并不存在 —— 这种「文档承诺了不存在的功能」比没有文档更糟。
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
          _section(theme, '📚 三步开始',
            '1. 选择工作目录：设置 → 工作目录，选一个文件夹存放数据\n'
            '2. 导入学生名单：班级页 → 导入，选择 xlsx 名单\n'
            '3. 开始上课：用抽取、计时、积分完成课堂互动\n\n'
            '名单文件名建议写成「三年级1班.xlsx」这样的格式，'
            '应用会据此识别年级班级并归类。'),
          _section(theme, '🎲 随机抽取',
            '• 点击圆形「抽!」按钮随机抽取学生/小组\n'
            '• 抽取时伴有滚动动画和音效\n'
            '• 选定后可立即加减分\n'
            '• 支持锁定小组，抽取范围限定在该小组内\n'
            '• 「排除已选」模式下抽过的人不再重复出现'),
          _section(theme, '📝 题库管理',
            '• 使用 Excel 模板导入题库（第三列为风险题标识）\n'
            '• 混合模式：从所有题库中随机选题\n'
            '• 已答题目自动标记（删除线）\n'
            '• 支持一键重置已答状态'),
          _section(theme, '⏱ 计时器',
            '• 支持预设时间（可在设置中自定义）\n'
            '• 支持小数分钟输入（如 1.5 = 90 秒）\n'
            '• 最后 10 秒红色警告 + 结束音效提醒'),
          _section(theme, '🏆 积分与排行',
            '• 个人榜/小组榜双模式切换\n'
            '• 段位系统：青铜→白银→黄金→…→王者（共 8 段 × 5 小段）\n'
            '• 前 3 名高亮显示\n'
            '• 支持撤销最近一次加减分\n'
            '• 积分写入工作区的「学生信息」目录，可直接用 Excel 打开核对'),
          _section(theme, '📖 教材与批注',
            '• 教材索引已内置（1905 本，含学段/科目/版本/年级信息）\n'
            '• PDF 本体按需从开源教材仓库下载并本地缓存，首次打开需要联网\n'
            '• 阅读器支持翻页、页码跳转、缩放\n'
            '• 批注：笔刷/橡皮擦/颜色/粗细，可撤销、可清除本页\n'
            '• 批注**不写入 PDF 文件本身**，而是独立图层，翻页与缩放都不会位移\n'
            '• 批注保存在工作区「数据存档/批注/」下'),
          _section(theme, '☁️ 云端同步 (WebDAV)',
            '• 推荐坚果云：先在应用内点「注册坚果云账号」\n'
            '• 注册后到「账户信息 → 安全选项 → 添加应用密码」生成专用密码\n'
            '• 密码必须填这个应用密码，**不能用登录密码**（用登录密码只会得到 401）\n'
            '• 服务器地址固定为 https://dav.jianguoyun.com/dav/ （HTTPS，端口 443）\n'
            '• 云端目录：SmartClassroom/students/<年级班级>/ 与 SmartClassroom/questions/\n'
            '  （英文路径，避免不同服务端对中文路径处理不一致）\n'
            '• 同步按修改时间增量比对，不会把整个目录来回覆盖\n'
            '• 覆盖之前会把被覆盖的那一份存入「数据存档」，不静默丢数据'),
          _section(theme, '💾 数据与排错',
            '• 自动保存：改动后 5 秒防抖写入，切到后台立即保存\n'
            '• 名单版本收敛：同年级班级只保留最旧 1 份 + 最新 5 份，其余淘汰\n'
            '• 运行日志：工作区「数据存档/运行日志.log」，出问题时可直接提供给开发者\n'
            '• 数据存档目录还存放：被淘汰的旧名单、同步冲突备份、批注文件'),
          _section(theme, '🎨 自定义设置',
            '• 音效开关：抽取/加减分/计时音效独立控制\n'
            '• 触感反馈：按钮振动独立开关\n'
            '• 深色模式 / 24 小时制\n'
            '• 布局方向：自动 / 横屏 / 竖屏，适配教室大屏与手机'),
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
