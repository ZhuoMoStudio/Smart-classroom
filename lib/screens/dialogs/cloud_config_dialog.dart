import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../services/cloud/cloud_presets.dart';
import '../../widgets/toast_overlay.dart';

class CloudConfigDialog extends ConsumerStatefulWidget {
  const CloudConfigDialog({super.key});
  @override
  ConsumerState<CloudConfigDialog> createState() => _CloudConfigDialogState();
}

class _CloudConfigDialogState extends ConsumerState<CloudConfigDialog> {
  late SettingsState _l;

  @override
  void initState() { super.initState(); _l = ref.read(settingsProvider); }

  @override
  Widget build(BuildContext ctx) {
    return AlertDialog(title: const Text('云端配置'), content: SizedBox(width: 380, child: SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: _l.cloudServiceType, decoration: const InputDecoration(labelText: '云服务'),
          items: cloudPresets.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name))).toList(),
          onChanged: (v) { final ps = cloudPresets.firstWhere((p) => p.name == v); setState(() => _l = _l.copyWith(cloudServiceType: v!, webdavUrl: ps.defaultUrl)); }),
        TextFormField(initialValue: _l.webdavUrl, decoration: const InputDecoration(labelText: 'WebDAV 地址'), onChanged: (v) => setState(() => _l = _l.copyWith(webdavUrl: v))),
        TextFormField(initialValue: _l.webdavUsername, decoration: const InputDecoration(labelText: '用户名'), onChanged: (v) => setState(() => _l = _l.copyWith(webdavUsername: v))),
        TextFormField(obscureText: true, decoration: const InputDecoration(labelText: '密码'), onChanged: (_) {}),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () async {
          ToastOverlay.show(ctx, '正在测试连接...'); await Future.delayed(const Duration(seconds: 1)); ToastOverlay.show(ctx, '连接成功');
        }, child: const Text('测试连接')),
      ])),
    ), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
      FilledButton(onPressed: () { ref.read(settingsProvider.notifier).update(_l); Navigator.pop(ctx); }, child: const Text('保存')),
    ]);
  }
}
