import 'package:supabase_flutter/supabase_flutter.dart';

class CommentModel {
  final String id;
  final String pollId;
  final String? userName;
  final bool isAnonymous;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.pollId,
    required this.userName,
    required this.isAnonymous,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) => CommentModel(
        id: map['id'].toString(),
        pollId: map['poll_id'].toString(),
        userName: map['user_name'],
        isAnonymous: map['is_anonymous'] ?? true,
        content: map['content'] ?? '',
        createdAt: DateTime.parse(map['created_at']).toLocal(),
      );
}

class CommentsService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Stream newest comments first
  static Stream<List<CommentModel>> streamComments(String pollId) {
    return _client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('poll_id', pollId)
        .order('created_at') // stream doesn't support desc reliably; reverse manually
        .map((rows) {
          final list = rows.map(CommentModel.fromMap).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  static Future<int> getCommentsCount(String pollId) async {
    final res = await _client
        .from('comments_count_per_poll')
        .select('comments_count')
        .eq('poll_id', int.parse(pollId))
        .maybeSingle();
    if (res == null) return 0;
    return (res['comments_count'] as int?) ?? 0;
  }

  static Stream<int> streamCommentsCount(String pollId) {
    return _client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('poll_id', int.parse(pollId))
        .map((rows) => rows.length);
  }

  static Future<void> addComment({
    required String pollId,
    required String content,
    String? userName,
    bool isAnonymous = true,
  }) async {
    final text = content.trim();
    if (text.isEmpty) {
      throw Exception('Kommentar darf nicht leer sein');
    }
    if (text.length > 1000) {
      throw Exception('Kommentar ist zu lang (max. 1000 Zeichen)');
    }

    await _client.from('comments').insert({
      'poll_id': int.parse(pollId),
      'user_name': isAnonymous ? null : (userName?.trim().isEmpty == true ? null : userName?.trim()),
      'is_anonymous': isAnonymous,
      'content': text,
    });
  }
}
