import 'package:equatable/equatable.dart';
import 'package:pollino/features/polls/domain/entities/poll_option.dart';
import 'package:pollino/features/polls/domain/value_objects/poll_expiration.dart';
import 'package:pollino/features/polls/domain/value_objects/poll_id.dart';

/// Poll domain entity - core business object
///
/// This represents the essential structure of a Poll in our domain
/// Independent of any external frameworks or data sources
class Poll extends Equatable {
  final PollId id;
  final String title;
  final String? description;
  final List<PollOption> options;
  final bool isAnonymous;
  final bool allowsMultipleVotes;
  final String? createdByName;
  final String? createdBy;
  final DateTime createdAt;
  final PollExpiration? expiration;

  const Poll({
    required this.id,
    required this.title,
    required this.options,
    this.description,
    this.isAnonymous = true,
    this.allowsMultipleVotes = false,
    this.createdByName,
    this.createdBy,
    required this.createdAt,
    this.expiration,
  });

  /// Returns true if the poll is expired
  bool get isExpired {
    if (expiration == null) return false;
    return expiration!.isExpired;
  }

  /// Returns true if the poll allows voting
  bool get canVote => !isExpired;

  /// Returns the total number of votes across all options
  int get totalVotes {
    return options.fold<int>(0, (sum, option) => sum + option.votes);
  }

  /// Returns true if the poll has any votes
  bool get hasVotes => totalVotes > 0;

  /// Returns true if the poll should be automatically deleted when expired
  bool get autoDeletesAfterExpiry {
    return expiration?.autoDelete ?? false;
  }

  /// Creates a copy of this poll with updated fields
  Poll copyWith({
    PollId? id,
    String? title,
    String? description,
    List<PollOption>? options,
    bool? isAnonymous,
    bool? allowsMultipleVotes,
    String? createdByName,
    String? createdBy,
    DateTime? createdAt,
    PollExpiration? expiration,
  }) {
    return Poll(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      options: options ?? this.options,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      allowsMultipleVotes: allowsMultipleVotes ?? this.allowsMultipleVotes,
      createdByName: createdByName ?? this.createdByName,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiration: expiration ?? this.expiration,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        options,
        isAnonymous,
        allowsMultipleVotes,
        createdByName,
        createdBy,
        createdAt,
        expiration,
      ];
}
