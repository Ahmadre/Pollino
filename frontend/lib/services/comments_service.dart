import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class CommentModel {
  final String id;
  final String pollId;
  final String? userName;
  final bool isAnonymous;
  final String content;
  final DateTime createdAt;
  final String? clientId;
  final DateTime? updatedAt;

  CommentModel({
    required this.id,
    required this.pollId,
    required this.userName,
    required this.isAnonymous,
    required this.content,
    required this.createdAt,
    this.clientId,
    this.updatedAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) => CommentModel(
        id: map['id'].toString(),
        pollId: map['poll_id'].toString(),
        userName: map['user_name'],
        isAnonymous: map['is_anonymous'] ?? true,
        content: map['content'] ?? '',
        createdAt: DateTime.parse(map['created_at']).toLocal(),
    clientId: map['client_id'] as String?,
    updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString())?.toLocal() : null,
      );
}

class CommentsService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const _clientIdKey = 'comments_client_id';
  static String? _clientId;

  /// Returns a stable UUID for this device/client used for rate limiting and UI
  static Future<String> _getOrCreateClientId() async {
    if (_clientId != null) return _clientId!;
    // Use a Hive box for lightweight persistent storage
    final box = await Hive.openBox('app_prefs');
    final existing = box.get(_clientIdKey) as String?;
    if (existing != null && existing.isNotEmpty) {
      _clientId = existing;
      return existing;
    }
    final id = const Uuid().v4();
    await box.put(_clientIdKey, id);
    _clientId = id;
    return id;
  }

  /// Expose clientId for UI checks
  static Future<String> get clientId async => _getOrCreateClientId();

  // Stream newest comments first
  static Stream<List<CommentModel>> streamComments(String pollId) {
    return _client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('poll_id', int.tryParse(pollId) ?? pollId)
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
        .eq('poll_id', int.tryParse(pollId) ?? pollId)
        .maybeSingle();
    if (res == null) return 0;
    return (res['comments_count'] as int?) ?? 0;
  }

  static Stream<int> streamCommentsCount(String pollId) {
    return _client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('poll_id', int.tryParse(pollId) ?? pollId)
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
    final clientId = await _getOrCreateClientId();
    await _client.from('comments').insert({
      'poll_id': int.tryParse(pollId) ?? pollId,
      'user_name': isAnonymous ? null : (userName?.trim().isEmpty == true ? null : userName?.trim()),
      'is_anonymous': isAnonymous,
      'content': text,
      'client_id': clientId,
    });
  }

  /// Update a comment content if client_id matches
  static Future<void> updateComment({
    required String commentId,
    required String newContent,
  }) async {
    final text = newContent.trim();
    if (text.isEmpty) {
      throw Exception('Kommentar darf nicht leer sein');
    }
    if (text.length > 1000) {
      throw Exception('Kommentar ist zu lang (max. 1000 Zeichen)');
    }
    final cid = await _getOrCreateClientId();
    // Call secure RPC to edit
    await _client.rpc('edit_comment', params: {
      'p_comment_id': int.tryParse(commentId) ?? commentId,
      'p_client_id': cid,
      'p_content': text,
    },
    // Ensure header reaches RLS/SECURITY DEFINER if needed by logging/edge; params suffice here
    );
  }

  /// Delete a comment if client_id matches
  static Future<void> deleteComment({
    required String commentId,
  }) async {
    final cid = await _getOrCreateClientId();
    await _client.rpc('delete_comment', params: {
      'p_comment_id': int.tryParse(commentId) ?? commentId,
      'p_client_id': cid,
    });
  }
}
