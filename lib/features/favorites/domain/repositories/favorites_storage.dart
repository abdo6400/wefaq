import '../models/favorite_question_item.dart';

/// Contract for managing bookmarked questions locally.
abstract interface class FavoritesStorage {
  /// Returns all saved favorite items in order of addition.
  Future<List<FavoriteQuestionItem>> getFavorites();

  /// Checks if a question ID is currently favorited.
  Future<bool> isFavorite(String questionId);

  /// Toggles favorite state. Returns true if added, false if removed.
  Future<bool> toggleFavorite(String questionId);

  /// Explicitly removes a question from favorites.
  Future<void> removeFavorite(String questionId);

  /// Clears all favorites.
  Future<void> clearFavorites();
}
