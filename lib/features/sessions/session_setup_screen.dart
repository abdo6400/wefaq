import 'package:flutter/material.dart';

import 'session_data.dart';
import 'session_screen.dart';

class SessionSetupScreen extends StatefulWidget {
  const SessionSetupScreen({super.key});
  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  ConversationMode mode = ConversationMode.together;
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
                const Text(
                  'أسئلة تجريبية للاختبار فقط، لم تُراجع شرعيًا أو أسريًا بعد.',
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<ConversationMode>(
                  initialValue: mode,
                  decoration: const InputDecoration(
                    labelText: 'طريقة الحوار',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final item in ConversationMode.values)
                      DropdownMenuItem(value: item, child: Text(item.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => mode = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Topic>(
                  initialValue: topic,
                  decoration: const InputDecoration(
                    labelText: 'المجال',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final item in Topic.values)
                      DropdownMenuItem(value: item, child: Text(item.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        topic = value;
                        count = 1;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Depth>(
                  initialValue: depth,
                  decoration: const InputDecoration(
                    labelText: 'المستوى',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final item in Depth.values)
                      DropdownMenuItem(value: item, child: Text(item.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        depth = value;
                        count = 1;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  key: ValueKey('count-${topic.name}-${depth.name}'),
                  initialValue: count,
                  decoration: const InputDecoration(
                    labelText: 'عدد الأسئلة',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (var i = 1; i <= questions.length; i++)
                      DropdownMenuItem(value: i, child: Text('$i')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => count = value);
                  },
                ),
                const SizedBox(height: 12),
                Text('المتاح للاختيار: ${questions.length} أسئلة تجريبية.'),
                if (mode == ConversationMode.phone)
                  const Text(
                    'افتحوا مكالمة خارج التطبيق، ويقرأ أحدكما الأسئلة.',
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
