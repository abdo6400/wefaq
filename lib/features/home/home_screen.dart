import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../sessions/session_data.dart';
import '../sessions/session_setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void open([ConversationMode mode = ConversationMode.together]) =>
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SessionSetupScreen(initialMode: mode),
          ),
        );
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/wefaq_icon_concept.png',
                        width: 42,
                        height: 42,
                        semanticLabel: 'رمز وفاق',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'وفاق',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppTheme.dark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'نسخة تجريبية',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  'أهلًا بكم في وفاق',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppTheme.dark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'حوار يقرّب الفهم',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'مساحة تساعدكم تفتحوا مواضيع مهمة، وتفهموا بعض بهدوء واحترام.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.muted,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: open,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('ابدأ جلسة تجريبية'),
                ),
                const SizedBox(height: 36),
                Text(
                  'اختاروا طريقة الحوار',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.dark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ابدأوا بالطريقة المناسبة لكم',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.muted,
                  ),
                ),
                const SizedBox(height: 16),
                _ModeCard(
                  icon: Icons.people_outline,
                  title: 'مع بعض',
                  subtitle: 'حوار مباشر من جهاز واحد',
                  onTap: () => open(ConversationMode.together),
                ),
                const SizedBox(height: 12),
                _ModeCard(
                  icon: Icons.phone_outlined,
                  title: 'في مكالمة',
                  subtitle: 'اقرأوا الأسئلة خلال مكالمة خارج التطبيق',
                  onTap: () => open(ConversationMode.phone),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EBDD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.dark, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'الأسئلة تجريبية ولم تُراجع شرعيًا أو أسريًا بعد. هذه نسخة أولية قيد التطوير.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F0EA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.green),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, color: AppTheme.muted),
          ],
        ),
      ),
    ),
  );
}
