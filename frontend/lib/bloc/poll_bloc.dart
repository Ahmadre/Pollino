import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:pollino/bloc/poll.dart';
import 'package:pollino/services/supabase_service.dart';

part 'poll_bloc.freezed.dart';

@freezed
class PollEvent with _$PollEvent {
  const factory PollEvent.loadPolls({required int page, required int limit}) = LoadPolls;
  const factory PollEvent.refreshPolls() = RefreshPolls;
  const factory PollEvent.loadPoll(String pollId) = LoadPoll;
  const factory PollEvent.loadMore({required int page, required int limit}) = LoadMore;
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
        // Try fetching from Supabase database
        final response = await SupabaseService.fetchPolls(event.page, event.limit);
        final polls = response['polls'] as List<Poll>;
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
        final response = await SupabaseService.fetchPolls(1, 10);
        final polls = response['polls'] as List<Poll>;
        final total = response['total'];
        emit(PollState.loaded(polls, polls.length < total));
      } catch (e) {
        emit(PollState.error(e.toString()));
      }
    });

    on<LoadPoll>((event, emit) async {
      emit(const PollState.loading());
      try {
        final poll = await SupabaseService.fetchPoll(event.pollId);
        emit(PollState.loaded([poll], false));
      } catch (e) {
        emit(PollState.error(e.toString()));
      }
    });

    on<LoadMore>((event, emit) async {
      if (state is Loaded) {
        final currentState = state as Loaded;
        try {
          final response = await SupabaseService.fetchPolls(event.page, event.limit);
          final newPolls = response['polls'] as List<Poll>;
          final total = response['total'];
          emit(PollState.loaded(currentState.polls + newPolls, currentState.polls.length + newPolls.length < total));
        } catch (e) {
          emit(PollState.error(e.toString()));
        }
      }
    });

    on<Vote>((event, emit) async {
      emit(PollState.loading());
      try {
        // Send vote to Supabase database
        await SupabaseService.sendVote(event.pollId, event.optionId);

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
          emit(PollState.loaded([updatedPoll], false));
        }
      } catch (e) {
        emit(PollState.error('Failed to submit vote: ${e.toString()}'));
      }
    });
  }

  Future<void> synchronizeWithBackend() async {
    try {
      final cachedPolls = hiveBox.values.toList();
      // Synchronize with Supabase database
      await SupabaseService.synchronizePolls(cachedPolls);
      add(const LoadPolls(page: 1, limit: 10)); // Reload polls after sync
    } catch (e) {
      debugPrint('Failed to synchronize with Supabase: ${e.toString()}');
    }
  }
}
