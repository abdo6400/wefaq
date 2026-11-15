import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final filePath = args.isNotEmpty
      ? args[0]
      : 'assets/content/questions_v1.json';
  final file = File(filePath);

  if (!file.existsSync()) {
    stderr.writeln('ERROR: Content file not found: $filePath');
    exit(1);
  }

  stdout.writeln('==============================================');
  stdout.writeln('  Wefaq Content Catalog Audit & Validation    ');
  stdout.writeln('==============================================');
  stdout.writeln('File: $filePath\n');

  final content = file.readAsStringSync();
  final Map<String, dynamic> data;
  try {
    data = jsonDecode(content) as Map<String, dynamic>;
  } catch (e) {
    stderr.writeln('FATAL: Malformed JSON syntax: $e');
    exit(1);
  }

  final version = data['version'];
  final questions = data['questions'] as List<dynamic>?;

  if (version == null || questions == null) {
    stderr.writeln('FATAL: Missing "version" or "questions" root key');
    exit(1);
  }

  stdout.writeln('Catalog Schema Version: $version');
  stdout.writeln('Total Questions Found:  ${questions.length}\n');

  final seenIds = <String>{};
  final seenTexts = <String, String>{};
  final topicCounts = <String, int>{};
  final depthCounts = <String, int>{};
  final modeCounts = <String, int>{};
  final errors = <String>[];
  final warnings = <String>[];

  final validTopics = {
    'communication',
    'dailyLife',
    'familyRelations',
    'finances',
    'coreValues',
  };

  final validDepths = {'introductory', 'deeper'};
  final validModes = {'together', 'phone'};

  for (int i = 0; i < questions.length; i++) {
    final item = questions[i];
    final indexStr = 'Question #$i';

    if (item is! Map<String, dynamic>) {
      errors.add('$indexStr: Entry is not a JSON object');
      continue;
    }

    final id = item['id'] as String? ?? '';
    final text = item['text'] as String? ?? '';
    final clarification = item['clarification'] as String? ?? '';
    final topic = item['topic'] as String? ?? '';
    final depth = item['depth'] as String? ?? '';
    final rawModes = item['suitableModes'] as List<dynamic>? ?? [];

    if (id.trim().isEmpty) {
      errors.add('$indexStr: Missing or empty "id"');
    } else if (seenIds.contains(id)) {
      errors.add('$indexStr: Duplicate question ID "$id"');
    } else {
      seenIds.add(id);
    }

    if (text.trim().isEmpty) {
      errors.add('$indexStr (ID: $id): Missing or empty "text"');
    } else {
      final normalized = text.replaceAll(
        RegExp(r'[\s\p{P}]+', unicode: true),
        '',
      );
      if (seenTexts.containsKey(normalized)) {
        warnings.add(
          'Potential duplicate text between "$id" and "${seenTexts[normalized]}": "$text"',
        );
      } else {
        seenTexts[normalized] = id;
      }
    }

    if (clarification.trim().isEmpty) {
      warnings.add('$indexStr (ID: $id): Missing clarification guide');
    }

    if (!validTopics.contains(topic)) {
      errors.add('$indexStr (ID: $id): Invalid topic "$topic"');
    } else {
      topicCounts[topic] = (topicCounts[topic] ?? 0) + 1;
    }

    if (!validDepths.contains(depth)) {
      errors.add('$indexStr (ID: $id): Invalid depth "$depth"');
    } else {
      depthCounts[depth] = (depthCounts[depth] ?? 0) + 1;
    }

    if (rawModes.isEmpty) {
      errors.add('$indexStr (ID: $id): suitableModes cannot be empty');
    } else {
      for (final m in rawModes) {
        final modeStr = m.toString();
        if (!validModes.contains(modeStr)) {
          errors.add('$indexStr (ID: $id): Invalid mode "$modeStr"');
        } else {
          modeCounts[modeStr] = (modeCounts[modeStr] ?? 0) + 1;
        }
      }
    }
  }

  // Distribution report
  stdout.writeln('----------------------------------------------');
  stdout.writeln('  Domain Topic Distribution                   ');
  stdout.writeln('----------------------------------------------');
  for (final t in validTopics) {
    final count = topicCounts[t] ?? 0;
    final pct = (count / questions.length * 100).toStringAsFixed(1);
    stdout.writeln(
      '  • ${t.padRight(18)} : ${count.toString().padLeft(3)} ($pct%)',
    );
  }

  stdout.writeln('\n----------------------------------------------');
  stdout.writeln('  Depth Distribution                          ');
  stdout.writeln('----------------------------------------------');
  for (final d in validDepths) {
    final count = depthCounts[d] ?? 0;
    final pct = (count / questions.length * 100).toStringAsFixed(1);
    stdout.writeln(
      '  • ${d.padRight(18)} : ${count.toString().padLeft(3)} ($pct%)',
    );
  }

  stdout.writeln('\n----------------------------------------------');
  stdout.writeln('  Mode Suitability Distribution               ');
  stdout.writeln('----------------------------------------------');
  for (final m in validModes) {
    final count = modeCounts[m] ?? 0;
    stdout.writeln(
      '  • ${m.padRight(18)} : ${count.toString().padLeft(3)} occurrences',
    );
  }

  if (warnings.isNotEmpty) {
    stdout.writeln('\n⚠️  Warnings (${warnings.length}):');
    for (final w in warnings) {
      stdout.writeln('  - $w');
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('\n❌ Errors found (${errors.length}):');
    for (final err in errors) {
      stderr.writeln('  - $err');
    }
    exit(1);
  }

  stdout.writeln('\n✅ Content catalog validation passed with 0 errors.');
  exit(0);
}
