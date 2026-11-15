import 'dart:convert';
import 'dart:io';

import '../domain/models/favorite_question_item.dart';
import '../domain/repositories/favorites_storage.dart';

/// In-memory implementation of [FavoritesStorage] for unit/widget testing.
class InMemoryFavoritesStorage implements FavoritesStorage {
  final Map<String, FavoriteQuestionItem> _items = {};

  @override
  Future<List<FavoriteQuestionItem>> getFavorites() async =>
      _items.values.toList();

  @override
  Future<bool> isFavorite(String questionId) async =>
      _items.containsKey(questionId);

  @override
  Future<bool> toggleFavorite(String questionId) async {
    if (_items.containsKey(questionId)) {
      _items.remove(questionId);
      return false;
    } else {
      _items[questionId] = FavoriteQuestionItem(
        questionId: questionId,
        savedAt: DateTime.now().toUtc(),
      );
      return true;
    }
  }

  @override
  Future<void> removeFavorite(String questionId) async {
    _items.remove(questionId);
  }

  @override
  Future<void> clearFavorites() async {
    _items.clear();
  }
}

/// File-backed persistent implementation of [FavoritesStorage] with atomic writes.
class FileFavoritesStorage implements FavoritesStorage {
  FileFavoritesStorage({required this.storageFile});

  final File storageFile;

  @override
  Future<List<FavoriteQuestionItem>> getFavorites() async {
    if (!await storageFile.exists()) return [];
    final decoded = jsonDecode(await storageFile.readAsString());
    if (decoded is! List) throw const FormatException('Invalid favorites');
    return decoded.map((entry) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Invalid favorite');
      }
      return FavoriteQuestionItem.fromJson(entry);
    }).toList();
  }

  @override
  Future<bool> isFavorite(String questionId) async {
    final list = await getFavorites();
    return list.any((item) => item.questionId == questionId);
  }

  @override
  Future<bool> toggleFavorite(String questionId) async {
    final list = await getFavorites();
    final index = list.indexWhere((item) => item.questionId == questionId);
    bool added = false;

    if (index >= 0) {
      list.removeAt(index);
    } else {
      list.add(
        FavoriteQuestionItem(
          questionId: questionId,
          savedAt: DateTime.now().toUtc(),
        ),
      );
      added = true;
    }

    await _persistList(list);
    return added;
  }

  @override
  Future<void> removeFavorite(String questionId) async {
    final list = await getFavorites();
    list.removeWhere((item) => item.questionId == questionId);
    await _persistList(list);
  }

  @override
  Future<void> clearFavorites() async {
    await _safeDeleteFile();
  }

  Future<void> _persistList(List<FavoriteQuestionItem> list) async {
    await storageFile.parent.create(recursive: true);
    final tempFile = File('${storageFile.path}.tmp');
    await tempFile.writeAsString(
      jsonEncode(list.map((i) => i.toJson()).toList()),
      flush: true,
    );
    await tempFile.rename(storageFile.path);
  }

  Future<void> _safeDeleteFile() async {
    if (await storageFile.exists()) await storageFile.delete();
    final tempFile = File('${storageFile.path}.tmp');
    if (await tempFile.exists()) await tempFile.delete();
  }
}
