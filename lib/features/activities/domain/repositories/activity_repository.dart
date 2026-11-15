import '../../../sessions/session_data.dart';
import '../models/activity.dart';

/// Interface for querying structured discussion activities.
abstract class ActivityRepository {
  /// Fetches activities matching the optional [topic] and [type] filters.
  Future<List<Activity>> getActivities({
    Topic? topic,
    ActivityType? type,
    int? limit,
  });

  /// Retrieves an activity by its unique [id], or null if not found.
  Future<Activity?> getActivityById(String id);
}
