import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../timetable/models/course.dart';
import '../../timetable/providers/timetable_provider.dart';
import 'jw_webview_page.dart';
import '../parsers/njtech_xls_parser.dart';

class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  List<Course>? _parsedCourses;
  String? _fileName;
  bool _isParsing = false;
  String? _errorMessage;

  Future<void> _pickAndParseFile() async {
    setState(() {
      _isParsing = true;
      _errorMessage = null;
      _parsedCourses = null;
      _fileName = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xls', 'xlsx'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isParsing = false;
        });
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _errorMessage = '文件为空或无法读取';
          _isParsing = false;
        });
        return;
      }

      setState(() {
        _fileName = file.name;
      });

      final excel = Excel.decodeBytes(bytes);

      List<List<dynamic>> rows = [];

      for (final table in excel.tables.values) {
        for (final row in table.rows) {
          final cells = <dynamic>[];

          for (final cell in row) {
            cells.add(cell?.value?.toString() ?? '');
          }

          rows.add(cells);
        }
      }

      final parser = NjtechXlsParser();
      final courses = parser.parse(rows);

      setState(() {
        _parsedCourses = courses;
        _isParsing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '解析失败：$e';
        _isParsing = false;
      });
    }
  }

  Future<void> _confirmImport() async {
    if (_parsedCourses == null || _parsedCourses!.isEmpty) return;

    await ref
        .read(timetableProvider.notifier)
        .clearAndImportCourses(_parsedCourses!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导入成功！')),
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入课表'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('登录教务系统导入'),
                subtitle: const Text('在内置浏览器中登录南工大教务系统后提取课表页面'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const JwWebviewPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '从 XLS 文件导入',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '选择从南京工业大学教务系统导出的 XLS 课表文件，自动解析课程信息。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed:
                          _isParsing ? null : _pickAndParseFile,
                      icon: _isParsing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.file_upload_outlined),
                      label: Text(_isParsing
                          ? '正在解析...'
                          : '选择 XLS 文件'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_fileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '文件：$_fileName',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (_parsedCourses != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '识别到 ${_parsedCourses!.length} 门课程',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _parsedCourses!.isEmpty
                        ? null
                        : _confirmImport,
                    icon: const Icon(Icons.check),
                    label: const Text('确认导入'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_parsedCourses!.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('未能识别到课程，请检查文件格式是否正确。'),
                  ),
                )
              else
                ...List.generate(
                  _parsedCourses!.length,
                  (index) {
                    final course = _parsedCourses![index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 40,
                              decoration: BoxDecoration(
                                color: course.color,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${course.teacher}  ${course.classroom}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  Text(
                                    '周${_weekdayText(course.weekday)} '
                                    '第${course.startSection}-${course.endSection}节 '
                                    '(${course.weeks.length}周)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _weekdayText(int weekday) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return weekdays[weekday - 1];
  }
}
