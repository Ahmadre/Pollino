import 'package:equatable/equatable.dart';

/// Value Object representing poll expiration settings
///
/// Encapsulates expiration date and auto-delete behavior
class PollExpiration extends Equatable {
  final DateTime expiresAt;
  final bool autoDelete;

  const PollExpiration({
    required this.expiresAt,
    required this.autoDelete,
  });

  /// Factory constructor for creating expiration from duration
  factory PollExpiration.fromDuration({
    required Duration duration,
    bool autoDelete = false,
  }) {
    final expiresAt = DateTime.now().add(duration);
    return PollExpiration(
      expiresAt: expiresAt,
      autoDelete: autoDelete,
    );
  }

  /// Factory constructor for creating expiration from specific date
  factory PollExpiration.fromDateTime({
    required DateTime expiresAt,
    bool autoDelete = false,
  }) {
    if (expiresAt.isBefore(DateTime.now())) {
      throw ArgumentError('Expiration date cannot be in the past');
    }
    return PollExpiration(
      expiresAt: expiresAt,
      autoDelete: autoDelete,
    );
  }

  /// Returns true if the poll has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Returns the remaining time until expiration
  Duration get timeUntilExpiration {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) {
      return Duration.zero;
    }
    return expiresAt.difference(now);
  }

  /// Returns true if the poll expires within the given duration
  bool expiresWithin(Duration duration) {
    final threshold = DateTime.now().add(duration);
    return expiresAt.isBefore(threshold);
  }

  /// Returns a formatted string of time remaining
  String get formattedTimeRemaining {
    final remaining = timeUntilExpiration;

    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h verbleibend';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}min verbleibend';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}min verbleibend';
    } else if (remaining.inSeconds > 0) {
      return '${remaining.inSeconds}s verbleibend';
    } else {
      return 'Abgelaufen';
    }
  }

  @override
  List<Object> get props => [expiresAt, autoDelete];
}
