import 'package:equatable/equatable.dart';

/// Value Object representing a unique Poll identifier
///
/// Encapsulates the logic and validation for poll IDs
class PollId extends Equatable {
  final String value;

  const PollId._(this.value);

  /// Creates a PollId from a string value
  ///
  /// Throws [ArgumentError] if the value is invalid
  factory PollId.fromString(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('Poll ID cannot be empty');
    }
    return PollId._(value.trim());
  }

  /// Creates a PollId for a new poll (generates unique ID)
  factory PollId.generate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = DateTime.now().microsecond;
    return PollId._('${timestamp}_$randomPart');
  }

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;
}
