import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pollino/env.dart';
import 'package:pollino/features/polls/data/models/poll_model.dart';
import 'package:pollino/features/polls/data/models/poll_option_model.dart';
import 'package:pollino/core/error/failures.dart';

/// Contract for remote data operations
abstract class PollRemoteDataSource {
  /// Fetch paginated polls from server
  Future<List<PollModel>> getPolls({int page = 1, int limit = 20});

  /// Fetch a specific poll from server
  Future<PollModel> getPoll(String pollId);

  /// Create a new poll on server
  Future<PollModel> createPoll({
    required String title,
    required List<String> optionTexts,
    String? description,
    bool isAnonymous = true,
    bool allowsMultipleVotes = false,
    String? creatorName,
    DateTime? expiresAt,
    bool autoDeleteAfterExpiry = false,
  });

  /// Update an existing poll on server
  Future<PollModel> updatePoll(PollModel poll);

  /// Delete a poll from server
  Future<void> deletePoll(String pollId);

  /// Cast a vote for a poll option
  Future<void> castVote({
    required String pollId,
    required String optionId,
    String? voterName,
    bool isAnonymous = true,
  });

  /// Cast multiple votes for poll options
  Future<void> castMultipleVotes({
    required String pollId,
    required List<String> optionIds,
    String? voterName,
    bool isAnonymous = true,
  });

  /// Clean up expired polls (handled by backend scheduler now)
  Future<int> cleanupExpiredPolls();

  /// Get poll status
  Future<Map<String, dynamic>> getPollStatus(String pollId);
}

/// Implementation of remote data source using Spring Boot REST API
class PollRemoteDataSourceImpl implements PollRemoteDataSource {
  final http.Client client;
  String get _baseUrl => Environment.apiBaseUrl;

  PollRemoteDataSourceImpl({required this.client});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  PollModel _parsePoll(Map<String, dynamic> data) {
    final optionsData = data['options'] as List<dynamic>? ?? [];
    final options = optionsData.asMap().entries.map((entry) {
      final opt = entry.value as Map<String, dynamic>;
      return PollOptionModel(
        id: opt['id']?.toString() ?? '',
        text: opt['text'] ?? '',
        votes: opt['votes'] ?? 0,
        order: opt['order'] ?? entry.key,
      );
    }).toList();

    return PollModel(
      id: data['id']?.toString() ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      options: options,
      isAnonymous: data['anonymous'] ?? true,
      allowsMultipleVotes: data['allowsMultipleVotes'] ?? false,
      createdByName: data['createdByName'],
      createdBy: data['createdBy'],
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now(),
      expiresAt: data['expiresAt'] != null ? DateTime.parse(data['expiresAt']) : null,
      autoDeleteAfterExpiry: data['autoDeleteAfterExpiry'] ?? false,
    );
  }

  @override
  Future<List<PollModel>> getPolls({int page = 1, int limit = 20}) async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/api/polls?page=$page&size=$limit'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw ServerFailure(message: 'Failed to fetch polls: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final pollsData = data['polls'] as List<dynamic>? ?? [];
      return pollsData.map((p) => _parsePoll(p as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure(message: 'Failed to fetch polls: $e');
    }
  }

  @override
  Future<PollModel> getPoll(String pollId) async {
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/api/polls/$pollId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw ServerFailure(message: 'Failed to fetch poll: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return _parsePoll(data);
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure(message: 'Failed to fetch poll: $e');
    }
  }

  @override
  Future<PollModel> createPoll({
    required String title,
    required List<String> optionTexts,
    String? description,
    bool isAnonymous = true,
    bool allowsMultipleVotes = false,
    String? creatorName,
    DateTime? expiresAt,
    bool autoDeleteAfterExpiry = false,
  }) async {
    try {
      final body = {
        'title': title,
        'description': description ?? '',
        'options': optionTexts,
        'anonymous': isAnonymous,
        'allowsMultipleVotes': allowsMultipleVotes,
        'createdByName': creatorName,
        if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
        'autoDeleteAfterExpiry': autoDeleteAfterExpiry,
      };

      final response = await client.post(
        Uri.parse('$_baseUrl/api/polls'),
        headers: _headers,
        body: json.encode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(message: 'Failed to create poll: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return _parsePoll(data);
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure(message: 'Failed to create poll: $e');
    }
  }

  @override
  Future<PollModel> updatePoll(PollModel poll) async {
    try {
      final body = {
        'title': poll.title,
        'description': poll.description,
        'options': poll.options.map((o) => o.text).toList(),
        'anonymous': poll.isAnonymous,
        'allowsMultipleVotes': poll.allowsMultipleVotes,
        if (poll.expiresAt != null) 'expiresAt': poll.expiresAt!.toIso8601String(),
        'autoDeleteAfterExpiry': poll.autoDeleteAfterExpiry,
      };

      final response = await client.put(
        Uri.parse('$_baseUrl/api/polls/${poll.id}'),
        headers: _headers,
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        throw ServerFailure(message: 'Failed to update poll: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return _parsePoll(data);
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure(message: 'Failed to update poll: $e');
    }
  }

  @override
  Future<void> deletePoll(String pollId) async {
    try {
      final response = await client.delete(
        Uri.parse('$_baseUrl/api/polls/$pollId'),
        headers: _headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure(message: 'Failed to delete poll: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure(message: 'Failed to delete poll: $e');
    }
  }

  @override
  Future<void> castVote({
    required String pollId,
    required String optionId,
    String? voterName,
    bool isAnonymous = true,
  }) async {
    try {
      final body = {
        'optionId': optionId,
        'voterName': voterName,
        'anonymous': isAnonymous,
      };

      final response = await client.post(
        Uri.parse('$_baseUrl/api/polls/$pollId/vote'),
        headers: _headers,
        body: json.encode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure(message: 'Failed to cast vote: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure(message: 'Failed to cast vote: $e');
    }
  }

  @override
  Future<void> castMultipleVotes({
    required String pollId,
    required List<String> optionIds,
    String? voterName,
    bool isAnonymous = true,
  }) async {
    for (final optionId in optionIds) {
      await castVote(
        pollId: pollId,
        optionId: optionId,
        voterName: voterName,
        isAnonymous: isAnonymous,
      );
    }
  }

  @override
  Future<int> cleanupExpiredPolls() async {
    // Cleanup is now handled by the Spring Boot backend scheduler
    return 0;
  }

  @override
  Future<Map<String, dynamic>> getPollStatus(String pollId) async {
    try {
      final poll = await getPoll(pollId);
      return {
        'id': poll.id,
        'title': poll.title,
        'isActive': true,
        'totalVotes': poll.options.fold<int>(0, (sum, opt) => sum + opt.votes),
        'optionsCount': poll.options.length,
      };
    } catch (e) {
      throw ServerFailure(message: 'Failed to get poll status: $e');
    }
  }
}