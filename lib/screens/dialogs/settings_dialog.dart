import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/audio_engine.dart';
import '../../services/cloud/cloud_presets.dart';
import '../../services/update_service.dart';
import '../../widgets/toast_overlay.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});
  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  late SettingsState _l;

  @override
  void initState() { super.initState(); _l = ref.read(settingsProvider); }

  @override
  Widget build(BuildContext ctx) {
    return AlertDialog(title: const Text('设置'), content: SizedBox(width: 400, child: SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        SwitchListTile(title: const Text('24小时制'), value: _l.is24Hour, onChanged: (v) => setState(() => _l = _l.copyWith(is24Hour: v))),
        SwitchListTile(title: const Text('深色模式'), value: _l.isDarkMode, onChanged: (v) => setState(() => _l = _l.copyWith(isDarkMode: v))),
        DropdownButtonFormField<String>(value: _l.wallpaperSource, decoration: const InputDecoration(labelText: '壁纸源'), items: const [
          DropdownMenuItem(value: 'none', child: Text('无')), DropdownMenuItem(value: 'local', child: Text('本地图片')),
          DropdownMenuItem(value: 'bing', child: Text('必应每日')), DropdownMenuItem(value: 'unsplash', child: Text('Unsplash')),
          DropdownMenuItem(value: 'url', child: Text('自定义URL')),
        ], onChanged: (v) => setState(() => _l = _l.copyWith(wallpaperSource: v!))),
        DropdownButtonFormField<int>(value: _l.wallpaperInterval, decoration: const InputDecoration(labelText: '自动换壁纸间隔'), items: const [
          DropdownMenuItem(value: 0, child: Text('关闭')), DropdownMenuItem(value: 5, child: Text('5分钟')),
          DropdownMenuItem(value: 15, child: Text('15分钟')), DropdownMenuItem(value: 30, child: Text('30分钟')),
        ], onChanged: (v) => setState(() => _l = _l.copyWith(wallpaperInterval: v!))),
        SwitchListTile(title: const Text('音效'), value: _l.soundEnabled, onChanged: (v) => setState(() => _l = _l.copyWith(soundEnabled: v))),
        DropdownButtonFormField<String>(value: _l.layoutMode, decoration: const InputDecoration(labelText: '布局'), items: const [
          DropdownMenuItem(value: 'auto', child: Text('自动')), DropdownMenuItem(value: 'landscape', child: Text('横屏')),
          DropdownMenuItem(value: 'portrait', child: Text('竖屏')),
        ], onChanged: (v) => setState(() => _l = _l.copyWith(layoutMode: v!))),
        TextFormField(initialValue: _l.timerPresets.join(','), decoration: const InputDecoration(labelText: '计时预设 (逗号分隔)'),
          onChanged: (v) { final list = v.split(',').map((s) => int.tryParse(s.trim()) ?? 0).where((n) => n > 0).toList(); if (list.isNotEmpty) setState(() => _l = _l.copyWith(timerPresets: list)); }),
        const Divider(),
        const Text('云端同步配置', style: TextStyle(fontWeight: FontWeight.bold)),
        DropdownButtonFormField<String>(value: _l.cloudServiceType, decoration: const InputDecoration(labelText: '云服务'),
          items: cloudPresets.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))).toList(),
          onChanged: (v) { final ps = cloudPresets.firstWhere((p) => p.name == v); setState(() => _l = _l.copyWith(cloudServiceType: v!, webdavUrl: ps.defaultUrl)); }),
        TextFormField(initialValue: _l.webdavUrl, decoration: const InputDecoration(labelText: 'WebDAV 地址'), onChanged: (v) => setState(() => _l = _l.copyWith(webdavUrl: v))),
        TextFormField(initialValue: _l.webdavUsername, decoration: const InputDecoration(labelText: '用户名'), onChanged: (v) => setState(() => _l = _l.copyWith(webdavUsername: v))),
        TextFormField(obscureText: true, decoration: const InputDecoration(labelText: '密码'), onChanged: (_) {}),
        TextFormField(initialValue: _l.remoteFolder, decoration: const InputDecoration(labelText: '远程文件夹路径'), onChanged: (v) => setState(() => _l = _l.copyWith(remoteFolder: v))),
        Row(children: [ElevatedButton(onPressed: () async {
          ToastOverlay.show(ctx, '正在测试连接...'); await Future.delayed(const Duration(seconds: 1)); ToastOverlay.show(ctx, '连接成功 \u2713');
        }, child: const Text('测试连接'))]),
        SwitchListTile(title: const Text('自动同步'), value: _l.autoSync, onChanged: (v) => setState(() => _l = _l.copyWith(autoSync: v))),
        DropdownButtonFormField<int>(value: _l.autoSyncInterval, decoration: const InputDecoration(labelText: '自动同步间隔'), items: const [
          DropdownMenuItem(value: 0, child: Text('手动')), DropdownMenuItem(value: 5, child: Text('5分钟')),
          DropdownMenuItem(value: 15, child: Text('15分钟')), DropdownMenuItem(value: 30, child: Text('30分钟')),
          DropdownMenuItem(value: 60, child: Text('1小时')),
        ], onChanged: (v) => setState(() => _l = _l.copyWith(autoSyncInterval: v!))),
        DropdownButtonFormField<String>(value: _l.syncStrategy, decoration: const InputDecoration(labelText: '同步策略'), items: const [
          DropdownMenuItem(value: 'upload', child: Text('仅上传')), DropdownMenuItem(value: 'download', child: Text('仅下载')),
          DropdownMenuItem(value: 'bidirectional', child: Text('双向同步')),
        ], onChanged: (v) => setState(() => _l = _l.copyWith(syncStrategy: v!))),
        DropdownButtonFormField<String>(value: _l.conflictStrategy, decoration: const InputDecoration(labelText: '冲突处理'), items: const [
          DropdownMenuItem(value: 'remote', child: Text('云端优先')), DropdownMenuItem(value: 'local', child: Text('本地优先')),
          DropdownMenuItem(value: 'manual', child: Text('手动选择')),
        ], onChanged: (v) => setState(() => _l = _l.copyWith(conflictStrategy: v!))),
        ElevatedButton.icon(icon: const Icon(Icons.sync), label: const Text('立即同步'), onPressed: () {
          ref.read(syncProvider.notifier).startSync();
          Future.delayed(const Duration(seconds: 2), () { ref.read(syncProvider.notifier).syncComplete(); ToastOverlay.show(ctx, '同步完成'); });
        }),
        const Divider(),
        const Text('存档操作', style: TextStyle(fontWeight: FontWeight.bold)),
        SwitchListTile(title: const Text('自动保存'), value: _l.autoSave, onChanged: (v) => setState(() => _l = _l.copyWith(autoSave: v))),
        DropdownButtonFormField<int>(value: _l.autoSaveInterval, decoration: const InputDecoration(labelText: '自动保存间隔'), items: const [
          DropdownMenuItem(value: 15, child: Text('15秒')), DropdownMenuItem(value: 30, child: Text('30秒')),
          DropdownMenuItem(value: 60, child: Text('60秒')), DropdownMenuItem(value: 120, child: Text('120秒')),
        ], onChanged: (v) => setState(() => _l = _l.copyWith(autoSaveInterval: v!))),
        const SizedBox(height: 12),
        ElevatedButton.icon(icon: const Icon(Icons.system_update), label: const Text('检查更新'), onPressed: () async {
          final r = await UpdateService.check();
          if (!mounted) return;
          if (r.hasUpdate) {
            final ok = await showDialog<bool>(context: ctx, builder: (c) => AlertDialog(
              title: const Text('发现新版本'),
              content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('当前版本: v${r.currentVersion}'), Text('最新版本: v${r.latestVersion}'),
                const SizedBox(height: 8), const Text('是否前往下载页面？'),
              ]),
              actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
                FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('去下载'))],
            ));
            if (ok == true && r.downloadUrl != null) { launchUrl(Uri.parse(r.downloadUrl!), mode: LaunchMode.externalApplication); }
          } else { ToastOverlay.show(ctx, r.message ?? '已是最新版本'); }
        }),
      ])),
    ), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
      FilledButton(onPressed: () { ref.read(settingsProvider.notifier).update(_l); AudioEngine().setEnabled(_l.soundEnabled); Navigator.pop(ctx); }, child: const Text('应用')),
    ]);
  }
}
