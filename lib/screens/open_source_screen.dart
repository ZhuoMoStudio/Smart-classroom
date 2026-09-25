import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 开源项目说明页面
///
/// 三件事要说清楚：
///   1. 本项目自己用什么协议、使用者需要遵守什么；
///   2. 用了哪些开源项目、它们各自是什么协议；
///   3. 想看完整协议原文时去哪儿看。
///
/// 关于第 3 点的设计取舍：
/// 源码里曾有一份**手写的**依赖清单（18 行），它已经不准了 ——
/// 既列着一个从未被调用的 flutter_local_notifications，
/// 也漏掉了 meta / http_parser 这类间接依赖。
/// 手写的清单一定会腐烂，所以这里改成：
///   - 页面只列「直接依赖」这个规模可控、且与 pubspec 一一对应的集合；
///   - 完整清单由 `tools/gen_third_party.py` 从 pubspec.lock 生成（docs/third-party.md）；
///   - 协议**原文**直接调用 Flutter 框架的 showLicensePage()，
///     它在构建时自动收集所有依赖的 LICENSE，不可能与依赖实际状态脱节。
class OpenSourceScreen extends StatelessWidget {
  const OpenSourceScreen({super.key});

  static const String repoUrl =
      'https://github.com/ZhuoMoStudio/Smart-classroom';
  static const String agplUrl =
      'https://www.gnu.org/licenses/agpl-3.0.html';
  static const String thirdPartyUrl =
      'https://github.com/ZhuoMoStudio/Smart-classroom/blob/main/docs/third-party.md';
  static const String textbookRepoUrl =
      'https://github.com/TapXWorld/ChinaTextbook';

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
            // ---------- 本项目协议 ----------
            _sectionCard(
              context,
              icon: Icons.gavel,
              title: '本项目协议',
              color: Colors.red.shade700,
              children: [
                const Text(
                  '灵动课堂 (Smart Classroom) 采用 AGPL-3.0',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AGPL-3.0 是强著佐权（copyleft）协议：你可以自由使用、修改、分发本软件，'
                  '甚至可以商用，但必须遵守以下义务。',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
                const SizedBox(height: 10),
                const Text('使用或分发本软件时，你需要：',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                const Text(
                  '· 若分发修改版，必须以 AGPL-3.0 公开完整源代码；\n'
                  '· 若把本软件作为网络服务提供给他人使用，'
                  '也必须向使用者提供源代码；\n'
                  '· 保留原始版权声明与许可声明；\n'
                  '· 注明你做了哪些修改；\n'
                  '· 本软件按「原样」提供，不附带任何担保。',
                  style: TextStyle(fontSize: 13, height: 1.7),
                ),
                const SizedBox(height: 10),
                _linkButton('查看 AGPL-3.0 协议全文', agplUrl),
                _linkButton('项目仓库', repoUrl),
              ],
            ),

            const SizedBox(height: 12),

            // ---------- 完整协议原文 ----------
            _sectionCard(
              context,
              icon: Icons.description_outlined,
              title: '完整协议原文',
              color: Colors.indigo.shade600,
              children: [
                const Text(
                  '本软件与全部依赖库的许可协议原文，由 Flutter 框架在构建时自动收集。'
                  '点击下方按钮即可查看完整列表 —— 这份内容不经过人手维护，'
                  '因此不会与依赖的实际状态脱节。',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.list_alt, size: 16),
                      label: const Text('查看完整开源许可'),
                      onPressed: () => showLicensePage(
                        context: context,
                        applicationName: '灵动课堂 (Smart Classroom)',
                        applicationLegalese:
                            'AGPL-3.0 · 本项目及其依赖的开源许可',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('第三方组件清单（由 pubspec.lock 生成）',
                      style: TextStyle(fontSize: 13)),
                  onPressed: () => _open(thirdPartyUrl),
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---------- 直接使用的开源项目 ----------
            _sectionCard(
              context,
              icon: Icons.favorite,
              title: '直接使用的开源项目',
              color: Colors.pink.shade600,
              children: [
                const Text(
                  '下列是本项目的直接依赖（与 pubspec.yaml 一一对应）。'
                  '间接依赖请用上面的「完整开源许可」查看。',
                  style: TextStyle(fontSize: 12, height: 1.6),
                ),
                const SizedBox(height: 8),
                _licenseItem('Flutter', 'BSD-3-Clause',
                    'https://github.com/flutter/flutter'),
                _licenseItem('flutter_riverpod', 'MIT',
                    'https://github.com/rrousselGit/riverpod'),
                _licenseItem('pdfrx', 'MIT',
                    'https://github.com/espresso3389/pdfrx'),
                _licenseItem('webdav_plus', 'MIT',
                    'https://github.com/arcticfox1919/webdav_plus'),
                _licenseItem('excel', 'MIT',
                    'https://github.com/justkawal/excel'),
                _licenseItem('file_picker', 'MIT',
                    'https://github.com/miguelpruivo/flutter_file_picker'),
                _licenseItem('audioplayers', 'MIT',
                    'https://github.com/bluefireteam/audioplayers'),
                _licenseItem('uuid', 'MIT',
                    'https://github.com/daegalus/dart-uuid'),
                _licenseItem('http', 'BSD-3-Clause',
                    'https://github.com/dart-lang/http'),
                _licenseItem('crypto', 'BSD-3-Clause',
                    'https://github.com/dart-lang/crypto'),
                _licenseItem('intl', 'BSD-3-Clause',
                    'https://github.com/dart-lang/intl'),
                _licenseItem('path', 'BSD-3-Clause',
                    'https://github.com/dart-lang/path'),
                _licenseItem('shared_preferences', 'BSD-3-Clause',
                    'https://github.com/flutter/packages'),
                _licenseItem('path_provider', 'BSD-3-Clause',
                    'https://github.com/flutter/packages'),
                _licenseItem('url_launcher', 'BSD-3-Clause',
                    'https://github.com/flutter/packages'),
                _licenseItem('package_info_plus', 'BSD-3-Clause',
                    'https://github.com/fluttercommunity/plus_plugins'),
                _licenseItem('flutter_secure_storage', 'BSD-3-Clause',
                    'https://github.com/mogol/flutter_secure_storage'),
              ],
            ),

            const SizedBox(height: 12),

            // ---------- 教材内容来源 ----------
            _sectionCard(
              context,
              icon: Icons.menu_book,
              title: '教材内容来源',
              color: Colors.teal.shade600,
              children: [
                const Text(
                  '应用内的教材索引指向公开的教材仓库；PDF 由该仓库提供并按需下载，'
                  '不随本应用分发。使用这些教材时，请同时遵循该仓库的声明与相关版权要求。',
                  style: TextStyle(fontSize: 13, height: 1.6),
                ),
                const SizedBox(height: 8),
                _licenseItem('TapXWorld/ChinaTextbook', '见仓库声明',
                    textbookRepoUrl),
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

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
        onTap: () => _open(url),
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
      onPressed: () => _open(url),
      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
    );
  }
}
