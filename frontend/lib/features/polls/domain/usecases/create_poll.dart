import 'package:dartz/dartz.dart';
import 'package:pollino/core/error/failures.dart';
import 'package:pollino/core/usecase/usecase.dart';
import 'package:pollino/features/polls/domain/entities/poll.dart';
import 'package:pollino/features/polls/domain/repositories/poll_repository.dart';

/// Use case for creating a new poll
class CreatePoll implements UseCase<Poll, CreatePollParams> {
  final PollRepository repository;

  CreatePoll(this.repository);

  @override
  Future<Either<Failure, Poll>> call(CreatePollParams params) async {
    // Business rule validation
    if (params.title.trim().isEmpty) {
      return const Left(ValidationFailure(message: 'Poll title cannot be empty'));
    }

    if (params.optionTexts.length < 2) {
      return const Left(ValidationFailure(message: 'Poll must have at least 2 options'));
    }

    if (params.optionTexts.any((text) => text.trim().isEmpty)) {
      return const Left(ValidationFailure(message: 'All poll options must have text'));
    }

    if (params.expiresAt != null && params.expiresAt!.isBefore(DateTime.now())) {
      return const Left(ValidationFailure(message: 'Expiration date cannot be in the past'));
    }

    // Delegate to repository
    return await repository.createPoll(
      title: params.title.trim(),
      optionTexts: params.optionTexts.map((text) => text.trim()).toList(),
      description: params.description?.trim(),
      isAnonymous: params.isAnonymous,
      allowsMultipleVotes: params.allowsMultipleVotes,
      creatorName: params.creatorName?.trim(),
      expiresAt: params.expiresAt,
      autoDeleteAfterExpiry: params.autoDeleteAfterExpiry,
    );
  }
}

/// Parameters for CreatePoll use case
class CreatePollParams {
  final String title;
  final List<String> optionTexts;
  final String? description;
  final bool isAnonymous;
  final bool allowsMultipleVotes;
  final String? creatorName;
  final DateTime? expiresAt;
  final bool autoDeleteAfterExpiry;

  const CreatePollParams({
    required this.title,
    required this.optionTexts,
    this.description,
    this.isAnonymous = true,
    this.allowsMultipleVotes = false,
    this.creatorName,
    this.expiresAt,
    this.autoDeleteAfterExpiry = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreatePollParams &&
        other.title == title &&
        other.optionTexts == optionTexts &&
        other.description == description &&
        other.isAnonymous == isAnonymous &&
        other.allowsMultipleVotes == allowsMultipleVotes &&
        other.creatorName == creatorName &&
        other.expiresAt == expiresAt &&
        other.autoDeleteAfterExpiry == autoDeleteAfterExpiry;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        optionTexts.hashCode ^
        description.hashCode ^
        isAnonymous.hashCode ^
        allowsMultipleVotes.hashCode ^
        creatorName.hashCode ^
        expiresAt.hashCode ^
        autoDeleteAfterExpiry.hashCode;
  }
}
