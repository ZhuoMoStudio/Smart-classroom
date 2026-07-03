import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/audio_engine.dart';
import '../../services/cloud/cloud_presets.dart';
import '../../services/cloud/webdav_plus_sync.dart';
import '../../services/storage_service.dart';
import '../../services/update_service.dart';
import '../../providers/services_provider.dart';
import '../../services/cloud/cloud_storage_service.dart';
import '../../widgets/toast_overlay.dart';
import '../open_source_screen.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});
  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  late SettingsState _local;

  static const _grades = [
    '一年级',
    '二年级',
    '三年级',
    '四年级',
    '五年级',
    '六年级',
    '初一',
    '初二',
    '初三',
    '高一',
    '高二',
    '高三',
  ];
  static const _subjects = [
    '语文',
    '数学',
    '英语',
    '物理',
    '化学',
    '生物',
    '历史',
    '地理',
    '政治',
    '科学',
    '信息技术',
    '通用技术',
    '体育',
    '音乐',
    '美术',
  ];

  @override
  void initState() {
    super.initState();
    _local = ref.read(settingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings, size: 20),
          SizedBox(width: 8),
          Text('设置'),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 年级学科切换
              _section('当前教学信息'),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _local.currentGrade,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: '年级',
                        hintText: '选择年级',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('不限'),
                        ),
                        ..._grades.map(
                          (g) => DropdownMenuItem(value: g, child: Text(g)),
                        ),
                      ],
                      onChanged:
                          (v) => setState(
                            () => _local = _local.copyWith(currentGrade: v),
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _local.currentSubject,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: '学科',
                        hintText: '选择学科',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('不限'),
                        ),
                        ..._subjects.map(
                          (s) => DropdownMenuItem(value: s, child: Text(s)),
                        ),
                      ],
                      onChanged:
                          (v) => setState(
                            () => _local = _local.copyWith(currentSubject: v),
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),

              // 主题
              _section('主题设置'),
              SwitchListTile(
                title: const Text('24小时制'),
                value: _local.is24Hour,
                dense: true,
                onChanged:
                    (v) =>
                        setState(() => _local = _local.copyWith(is24Hour: v)),
              ),
              SwitchListTile(
                title: const Text('深色模式'),
                value: _local.isDarkMode,
                dense: true,
                onChanged:
                    (v) =>
                        setState(() => _local = _local.copyWith(isDarkMode: v)),
              ),
              SwitchListTile(
                title: const Text('音效'),
                value: _local.soundEnabled,
                dense: true,
                onChanged:
                    (v) => setState(
                      () => _local = _local.copyWith(soundEnabled: v),
                    ),
              ),
              // 教学模式切换（非依赖 Platform，纯 UI 开关）
              SwitchListTile(
                title: const Text('课堂大屏模式'),
                subtitle: const Text('启用大屏布局：超大按钮、高对比度、沉浸全屏'),
                value: _local.teachingMode,
                dense: true,
                onChanged:
                    (v) => setState(
                      () => _local = _local.copyWith(teachingMode: v),
                    ),
              ),
              DropdownButtonFormField<String>(
                value: _local.layoutMode,
                decoration: const InputDecoration(
                  labelText: '布局',
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('自动')),
                  DropdownMenuItem(value: 'landscape', child: Text('横屏')),
                  DropdownMenuItem(value: 'portrait', child: Text('竖屏')),
                ],
                onChanged:
                    (v) => setState(
                      () => _local = _local.copyWith(layoutMode: v!),
                    ),
              ),
              TextFormField(
                initialValue: _local.timerPresets.join(','),
                decoration: const InputDecoration(
                  labelText: '计时预设 (逗号分隔)',
                  isDense: true,
                ),
                onChanged: (v) {
                  final l =
                      v
                          .split(',')
                          .map((s) => int.tryParse(s.trim()) ?? 0)
                          .where((n) => n > 0)
                          .toList();
                  if (l.isNotEmpty)
                    setState(() => _local = _local.copyWith(timerPresets: l));
                },
              ),
              const SizedBox(height: 8), const Divider(),

              // 云同步 (WebDAV Plus)
              _section('云端同步 (WebDAV)'),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '同步至坚果云',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('注册账号'),
                    onPressed:
                        () => launchUrl(
                          Uri.parse('https://www.jianguoyun.com/signup'),
                          mode: LaunchMode.externalApplication,
                        ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: _local.cloudServiceType,
                decoration: const InputDecoration(
                  labelText: '云服务',
                  isDense: true,
                ),
                items:
                    cloudPresets
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.name,
                            child: Text(p.name),
                          ),
                        )
                        .toList(),
                onChanged: (v) {
                  final ps = cloudPresets.firstWhere((p) => p.name == v);
                  setState(
                    () =>
                        _local = _local.copyWith(
                          cloudServiceType: v!,
                          webdavUrl: ps.defaultUrl,
                        ),
                  );
                },
              ),
              TextFormField(
                initialValue: _local.webdavUrl,
                decoration: const InputDecoration(
                  labelText: 'WebDAV 地址',
                  isDense: true,
                  hintText: 'https://dav.jianguoyun.com/dav/',
                ),
                onChanged:
                    (v) =>
                        setState(() => _local = _local.copyWith(webdavUrl: v)),
              ),
              TextFormField(
                initialValue: _local.webdavUsername,
                decoration: const InputDecoration(
                  labelText: '用户名（邮箱/手机号）',
                  isDense: true,
                ),
                onChanged:
                    (v) => setState(
                      () => _local = _local.copyWith(webdavUsername: v),
                    ),
              ),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '第三方应用专用密码',
                  isDense: true,
                  hintText: '非登录密码',
                ),
                onChanged: (v) => _savePassword(v),
              ),
              TextFormField(
                initialValue: _local.remoteFolder,
                decoration: const InputDecoration(
                  labelText: '远程文件夹',
                  isDense: true,
                  hintText: '/灵动课堂数据/',
                ),
                onChanged:
                    (v) => setState(
                      () => _local = _local.copyWith(remoteFolder: v),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '文件名禁止包含 \\ / : * ? " < > | 等特殊字符',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.wifi, size: 16),
                    label: const Text('测试连接'),
                    onPressed: () async {
                      ToastOverlay.show(context, '正在测试连接...');
                      final svc = WebdavPlusSyncService(ref);
                      final ok = await svc.testConnection();
                      if (mounted)
                        ToastOverlay.show(
                          context,
                          ok ? '连接成功 ✓' : '连接失败，请检查地址和密码',
                        );
                    },
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('立即同步'),
                    onPressed: () async {
                      ref.read(syncProvider.notifier).startSync();
                      try {
                        final cloudService = ref.read(
                          cloudStorageServiceProvider,
                        );
                        final success = await cloudService.sync();
                        if (mounted) {
                          ToastOverlay.show(
                            context,
                            success ? '同步完成' : '同步失败，请检查配置',
                          );
                        }
                      } catch (e) {
                        if (mounted) ToastOverlay.show(context, '同步异常: $e');
                      }
                    },
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('自动同步'),
                value: _local.autoSync,
                dense: true,
                onChanged:
                    (v) =>
                        setState(() => _local = _local.copyWith(autoSync: v)),
              ),
              DropdownButtonFormField<int>(
                value: _local.autoSyncInterval,
                decoration: const InputDecoration(
                  labelText: '同步间隔',
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('手动')),
                  DropdownMenuItem(value: 5, child: Text('5分钟')),
                  DropdownMenuItem(value: 15, child: Text('15分钟')),
                  DropdownMenuItem(value: 30, child: Text('30分钟')),
                ],
                onChanged:
                    (v) => setState(
                      () => _local = _local.copyWith(autoSyncInterval: v!),
                    ),
              ),
              const SizedBox(height: 8), const Divider(),

              // 存档
              _section('存档操作'),
              SwitchListTile(
                title: const Text('自动保存'),
                value: _local.autoSave,
                dense: true,
                onChanged:
                    (v) =>
                        setState(() => _local = _local.copyWith(autoSave: v)),
              ),
              DropdownButtonFormField<int>(
                value: _local.autoSaveInterval,
                decoration: const InputDecoration(
                  labelText: '保存间隔',
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 15, child: Text('15秒')),
                  DropdownMenuItem(value: 30, child: Text('30秒')),
                  DropdownMenuItem(value: 60, child: Text('60秒')),
                  DropdownMenuItem(value: 120, child: Text('120秒')),
                ],
                onChanged:
                    (v) => setState(
                      () => _local = _local.copyWith(autoSaveInterval: v!),
                    ),
              ),
              TextFormField(
                initialValue: _local.usbDataPath ?? '',
                decoration: const InputDecoration(
                  labelText: 'U盘数据路径',
                  isDense: true,
                  hintText: '留空自动检测',
                ),
                onChanged:
                    (v) => setState(
                      () =>
                          _local = _local.copyWith(
                            usbDataPath: v.isEmpty ? null : v,
                          ),
                    ),
              ),
              const SizedBox(height: 8), const Divider(),

              // 关于
              _section('关于'),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '灵动课堂 v1.0.0',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.favorite, size: 14),
                    label: const Text('开源说明'),
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OpenSourceScreen(),
                          ),
                        ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.system_update, size: 16),
                label: const Text('检查更新'),
                onPressed: () async {
                  final r = await UpdateService.check();
                  if (!mounted) return;
                  if (r.hasUpdate) {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder:
                          (c) => AlertDialog(
                            title: const Text('发现新版本'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('当前版本: v${r.currentVersion}'),
                                Text('最新版本: v${r.latestVersion}'),
                                const SizedBox(height: 8),
                                const Text('是否前往下载页面？'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('取消'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('去下载'),
                              ),
                            ],
                          ),
                    );
                    if (ok == true && r.downloadUrl != null)
                      launchUrl(
                        Uri.parse(r.downloadUrl!),
                        mode: LaunchMode.externalApplication,
                      );
                  } else {
                    ToastOverlay.show(context, r.message ?? '已是最新版本');
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            ref.read(settingsProvider.notifier).update(_local);
            AudioEngine().setEnabled(_local.soundEnabled);
            Navigator.pop(context);
          },
          child: const Text('应用'),
        ),
      ],
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 4),
    child: Text(
      t,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
        fontSize: 14,
      ),
    ),
  );

  Future<void> _savePassword(String pw) async {
    if (pw.isNotEmpty) {
      await ref.read(storageServiceProvider).setSecure('webdav_password', pw);
    }
  }
}
