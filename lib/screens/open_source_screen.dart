import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 开源项目说明页面
///
/// 展示本项目所使用的开源项目、协议、以及本项目的授权条款。
class OpenSourceScreen extends StatelessWidget {
  const OpenSourceScreen({super.key});

  static const String repoUrl =
      'https://github.com/ZhuoMoStudio/Smart-classroom';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('开源项目说明'),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 本项目协议
            _sectionCard(
              context,
              icon: Icons.gavel,
              title: '本项目协议',
              color: Colors.red.shade700,
              children: [
                const Text(
                  '灵动课堂 (Smart Classroom) 采用 CC BY-NC 4.0 协议',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                const Text(
                  '本软件仅供非商业用途使用。任何个人或组织不得将本软件或其衍生作品用于商业目的，包括但不限于销售、出租、商业培训、商业服务等场景。如需商业授权，请联系开发者获取许可。',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 12),
                _linkButton(
                  '查看完整协议 (CC BY-NC 4.0)',
                  'https://creativecommons.org/licenses/by-nc/4.0/',
                ),
                const SizedBox(height: 4),
                _linkButton('项目仓库', repoUrl),
              ],
            ),

            const SizedBox(height: 12),

            // 使用条款
            _sectionCard(
              context,
              icon: Icons.warning_amber,
              title: '使用条款',
              color: Colors.orange.shade700,
              children: const [
                Text(
                  '• 本软件按"原样"提供，不提供任何明示或暗示的担保。\n'
                  '• 使用者需自行承担使用本软件的所有风险。\n'
                  '• 开发者不对因使用本软件造成的任何损失承担责任。\n'
                  '• 使用本软件即表示您同意上述条款。',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 使用的开源项目
            _sectionCard(
              context,
              icon: Icons.favorite,
              title: '使用的开源项目',
              color: Colors.pink.shade600,
              children: [
                _licenseItem(
                  'Flutter',
                  'BSD-3-Clause',
                  'https://github.com/flutter/flutter',
                ),
                _licenseItem(
                  'flutter_riverpod',
                  'MIT',
                  'https://github.com/rrousselGit/riverpod',
                ),
                _licenseItem(
                  'pdfrx',
                  'MIT',
                  'https://github.com/espresso3389/pdfrx',
                ),
                _licenseItem(
                  'webdav_plus',
                  'MIT',
                  'https://github.com/arcticfox1919/webdav_plus',
                ),
                _licenseItem(
                  'excel',
                  'MIT',
                  'https://github.com/justkawal/excel',
                ),
                _licenseItem(
                  'file_picker',
                  'MIT',
                  'https://github.com/miguelpruivo/flutter_file_picker',
                ),
                _licenseItem('dio', 'MIT', 'https://github.com/cfug/dio'),
                _licenseItem(
                  'http',
                  'BSD-3-Clause',
                  'https://github.com/dart-lang/http',
                ),
                _licenseItem(
                  'crypto',
                  'BSD-3-Clause',
                  'https://github.com/dart-lang/crypto',
                ),
                _licenseItem(
                  'archive',
                  'MIT',
                  'https://github.com/brendan-duncan/archive',
                ),
                _licenseItem(
                  'uuid',
                  'MIT',
                  'https://github.com/daegalus/dart-uuid',
                ),
                _licenseItem(
                  'audioplayers',
                  'MIT',
                  'https://github.com/bluefireteam/audioplayers',
                ),
                _licenseItem(
                  'path_provider',
                  'BSD-3-Clause',
                  'https://github.com/flutter/packages',
                ),
                _licenseItem(
                  'shared_preferences',
                  'BSD-3-Clause',
                  'https://github.com/flutter/packages',
                ),
                _licenseItem(
                  'flutter_secure_storage',
                  'BSD-3-Clause',
                  'https://github.com/mogol/flutter_secure_storage',
                ),
                _licenseItem(
                  'package_info_plus',
                  'BSD-3-Clause',
                  'https://github.com/fluttercommunity/plus_plugins',
                ),
                _licenseItem(
                  'url_launcher',
                  'BSD-3-Clause',
                  'https://github.com/flutter/packages',
                ),
                _licenseItem(
                  'flutter_local_notifications',
                  'BSD-3-Clause',
                  'https://github.com/MaikuB/flutter_local_notifications',
                ),
                _licenseItem(
                  'intl',
                  'BSD-3-Clause',
                  'https://github.com/dart-lang/intl',
                ),
              ],
            ),

            const SizedBox(height: 16),
            Center(
              child: Text(
                '感谢所有开源项目的贡献者 ❤️',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _licenseItem(String name, String license, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap:
            () =>
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  license,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linkButton(String label, String url) {
    return TextButton.icon(
      icon: const Icon(Icons.open_in_new, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed:
          () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
    );
  }
}
