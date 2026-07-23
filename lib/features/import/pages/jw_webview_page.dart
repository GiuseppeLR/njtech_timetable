import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../timetable/models/course.dart';
import '../../timetable/providers/timetable_provider.dart';
import '../parsers/njtech_web_parser.dart';

class JwWebviewPage extends ConsumerStatefulWidget {
  const JwWebviewPage({super.key});

  @override
  ConsumerState<JwWebviewPage> createState() => _JwWebviewPageState();
}

class _JwWebviewPageState extends ConsumerState<JwWebviewPage> {
  late final WebViewController _controller;

  bool _isLoading = true;
  String _currentUrl = '';

  static const String _jwHomeUrl = 'https://jwgl.njtech.edu.cn';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'NjtechBridge',
        onMessageReceived: _handleBridgeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_jwHomeUrl));
  }

  Future<void> _extractCourseJson() async {
    try {
      await _controller.runJavaScript(r'''
(function () {
  const params = new URLSearchParams();

  params.append('xnm', document.querySelector('#xnm')?.value || '');
  params.append('xqm', document.querySelector('#xqm')?.value || '');
  params.append('kzlx', 'ck');
  params.append('xsdm', document.querySelector('#xsdm')?.value || '');
  params.append('kclbdm', document.querySelector('#kclbdm')?.value || '');
  params.append('kclxdm', document.querySelector('#kclxdm')?.value || '');

  fetch('/kbcx/xskbcx_cxXsgrkb.html', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'X-Requested-With': 'XMLHttpRequest'
    },
    body: params.toString(),
    credentials: 'include'
  })
    .then(function (response) {
      return response.text().then(function (text) {
        return {
          status: response.status,
          body: text
        };
      });
    })
    .then(function (data) {
      const payload = JSON.stringify({
        url: location.href,
        xnm: document.querySelector('#xnm')?.value || '',
        xqm: document.querySelector('#xqm')?.value || '',
        status: data.status,
        body: data.body
      });

      window.NjtechBridge.postMessage(payload);
    })
    .catch(function (error) {
      window.NjtechBridge.postMessage(JSON.stringify({
        error: String(error),
        url: location.href
      }));
    });
})();
''');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在提取课表接口数据，请稍等')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('执行脚本失败：$e')),
      );
    }
  }

  void _handleBridgeMessage(JavaScriptMessage message) {
    debugPrint('===== NJTECH KB CURRENT URL =====');
    debugPrint(_currentUrl);
    debugPrint('===== NJTECH KB JSON START =====');
    debugPrint(message.message);
    debugPrint('===== NJTECH KB JSON END =====');

    if (!mounted) return;

    final courses = NjtechWebParser().parse(message.message);

    if (courses.isEmpty) {
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('未识别到课程'),
            content: const Text(
              '已经拿到接口数据，但没有解析出课程。\n\n'
              '请把调试控制台里 NJTECH KB JSON START 到 END 之间的内容发给我继续调整。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('知道了'),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('识别到课表数据'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('共识别到 ${courses.length} 条课程安排。'),
                const SizedBox(height: 12),
                Text(
                  '确认导入后，会先自动备份当前课程表，再替换为教务系统课表。',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                _CoursePreview(courses: courses.take(5).toList()),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(timetableProvider.notifier)
                    .clearAndImportCourses(courses);

                if (!context.mounted) return;
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('课表导入成功')),
                );
              },
              child: const Text('确认导入'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _goToCoursePage() async {
    await _controller.loadRequest(Uri.parse(_jwHomeUrl));
  }

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    }
  }

  Future<void> _goForward() async {
    if (await _controller.canGoForward()) {
      await _controller.goForward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('教务系统导入'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '返回',
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
          IconButton(
            tooltip: '前进',
            icon: const Icon(Icons.arrow_forward),
            onPressed: _goForward,
          ),
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            tooltip: '教务首页',
            icon: const Icon(Icons.home_outlined),
            onPressed: _goToCoursePage,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              _currentUrl.isEmpty ? '正在打开教务系统...' : _currentUrl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Text(
              '提示：登录后请进入“个人课表”页面，再点击右下角“提取课表”。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
            ),
          ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _extractCourseJson,
        icon: const Icon(Icons.download_outlined),
        label: const Text('提取课表'),
      ),
    );
  }
}

class _CoursePreview extends StatelessWidget {
  final List<Course> courses;

  const _CoursePreview({
    required this.courses,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: courses.map((course) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: course.color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '周${course.weekday} 第${course.startSection}-${course.endSection}节 ${course.classroom}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
