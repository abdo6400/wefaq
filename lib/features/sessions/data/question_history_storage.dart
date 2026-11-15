import 'dart:convert';
import 'dart:io';

import '../domain/repositories/question_history_storage.dart';

/// In-memory implementation of [QuestionHistoryStorage] for testing.
class InMemoryQuestionHistoryStorage implements QuestionHistoryStorage {
  final Set<String> _history = {};

  @override
  Future<Set<String>> getRecentlyAskedIds() async => Set.unmodifiable(_history);

  @override
  Future<void> recordAskedQuestions(List<String> questionIds) async {
    _history.addAll(questionIds);
  }

  @override
  Future<void> clearHistory() async {
    _history.clear();
  }
}

/// File-backed persistent implementation of [QuestionHistoryStorage].
class FileQuestionHistoryStorage implements QuestionHistoryStorage {
  FileQuestionHistoryStorage({required this.storageFile});
  final File storageFile;

  @override
  Future<Set<String>> getRecentlyAskedIds() async {
    if (!await storageFile.exists()) return {};
    final decoded = jsonDecode(await storageFile.readAsString());
    if (decoded is! List || decoded.any((item) => item is! String)) {
      throw const FormatException('Invalid question history');
    }
    return decoded.cast<String>().toSet();
  }

  @override
  Future<void> recordAskedQuestions(List<String> questionIds) async {
    final combined = await getRecentlyAskedIds();
    combined.addAll(questionIds);
    await storageFile.parent.create(recursive: true);
    final tempFile = File('${storageFile.path}.tmp');
    await tempFile.writeAsString(jsonEncode(combined.toList()), flush: true);
    await tempFile.rename(storageFile.path);
  }

  @override
  Future<void> clearHistory() async {
    if (await storageFile.exists()) await storageFile.delete();
    final tempFile = File('${storageFile.path}.tmp');
    if (await tempFile.exists()) await tempFile.delete();
  }
}
