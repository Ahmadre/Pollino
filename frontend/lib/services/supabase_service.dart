import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pollino/bloc/poll.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Lädt Umfragen mit Paginierung
  static Future<Map<String, dynamic>> fetchPolls(int page, int limit) async {
    final offset = (page - 1) * limit;

    try {
      // Zähle die Gesamtanzahl der Umfragen
      final countResponse = await _client.from('polls').select('id').count(CountOption.exact);
      final total = countResponse.count;

      // Hole die Umfragen
      final pollsResponse = await _client
          .from('polls')
          .select('id, title, description, created_at, is_active')
          .eq('is_active', true)
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      debugPrint('Polls response: $pollsResponse');

      // Hole die Optionen für alle Umfragen
      final List<Poll> polls = [];

      for (final pollData in pollsResponse) {
        final pollId = pollData['id'];

        final optionsResponse = await _client
            .from('poll_options')
            .select('id, text, votes')
            .eq('poll_id', pollId)
            .order('id');

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
          .select('id, title, description, created_at, is_active')
          .eq('id', pollId)
          .single();

      debugPrint('Single poll response: $pollResponse');

      // Hole die Optionen für diese Umfrage
      final optionsResponse = await _client
          .from('poll_options')
          .select('id, text, votes')
          .eq('poll_id', pollId)
          .order('id');

      debugPrint('Options response: $optionsResponse');

      final options = (optionsResponse as List).map((optionData) {
        return Option(id: optionData['id'].toString(), text: optionData['text'] ?? '', votes: optionData['votes'] ?? 0);
      }).toList();

      return Poll(
        id: pollResponse['id'].toString(),
        title: pollResponse['title'] ?? '',
        description: pollResponse['description'] ?? '',
        options: options,
      );
    } catch (e) {
      debugPrint('Error in fetchPoll: $e');
      rethrow;
    }
  }

  /// Sendet eine Stimme für eine Umfrageoption
  static Future<void> sendVote(String pollId, String optionId) async {
    // Prüfe ob die Option zur Umfrage gehört
    final optionExists = await _client
        .from('poll_options')
        .select('id')
        .eq('id', optionId)
        .eq('poll_id', pollId)
        .maybeSingle();

    if (optionExists == null) {
      throw Exception('Option nicht in dieser Umfrage gefunden');
    }

    // Erhöhe die Anzahl der Stimmen für diese Option
    await _client.rpc('increment_votes', params: {'option_id': optionId});
  }

  /// Synchronisiert lokale Daten mit Supabase (falls erforderlich)
  static Future<void> synchronizePolls(List<Poll> localPolls) async {
    // Für jedes lokale Poll prüfen, ob es in Supabase existiert, andernfalls hinzufügen oder aktualisieren
    for (final poll in localPolls) {
      // Prüfe, ob die Umfrage existiert
      final existingPoll = await _client.from('polls').select('id').eq('id', poll.id).maybeSingle();

      if (existingPoll == null) {
        // Umfrage existiert nicht, also anlegen
        await _client.from('polls').insert({
          'id': poll.id,
          'title': poll.title,
          'description': poll.description ?? '',
          'is_active': true,
        });
        // Optionen anlegen
        for (final option in poll.options) {
          await _client.from('poll_options').insert({
            'id': option.id,
            'poll_id': poll.id,
            'text': option.text,
            'votes': option.votes,
          });
        }
      } else {
        // Umfrage existiert, ggf. aktualisieren
        await _client
            .from('polls')
            .update({'title': poll.title, 'description': poll.description ?? '', 'is_active': true})
            .eq('id', poll.id);

        // Optionen synchronisieren
        for (final option in poll.options) {
          final existingOption = await _client
              .from('poll_options')
              .select('id')
              .eq('id', option.id)
              .eq('poll_id', poll.id)
              .maybeSingle();

          if (existingOption == null) {
            // Option existiert nicht, anlegen
            await _client.from('poll_options').insert({
              'id': option.id,
              'poll_id': poll.id,
              'text': option.text,
              'votes': option.votes,
            });
          } else {
            // Option existiert, aktualisieren
            await _client
                .from('poll_options')
                .update({'text': option.text, 'votes': option.votes})
                .eq('id', option.id)
                .eq('poll_id', poll.id);
          }
        }
      }
    }
  }

  /// Erstellt eine neue Umfrage (für zukünftige Erweiterungen)
  static Future<Poll> createPoll({
    required String title,
    required List<String> optionTexts,
    String? description,
  }) async {
    // Erstelle die Umfrage
    final pollResponse = await _client
        .from('polls')
        .insert({'title': title, 'description': description ?? ''})
        .select()
        .single();

    final pollId = pollResponse['id'];

    // Erstelle die Optionen
    final optionsData = optionTexts.map((text) => {'poll_id': pollId, 'text': text, 'votes': 0}).toList();

    final optionsResponse = await _client.from('poll_options').insert(optionsData).select();

    // Erstelle die Poll-Instanz
    final options = optionsResponse.map((optionData) {
      return Option(id: optionData['id'].toString(), text: optionData['text'], votes: optionData['votes'] ?? 0);
    }).toList();

    return Poll(id: pollId.toString(), title: title, description: description ?? '', options: options);
  }
}
