import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  static const String _email = 'yni501044@gmail.com';

  Future<void> _sendEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _email,
      queryParameters: {
        'subject': '南工课程表反馈',
        'body': '请在这里描述你遇到的问题或建议：\n\n设备型号：\n系统版本：\nApp 版本：1.0.0\n',
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    await Clipboard.setData(const ClipboardData(text: _email));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('未能打开邮箱，已复制邮箱地址')),
    );
  }

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _email));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制邮箱地址')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('反馈'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.feedback_outlined,
                    size: 36,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '欢迎反馈问题或建议',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '如果你在使用南工课程表时遇到导入失败、课程显示异常、提醒不准等问题，可以通过邮箱联系开发者。',
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
                  leading: Icon(Icons.email_outlined, color: colorScheme.primary),
                  title: const Text('邮箱'),
                  subtitle: const Text(_email),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _sendEmail(context),
                  onLongPress: () => _copyEmail(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.copy_outlined, color: colorScheme.primary),
                  title: const Text('复制邮箱地址'),
                  subtitle: const Text('如果无法唤起邮箱 App，可以手动复制后发送'),
                  onTap: () => _copyEmail(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '建议反馈时附上：手机型号、系统版本、App 版本、问题截图，以及你当时正在进行的操作。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
