import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../sessions/session_setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('وفاق')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/images/wefaq_icon_concept.png',
                      width: 112,
                      height: 112,
                      semanticLabel: 'رمز وفاق',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'حوار يقرّب الفهم',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppTheme.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'مساحة تساعد المخطوبين على فتح مواضيع مهمة والتعرف على طريقة تفكير بعض بهدوء واحترام.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SessionSetupScreen(),
                    ),
                  ),
                  child: const Text('ابدأ جلسة تجريبية'),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'عن النسخة التجريبية',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'جلسات حوار للقاءات أو أثناء مكالمة خارج التطبيق.',
                        ),
                        const SizedBox(height: 8),
                        const Text('اختيار المجال والمستوى وعدد الأسئلة.'),
                        const SizedBox(height: 8),
                        const Text(
                          'الأسئلة تجريبية ولم تُراجع شرعيًا أو أسريًا بعد.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'هذه نسخة أولية قيد التطوير.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
