import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pollino/features/polls/domain/entities/poll_option.dart';

part 'poll_option_model.freezed.dart';
part 'poll_option_model.g.dart';

/// Data model for PollOption
@freezed
class PollOptionModel with _$PollOptionModel {
  const factory PollOptionModel({
    required String id,
    required String text,
    @Default(0) int votes,
  }) = _PollOptionModel;

  factory PollOptionModel.fromJson(Map<String, dynamic> json) => _$PollOptionModelFromJson(json);
}

/// Extension to convert between domain entity and data model
extension PollOptionModelX on PollOptionModel {
  /// Converts data model to domain entity
  PollOption toDomain() {
    return PollOption(
      id: id,
      text: text,
      votes: votes,
    );
  }
}

/// Extension helper for creating PollOptionModel from domain entity
extension PollOptionModelFactory on PollOptionModel {
  /// Creates data model from domain entity
  static PollOptionModel fromDomain(PollOption option) {
    return PollOptionModel(
      id: option.id,
      text: option.text,
      votes: option.votes,
    );
  }
}
