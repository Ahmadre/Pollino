import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pollino/env.dart' show Environment;
import 'package:pollino/bloc/poll.dart';

/// REST API service for communicating with the Spring Boot backend.
/// Replaces the previous SupabaseService.
class ApiService {
  static String get _baseUrl => Environment.apiBaseUrl;

  static final http.Client _client = http.Client();

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ──────────────────────────────────────────────
  // Poll Operations
  // ──────────────────────────────────────────────

  /// Fetches paginated polls from the API.
  static Future<Map<String, dynamic>> fetchPolls(int page, int limit) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/polls?page=$page&limit=$limit');
      final response = await _client.get(uri, headers: _headers);
      _checkResponse(response);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final pollsJson = data['polls'] as List<dynamic>;

      final polls = pollsJson.map((json) => _pollFromJson(json)).toList();

      return {
        'polls': polls,
        'total': data['total'] as int,
        'hasMore': data['hasMore'] as bool,
      };
    } catch (e) {
      debugPrint('Error in fetchPolls: $e');
      rethrow;
    }
  }

  /// Fetches a single poll by ID.
  static Future<Poll> fetchPoll(String pollId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/polls/$pollId');
      final response = await _client.get(uri, headers: _headers);
      _checkResponse(response);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _pollFromJson(data);
    } catch (e) {
      debugPrint('Error in fetchPoll: $e');
      rethrow;
    }
  }

  /// Creates a new poll and returns poll data + admin token + admin URL.
  static Future<Map<String, dynamic>> createPoll({
    required String title,
    required List<String> optionTexts,
    String? description,
    bool isAnonymous = true,
    bool allowsMultipleVotes = false,
    DateTime? expiresAt,
    bool autoDeleteAfterExpiry = false,
    String? creatorName,
    String? creatorEmail,
    String pollType = 'STANDARD',
    List<Map<String, dynamic>>? feedbackQuestions,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/polls');
      final body = <String, dynamic>{
        'title': title,
        'description': description ?? '',
        'pollType': pollType,
        'anonymous': isAnonymous,
        'allowsMultipleVotes': allowsMultipleVotes,
        'expiresAt': expiresAt?.toUtc().toIso8601String(),
        'autoDeleteAfterExpiry': autoDeleteAfterExpiry,
        'creatorName': creatorName,
        'creatorEmail': creatorEmail,
      };

      if (pollType == 'FEEDBACK' && feedbackQuestions != null) {
        body['feedbackQuestions'] = feedbackQuestions;
      } else {
        body['options'] = optionTexts;
      }

      final headers = Map<String, String>.from(_headers);
      headers['X-Web-App-Url'] = Environment.webAppUrl;

      final response =
          await _client.post(uri, headers: headers, body: jsonEncode(body));
      _checkResponse(response);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final pollJson = data['poll'] as Map<String, dynamic>;
      final poll = _pollFromJson(pollJson);
      final adminToken = data['adminToken'] as String;
      final adminUrl = data['adminUrl'] as String? ??
          '${Environment.webAppUrl}/admin/${poll.id}/$adminToken';

      return {
        'poll': poll,
        'admin_token': adminToken,
        'admin_url': adminUrl,
      };
    } catch (e) {
      debugPrint('Error in createPoll: $e');
      rethrow;
    }
  }

  /// Sends a single vote for a poll option.
  static Future<void> sendVote(
    String pollId,
    String optionId, {
    String? voterName,
    bool isAnonymous = true,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/polls/$pollId/vote');
      final body = {
        'optionIds': [optionId],
        'voterName': voterName,
        'anonymous': isAnonymous,
      };

      final response =
          await _client.post(uri, headers: _headers, body: jsonEncode(body));
      _checkResponse(response);
    } catch (e) {
      debugPrint('Error in sendVote: $e');
      rethrow;
    }
  }

  /// Sends multiple votes for a poll (for multiple choice polls).
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
      final uri = Uri.parse('$_baseUrl/api/polls/$pollId/vote');
      final body = {
        'optionIds': optionIds,
        'voterName': voterName,
        'anonymous': isAnonymous,
      };

      final response =
          await _client.post(uri, headers: _headers, body: jsonEncode(body));
      _checkResponse(response);
    } catch (e) {
      debugPrint('Error in sendMultipleVotes: $e');
      rethrow;
    }
  }

  /// Checks which options a user has already voted for.
  static Future<List<String>> getUserVotedOptions(
      String pollId, String userName) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/api/polls/$pollId/user-votes?voterName=${Uri.encodeComponent(userName)}');
      final response = await _client.get(uri, headers: _headers);
      _checkResponse(response);

      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<String>();
    } catch (e) {
      debugPrint('Error in getUserVotedOptions: $e');
      return [];
    }
  }

  /// Checks if a user has already voted on a poll.
  static Future<bool> hasUserVoted(String pollId, String userName) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/api/polls/$pollId/has-voted?voterName=${Uri.encodeComponent(userName)}');
      final response = await _client.get(uri, headers: _headers);
      _checkResponse(response);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['hasVoted'] as bool? ?? false;
    } catch (e) {
      debugPrint('Error in hasUserVoted: $e');
      return false;
    }
  }

  /// Gets all votes for a poll (for voter name display).
  static Future<List<Map<String, dynamic>>> getVotesForPoll(
      String pollId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/polls/$pollId/votes');
      final response = await _client.get(uri, headers: _headers);
      _checkResponse(response);

      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error in getVotesForPoll: $e');
      return [];
    }
  }

  /// Gets voters for a specific option.
  static Future<List<Map<String, dynamic>>> getVotersForOption(
      String pollId, String optionId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/polls/$pollId/votes/$optionId');
      final response = await _client.get(uri, headers: _headers);
      _checkResponse(response);

      final data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error in getVotersForOption: $e');
      return [];
    }
  }

  /// Toggles like on a poll.
  static Future<void> toggleLike(String pollId, bool isLiked) async {
    try {
      final uri =
          Uri.parse('$_baseUrl/api/polls/$pollId/like?currentlyLiked=$isLiked');
      final response = await _client.post(uri, headers: _headers);
      _checkResponse(response);
    } catch (e) {
      debugPrint('Error in toggleLike: $e');
      rethrow;
    }
  }

  /// Validates an admin token for a poll.
  static Future<bool> validateAdminToken(
      String pollId, String adminToken) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/polls/$pollId/validate-token');
      final body = {'adminToken': adminToken};
      final response =
          await _client.post(uri, headers: _headers, body: jsonEncode(body));
      _checkResponse(response);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['valid'] as bool? ?? false;
    } catch (e) {
      debugPrint('Error in validateAdminToken: $e');
      return false;
    }
  }

  /// Updates a poll (requires valid admin token).
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
    List<Map<String, dynamic>>? feedbackQuestions,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/polls/$pollId');
      final body = {
        'adminToken': adminToken,
        'title': title,
        'description': description ?? '',
        'options': optionTexts,
        'anonymous': isAnonymous,
        'allowsMultipleVotes': allowsMultipleVotes,
        'expiresAt': expiresAt?.toUtc().toIso8601String(),
        'autoDeleteAfterExpiry': autoDeleteAfterExpiry,
        'creatorName': creatorName,
        if (feedbackQuestions != null) 'feedbackQuestions': feedbackQuestions,
      };

      final response =
          await _client.put(uri, headers: _headers, body: jsonEncode(body));
      _checkResponse(response);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _pollFromJson(data);
    } catch (e) {
      debugPrint('Error in updatePoll: $e');
      rethrow;
    }
  }

  /// Deletes a poll.
  static Future<void> deletePoll(String pollId,
      {String adminToken = ''}) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/api/polls/$pollId?adminToken=${Uri.encodeComponent(adminToken)}');
      final response = await _client.delete(uri, headers: _headers);
      _checkResponse(response);
      debugPrint('Poll $pollId successfully deleted');
    } catch (e) {
      debugPrint('Error in deletePoll: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────
  // Feedback Operations
  // ──────────────────────────────────────────────

  /// Submit feedback answers for a feedback poll.
  static Future<Map<String, dynamic>> submitFeedback({
    required String pollId,
    String? respondentName,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/polls/$pollId/feedback');
      final body = {
        'respondentName': respondentName,
        'answers': answers,
      };

      final response =
          await _client.post(uri, headers: _headers, body: jsonEncode(body));
      _checkResponse(response);

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error in submitFeedback: $e');
      rethrow;
    }
  }

  /// Get feedback results for a poll (admin only).
  static Future<Map<String, dynamic>> getFeedbackResults(
      String pollId, String adminToken) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/api/polls/$pollId/feedback?adminToken=${Uri.encodeComponent(adminToken)}');
      final response = await _client.get(uri, headers: _headers);
      _checkResponse(response);

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error in getFeedbackResults: $e');
      rethrow;
    }
  }

  /// Get public AI summary for a feedback poll (no admin token required).
  static Future<Map<String, dynamic>> getPublicAiSummary(String pollId) async {
    try {
      final uri =
          Uri.parse('$_baseUrl/api/polls/$pollId/feedback/public-summary');
      final response = await _client.get(uri, headers: _headers);
      _checkResponse(response);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error in getPublicAiSummary: $e');
      rethrow;
    }
  }

  /// Get AI summary for a feedback poll (admin only).
  static Future<Map<String, dynamic>> getAiSummary(
      String pollId, String adminToken) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/api/polls/$pollId/feedback/summary?adminToken=${Uri.encodeComponent(adminToken)}');
      final response = await _client.get(uri, headers: _headers);
      _checkResponse(response);

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error in getAiSummary: $e');
      rethrow;
    }
  }

  /// Trigger AI summary regeneration (admin only).
  static Future<void> regenerateAiSummary(
      String pollId, String adminToken) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/api/polls/$pollId/feedback/summary/regenerate?adminToken=${Uri.encodeComponent(adminToken)}');
      final response = await _client.post(uri, headers: _headers);
      _checkResponse(response);
    } catch (e) {
      debugPrint('Error in regenerateAiSummary: $e');
      rethrow;
    }
  }

  /// Check if user has already responded to a feedback poll.
  static Future<bool> hasRespondedToFeedback(
      String pollId, String respondentName) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/api/polls/$pollId/feedback/has-responded?respondentName=${Uri.encodeComponent(respondentName)}');
      final response = await _client.get(uri, headers: _headers);
      _checkResponse(response);

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['hasResponded'] as bool? ?? false;
    } catch (e) {
      debugPrint('Error in hasRespondedToFeedback: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────
  // Utility Methods (kept from SupabaseService)
  // ──────────────────────────────────────────────

  /// Checks if a poll is expired.
  static bool isPollExpired(Poll poll) {
    if (poll.expiresAt == null) return false;
    return DateTime.now().isAfter(poll.expiresAt!);
  }

  /// Calculates the remaining time until expiry.
  static Duration? getTimeUntilExpiry(Poll poll) {
    if (poll.expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(poll.expiresAt!)) return Duration.zero;
    return poll.expiresAt!.difference(now);
  }

  /// Formats the remaining time as a string.
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

  // ──────────────────────────────────────────────
  // Private Helpers
  // ──────────────────────────────────────────────

  static void _checkResponse(http.Response response) {
    if (response.statusCode >= 400) {
      String message = 'API Error: ${response.statusCode}';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body.containsKey('message')) {
          message = body['message'] as String;
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  static Poll _pollFromJson(Map<String, dynamic> json) {
    final optionsList = (json['options'] as List<dynamic>?) ?? [];
    final options = optionsList.map((opt) {
      final optMap = opt as Map<String, dynamic>;
      return Option(
        id: optMap['id']?.toString() ?? '',
        text: optMap['text']?.toString() ?? '',
        votes: (optMap['votes'] as num?)?.toInt() ?? 0,
        order: (optMap['order'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    // Parse feedback questions if present
    final fbQuestionsList = (json['feedbackQuestions'] as List<dynamic>?) ?? [];
    final feedbackQuestions = fbQuestionsList.map((fq) {
      final fqMap = fq as Map<String, dynamic>;
      return FeedbackQuestion(
        id: fqMap['id']?.toString() ?? '',
        questionText: fqMap['questionText']?.toString() ?? '',
        questionType: fqMap['questionType']?.toString() ?? 'FREE_TEXT',
        options: (fqMap['options'] as List<dynamic>?)
                ?.map((o) => o.toString())
                .toList() ??
            [],
        order: (fqMap['order'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    return Poll(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      options: options,
      isAnonymous: json['anonymous'] as bool? ?? true,
      createdByName: json['createdByName'] as String?,
      createdBy: json['createdBy'] as String?,
      allowsMultipleVotes: json['allowsMultipleVotes'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String).toLocal()
          : null,
      autoDeleteAfterExpiry: json['autoDeleteAfterExpiry'] as bool? ?? false,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      pollType: json['pollType']?.toString() ?? 'STANDARD',
      feedbackQuestions: feedbackQuestions,
      feedbackResponseCount:
          (json['feedbackResponseCount'] as num?)?.toInt() ?? 0,
    );
  }
}
