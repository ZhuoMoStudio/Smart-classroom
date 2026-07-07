import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/design_tokens.dart';
import '../services/storage_service.dart';

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
      desc: '一款专为教师设计的免费课堂互动管理工具\n\n'
            '苹果透明磨砂玻璃拟态设计风格\n'
            '高效管理班级、小组和成员\n'
            '随机抽取、积分管理、课堂计时\n'
            '1905本教材离线浏览\n\n'
            '本软件采用 MIT + Commons Clause 协议\n'
            '仅供非商业用途使用',
    ),
    _Page(
      title: '苹果磨砂玻璃UI',
      icon: Icons.blur_on,
      color: Color(0xFF5E7EFF),
      desc: '纯净高级的教学视觉体验\n\n'
            '全部界面采用苹果透明毛玻璃设计\n'
            '半透明磨砂模糊背景，通透不遮挡\n'
            '大圆角 + 极浅柔和阴影\n'
            '无粗线条、无厚重色块\n\n'
            '适配教室大屏与手机护眼显示',
    ),
    _Page(
      title: '配置云同步',
      icon: Icons.cloud_sync_outlined,
      color: AppColors.info,
      desc: '推荐使用坚果云 WebDAV 实现多端数据同步\n\n'
            '点击下方按钮注册坚果云账号\n'
            '在坚果云中创建第三方应用专用密码\n'
            '填入设置即可启用自动同步\n\n'
            '数据自动防抖保存，进入后台自动存档',
      showRegisterButton: true,
    ),
    _Page(
      title: '教材仓库与批注',
      icon: Icons.menu_book_outlined,
      color: AppColors.success,
      desc: '1905本教材内置于应用，离线浏览\n\n'
            '学段→科目→版本 三层次快速筛选\n'
            '关键字搜索教材名称\n'
            '选择后自动下载PDF阅读\n\n'
            '支持导入外部PDF文件\n'
            '独立悬浮批注，不嵌入PDF，翻页不位移',
    ),
    _Page(
      title: '开始使用',
      icon: Icons.touch_app_outlined,
      color: Color(0xFF00BCD4),
      desc: '希沃16:9宽屏 + 手机竖屏 双端适配\n\n'
            '宽屏：左侧工具栏 + 中间功能卡片 + 右侧投屏留白\n'
            '手机：透明标题栏 + 底部滑动磨砂工具栏\n\n'
            '数据自动防抖保存\n'
            '支持 WebDAV 云同步和 U盘备份\n\n'
            '现在就开始您的第一堂课吧！',
    ),
  ];

  @override
  void dispose() { _pc.dispose(); super.dispose(); }

  void _next() {
    if (_page < _pages.length - 1) {
      _pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _complete() {
    ref.read(storageServiceProvider).setBool('onboarding_complete', true);
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.color.withOpacity(0.10),
                border: Border.all(color: p.color.withOpacity(0.25), width: 2),
              ),
              child: Icon(p.icon, size: 56, color: p.color),
            ),
            const SizedBox(height: 32),
            Text(p.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(p.desc,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (p.showRegisterButton) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('注册坚果云账号'),
                onPressed: () => launchUrl(
                  Uri.parse('https://www.jianguoyun.com/signup'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              const SizedBox(height: 6),
              Text('注册后在「安全设置」中创建第三方应用密码',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
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
