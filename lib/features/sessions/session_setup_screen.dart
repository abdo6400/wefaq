import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import 'session_data.dart';
import 'session_screen.dart';

class SessionSetupScreen extends StatefulWidget {
  const SessionSetupScreen({
    super.key,
    this.initialMode = ConversationMode.together,
  });
  final ConversationMode initialMode;
  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  late ConversationMode mode = widget.initialMode;
  Topic topic = Topic.communication;
  Depth depth = Depth.introductory;
  int count = 3;
  @override
  Widget build(BuildContext context) {
    final questions = sampleQuestions[topic]![depth]!;
    return Scaffold(
      appBar: AppBar(title: const Text('إعداد الجلسة')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'خلّوا الحوار على راحتكم',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.dark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'اختاروا التفاصيل المناسبة لكم.',
                  style: TextStyle(color: AppTheme.muted),
                ),
                const SizedBox(height: 20),
                const Text(
                  'أسئلة تجريبية للاختبار فقط، لم تُراجع شرعيًا أو أسريًا بعد.',
                  style: TextStyle(color: AppTheme.muted),
                ),
                const SizedBox(height: 16),
                _Section(
                  icon: Icons.people_outline,
                  title: 'طريقة الحوار',
                  child: _Choices<ConversationMode>(
                    values: ConversationMode.values,
                    selected: mode,
                    label: (value) => value.label,
                    onChanged: (value) => setState(() => mode = value),
                  ),
                ),
                const SizedBox(height: 12),
                _Section(
                  icon: Icons.category_outlined,
                  title: 'الموضوع',
                  child: _Choices<Topic>(
                    values: Topic.values,
                    selected: topic,
                    label: (value) => value.label,
                    onChanged: (value) => setState(() {
                      topic = value;
                      count = 1;
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                _Section(
                  icon: Icons.tune,
                  title: 'عمق الحوار',
                  child: _Choices<Depth>(
                    values: Depth.values,
                    selected: depth,
                    label: (value) => value.label,
                    onChanged: (value) => setState(() {
                      depth = value;
                      count = 1;
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                _Section(
                  icon: Icons.format_list_numbered,
                  title: 'عدد الأسئلة',
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: count > 1
                            ? () => setState(() => count--)
                            : null,
                        tooltip: 'تقليل عدد الأسئلة',
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$count',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: count < questions.length
                            ? () => setState(() => count++)
                            : null,
                        tooltip: 'زيادة عدد الأسئلة',
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          'المتاح ${questions.length}',
                          style: const TextStyle(color: AppTheme.muted),
                        ),
                      ),
                    ],
                  ),
                ),
                if (mode == ConversationMode.phone)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'افتحوا مكالمة خارج التطبيق، ويقرأ أحدكما الأسئلة.',
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    final selected = List<String>.of(questions)..shuffle();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SessionScreen(
                          questions: selected.take(count).toList(),
                          mode: mode,
                        ),
                      ),
                    );
                  },
                  child: const Text('ابدأ الجلسة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE8EDE8)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.dark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final value in values)
        ChoiceChip(
          label: Text(label(value)),
          selected: value == selected,
          onSelected: (_) => onChanged(value),
          showCheckmark: false,
          selectedColor: AppTheme.green,
          backgroundColor: AppTheme.background,
          labelStyle: TextStyle(
            color: value == selected ? Colors.white : AppTheme.dark,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(
            color: value == selected ? AppTheme.green : const Color(0xFFDDE5DF),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
    ],
  );
}
