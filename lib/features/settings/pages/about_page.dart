import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String _qqNumber = '3125404718';
  static const String _githubUrl = 'https://www.github.com/GiuseppeLR';

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('无法打开链接，请稍后重试')),
    );
  }

  Future<void> _launchQQ(BuildContext context) async {
    final uri = Uri.parse('mqqwpa://im/chat?chat_type=wpa&uin=$_qqNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    await Clipboard.setData(const ClipboardData(text: _qqNumber));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('未能唤起 QQ，已复制 QQ 号')),
    );
  }

  Future<void> _copyText(
    BuildContext context,
    String text,
    String message,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '南工课程表',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final versionText = info == null
                        ? '正在读取版本信息...'
                        : '版本 ${info.version}+${info.buildNumber}';

                    return Text(
                      versionText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '产品介绍',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '南工课程表是一款专为南京工业大学学生打造的课程管理工具。'
                    '支持手动添加、编辑课程，从教务系统一键导入课表，XLS 文件导入，'
                    '学期周数自动计算、课程冲突检测、课表分享，以及课程开始前自动提醒等功能。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person_outline, color: colorScheme.primary),
                  title: const Text('开发者'),
                  subtitle: const Text('GiuseppeLR'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      Icon(Icons.chat_bubble_outline, color: colorScheme.primary),
                  title: const Text('QQ'),
                  subtitle: const Text(_qqNumber),
                  trailing: const Icon(Icons.copy_outlined, size: 18),
                  onTap: () => _launchQQ(context),
                  onLongPress: () => _copyText(
                    context,
                    _qqNumber,
                    '已复制 QQ 号',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.code_outlined, color: colorScheme.primary),
                  title: const Text('GitHub'),
                  subtitle: const Text(_githubUrl),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _launchUrl(context, _githubUrl),
                  onLongPress: () => _copyText(
                    context,
                    _githubUrl,
                    '已复制 GitHub 链接',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading:
                  Icon(Icons.description_outlined, color: colorScheme.primary),
              title: const Text('开源许可'),
              subtitle: const Text('Apache License 2.0'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const _LicensePage(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Made for NJTech students',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LicensePage extends StatelessWidget {
  const _LicensePage();

  static const String _licenseText = '''
Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/

TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

1. Definitions.

"License" shall mean the terms and conditions for use, reproduction, and distribution as defined by Sections 1 through 9 of this document.

"Licensor" shall mean the copyright owner or entity authorized by the copyright owner that is granting the License.

"Legal Entity" shall mean the union of the acting entity and all other entities that control, are controlled by, or are under common control with that entity.

"You" (or "Your") shall mean an individual or Legal Entity exercising permissions granted by this License.

"Source" form shall mean the preferred form for making modifications.

"Object" form shall mean any form resulting from mechanical transformation or translation of a Source form.

"Work" shall mean the work of authorship made available under the License.

"Derivative Works" shall mean any work that is based on or derived from the Work.

"Contribution" shall mean any work of authorship intentionally submitted to the Licensor for inclusion in the Work.

"Contributor" shall mean Licensor and any individual or Legal Entity on behalf of whom a Contribution has been received.

2. Grant of Copyright License. Each Contributor grants You a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable copyright license.

3. Grant of Patent License. Each Contributor grants You a perpetual, worldwide, non-exclusive, no-charge, royalty-free, irrevocable patent license.

4. Redistribution. You may reproduce and distribute copies of the Work or Derivative Works in any medium, with or without modifications.

5. Submission of Contributions. Unless You explicitly state otherwise, any Contribution submitted for inclusion in the Work shall be under this License.

6. Trademarks. This License does not grant permission to use trade names, trademarks, service marks, or product names of the Licensor.

7. Disclaimer of Warranty. The Work is provided on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND.

8. Limitation of Liability. In no event shall any Contributor be liable for damages arising from the use of the Work.

9. Accepting Warranty or Additional Liability. You may choose to offer support, warranty, indemnity, or other liability obligations only on Your own behalf.

END OF TERMS AND CONDITIONS
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apache License 2.0'),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(_licenseText),
      ),
    );
  }
}
