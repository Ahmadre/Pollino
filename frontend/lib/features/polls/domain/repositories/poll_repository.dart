import 'package:dartz/dartz.dart';
import 'package:pollino/core/error/failures.dart';
import 'package:pollino/features/polls/domain/entities/poll.dart';
import 'package:pollino/features/polls/domain/value_objects/poll_id.dart';

/// Contract for Poll data operations
///
/// This interface defines what data operations our domain needs
/// Independent of any specific data source or framework
abstract class PollRepository {
  /// Fetches paginated list of polls
  Future<Either<Failure, List<Poll>>> getPolls({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  });

  /// Fetches a single poll by ID
  Future<Either<Failure, Poll>> getPoll(PollId pollId);

  /// Creates a new poll
  Future<Either<Failure, Poll>> createPoll({
    required String title,
    required List<String> optionTexts,
    String? description,
    bool isAnonymous = true,
    bool allowsMultipleVotes = false,
    String? creatorName,
    DateTime? expiresAt,
    bool autoDeleteAfterExpiry = false,
  });

  /// Updates an existing poll
  Future<Either<Failure, Poll>> updatePoll(Poll poll);

  /// Deletes a poll
  Future<Either<Failure, Unit>> deletePoll(PollId pollId);

  /// Casts a single vote for a poll option
  Future<Either<Failure, Unit>> castVote({
    required PollId pollId,
    required String optionId,
    String? voterName,
    bool isAnonymous = true,
  });

  /// Casts multiple votes for poll options (for multiple choice polls)
  Future<Either<Failure, Unit>> castMultipleVotes({
    required PollId pollId,
    required List<String> optionIds,
    String? voterName,
    bool isAnonymous = true,
  });

  /// Synchronizes local cache with remote data
  Future<Either<Failure, Unit>> synchronizeData();

  /// Cleans up expired polls that are marked for auto-deletion
  Future<Either<Failure, int>> cleanupExpiredPolls();

  /// Checks if a poll has expired
  Future<Either<Failure, bool>> isPollExpired(PollId pollId);

  /// Gets poll status including expiration information
  Future<Either<Failure, Map<String, dynamic>>> getPollStatus(PollId pollId);
}
