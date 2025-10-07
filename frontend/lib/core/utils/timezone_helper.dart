import '../localization/i18n_service.dart';

/// Utility class for consistent timezone handling across the app
///
/// This ensures all timestamps are properly converted between:
/// - User's local timezone (for display and input)
/// - UTC timezone (for database storage)

class TimezoneHelper {
  /// Returns current time in UTC (for database operations)
  static DateTime nowUtc() {
    return DateTime.now().toUtc();
  }

  /// Returns current time in user's local timezone (for display)
  static DateTime nowLocal() {
    return DateTime.now();
  }

  /// Converts user's local DateTime to UTC for database storage
  ///
  /// Example: User selects "07.10.2025 16:00" in Berlin timezone
  /// This converts it to UTC for database storage
  static DateTime localToUtc(DateTime localDateTime) {
    return localDateTime.toUtc();
  }

  /// Converts UTC DateTime from database to user's local timezone for display
  ///
  /// Example: Database has "2025-10-07 14:00:00Z" (UTC)
  /// This converts it to "16:00" if user is in Berlin timezone
  static DateTime utcToLocal(DateTime utcDateTime) {
    return utcDateTime.toLocal();
  }

  /// Formats a UTC DateTime for display in user's local timezone
  static String formatForDisplay(DateTime utcDateTime, {bool showSeconds = false}) {
    final localDateTime = utcToLocal(utcDateTime);
    final i18n = I18nService.instance;

    final day = localDateTime.day.toString().padLeft(2, '0');
    final month = localDateTime.month.toString().padLeft(2, '0');
    final year = localDateTime.year;
    final hour = localDateTime.hour.toString().padLeft(2, '0');
    final minute = localDateTime.minute.toString().padLeft(2, '0');

    String timeString = i18n.translate('time.format.timeOnly', params: {'hour': hour, 'minute': minute});

    if (showSeconds) {
      final second = localDateTime.second.toString().padLeft(2, '0');
      timeString = '$hour:$minute:$second';
    }

    final now = nowLocal();
    final isToday = localDateTime.year == now.year && localDateTime.month == now.month && localDateTime.day == now.day;

    if (isToday) {
      return i18n.translate('time.relative.today') + ' $timeString';
    } else {
      return i18n.translate('time.format.dateTime', params: {
        'day': day,
        'month': month,
        'year': year.toString(),
        'hour': hour,
        'minute': minute,
      });
    }
  }

  /// Gets relative time description with correct singular/plural
  static String getRelativeTime(DateTime utcDateTime) {
    final localDateTime = utcToLocal(utcDateTime);
    final now = nowLocal();
    final difference = localDateTime.difference(now);
    final i18n = I18nService.instance;

    if (difference.isNegative) {
      // Past time
      final absDifference = difference.abs();
      if (absDifference.inMinutes < 60) {
        final timeText = i18n.formatTime(absDifference.inMinutes, 'minute');
        return i18n.translate('time.relative.ago', params: {'time': timeText});
      } else if (absDifference.inHours < 24) {
        final timeText = i18n.formatTime(absDifference.inHours, 'hour');
        return i18n.translate('time.relative.ago', params: {'time': timeText});
      } else {
        final timeText = i18n.formatTime(absDifference.inDays, 'day');
        return i18n.translate('time.relative.ago', params: {'time': timeText});
      }
    } else {
      // Future time
      if (difference.inMinutes < 60) {
        final timeText = i18n.formatTime(difference.inMinutes, 'minute');
        return i18n.translate('time.relative.in', params: {'time': timeText});
      } else if (difference.inHours < 24) {
        final timeText = i18n.formatTime(difference.inHours, 'hour');
        return i18n.translate('time.relative.in', params: {'time': timeText});
      } else {
        final timeText = i18n.formatTime(difference.inDays, 'day');
        return i18n.translate('time.relative.in', params: {'time': timeText});
      }
    }
  }

  /// Formats remaining time until expiry with correct singular/plural
  static String formatTimeRemaining(Duration timeRemaining) {
    final i18n = I18nService.instance;

    if (timeRemaining.inDays > 0) {
      final daysText = i18n.formatTime(timeRemaining.inDays, 'day');
      if (timeRemaining.inDays >= 1 && timeRemaining.inHours % 24 > 0) {
        final hoursText = i18n.formatTime(timeRemaining.inHours % 24, 'hour');
        return '$daysText $hoursText';
      } else {
        return daysText;
      }
    } else if (timeRemaining.inHours > 0) {
      final hoursText = i18n.formatTime(timeRemaining.inHours, 'hour');
      if (timeRemaining.inMinutes % 60 > 0) {
        final minutesText = i18n.formatTime(timeRemaining.inMinutes % 60, 'minute');
        return '$hoursText $minutesText';
      } else {
        return hoursText;
      }
    } else if (timeRemaining.inMinutes > 0) {
      final minutesText = i18n.formatTime(timeRemaining.inMinutes, 'minute');
      return minutesText;
    } else {
      return i18n.translate('time.relative.fewSeconds');
    }
  }

  /// Checks if a UTC timestamp represents an expired time
  static bool isExpired(DateTime utcDateTime) {
    return nowUtc().isAfter(utcDateTime);
  }

  /// Gets time until expiry (returns null if already expired)
  static Duration? timeUntilExpiry(DateTime utcDateTime) {
    final now = nowUtc();
    if (now.isAfter(utcDateTime)) {
      return null; // Already expired
    }
    return utcDateTime.difference(now);
  }

  /// Converts DateTime to ISO8601 string for database storage (ensures UTC)
  static String toIso8601Utc(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// Parses ISO8601 string from database and returns UTC DateTime
  static DateTime fromIso8601Utc(String iso8601String) {
    return DateTime.parse(iso8601String).toUtc();
  }

  /// Creates a DateTime from user input components (assumes local timezone)
  /// and converts to UTC for database storage
  static DateTime createUtcFromUserInput({
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
    int second = 0,
  }) {
    final localDateTime = DateTime(year, month, day, hour, minute, second);
    return localToUtc(localDateTime);
  }
}
