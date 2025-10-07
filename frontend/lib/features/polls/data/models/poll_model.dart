import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pollino/features/polls/domain/entities/poll.dart';

import 'package:pollino/features/polls/domain/value_objects/poll_expiration.dart';
import 'package:pollino/features/polls/domain/value_objects/poll_id.dart';
import 'package:pollino/features/polls/data/models/poll_option_model.dart';

part 'poll_model.freezed.dart';
part 'poll_model.g.dart';

/// Data model for Poll
///
/// This handles the data representation and serialization/deserialization
/// Extends the domain entity with JSON and database operations
@freezed
class PollModel with _$PollModel {
  const factory PollModel({
    required String id,
    required String title,
    String? description,
    required List<PollOptionModel> options,
    @Default(true) bool isAnonymous,
    @Default(false) bool allowsMultipleVotes,
    String? createdByName,
    String? createdBy,
    required DateTime createdAt,
    DateTime? expiresAt,
    @Default(false) bool autoDeleteAfterExpiry,
  }) = _PollModel;

  factory PollModel.fromJson(Map<String, dynamic> json) => _$PollModelFromJson(json);
}

/// Extension to convert between domain entity and data model
extension PollModelX on PollModel {
  /// Converts data model to domain entity
  Poll toDomain() {
    PollExpiration? expiration;
    if (expiresAt != null) {
      expiration = PollExpiration.fromDateTime(
        expiresAt: expiresAt!,
        autoDelete: autoDeleteAfterExpiry,
      );
    }

    return Poll(
      id: PollId.fromString(id),
      title: title,
      description: description,
      options: options.map((option) => option.toDomain()).toList(),
      isAnonymous: isAnonymous,
      allowsMultipleVotes: allowsMultipleVotes,
      createdByName: createdByName,
      createdBy: createdBy,
      createdAt: createdAt,
      expiration: expiration,
    );
  }
}

/// Extension helper for creating PollModel from domain entity
extension PollModelFactory on PollModel {
  /// Creates data model from domain entity
  static PollModel fromDomain(Poll poll) {
    return PollModel(
      id: poll.id.value,
      title: poll.title,
      description: poll.description,
      options: poll.options.map((option) => PollOptionModelFactory.fromDomain(option)).toList(),
      isAnonymous: poll.isAnonymous,
      allowsMultipleVotes: poll.allowsMultipleVotes,
      createdByName: poll.createdByName,
      createdBy: poll.createdBy,
      createdAt: poll.createdAt,
      expiresAt: poll.expiration?.expiresAt,
      autoDeleteAfterExpiry: poll.expiration?.autoDelete ?? false,
    );
  }
}
