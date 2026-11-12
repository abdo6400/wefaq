import 'package:flutter/material.dart';

import 'session_data.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.questions, required this.mode});
  final List<String> questions;
  final ConversationMode mode;
  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late final SessionProgress progress = SessionProgress(widget.questions);
  Future<void> exit() async {
    if (progress.complete) {
      Navigator.of(context).pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنهاء الجلسة؟'),
        content: const Text('لن يُحفظ تقدم الجلسة في هذه النسخة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('متابعة الجلسة'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: progress.complete,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) exit();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          progress.complete ? 'انتهت الجلسة' : 'جلسة ${widget.mode.label}',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: progress.complete
                  ? [
                      Text(
                        'الأسئلة التي انتقلتم منها: ${progress.discussedCount}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text('الأسئلة المتخطاة: ${progress.skippedCount}'),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: exit,
                        child: const Text('العودة لإعداد الجلسة'),
                      ),
                    ]
                  : [
                      Text(
                        'السؤال ${progress.index + 1} من ${progress.questions.length}',
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: (progress.index + 1) / progress.questions.length,
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            progress.questions[progress.index],
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'من حق أي طرف تخطي السؤال. لا يسجل التطبيق إجاباتكما.',
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: progress.index == 0
                                ? null
                                : () => setState(progress.previous),
                            child: const Text('السابق'),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                setState(() => progress.advance(skipped: true)),
                            child: const Text('تخطي'),
                          ),
                          FilledButton(
                            onPressed: () => setState(
                              () => progress.advance(skipped: false),
                            ),
                            child: Text(
                              progress.index == progress.questions.length - 1
                                  ? 'إنهاء الجلسة'
                                  : 'التالي',
                            ),
                          ),
                        ],
                      ),
                    ],
            ),
          ),
        ),
      ),
    ),
  );
}
