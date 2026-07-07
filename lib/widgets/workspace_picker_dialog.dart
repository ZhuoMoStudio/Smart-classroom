import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/workspace_service.dart';
import '../services/data_service.dart';
import '../theme/design_tokens.dart';
import 'toast_overlay.dart';

/// 首次使用工作目录选择对话框
/// 引导页完成后弹出，可选择工作目录或跳过
class WorkspacePickerDialog extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;
  const WorkspacePickerDialog({super.key, this.onComplete});

  @override
  ConsumerState<WorkspacePickerDialog> createState() =>
      _WorkspacePickerDialogState();
}

class _WorkspacePickerDialogState extends ConsumerState<WorkspacePickerDialog>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ws = ref.watch(workspaceServiceProvider);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandPrimary.withOpacity(0.1),
                ),
                child: const Icon(Icons.folder_open,
                    size: 36, color: AppColors.brandPrimary),
              ),
              const SizedBox(height: 20),
              Text(
                '选择工作目录',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '请选择一个文件夹作为工作目录\n应用将在其中自动创建「学生信息」和「题库」文件夹\n'
                '所有数据将以 xlsx 格式保存在工作目录中',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // 当前状态
              if (ws.isConfigured)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '当前目录: ${ws.rootPath}',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // 选择按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.folder),
                  label: Text(_loading ? '正在读取...' : '选择文件夹'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _loading ? null : _pickAndLoad,
                ),
              ),
              const SizedBox(height: 10),

              // 跳过按钮
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: _loading ? null : _skip,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('稍后设置', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndLoad() async {
    setState(() => _loading = true);
    try {
      final ws = ref.read(workspaceServiceProvider);
      final path = await ws.pickFolder();
      if (path != null && mounted) {
        await ws.ensureInitialTemplates();
        await ref.read(dataServiceProvider).loadFromWorkspace();
        ToastOverlay.show(context, '工作目录已设置 ✓', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastOverlay.show(context, '设置失败: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    widget.onComplete?.call();
    if (mounted) Navigator.of(context).pop();
  }

  void _skip() {
    widget.onComplete?.call();
    Navigator.of(context).pop();
  }
}
