import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_provider.dart';
import '../providers/settings_provider.dart';
import '../services/data_service.dart';
import '../theme/design_tokens.dart';
import '../theme/responsive.dart';
import '../theme/route_utils.dart';
import '../widgets/glass_panel.dart';
import '../widgets/toast_overlay.dart';
import '../widgets/auto_save_indicator.dart';
import '../widgets/sync_status_indicator.dart';
import '../widgets/textbook_panel.dart';
import '../services/audio_engine.dart';
import 'draw_panel.dart';
import 'question_panel.dart';
import 'timer_panel.dart';
import 'leaderboard_panel.dart';
import 'dialogs/settings_dialog.dart';
import 'open_source_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;
  static const _tabLabels = ['课堂', '班级', '资源', '设置'];
  static const _tabIcons = [Icons.chalkboard, Icons.people, Icons.menu_book, Icons.settings];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_LifecycleObserver(ref));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(autoSaveProvider);
    final isWide = MediaQuery.of(context).size.width >= AppBreakpoints.desktop;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  // ==================== 宽屏：希沃16:9三分栏 ====================
  Widget _buildWideLayout() {
    return Row(
      children: [
        // 左侧磨砂工具栏
        _buildLeftToolbar(),
        // 中间主画布
        Expanded(child: _buildMainContent()),
        // 右侧留白
        const SizedBox(width: 1),
      ],
    );
  }

  Widget _buildLeftToolbar() {
    final theme = Theme.of(context);
    return FrostedPanel(
      width: 72,
      height: double.infinity,
      blur: 20,
      borderRadius: BorderRadius.zero,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Tab 按钮
          for (int i = 0; i < _tabLabels.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _toolbarBtn(
                icon: _tabIcons[i],
                label: _tabLabels[i],
                selected: _tabIndex == i,
                onTap: () => setState(() => _tabIndex = i),
              ),
            ),
          const Spacer(),
          // 底部
          AutoSaveIndicator(isDirty: ref.watch(classProvider).isDirty),
          const SizedBox(height: 4),
          SyncStatusIndicator(),
        ],
      ),
    );
  }

  Widget _toolbarBtn({
    required IconData icon, required String label,
    required bool selected, required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: FrostedPanel(
        blur: 8,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        backgroundColor: selected
            ? AppColors.brandPrimary.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22,
                color: selected ? AppColors.brandPrimary : AppColors.textSecondary),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              fontSize: 10,
              color: selected ? AppColors.brandPrimary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_tabIndex) {
      case 0: return const _ClassroomView();
      case 1: return const _ClassDataView();
      case 2: return const TextbookPanel();
      case 3: return const _SettingsPlaceholder();
      default: return const _ClassroomView();
    }
  }

  // ==================== 窄屏：手机竖屏 ====================
  Widget _buildNarrowLayout() {
    return Column(
      children: [
        // 顶部沉浸式透明标题栏
        Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('灵动课堂', style: Theme.of(context).textTheme.title2),
                const Spacer(),
                SyncStatusIndicator(),
                const SizedBox(width: 8),
                AutoSaveIndicator(isDirty: ref.watch(classProvider).isDirty),
              ],
            ),
          ),
        ),
        // 主内容区
        Expanded(child: _buildMainContent()),
        // 底部磨砂工具栏
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildBottomBar() {
    return FrostedPanel(
      blur: 20,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabLabels.length, (i) {
            return GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: FrostedPanel(
                blur: 6,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                backgroundColor: _tabIndex == i
                    ? AppColors.brandPrimary.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_tabIcons[i], size: 18,
                        color: _tabIndex == i ? AppColors.brandPrimary : AppColors.textSecondary),
                    if (_tabIndex == i) ...[
                      const SizedBox(width: 4),
                      Text(_tabLabels[i], style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary,
                      )),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ==================== 课堂主页 ====================
class _ClassroomView extends ConsumerWidget {
  const _ClassroomView();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // 功能快捷区
          Expanded(
            child: Row(
              children: [
                Expanded(child: _FeatureCard(
                  icon: Icons.casino, label: '随机抽取',
                  color: AppColors.brandPrimary,
                  child: const DrawPanel(),
                )),
                const SizedBox(width: 8),
                Expanded(child: _FeatureCard(
                  icon: Icons.timer, label: '课堂计时',
                  color: Colors.orange,
                  child: const TimerPanel(),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _FeatureCard(
                  icon: Icons.leaderboard, label: '排行榜',
                  color: Colors.green,
                  child: const LeaderboardPanel(),
                )),
                const SizedBox(width: 8),
                Expanded(child: _FeatureCard(
                  icon: Icons.quiz, label: '题库',
                  color: Colors.purple,
                  child: const QuestionPanel(),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon; final String label;
  final Color color; final Widget child;
  const _FeatureCard({required this.icon, required this.label, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return FrostedPanel.card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ]),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ==================== 班级数据 ====================
class _ClassDataView extends ConsumerWidget {
  const _ClassDataView();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Center(child: Text('班级数据', style: TextStyle(color: AppColors.textSecondary)));
  }
}

// ==================== 设置占位 ====================
class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('设置', style: TextStyle(color: AppColors.textSecondary)));
  }
}

// ==================== 生命周期观察者 ====================
class _LifecycleObserver extends WidgetsBindingObserver {
  final Ref ref;
  _LifecycleObserver(this.ref);
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ref.read(dataServiceProvider).saveImmediate(silent: true);
    }
  }
}