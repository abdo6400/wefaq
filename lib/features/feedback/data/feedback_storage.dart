import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../domain/models/feedback_report.dart';
import '../domain/repositories/feedback_storage.dart';

/// In-memory implementation of [FeedbackStorage] for hermetic testing.
class InMemoryFeedbackStorage implements FeedbackStorage {
  final List<FeedbackReport> _reports = [];

  @override
  Future<void> saveFeedback(FeedbackReport report) async {
    _reports.removeWhere((r) => r.id == report.id);
    _reports.add(report);
  }

  @override
  Future<List<FeedbackReport>> getFeedbackReports() async {
    return List.unmodifiable(_reports);
  }

  @override
  Future<void> clearAllFeedback() async {
    _reports.clear();
  }
}

/// Production atomic file storage for beta feedback.
class FileFeedbackStorage implements FeedbackStorage {
  FileFeedbackStorage({File? storageFile})
    : _storageFile = storageFile ?? File('wefaq_feedback.json');

  final File _storageFile;
  static const String defaultFileName = 'wefaq_feedback.json';

  @override
  Future<List<FeedbackReport>> getFeedbackReports() async {
    try {
      if (!await _storageFile.exists()) {
        return const [];
      }

      final content = await _storageFile.readAsString();
      if (content.trim().isEmpty) return const [];

      final decoded = jsonDecode(content);
      if (decoded is! List<dynamic>) return const [];

      final results = <FeedbackReport>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          try {
            results.add(FeedbackReport.fromJson(item));
          } catch (_) {
            // Skip invalid individual entry
          }
        }
      }
      return results;
    } catch (_) {
      debugPrint(
        'FileFeedbackStorage: could not read feedback. Quarantining file.',
      );
      await _quarantine();
      return const [];
    }
  }

  @override
  Future<void> saveFeedback(FeedbackReport report) async {
    final current = await getFeedbackReports();
    final updated = List<FeedbackReport>.of(current)
      ..removeWhere((r) => r.id == report.id)
      ..add(report);

    final tempFile = File('${_storageFile.path}.tmp');

    final jsonString = jsonEncode(updated.map((r) => r.toJson()).toList());
    await tempFile.writeAsString(jsonString, flush: true);

    await tempFile.rename(_storageFile.path);
  }

  @override
  Future<void> clearAllFeedback() async {
    if (await _storageFile.exists()) {
      await _storageFile.delete();
    }
  }

  Future<void> _quarantine() async {
    try {
      if (await _storageFile.exists()) {
        final quarantinePath =
            '${_storageFile.path}.corrupt.${DateTime.now().millisecondsSinceEpoch}';
        await _storageFile.rename(quarantinePath);
      }
    } catch (_) {}
  }
}
