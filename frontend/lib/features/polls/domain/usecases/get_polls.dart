import 'package:dartz/dartz.dart';
import 'package:pollino/core/error/failures.dart';
import 'package:pollino/core/usecase/usecase.dart';
import 'package:pollino/features/polls/domain/entities/poll.dart';
import 'package:pollino/features/polls/domain/repositories/poll_repository.dart';

/// Use case for fetching paginated polls
class GetPolls implements UseCase<List<Poll>, PaginationParams> {
  final PollRepository repository;

  GetPolls(this.repository);

  @override
  Future<Either<Failure, List<Poll>>> call(PaginationParams params) async {
    return await repository.getPolls(
      page: params.page,
      limit: params.limit,
      filters: params.filters,
    );
  }
}
