import 'package:equatable/equatable.dart';

/// Poll Option domain entity
///
/// Represents a single option within a poll
class PollOption extends Equatable {
  final String id;
  final String text;
  final int votes;

  const PollOption({
    required this.id,
    required this.text,
    required this.votes,
  });

  /// Creates a new poll option
  factory PollOption.create({
    required String text,
  }) {
    if (text.trim().isEmpty) {
      throw ArgumentError('Poll option text cannot be empty');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = DateTime.now().microsecond;
    final id = '${timestamp}_$randomPart';

    return PollOption(
      id: id,
      text: text.trim(),
      votes: 0,
    );
  }

  /// Returns the percentage of votes this option has out of total votes
  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0.0;
    return votes / totalVotes;
  }

  /// Returns true if this option has the most votes
  bool isWinning(List<PollOption> allOptions) {
    if (allOptions.isEmpty) return false;
    final maxVotes = allOptions.map((o) => o.votes).reduce((a, b) => a > b ? a : b);
    return votes == maxVotes && votes > 0;
  }

  /// Creates a copy with updated vote count
  PollOption incrementVotes([int increment = 1]) {
    return copyWith(votes: votes + increment);
  }

  /// Creates a copy of this option with updated fields
  PollOption copyWith({
    String? id,
    String? text,
    int? votes,
  }) {
    return PollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      votes: votes ?? this.votes,
    );
  }

  @override
  List<Object> get props => [id, text, votes];
}
