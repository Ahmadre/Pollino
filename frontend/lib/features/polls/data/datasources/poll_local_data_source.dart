import 'package:hive_flutter/hive_flutter.dart';
import 'package:pollino/features/polls/data/models/poll_model.dart';
import 'package:pollino/core/error/failures.dart';

/// Contract for local data operations
abstract class PollLocalDataSource {
  /// Get cached polls
  Future<List<PollModel>> getCachedPolls();

  /// Get a specific cached poll
  Future<PollModel?> getCachedPoll(String pollId);

  /// Cache a list of polls
  Future<void> cachePolls(List<PollModel> polls);

  /// Cache a single poll
  Future<void> cachePoll(PollModel poll);

  /// Remove a poll from cache
  Future<void> removeCachedPoll(String pollId);

  /// Clear all cached polls
  Future<void> clearCache();

  /// Get the last cache update time
  DateTime? get lastCacheUpdate;
}

/// Implementation of local data source using Hive
class PollLocalDataSourceImpl implements PollLocalDataSource {
  final Box box; // Generic box for now, will be typed later
  static const String _lastUpdateKey = 'last_cache_update';

  PollLocalDataSourceImpl({required this.box});

  @override
  Future<List<PollModel>> getCachedPolls() async {
    try {
      return box.values.whereType<PollModel>().toList();
    } catch (e) {
      throw CacheFailure(message: 'Failed to get cached polls: $e');
    }
  }

  @override
  Future<PollModel?> getCachedPoll(String pollId) async {
    try {
      final pollData = box.get(pollId);
      if (pollData == null) return null;
      return PollModel.fromJson(Map<String, dynamic>.from(pollData));
    } catch (e) {
      throw CacheFailure(message: 'Failed to get cached poll: $e');
    }
  }

  @override
  Future<void> cachePolls(List<PollModel> polls) async {
    try {
      await clearCache(); // Clear existing cache first
      for (final poll in polls) {
        await box.put(poll.id, poll.toJson());
      }
      await box.put(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      throw CacheFailure(message: 'Failed to cache polls: $e');
    }
  }

  @override
  Future<void> cachePoll(PollModel poll) async {
    try {
      await box.put(poll.id, poll.toJson());
    } catch (e) {
      throw CacheFailure(message: 'Failed to cache poll: $e');
    }
  }

  @override
  Future<void> removeCachedPoll(String pollId) async {
    try {
      await box.delete(pollId);
    } catch (e) {
      throw CacheFailure(message: 'Failed to remove cached poll: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      // Keep the last update timestamp
      final lastUpdate = box.get(_lastUpdateKey);
      await box.clear();
      if (lastUpdate != null) {
        await box.put(_lastUpdateKey, lastUpdate);
      }
    } catch (e) {
      throw CacheFailure(message: 'Failed to clear cache: $e');
    }
  }

  @override
  DateTime? get lastCacheUpdate {
    try {
      final updateString = box.get(_lastUpdateKey) as String?;
      return updateString != null ? DateTime.parse(updateString) : null;
    } catch (e) {
      return null;
    }
  }
}
