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

  static const _pages = [
    _Page(
      icon: Icons.school_outlined,
      color: AppColors.brandPrimary,
      title: '欢迎使用灵动课堂',
      desc:
          '一款专为教师设计的免费课堂互动管理工具\n\n高效管理班级、小组和成员\n随机抽取、积分管理\n支持对接开源教材仓库\n\n本软件采用 CC BY-NC 4.0 协议\n仅供非商业用途使用',
    ),
    _Page(
      icon: Icons.cloud_sync_outlined,
      color: AppColors.info,
      title: '配置云同步',
      desc:
          '推荐使用坚果云 WebDAV 实现多端数据同步\n\n点击下方按钮注册坚果云账号\n在坚果云中创建第三方应用专用密码\n填入设置即可启用自动同步\n\n数据按年级、学科、班级自动分类存储',
      showRegisterButton: true,
    ),
    _Page(
      icon: Icons.group_add_outlined,
      color: AppColors.warning,
      title: '导入学生名单',
      desc:
          '下载名单模板并按格式填写\n班级、小组、姓名三列\n\n点击「更多」→「导入名单」选择 Excel 文件\n系统会自动识别年级班级\n相同班级的名单只保留最新版本\n\n支持一键切换年级和学科',
    ),
    _Page(
      icon: Icons.quiz_outlined,
      color: AppColors.success,
      title: '导入题库与教材',
      desc:
          '题库模板：题目、答案、是否为风险题\n风险题在课堂中会有醒目标识\n\n点击左上角「教材」按钮\n可浏览 GitHub 开源教材仓库\n通过国内加速节点直接下载阅读\n教材会自动缓存，二次打开无需下载',
    ),
    _Page(
      icon: Icons.touch_app_outlined,
      color: const Color(0xFF00BCD4),
      title: '开始使用',
      desc:
          '横屏触屏优化，适配 100 寸教室大屏\n\n中央控制台：保存/加载/同步/设置\n左上角：教材、年级学科切换\n右上角：状态指示器\n\n数据自动保存，支持 U 盘一键备份\n现在就开始您的第一堂课吧！',
    ),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1)
      _pc.nextPage(duration: AppDuration.short, curve: Curves.easeInOut);
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
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _complete,
                child: const Text('跳过引导'),
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                          color:
                              _page == i
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [p.color.withOpacity(0.15), p.color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: p.color.withOpacity(0.3), width: 2),
            ),
            child: Icon(p.icon, size: 56, color: p.color),
          ),
          const SizedBox(height: 40),
          Text(
            p.title,
            style: AppTypography.h2.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            p.desc,
            style: AppTypography.bodyLarge.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (p.showRegisterButton) ...[
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('注册坚果云账号'),
              onPressed:
                  () => launchUrl(
                    Uri.parse('https://www.jianguoyun.com/signup'),
                    mode: LaunchMode.externalApplication,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '注册后在「安全设置」中创建第三方应用密码',
              style: AppTypography.caption.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Page {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final bool showRegisterButton;
  const _Page({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    this.showRegisterButton = false,
  });
}
