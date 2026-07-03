import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
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
import '../usage_guide_screen.dart';
import '../open_source_screen.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});
  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  late SettingsState _local;

  static const _grades = [
    '一年级','二年级','三年级','四年级','五年级','六年级',
    '初一','初二','初三','高一','高二','高三',
  ];
  static const _subjects = [
    '语文','数学','英语','物理','化学','生物',
    '历史','地理','政治','科学','信息技术','通用技术','体育','音乐','美术',
  ];

  @override
  void initState() {
    super.initState();
    _local = ref.read(settingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.settings, size: 22, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '设置',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          // 可滚动内容
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section('教学信息'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _local.currentGrade,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: '年级',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('不限', style: TextStyle(fontSize: 14))),
                            ..._grades.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 14)))),
                          ],
                          onChanged: (v) => setState(() => _local = _local.copyWith(currentGrade: v)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _local.currentSubject,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: '学科',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('不限', style: TextStyle(fontSize: 14))),
                            ..._subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))),
                          ],
                          onChanged: (v) => setState(() => _local = _local.copyWith(currentSubject: v)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  _section('交互反馈'),
                  const SizedBox(height: 2),
                  SwitchListTile.adaptive(
                    title: const Text('音效', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('抽取、加减分、计时结束等音效', style: TextStyle(fontSize: 12)),
                    value: _local.soundEnabled,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _local = _local.copyWith(soundEnabled: v)),
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('触感反馈', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('按钮按压振动', style: TextStyle(fontSize: 12)),
                    value: _local.hapticFeedback,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _local = _local.copyWith(hapticFeedback: v)),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  _section('主题与界面'),
                  const SizedBox(height: 2),
                  SwitchListTile.adaptive(
                    title: const Text('24小时制', style: TextStyle(fontSize: 14)),
                    value: _local.is24Hour,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _local = _local.copyWith(is24Hour: v)),
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('深色模式', style: TextStyle(fontSize: 14)),
                    value: _local.isDarkMode,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _local = _local.copyWith(isDarkMode: v)),
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('课堂大屏模式', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('超大按钮、高对比度、沉浸全屏', style: TextStyle(fontSize: 12)),
                    value: _local.teachingMode,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _local = _local.copyWith(teachingMode: v)),
                  ),
                  DropdownButtonFormField<String>(
                    value: _local.layoutMode,
                    decoration: const InputDecoration(
                      labelText: '布局方向',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'auto', child: Text('自动', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: 'landscape', child: Text('横屏', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: 'portrait', child: Text('竖屏', style: TextStyle(fontSize: 14))),
                    ],
                    onChanged: (v) => setState(() => _local = _local.copyWith(layoutMode: v!)),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: _local.timerPresets.join(','),
                    decoration: const InputDecoration(
                      labelText: '计时预设 (逗号分隔)',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (v) {
                      final l = v.split(',').map((s) => int.tryParse(s.trim()) ?? 0).where((n) => n > 0).toList();
                      if (l.isNotEmpty) setState(() => _local = _local.copyWith(timerPresets: l));
                    },
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  _section('云端同步 (WebDAV)'),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '同步至坚果云',
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: theme.colorScheme.primary),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text('注册账号', style: TextStyle(fontSize: 13)),
                        onPressed: () => launchUrl(Uri.parse('https://www.jianguoyun.com/signup'), mode: LaunchMode.externalApplication),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _local.cloudServiceType,
                    decoration: const InputDecoration(
                      labelText: '云服务',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: cloudPresets.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: (v) {
                      final ps = cloudPresets.firstWhere((p) => p.name == v);
                      setState(() => _local = _local.copyWith(cloudServiceType: v!, webdavUrl: ps.defaultUrl));
                    },
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: _local.webdavUrl,
                    decoration: const InputDecoration(
                      labelText: 'WebDAV 地址',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      hintText: 'https://dav.jianguoyun.com/dav/',
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (v) => setState(() => _local = _local.copyWith(webdavUrl: v)),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: _local.webdavUsername,
                    decoration: const InputDecoration(
                      labelText: '用户名（邮箱/手机号）',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (v) => setState(() => _local = _local.copyWith(webdavUsername: v)),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '第三方应用专用密码',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      hintText: '非登录密码',
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (v) => _savePassword(v),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: _local.remoteFolder,
                    decoration: const InputDecoration(
                      labelText: '远程文件夹',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      hintText: '/灵动课堂数据/',
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (v) => setState(() => _local = _local.copyWith(remoteFolder: v)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('文件名禁止包含特殊字符', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.wifi, size: 16),
                          label: const Text('测试连接', style: TextStyle(fontSize: 13)),
                          onPressed: () => _testConnection(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.sync, size: 16),
                          label: const Text('立即同步', style: TextStyle(fontSize: 13)),
                          onPressed: () => _syncNow(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile.adaptive(
                    title: const Text('自动同步', style: TextStyle(fontSize: 14)),
                    value: _local.autoSync,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _local = _local.copyWith(autoSync: v)),
                  ),
                  DropdownButtonFormField<int>(
                    value: _local.autoSyncInterval,
                    decoration: const InputDecoration(
                      labelText: '同步间隔',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('手动', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: 5, child: Text('5分钟', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: 15, child: Text('15分钟', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: 30, child: Text('30分钟', style: TextStyle(fontSize: 14))),
                    ],
                    onChanged: (v) => setState(() => _local = _local.copyWith(autoSyncInterval: v!)),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  _section('本地存档'),
                  const SizedBox(height: 2),
                  SwitchListTile.adaptive(
                    title: const Text('自动保存', style: TextStyle(fontSize: 14)),
                    value: _local.autoSave,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _local = _local.copyWith(autoSave: v)),
                  ),
                  DropdownButtonFormField<int>(
                    value: _local.autoSaveInterval,
                    decoration: const InputDecoration(
                      labelText: '保存间隔',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 15, child: Text('15秒', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: 30, child: Text('30秒', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: 60, child: Text('60秒', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: 120, child: Text('120秒', style: TextStyle(fontSize: 14))),
                    ],
                    onChanged: (v) => setState(() => _local = _local.copyWith(autoSaveInterval: v!)),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _local.usbDataPath ?? 'U盘数据路径（未设置，自动检测）',
                          style: TextStyle(fontSize: 13, color: _local.usbDataPath != null ? theme.colorScheme.onSurface : theme.colorScheme.outline),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.folder_open, size: 16),
                        label: const Text('选择文件夹', style: TextStyle(fontSize: 12)),
                        onPressed: () async {
                          final path = await FilePicker.platform.getDirectoryPath();
                          if (path != null) {
                            setState(() => _local = _local.copyWith(usbDataPath: path));
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  _section('关于'),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Text('灵动课堂 v1.0.5', style: TextStyle(fontSize: 13)),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.help_outline, size: 14),
                        label: const Text('使用指南', style: TextStyle(fontSize: 13)),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsageGuideScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.system_update, size: 16),
                      label: const Text('检查更新', style: TextStyle(fontSize: 13)),
                      onPressed: _checkUpdate,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // 底部按钮
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.dividerColor, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    ref.read(settingsProvider.notifier).update(_local);
                    AudioEngine().setSoundEnabled(_local.soundEnabled);
                    AudioEngine().setHapticEnabled(_local.hapticFeedback);
                    AudioEngine().hapticMedium();
                    Navigator.pop(context);
                  },
                  child: const Text('应用', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String t) => Text(
    t,
    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 14),
  );

  Future<void> _testConnection() async {
    const svc = WebdavPlusSyncService();
    final pw = await ref.read(storageServiceProvider).getSecure('webdav_password') ?? '';
    ToastOverlay.show(context, '正在测试连接...');
    final ok = await svc.testConnection(settings: _local, password: pw);
    if (mounted) {
      ToastOverlay.show(context, ok ? '连接成功 ✓' : '连接失败，请检查地址和密码');
    }
  }

  Future<void> _syncNow() async {
    ref.read(syncProvider.notifier).startSync();
    ToastOverlay.show(context, '正在同步...');
    try {
      final cloudService = ref.read(cloudStorageServiceProvider);
      final success = await cloudService.sync();
      if (mounted) {
        ToastOverlay.show(context, success ? '同步完成 ✓' : '同步失败，请检查云端配置');
      }
    } catch (e) {
      if (mounted) ToastOverlay.show(context, '同步异常: $e');
    }
  }

  Future<void> _checkUpdate() async {
    final r = await UpdateService.check();
    if (!mounted) return;
    if (r.hasUpdate) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('发现新版本'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('当前版本: v${r.currentVersion}'),
            Text('最新版本: v${r.latestVersion}'),
            const SizedBox(height: 8),
            const Text('是否前往下载页面？'),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('去下载')),
          ],
        ),
      );
      if (ok == true && r.downloadUrl != null) {
        launchUrl(Uri.parse(r.downloadUrl!), mode: LaunchMode.externalApplication);
      }
    } else {
      ToastOverlay.show(context, r.message ?? '已是最新版本');
    }
  }

  Future<void> _savePassword(String pw) async {
    if (pw.isNotEmpty) {
      await ref.read(storageServiceProvider).setSecure('webdav_password', pw);
    }
  }
}
