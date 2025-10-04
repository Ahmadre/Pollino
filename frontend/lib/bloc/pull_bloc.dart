import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:pollino/bloc/poll.dart';
import 'package:pollino/env.dart';

part 'pull_bloc.freezed.dart';

@freezed
class PollEvent with _$PollEvent {
  const factory PollEvent.loadPolls({required int page, required int limit}) =
      LoadPolls;
  const factory PollEvent.refreshPolls() = RefreshPolls;
  const factory PollEvent.loadPoll(String pollId) = LoadPoll;
  const factory PollEvent.loadMore({required int page, required int limit}) =
      LoadMore;
  const factory PollEvent.vote(String pollId, String optionId) = Vote;
}

@freezed
class PollState with _$PollState {
  const factory PollState.initial() = Initial;
  const factory PollState.loading() = Loading;
  const factory PollState.loaded(List<Poll> polls, bool hasMore) = Loaded;
  const factory PollState.error(String message) = Error;
}

class PollBloc extends Bloc<PollEvent, PollState> {
  final Box<Poll> hiveBox;
  PollBloc(this.hiveBox) : super(const PollState.initial()) {
    on<LoadPolls>((event, emit) async {
      emit(const PollState.loading());
    try {
      // Try fetching from backend
      final response = await fetchPolls(event.page, event.limit);
      final polls = (response['polls'] as List)
          .map((poll) => Poll.fromJson(poll))
          .toList();
      final total = response['total'];

      // Cache results in Hive
      await hiveBox.clear();
      for (var poll in polls) {
        hiveBox.put(poll.id, poll);
      }

      emit(PollState.loaded(polls, polls.length < total));
    } catch (e) {
      // Fallback to Hive if backend is unreachable
      final cachedPolls = hiveBox.values.toList();
      if (cachedPolls.isNotEmpty) {
        emit(PollState.loaded(cachedPolls, false));
      } else {
        emit(PollState.error('Failed to load polls: ${e.toString()}'));
      }
    }
    });

    on<RefreshPolls>((event, emit) async {
      emit(const PollState.loading());
      try {
        final response = await fetchPolls(1, 10);
        final polls = response['polls'];
        final total = response['total'];
        emit(PollState.loaded(polls, polls.length < total));
      } catch (e) {
        emit(PollState.error(e.toString()));
      }
    });

    on<LoadPoll>((event, emit) async {
      emit(const PollState.loading());
      try {
        final poll = await fetchPoll(event.pollId);
        emit(PollState.loaded([poll], false));
      } catch (e) {
        emit(PollState.error(e.toString()));
      }
    });

    on<LoadMore>((event, emit) async {
      if (state is Loaded) {
        final currentState = state as Loaded;
        try {
          final response = await fetchPolls(event.page, event.limit);
          final newPolls = response['polls'];
          final total = response['total'];
          emit(
            PollState.loaded(
              currentState.polls + newPolls,
              currentState.polls.length + newPolls.length < total,
            ),
          );
        } catch (e) {
          emit(PollState.error(e.toString()));
        }
      }
    });

    on<Vote>((event, emit) async {
      try {
      // Try sending vote to backend
      await sendVote(event.pollId, event.optionId);

      // Update local cache
      final poll = hiveBox.get(event.pollId);
      if (poll != null) {
        final updatedOptions = poll.options.map((option) {
          if (option.id == event.optionId) {
            return option.copyWith(votes: option.votes + 1);
          }
          return option;
        }).toList();
        final updatedPoll = poll.copyWith(options: updatedOptions);
        hiveBox.put(event.pollId, updatedPoll);
      }

      add(LoadPolls(page: 1, limit: 10)); // Reload polls
    } catch (e) {
      emit(PollState.error('Failed to submit vote: ${e.toString()}'));
    }
    });
  }

  Future<void> synchronizeWithBackend() async {
    try {
      final cachedPolls = hiveBox.values.toList();
      for (var poll in cachedPolls) {
        // Send cached data to backend
        await http.post(
          Uri.parse('$BACKEND_URI/sync'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(poll.toJson()),
        );
      }
      add(LoadPolls(page: 1, limit: 10)); // Reload polls after sync
    } catch (e) {
      debugPrint('Failed to synchronize with backend: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> fetchPolls(int page, int limit) async {
    final response = await http.get(
      Uri.parse('$BACKEND_URI/polls?page=$page&limit=$limit'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load polls');
    }
  }

  Future<Poll> fetchPoll(String pollId) async {
    final response = await http.get(
      Uri.parse('$BACKEND_URI/polls/$pollId'),
    );
    if (response.statusCode == 200) {
      return Poll.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load poll');
    }
  }

  Future<void> sendVote(String pollId, String optionId) async {
    final response = await http.post(
      Uri.parse('$BACKEND_URI/vote'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pollId': pollId, 'optionId': optionId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to submit vote');
    }
  }
}
