import 'package:dartz/dartz.dart';
import 'package:pollino/core/error/failures.dart';
import 'package:pollino/core/network/network_info.dart';
import 'package:pollino/features/polls/domain/entities/poll.dart';
import 'package:pollino/features/polls/domain/repositories/poll_repository.dart';
import 'package:pollino/features/polls/domain/value_objects/poll_id.dart';
import 'package:pollino/features/polls/data/datasources/poll_local_data_source.dart';
import 'package:pollino/features/polls/data/datasources/poll_remote_data_source.dart';
import 'package:pollino/features/polls/data/models/poll_model.dart';

/// Implementation of the PollRepository
class PollRepositoryImpl implements PollRepository {
  final PollRemoteDataSource remoteDataSource;
  final PollLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  PollRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Poll>>> getPolls({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remotePolls = await remoteDataSource.getPolls(page: page, limit: limit);
        final polls = remotePolls.map((poll) => poll.toDomain()).toList();

        // Cache the results
        if (page == 1) {
          await localDataSource.cachePolls(remotePolls);
        }

        return Right(polls);
      } catch (e) {
        // Fall back to cache on remote failure
        return await _getCachedPolls();
      }
    } else {
      // No network, use cache
      return await _getCachedPolls();
    }
  }

  @override
  Future<Either<Failure, Poll>> getPoll(PollId pollId) async {
    if (await networkInfo.isConnected) {
      try {
        final remotePoll = await remoteDataSource.getPoll(pollId.value);
        final poll = remotePoll.toDomain();

        // Cache the result
        await localDataSource.cachePoll(remotePoll);

        return Right(poll);
      } catch (e) {
        // Fall back to cache on remote failure
        return await _getCachedPoll(pollId);
      }
    } else {
      // No network, use cache
      return await _getCachedPoll(pollId);
    }
  }

  @override
  Future<Either<Failure, Poll>> createPoll({
    required String title,
    required List<String> optionTexts,
    String? description,
    bool isAnonymous = true,
    bool allowsMultipleVotes = false,
    String? creatorName,
    DateTime? expiresAt,
    bool autoDeleteAfterExpiry = false,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remotePoll = await remoteDataSource.createPoll(
          title: title,
          optionTexts: optionTexts,
          description: description,
          isAnonymous: isAnonymous,
          allowsMultipleVotes: allowsMultipleVotes,
          creatorName: creatorName,
          expiresAt: expiresAt,
          autoDeleteAfterExpiry: autoDeleteAfterExpiry,
        );

        final poll = remotePoll.toDomain();

        // Cache the new poll
        await localDataSource.cachePoll(remotePoll);

        return Right(poll);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Poll>> updatePoll(Poll poll) async {
    if (await networkInfo.isConnected) {
      try {
        // Convert domain to data model
        final pollModel = PollModelFactory.fromDomain(poll);
        final updatedPollModel = await remoteDataSource.updatePoll(pollModel);
        final updatedPoll = updatedPollModel.toDomain();

        // Update cache
        await localDataSource.cachePoll(updatedPollModel);

        return Right(updatedPoll);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePoll(PollId pollId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deletePoll(pollId.value);

        // Remove from cache
        await localDataSource.removeCachedPoll(pollId.value);

        return const Right(unit);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Unit>> castVote({
    required PollId pollId,
    required String optionId,
    String? voterName,
    bool isAnonymous = true,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.castVote(
          pollId: pollId.value,
          optionId: optionId,
          voterName: voterName,
          isAnonymous: isAnonymous,
        );

        return const Right(unit);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Unit>> castMultipleVotes({
    required PollId pollId,
    required List<String> optionIds,
    String? voterName,
    bool isAnonymous = true,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.castMultipleVotes(
          pollId: pollId.value,
          optionIds: optionIds,
          voterName: voterName,
          isAnonymous: isAnonymous,
        );

        return const Right(unit);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Unit>> synchronizeData() async {
    if (await networkInfo.isConnected) {
      try {
        // Get fresh data from remote
        final remotePolls = await remoteDataSource.getPolls();

        // Update cache
        await localDataSource.cachePolls(remotePolls);

        return const Right(unit);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, int>> cleanupExpiredPolls() async {
    if (await networkInfo.isConnected) {
      try {
        final deletedCount = await remoteDataSource.cleanupExpiredPolls();
        return Right(deletedCount);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> isPollExpired(PollId pollId) async {
    try {
      final status = await remoteDataSource.getPollStatus(pollId.value);
      return Right(status['is_expired'] ?? false);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPollStatus(PollId pollId) async {
    try {
      final status = await remoteDataSource.getPollStatus(pollId.value);
      return Right(status);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // Helper methods
  Future<Either<Failure, List<Poll>>> _getCachedPolls() async {
    try {
      final cachedPolls = await localDataSource.getCachedPolls();
      final polls = cachedPolls.map((poll) => poll.toDomain()).toList();
      return Right(polls);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, Poll>> _getCachedPoll(PollId pollId) async {
    try {
      final cachedPoll = await localDataSource.getCachedPoll(pollId.value);
      if (cachedPoll != null) {
        return Right(cachedPoll.toDomain());
      } else {
        return const Left(CacheFailure(message: 'Poll not found in cache'));
      }
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
