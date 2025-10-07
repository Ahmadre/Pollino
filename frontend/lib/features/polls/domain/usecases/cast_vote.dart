import 'package:dartz/dartz.dart';
import 'package:pollino/core/error/failures.dart';
import 'package:pollino/core/usecase/usecase.dart';
import 'package:pollino/features/polls/domain/repositories/poll_repository.dart';
import 'package:pollino/features/polls/domain/value_objects/poll_id.dart';

/// Use case for casting a vote on a poll
class CastVote implements UseCase<Unit, CastVoteParams> {
  final PollRepository repository;

  CastVote(this.repository);

  @override
  Future<Either<Failure, Unit>> call(CastVoteParams params) async {
    // Business rule validation
    if (params.optionId.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Option ID cannot be empty'));
    }

    if (!params.isAnonymous && (params.voterName == null || params.voterName!.trim().isEmpty)) {
      return const Left(ValidationFailure(message: 'Voter name is required for non-anonymous votes'));
    }

    // Check if poll is expired
    final pollStatusResult = await repository.getPollStatus(params.pollId);
    return pollStatusResult.fold(
      (failure) => Left(failure),
      (status) async {
        if (status['is_expired'] == true) {
          return const Left(ValidationFailure(message: 'Cannot vote on an expired poll'));
        }

        // Delegate to repository
        return await repository.castVote(
          pollId: params.pollId,
          optionId: params.optionId.trim(),
          voterName: params.voterName?.trim(),
          isAnonymous: params.isAnonymous,
        );
      },
    );
  }
}

/// Parameters for CastVote use case
class CastVoteParams {
  final PollId pollId;
  final String optionId;
  final String? voterName;
  final bool isAnonymous;

  const CastVoteParams({
    required this.pollId,
    required this.optionId,
    this.voterName,
    this.isAnonymous = true,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CastVoteParams &&
        other.pollId == pollId &&
        other.optionId == optionId &&
        other.voterName == voterName &&
        other.isAnonymous == isAnonymous;
  }

  @override
  int get hashCode {
    return pollId.hashCode ^ optionId.hashCode ^ voterName.hashCode ^ isAnonymous.hashCode;
  }
}
