import 'package:supabase_flutter/supabase_flutter.dart';
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

  /// Clean up expired polls
  Future<int> cleanupExpiredPolls();

  /// Get poll status
  Future<Map<String, dynamic>> getPollStatus(String pollId);
}

/// Implementation of remote data source using Supabase
class PollRemoteDataSourceImpl implements PollRemoteDataSource {
  final SupabaseClient client;

  PollRemoteDataSourceImpl({required this.client});

  @override
  Future<List<PollModel>> getPolls({int page = 1, int limit = 20}) async {
    try {
      final offset = (page - 1) * limit;

      final pollsResponse = await client
          .from('polls')
          .select('*')
          .eq('is_active', true)
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      final List<PollModel> polls = [];

      for (final pollData in pollsResponse) {
        // Fetch options for each poll
        final optionsResponse =
            await client.from('poll_options').select('*').eq('poll_id', pollData['id']).order('option_order, id');

        final options = (optionsResponse as List).map((optionData) {
          return PollOptionModel(
            id: optionData['id'].toString(),
            text: optionData['text'] ?? '',
            votes: optionData['votes'] ?? 0,
            order: optionData['option_order'] ?? 0,
          );
        }).toList();

        polls.add(PollModel(
          id: pollData['id'].toString(),
          title: pollData['title'] ?? '',
          description: pollData['description'],
          options: options,
          isAnonymous: pollData['is_anonymous'] ?? true,
          allowsMultipleVotes: pollData['allows_multiple_votes'] ?? false,
          createdByName: pollData['created_by_name'],
          createdBy: pollData['created_by'],
          createdAt: DateTime.parse(pollData['created_at']),
          expiresAt: pollData['expires_at'] != null ? DateTime.parse(pollData['expires_at']) : null,
          autoDeleteAfterExpiry: pollData['auto_delete_after_expiry'] ?? false,
        ));
      }

      return polls;
    } catch (e) {
      throw ServerFailure(message: 'Failed to fetch polls: $e');
    }
  }

  @override
  Future<PollModel> getPoll(String pollId) async {
    try {
      final pollResponse = await client.from('polls').select('*').eq('id', pollId).single();

      final optionsResponse =
          await client.from('poll_options').select('*').eq('poll_id', pollId).order('option_order, id');

      final options = (optionsResponse as List).map((optionData) {
        return PollOptionModel(
          id: optionData['id'].toString(),
          text: optionData['text'] ?? '',
          votes: optionData['votes'] ?? 0,
          order: optionData['option_order'] ?? 0,
        );
      }).toList();

      return PollModel(
        id: pollResponse['id'].toString(),
        title: pollResponse['title'] ?? '',
        description: pollResponse['description'],
        options: options,
        isAnonymous: pollResponse['is_anonymous'] ?? true,
        allowsMultipleVotes: pollResponse['allows_multiple_votes'] ?? false,
        createdByName: pollResponse['created_by_name'],
        createdBy: pollResponse['created_by'],
        createdAt: DateTime.parse(pollResponse['created_at']),
        expiresAt: pollResponse['expires_at'] != null ? DateTime.parse(pollResponse['expires_at']) : null,
        autoDeleteAfterExpiry: pollResponse['auto_delete_after_expiry'] ?? false,
      );
    } catch (e) {
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
      String? createdBy;

      // Create or find user if not anonymous
      if (!isAnonymous && creatorName != null && creatorName.isNotEmpty) {
        final userResult = await client.rpc('create_or_get_user', params: {
          'user_name': creatorName,
        });
        createdBy = userResult.toString();
      }

      // Create poll
      final pollResponse = await client
          .from('polls')
          .insert({
            'title': title,
            'description': description ?? '',
            'is_anonymous': isAnonymous,
            'allows_multiple_votes': allowsMultipleVotes,
            'expires_at': expiresAt?.toIso8601String(),
            'auto_delete_after_expiry': autoDeleteAfterExpiry,
            'created_by': createdBy,
            'created_by_name': creatorName,
          })
          .select()
          .single();

      final pollId = pollResponse['id'];

      // Create options
      final optionsData = optionTexts
          .asMap()
          .entries
          .map((entry) => {
                'poll_id': pollId,
                'text': entry.value,
                'votes': 0,
                'option_order': entry.key + 1,
              })
          .toList();

      final optionsResponse = await client.from('poll_options').insert(optionsData).select();

      final options = (optionsResponse as List).map((optionData) {
        return PollOptionModel(
          id: optionData['id'].toString(),
          text: optionData['text'] ?? '',
          votes: optionData['votes'] ?? 0,
          order: optionData['option_order'] ?? 0,
        );
      }).toList();

      return PollModel(
        id: pollId.toString(),
        title: title,
        description: description,
        options: options,
        isAnonymous: isAnonymous,
        allowsMultipleVotes: allowsMultipleVotes,
        createdByName: creatorName,
        createdBy: createdBy,
        createdAt: DateTime.parse(pollResponse['created_at']),
        expiresAt: expiresAt,
        autoDeleteAfterExpiry: autoDeleteAfterExpiry,
      );
    } catch (e) {
      throw ServerFailure(message: 'Failed to create poll: $e');
    }
  }

  @override
  Future<PollModel> updatePoll(PollModel poll) async {
    try {
      final pollResponse = await client
          .from('polls')
          .update({
            'title': poll.title,
            'description': poll.description,
            'is_anonymous': poll.isAnonymous,
            'allows_multiple_votes': poll.allowsMultipleVotes,
            'expires_at': poll.expiresAt?.toIso8601String(),
            'auto_delete_after_expiry': poll.autoDeleteAfterExpiry,
          })
          .eq('id', poll.id)
          .select()
          .single();

      // Update options if needed
      for (final option in poll.options) {
        await client.from('poll_options').update({
          'text': option.text,
          'votes': option.votes,
        }).eq('id', option.id);
      }

      return await getPoll(poll.id);
    } catch (e) {
      throw ServerFailure(message: 'Failed to update poll: $e');
    }
  }

  @override
  Future<void> deletePoll(String pollId) async {
    try {
      await client.from('polls').delete().eq('id', pollId);
    } catch (e) {
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
      await client.rpc('cast_vote', params: {
        'p_poll_id': int.parse(pollId),
        'p_option_id': int.parse(optionId),
        'p_user_name': voterName,
        'p_is_anonymous': isAnonymous,
      });
    } catch (e) {
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
    try {
      for (final optionId in optionIds) {
        await castVote(
          pollId: pollId,
          optionId: optionId,
          voterName: voterName,
          isAnonymous: isAnonymous,
        );
      }
    } catch (e) {
      throw ServerFailure(message: 'Failed to cast multiple votes: $e');
    }
  }

  @override
  Future<int> cleanupExpiredPolls() async {
    try {
      final result = await client.rpc('cleanup_expired_polls');
      return result as int;
    } catch (e) {
      throw ServerFailure(message: 'Failed to cleanup expired polls: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getPollStatus(String pollId) async {
    try {
      final result = await client.rpc('get_poll_status', params: {
        'poll_id': pollId,
      });
      return Map<String, dynamic>.from(result);
    } catch (e) {
      throw ServerFailure(message: 'Failed to get poll status: $e');
    }
  }
}
