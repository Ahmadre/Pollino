import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:pollino/env.dart' show Environment;

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

  factory CommentModel.fromJson(Map<String, dynamic> map) => CommentModel(
        id: map['id'].toString(),
        pollId: map['pollId'].toString(),
        userName: map['userName'] as String?,
        isAnonymous: map['anonymous'] as bool? ?? true,
        content: map['content']?.toString() ?? '',
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'].toString()).toLocal()
            : DateTime.now(),
        clientId: map['clientId'] as String?,
        updatedAt: map['updatedAt'] != null
            ? DateTime.tryParse(map['updatedAt'].toString())?.toLocal()
            : null,
      );
}

class CommentsService {
  static String get _baseUrl => Environment.apiBaseUrl;
  static final http.Client _httpClient = http.Client();
  static const _clientIdKey = 'comments_client_id';
  static String? _clientId;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Returns a stable UUID for this device/client
  static Future<String> _getOrCreateClientId() async {
    if (_clientId != null) return _clientId!;
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

  /// Fetch comments for a poll (returns a Future, not a Stream).
  /// The UI should poll this periodically or call it on user interaction.
  static Future<List<CommentModel>> fetchComments(String pollId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/comments/$pollId');
      final response = await _httpClient.get(uri, headers: _headers);
      if (response.statusCode >= 400) {
        throw Exception('Failed to fetch comments: ${response.statusCode}');
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      return [];
    }
  }

  /// Provides a polling-based stream of comments for a poll.
  /// Refreshes every [interval] (default 5 seconds).
  static Stream<List<CommentModel>> streamComments(String pollId,
      {Duration interval = const Duration(seconds: 5)}) {
    late StreamController<List<CommentModel>> controller;
    Timer? timer;

    controller = StreamController<List<CommentModel>>(
      onListen: () async {
        // Fetch immediately
        final comments = await fetchComments(pollId);
        if (!controller.isClosed) controller.add(comments);
        // Then poll periodically
        timer = Timer.periodic(interval, (_) async {
          try {
            final comments = await fetchComments(pollId);
            if (!controller.isClosed) controller.add(comments);
          } catch (e) {
            debugPrint('Error polling comments: $e');
          }
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );

    return controller.stream;
  }

  static Future<int> getCommentsCount(String pollId) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/comments/$pollId/count');
      final response = await _httpClient.get(uri, headers: _headers);
      if (response.statusCode >= 400) return 0;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['count'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('Error getting comments count: $e');
      return 0;
    }
  }

  /// Provides a polling-based stream for comment count.
  static Stream<int> streamCommentsCount(String pollId,
      {Duration interval = const Duration(seconds: 10)}) {
    late StreamController<int> controller;
    Timer? timer;

    controller = StreamController<int>(
      onListen: () async {
        final count = await getCommentsCount(pollId);
        if (!controller.isClosed) controller.add(count);
        timer = Timer.periodic(interval, (_) async {
          try {
            final count = await getCommentsCount(pollId);
            if (!controller.isClosed) controller.add(count);
          } catch (e) {
            debugPrint('Error polling comments count: $e');
          }
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );

    return controller.stream;
  }

  static Future<void> addComment({
    required String pollId,
    required String content,
    String? userName,
    bool isAnonymous = true,
  }) async {
    final text = content.trim();
    if (text.isEmpty) {
      throw Exception('Comment content must not be empty');
    }
    if (text.length > 1000) {
      throw Exception('Comment must not exceed 1000 characters');
    }

    final cId = await _getOrCreateClientId();
    final uri = Uri.parse('$_baseUrl/api/comments/$pollId');
    final body = {
      'content': text,
      'userName': userName,
      'anonymous': isAnonymous,
      'clientId': cId,
    };

    final response =
        await _httpClient.post(uri, headers: _headers, body: jsonEncode(body));
    if (response.statusCode >= 400) {
      throw Exception('Failed to add comment: ${response.statusCode}');
    }
  }

  static Future<void> updateComment({
    required String commentId,
    required String pollId,
    required String content,
  }) async {
    final cId = await _getOrCreateClientId();
    final uri = Uri.parse('$_baseUrl/api/comments/$pollId/$commentId');
    final body = {
      'content': content.trim(),
      'clientId': cId,
    };

    final response =
        await _httpClient.put(uri, headers: _headers, body: jsonEncode(body));
    if (response.statusCode >= 400) {
      throw Exception('Failed to update comment: ${response.statusCode}');
    }
  }

  static Future<void> deleteComment({
    required String commentId,
    required String pollId,
  }) async {
    final cId = await _getOrCreateClientId();
    final uri = Uri.parse(
        '$_baseUrl/api/comments/$pollId/$commentId?clientId=${Uri.encodeComponent(cId)}');
    final response = await _httpClient.delete(uri, headers: _headers);
    if (response.statusCode >= 400) {
      throw Exception('Failed to delete comment: ${response.statusCode}');
    }
  }
}
