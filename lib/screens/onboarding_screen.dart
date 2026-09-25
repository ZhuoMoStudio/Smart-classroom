import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/cloud/webdav_plus_sync.dart';
import '../theme/design_tokens.dart';
import '../services/storage_service.dart';

/// 首次使用引导。
///
/// 这一版是按「第一次用的老师能在两三分钟内上手」来写的：
/// 每一页只讲一件事，并且给的是可执行的下一步，而不是设计理念。
///
/// 同时修正了旧版几处与实现不符的说法：
///   - 「1905本教材内置于应用，离线浏览」→ 实际是索引内置、PDF 按需下载并缓存；
///   - 「支持 WebDAV 云同步和 U盘备份」→ U盘检测从未实现，已删除该说法。
/// 文档承诺了不存在的功能，比没有文档更糟。
class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;
  const OnboardingScreen({super.key, this.onComplete});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pc = PageController();
  int _page = 0;

  static const _pages = <_Page>[
    _Page(
      title: '欢迎使用灵动课堂',
      icon: Icons.school_outlined,
      color: AppColors.brandPrimary,
      desc: '课堂互动管理工具，专为教师设计，Android 与 Windows 都可用\n\n'
          '· 班级 / 小组 / 成员 三层管理\n'
          '· 随机抽取、计时、积分与段位排行\n'
          '· 1905 本教材索引内置，PDF 按需下载\n'
          '· PDF 批注独立图层，不改动教材原件\n\n'
          '本项目采用 AGPL-3.0 协议：可自由使用、修改、分发，'
          '但衍生作品也必须以同样协议开放源代码。',
    ),
    _Page(
      title: '三步就能上课',
      icon: Icons.checklist_rtl,
      color: Color(0xFF5E7EFF),
      desc: '第一步 选择工作目录\n'
          '　设置 → 工作目录，选一个文件夹存放名单与题库\n\n'
          '第二步 导入学生名单\n'
          '　班级页 → 导入，选择 xlsx 名单\n'
          '　文件名建议写成「三年级1班.xlsx」，应用据此识别年级班级\n\n'
          '第三步 开始上课\n'
          '　用抽取、计时、积分完成课堂互动',
    ),
    _Page(
      title: '课堂三件套',
      icon: Icons.auto_awesome,
      color: AppColors.success,
      desc: '抽取\n'
          '　点圆形「抽!」按钮，带滚动动画与音效\n'
          '　抽到后可直接加减分；也可锁定小组只在组内抽\n\n'
          '计时\n'
          '　预设时间一键启动，最后 10 秒红色警告 + 提示音\n'
          '　支持小数分钟，例如 1.5 表示 90 秒\n\n'
          '积分\n'
          '　段位从青铜到王者，个人榜/小组榜随时切换\n'
          '　支持撤销最近一次加减分',
    ),
    _Page(
      title: '教材与批注',
      icon: Icons.menu_book_outlined,
      color: Color(0xFFFB8C00),
      desc: '教材\n'
          '　索引内置 1905 本，含学段/科目/版本/年级\n'
          '　PDF 本体首次打开时按需下载并本地缓存\n\n'
          '批注\n'
          '　笔刷、橡皮擦、5 种颜色、3 档粗细\n'
          '　可撤销、可清除本页\n'
          '　批注**不写入 PDF 文件本身**，而是独立图层，\n'
          '　因此翻页、缩放都不会位移，教材原件也不会被改动',
    ),
    _Page(
      title: '配置云同步（可选）',
      icon: Icons.cloud_sync_outlined,
      color: AppColors.info,
      desc: '推荐使用坚果云，多端同步名单与题库\n\n'
          '① 点下方按钮注册坚果云账号\n'
          '② 到「账户信息 → 安全选项 → 添加应用密码」生成专用密码\n'
          '③ 回到应用的同步设置，填入邮箱、应用密码即可\n\n'
          '· 密码必须用「应用密码」，用登录密码只会得到 401\n'
          '· 服务地址固定 https://dav.jianguoyun.com/dav/\n'
          '· 云端目录为 SmartClassroom/students 与 questions\n'
          '· 覆盖前会先备份，不会静默丢数据',
      showRegisterButton: true,
    ),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _pc.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _complete() {
    ref.read(storageServiceProvider).setBool('onboarding_complete', true);
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _complete,
                  child: const Text('跳过引导'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _page == i ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _page == i
                              ? AppColors.brandPrimary
                              : AppColors.neutral300,
                        ),
                      ),
                    ),
                  ),
                  _page == _pages.length - 1
                      ? FilledButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('开始使用'),
                          onPressed: _complete,
                        )
                      : FilledButton.icon(
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('下一步'),
                          onPressed: _next,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_Page p) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.color.withOpacity(0.10),
                border: Border.all(color: p.color.withOpacity(0.25), width: 2),
              ),
              child: Icon(p.icon, size: 44, color: p.color),
            ),
            const SizedBox(height: 24),
            Text(p.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(p.desc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.7,
              ),
              textAlign: TextAlign.left,
            ),
            if (p.showRegisterButton) ...[
              const SizedBox(height: 18),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('注册坚果云账号'),
                onPressed: () => launchUrl(
                  Uri.parse(WebdavPlusSyncService.jianguoyunRegisterUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                WebdavPlusSyncService.jianguoyunAppPasswordHelp,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Page {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final bool showRegisterButton;
  const _Page({
    required this.title, required this.desc,
    required this.icon, required this.color,
    this.showRegisterButton = false,
  });
}
