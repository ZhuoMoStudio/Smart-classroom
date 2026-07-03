import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/design_tokens.dart';
import '../services/storage_service.dart';

/// 引导介绍页 — 带壁纸背景 + 应用图标展示
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
      desc:
          '一款专为教师设计的免费课堂互动管理工具\n\n'
          '高效管理班级、小组和成员\n'
          '随机抽取、积分管理\n'
          '支持对接开源教材仓库\n\n'
          '本软件采用 CC BY-NC 4.0 协议\n'
          '仅供非商业用途使用',
    ),
    _Page(
      title: '配置云同步',
      desc:
          '推荐使用坚果云 WebDAV 实现多端数据同步\n\n'
          '点击下方按钮注册坚果云账号\n'
          '在坚果云中创建第三方应用专用密码\n'
          '填入设置即可启用自动同步\n\n'
          '数据按年级、学科、班级自动分类存储',
      showRegisterButton: true,
    ),
    _Page(
      title: '导入学生名单',
      desc:
          '下载名单模板并按格式填写\n'
          '班级、小组、姓名三列\n\n'
          '点击「更多」→「导入名单」选择 Excel 文件\n'
          '系统会自动识别年级班级\n'
          '相同班级的名单只保留最新版本\n\n'
          '支持一键切换年级和学科',
    ),
    _Page(
      title: '导入题库与教材',
      desc:
          '题库模板：题目、答案、是否为风险题\n'
          '风险题在课堂中会有醒目标识\n\n'
          '点击左上角「教材」按钮\n'
          '可浏览 GitHub 开源教材仓库\n'
          '通过国内加速节点直接下载阅读\n'
          '教材会自动缓存，二次打开无需下载',
    ),
    _Page(
      title: '开始使用',
      desc:
          '横屏触屏优化，适配 100 寸教室大屏\n\n'
          '中央控制台：保存/加载/同步/设置\n'
          '左上角：教材、年级学科切换\n'
          '右上角：状态指示器\n\n'
          '数据自动保存，支持 U 盘一键备份\n'
          '现在就开始您的第一堂课吧！',
    ),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _pc.nextPage(duration: AppDuration.short, curve: Curves.easeInOut);
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
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 跳过按钮
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
            // 内容页
            Expanded(
              child: PageView.builder(
                controller: _pc,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _buildPage(_pages[i], i),
              ),
            ),
            // 底部指示器 + 按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 圆点指示器
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: AppDuration.short,
                        width: _page == i ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _page == i
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ),
                  // 下一步/开始按钮
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

  Widget _buildPage(_Page p, int index) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标：最后一页显示应用图标
            if (index == _pages.length - 1)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/wallpapers/app_icon.jpg',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _colorForIndex(index).withOpacity(0.15),
                      _colorForIndex(index).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: _colorForIndex(index).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _iconForIndex(index),
                  size: 56,
                  color: _colorForIndex(index),
                ),
              ),
            const SizedBox(height: 32),
            Text(
              p.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              p.desc,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
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
              Text(
                '注册后在「安全设置」中创建第三方应用密码',
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

  Color _colorForIndex(int index) {
    const colors = [
      AppColors.brandPrimary,
      AppColors.info,
      AppColors.warning,
      AppColors.success,
      Color(0xFF00BCD4),
    ];
    return colors[index % colors.length];
  }

  IconData _iconForIndex(int index) {
    const icons = [
      Icons.school_outlined,
      Icons.cloud_sync_outlined,
      Icons.group_add_outlined,
      Icons.quiz_outlined,
      Icons.touch_app_outlined,
    ];
    return icons[index % icons.length];
  }
}

class _Page {
  final String title;
  final String desc;
  final bool showRegisterButton;

  const _Page({
    required this.title,
    required this.desc,
    this.showRegisterButton = false,
  });
}
