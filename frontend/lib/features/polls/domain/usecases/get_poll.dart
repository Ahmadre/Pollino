import 'package:dartz/dartz.dart';
import 'package:pollino/core/error/failures.dart';
import 'package:pollino/core/usecase/usecase.dart';
import 'package:pollino/features/polls/domain/entities/poll.dart';
import 'package:pollino/features/polls/domain/repositories/poll_repository.dart';
import 'package:pollino/features/polls/domain/value_objects/poll_id.dart';

/// Use case for fetching a single poll
class GetPoll implements UseCase<Poll, GetPollParams> {
  final PollRepository repository;

  GetPoll(this.repository);

  @override
  Future<Either<Failure, Poll>> call(GetPollParams params) async {
    return await repository.getPoll(params.pollId);
  }
}

/// Parameters for GetPoll use case
class GetPollParams {
  final PollId pollId;

  const GetPollParams({required this.pollId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetPollParams && other.pollId == pollId;
  }

  @override
  int get hashCode => pollId.hashCode;
}