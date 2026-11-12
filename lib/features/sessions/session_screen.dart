import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6EFE9),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              widget.mode.label,
                              style: const TextStyle(
                                color: AppTheme.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'السؤال ${progress.index + 1} من ${progress.questions.length}',
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: (progress.index + 1) / progress.questions.length,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(8),
                        backgroundColor: const Color(0xFFE2E9E2),
                        color: AppTheme.green,
                      ),
                      const SizedBox(height: 28),
                      Container(
                        constraints: const BoxConstraints(minHeight: 300),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE8EDE8)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D153E33),
                              blurRadius: 22,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5ECDD),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: AppTheme.gold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'مساحة للحوار',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: AppTheme.muted),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              progress.questions[progress.index],
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: AppTheme.dark,
                                    fontWeight: FontWeight.bold,
                                    height: 1.6,
                                  ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: 36,
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppTheme.gold,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4EF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.spa_outlined,
                              size: 20,
                              color: AppTheme.green,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'خدوا وقتكم. من حق أي طرف تخطي السؤال، والتطبيق لا يسجل إجاباتكما.',
                                style: TextStyle(color: AppTheme.dark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              setState(() => progress.advance(skipped: false)),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: Text(
                            progress.index == progress.questions.length - 1
                                ? 'إنهاء الجلسة'
                                : 'التالي',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: progress.index == 0
                                  ? null
                                  : () => setState(progress.previous),
                              child: const Text('السابق'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(
                                () => progress.advance(skipped: true),
                              ),
                              child: const Text('تخطي'),
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
