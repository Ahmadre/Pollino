import 'package:flutter/foundation.dart';
import 'package:pollino/env.dart' show Environment;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pollino/bloc/poll.dart';
import 'package:pollino/core/utils/timezone_helper.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Lädt Umfragen mit Paginierung
  static Future<Map<String, dynamic>> fetchPolls(int page, int limit) async {
    final offset = (page - 1) * limit;

    try {
      // Zähle die Gesamtanzahl der SICHTBAREN Umfragen (mit denselben Filtern wie die Abfrage)
      final countResponse = await _client
          .from('polls')
          .select('id')
          .eq('is_active', true)
          .or('expires_at.is.null,expires_at.gt.now(),and(expires_at.lt.now(),auto_delete_after_expiry.is.false)')
          .count(CountOption.exact);
      final total = countResponse.count;

      // Hole die Umfragen (inklusive nicht abgelaufener oder nicht auto-gelöschter)
      final pollsResponse = await _client
          .from('polls')
          .select(
              'id, title, description, created_at, is_active, is_anonymous, created_by_name, created_by, allows_multiple_votes, expires_at, auto_delete_after_expiry, likes_count')
          .eq('is_active', true)
          .or('expires_at.is.null,expires_at.gt.now(),and(expires_at.lt.now(),auto_delete_after_expiry.is.false)')
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      debugPrint('Polls response: $pollsResponse');

      // Hole die Optionen für alle Umfragen
      final List<Poll> polls = [];

      for (final pollData in pollsResponse) {
        final pollId = pollData['id'];

        final optionsResponse =
            await _client.from('poll_options').select('id, text, votes').eq('poll_id', pollId).order('id');

        debugPrint('Options for poll $pollId: $optionsResponse');

        final options = (optionsResponse as List).map((optionData) {
          return Option(
            id: optionData['id'].toString(),
            text: optionData['text'] ?? '',
            votes: optionData['votes'] ?? 0,
          );
        }).toList();

        polls.add(
          Poll(
            id: pollData['id'].toString(),
            title: pollData['title'] ?? '',
            description: pollData['description'] ?? '',
            options: options,
            isAnonymous: pollData['is_anonymous'] ?? true,
            createdByName: pollData['created_by_name'],
            createdBy: pollData['created_by'],
            allowsMultipleVotes: pollData['allows_multiple_votes'] ?? false,
            expiresAt: pollData['expires_at'] != null ? TimezoneHelper.fromIso8601Utc(pollData['expires_at']) : null,
            autoDeleteAfterExpiry: pollData['auto_delete_after_expiry'] ?? false,
            likesCount: pollData['likes_count'] ?? 0,
          ),
        );
      }

      return {'polls': polls, 'total': total};
    } catch (e) {
      debugPrint('Error in fetchPolls: $e');
      rethrow;
    }
  }

  /// Lädt eine einzelne Umfrage
  static Future<Poll> fetchPoll(String pollId) async {
    try {
      // Hole die Umfrage
      final pollResponse = await _client
          .from('polls')
          .select(
              'id, title, description, created_at, is_active, is_anonymous, created_by_name, created_by, allows_multiple_votes, expires_at, auto_delete_after_expiry, likes_count')
          .eq('id', pollId)
          .single();

      debugPrint('Single poll response: $pollResponse');

      // Hole die Optionen für diese Umfrage
      final optionsResponse =
          await _client.from('poll_options').select('id, text, votes').eq('poll_id', pollId).order('id');

      debugPrint('Options response: $optionsResponse');

      final options = (optionsResponse as List).map((optionData) {
        return Option(id: optionData['id'].toString(), text: optionData['text'] ?? '', votes: optionData['votes'] ?? 0);
      }).toList();

      return Poll(
        id: pollResponse['id'].toString(),
        title: pollResponse['title'] ?? '',
        description: pollResponse['description'] ?? '',
        options: options,
        isAnonymous: pollResponse['is_anonymous'] ?? true,
        createdByName: pollResponse['created_by_name'],
        createdBy: pollResponse['created_by'],
        allowsMultipleVotes: pollResponse['allows_multiple_votes'] ?? false,
        expiresAt:
            pollResponse['expires_at'] != null ? TimezoneHelper.fromIso8601Utc(pollResponse['expires_at']) : null,
        autoDeleteAfterExpiry: pollResponse['auto_delete_after_expiry'] ?? false,
        likesCount: pollResponse['likes_count'] ?? 0,
      );
    } catch (e) {
      debugPrint('Error in fetchPoll: $e');
      rethrow;
    }
  }

  /// Sendet eine Stimme für eine Umfrageoption
  static Future<void> sendVote(
    String pollId,
    String optionId, {
    String? voterName,
    bool isAnonymous = true,
  }) async {
    try {
      await _client.rpc('cast_vote', params: {
        'p_poll_id': int.parse(pollId),
        'p_option_id': int.parse(optionId),
        'p_user_name': voterName,
        'p_is_anonymous': isAnonymous,
      });
    } catch (e) {
      debugPrint('Error in sendVote: $e');
      rethrow;
    }
  }

  /// Sendet multiple Stimmen für eine Umfrage (für Multiple Choice Polls)
  static Future<void> sendMultipleVotes(
    String pollId,
    List<String> optionIds, {
    String? voterName,
    bool isAnonymous = true,
  }) async {
    if (optionIds.isEmpty) {
      throw Exception('Keine Optionen zum Abstimmen ausgewählt');
    }

    try {
      // Erst prüfen ob Poll Multiple Voting erlaubt
      final poll = await fetchPoll(pollId);
      if (!poll.allowsMultipleVotes && optionIds.length > 1) {
        throw Exception('Diese Umfrage erlaubt nur eine Auswahl');
      }

      for (final optionId in optionIds) {
        await _client.rpc('cast_vote', params: {
          'p_poll_id': int.parse(pollId),
          'p_option_id': int.parse(optionId),
          'p_user_name': voterName,
          'p_is_anonymous': isAnonymous,
        });
      }
    } catch (e) {
      debugPrint('Error in sendMultipleVotes: $e');
      rethrow;
    }
  }

  /// Prüft welche Optionen ein User bereits gewählt hat (für Multiple Choice)
  static Future<List<String>> getUserVotedOptions(String pollId, String userName) async {
    try {
      final result =
          await _client.from('user_votes').select('option_id').eq('poll_id', pollId).eq('voter_name', userName);

      return result.map<String>((vote) => vote['option_id'].toString()).toList();
    } catch (e) {
      debugPrint('Error in getUserVotedOptions: $e');
      return [];
    }
  }

  /// Erstellt eine neue Umfrage
  static Future<Map<String, dynamic>> createPoll({
    required String title,
    required List<String> optionTexts,
    String? description,
    bool isAnonymous = true,
    bool allowsMultipleVotes = false,
    DateTime? expiresAt,
    bool autoDeleteAfterExpiry = false,
    String? creatorName,
  }) async {
    try {
      String? createdBy;

      // Falls nicht anonym, erstelle oder finde den User
      if (!isAnonymous && creatorName != null && creatorName.isNotEmpty) {
        final userResult = await _client.rpc('create_or_get_user', params: {
          'user_name': creatorName,
        });
        createdBy = userResult.toString();
      }

      // Erstelle die Umfrage (admin_token wird automatisch via Trigger generiert)
      final pollResponse = await _client
          .from('polls')
          .insert({
            'title': title,
            'description': description ?? '',
            'is_anonymous': isAnonymous,
            'allows_multiple_votes': allowsMultipleVotes,
            'expires_at': expiresAt != null ? TimezoneHelper.toIso8601Utc(expiresAt) : null,
            'auto_delete_after_expiry': autoDeleteAfterExpiry,
            'created_by': createdBy,
            'created_by_name': creatorName,
          })
          .select('*, admin_token')
          .single();

      final pollId = pollResponse['id'];
      final adminToken = pollResponse['admin_token'];

      // Erstelle die Optionen
      final optionsData = optionTexts.map((text) => {'poll_id': pollId, 'text': text, 'votes': 0}).toList();

      final optionsResponse = await _client.from('poll_options').insert(optionsData).select();

      // Erstelle die Poll-Instanz
      final options = optionsResponse.map((optionData) {
        return Option(
          id: optionData['id'].toString(),
          text: optionData['text'],
          votes: optionData['votes'] ?? 0,
        );
      }).toList();

      final poll = Poll(
        id: pollId.toString(),
        title: title,
        description: description ?? '',
        options: options,
        isAnonymous: isAnonymous,
        allowsMultipleVotes: allowsMultipleVotes,
        expiresAt: expiresAt,
        autoDeleteAfterExpiry: autoDeleteAfterExpiry,
        createdByName: creatorName,
        createdBy: createdBy,
        likesCount: 0, // Neue Umfragen beginnen mit 0 Likes
      );

      final path = '/admin/$pollId/$adminToken';

      return {
        'poll': poll,
        'admin_token': adminToken,
        'admin_url': Uri.base.origin.isNotEmpty ? '${Uri.base.origin}$path' : '${Environment.webAppUrl}$path',
      };
    } catch (e) {
      debugPrint('Error in createPoll: $e');
      rethrow;
    }
  }

  /// Prüft ob ein Benutzer bereits für eine Umfrage abgestimmt hat
  static Future<bool> hasUserVoted(String pollId, String userName) async {
    try {
      final result =
          await _client.from('user_votes').select('id').eq('poll_id', pollId).eq('voter_name', userName).maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint('Error in hasUserVoted: $e');
      return false;
    }
  }

  /// Erstellt oder findet einen Benutzer basierend auf dem Namen
  static Future<String?> createOrGetUser(String userName) async {
    try {
      final result = await _client.rpc('create_or_get_user', params: {
        'user_name': userName,
      });
      return result?.toString();
    } catch (e) {
      debugPrint('Error in createOrGetUser: $e');
      return null;
    }
  }

  /// Löscht eine Umfrage vollständig (mit CASCADE für Options und Votes)
  static Future<void> deletePoll(String pollId) async {
    try {
      // Da wir CASCADE DELETE in der Datenbank konfiguriert haben,
      // werden poll_options und user_votes automatisch mitgelöscht
      await _client.from('polls').delete().eq('id', pollId);

      debugPrint('Poll $pollId successfully deleted');
    } catch (e) {
      debugPrint('Error in deletePoll: $e');
      rethrow;
    }
  }

  /// Prüft ob eine Umfrage abgelaufen ist
  static bool isPollExpired(Poll poll) {
    if (poll.expiresAt == null) return false;
    return TimezoneHelper.isExpired(poll.expiresAt!);
  }

  /// Berechnet die verbleibende Zeit bis zum Ablauf
  static Duration? getTimeUntilExpiry(Poll poll) {
    if (poll.expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(poll.expiresAt!)) return Duration.zero;
    return poll.expiresAt!.difference(now);
  }

  /// Formatiert die verbleibende Zeit als String
  static String formatTimeUntilExpiry(Poll poll) {
    final duration = getTimeUntilExpiry(poll);
    if (duration == null) return '';

    if (duration.isNegative || duration == Duration.zero) {
      return 'Abgelaufen';
    }

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '$days Tag(e) $hours Std.';
    } else if (hours > 0) {
      return '$hours Std. $minutes Min.';
    } else {
      return '$minutes Min.';
    }
  }

  /// Gibt einer Umfrage ein Like oder entfernt es
  static Future<void> toggleLike(String pollId, bool isLiked) async {
    try {
      if (isLiked) {
        // User hat bereits geliked -> Unlike (decrement)
        await _client.rpc('decrement_poll_likes', params: {
          'p_poll_id': int.parse(pollId),
        });
      } else {
        // User hat noch nicht geliked -> Like (increment)
        await _client.rpc('increment_poll_likes', params: {
          'p_poll_id': int.parse(pollId),
        });
      }
    } catch (e) {
      debugPrint('Error in toggleLike: $e');
      rethrow;
    }
  }

  /// Validiert ein Admin-Token für eine Umfrage
  static Future<bool> validateAdminToken(String pollId, String adminToken) async {
    try {
      final result = await _client.rpc('validate_admin_token', params: {
        'poll_id': int.parse(pollId),
        'token': adminToken,
      });
      return result == true;
    } catch (e) {
      debugPrint('Error in validateAdminToken: $e');
      return false;
    }
  }

  /// Aktualisiert eine bestehende Umfrage (nur mit gültigem Admin-Token)
  static Future<Poll> updatePoll({
    required String pollId,
    required String adminToken,
    required String title,
    required List<String> optionTexts,
    String? description,
    bool isAnonymous = true,
    bool allowsMultipleVotes = false,
    DateTime? expiresAt,
    bool autoDeleteAfterExpiry = false,
    String? creatorName,
  }) async {
    try {
      // Erst Admin-Token validieren
      final isValidToken = await validateAdminToken(pollId, adminToken);
      if (!isValidToken) {
        throw Exception('Ungültiges Admin-Token');
      }

      String? createdBy;

      // Falls nicht anonym, erstelle oder finde den User
      if (!isAnonymous && creatorName != null && creatorName.isNotEmpty) {
        final userResult = await _client.rpc('create_or_get_user', params: {
          'user_name': creatorName,
        });
        createdBy = userResult.toString();
      }

      // Aktualisiere die Umfrage
      final pollResponse = await _client
          .from('polls')
          .update({
            'title': title,
            'description': description ?? '',
            'is_anonymous': isAnonymous,
            'allows_multiple_votes': allowsMultipleVotes,
            'expires_at': expiresAt != null ? TimezoneHelper.toIso8601Utc(expiresAt) : null,
            'auto_delete_after_expiry': autoDeleteAfterExpiry,
            'created_by': createdBy,
            'created_by_name': creatorName,
          })
          .eq('id', pollId)
          .select()
          .single();

      // Lösche alle bestehenden Optionen
      await _client.from('poll_options').delete().eq('poll_id', pollId);

      // Erstelle neue Optionen
      final optionsData = optionTexts.map((text) => {'poll_id': int.parse(pollId), 'text': text, 'votes': 0}).toList();

      final optionsResponse = await _client.from('poll_options').insert(optionsData).select();

      // Erstelle die aktualisierte Poll-Instanz
      final options = optionsResponse.map((optionData) {
        return Option(
          id: optionData['id'].toString(),
          text: optionData['text'],
          votes: optionData['votes'] ?? 0,
        );
      }).toList();

      final updatedPoll = Poll(
        id: pollId,
        title: title,
        description: description ?? '',
        options: options,
        isAnonymous: isAnonymous,
        allowsMultipleVotes: allowsMultipleVotes,
        expiresAt: expiresAt,
        autoDeleteAfterExpiry: autoDeleteAfterExpiry,
        createdByName: creatorName,
        createdBy: createdBy,
        likesCount: pollResponse['likes_count'] ?? 0,
      );

      return updatedPoll;
    } catch (e) {
      debugPrint('Error in updatePoll: $e');
      rethrow;
    }
  }

  /// Führt automatische Cleanup-Funktion aus (optional - DB macht das jetzt automatisch)
  /// Diese Methode kann manuell aufgerufen werden, ist aber nicht mehr notwendig
  /// da die Database das Cleanup automatisch über Trigger durchführt
  static Future<int> runExpiredPollsCleanup({String source = 'manual'}) async {
    try {
      final result = await _client.rpc('run_automatic_poll_cleanup');
      if (result > 0) {
        debugPrint('Manual cleanup completed: $result polls deleted');
      } else {
        debugPrint('No cleanup needed - automatic database cleanup is working');
      }
      return result as int;
    } catch (e) {
      debugPrint('Error in run_automatic_poll_cleanup: $e');
      // Fallback to old function if new one doesn't exist
      try {
        final fallbackResult = await _client.rpc('cleanup_expired_polls');
        debugPrint('Fallback cleanup completed: $fallbackResult polls deleted');
        return fallbackResult as int;
      } catch (fallbackError) {
        debugPrint('Fallback cleanup also failed: $fallbackError');
        return 0;
      }
    }
  }

  /// Überprüft den Status der automatischen Poll-Bereinigung
  static Future<Map<String, dynamic>> getCleanupStatus() async {
    try {
      final result = await _client
          .from('poll_cleanup_log')
          .select('cleanup_time, deleted_count, triggered_by')
          .order('cleanup_time', ascending: false)
          .limit(10);

      final expiredCount = await _client
          .from('polls')
          .select('id')
          .lt('expires_at', TimezoneHelper.toIso8601Utc(TimezoneHelper.nowUtc()))
          .eq('auto_delete_after_expiry', true)
          .count(CountOption.exact);

      return {
        'recent_cleanups': result,
        'pending_expired_polls': expiredCount.count,
        'last_cleanup': result.isNotEmpty ? result.first['cleanup_time'] : null,
      };
    } catch (e) {
      debugPrint('Error getting cleanup status: $e');
      return {
        'recent_cleanups': [],
        'pending_expired_polls': 0,
        'last_cleanup': null,
        'error': e.toString(),
      };
    }
  }
}
