import 'package:dartz/dartz.dart';
import 'package:pollino/core/error/failures.dart';

/// Base class for all Use Cases
///
/// Every use case should inherit from this and implement the call method
/// Type [T] is the type of the return value
/// Type [Params] is the type of the parameter
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case that doesn't need parameters
class NoParams {
  const NoParams();
}

/// Use case for paginated results
class PaginationParams {
  final int page;
  final int limit;
  final Map<String, dynamic>? filters;

  const PaginationParams({
    required this.page,
    required this.limit,
    this.filters,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaginationParams && other.page == page && other.limit == limit && other.filters == filters;
  }

  @override
  int get hashCode => page.hashCode ^ limit.hashCode ^ filters.hashCode;
}
