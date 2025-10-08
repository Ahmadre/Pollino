import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:pollino/bloc/poll.dart';
import 'package:pollino/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pollino/services/like_service.dart';

part 'poll_bloc.freezed.dart';

@freezed
class PollEvent with _$PollEvent {
  const factory PollEvent.loadPolls({required int page, required int limit}) = LoadPolls;
  const factory PollEvent.refreshPolls() = RefreshPolls;
  const factory PollEvent.loadPoll(String pollId) = LoadPoll;
  const factory PollEvent.loadMore({required int page, required int limit}) = LoadMore;
  const factory PollEvent.vote(String pollId, String optionId) = Vote;
  const factory PollEvent.voteWithName(String pollId, String optionId,
      {@Default(true) bool isAnonymous, String? voterName}) = VoteWithName;
  const factory PollEvent.voteMultiple(String pollId, List<String> optionIds,
      {@Default(true) bool isAnonymous, String? voterName}) = VoteMultiple;
  const factory PollEvent.deletePoll(String pollId) = DeletePoll;
  const factory PollEvent.toggleLike(String pollId) = ToggleLike;
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
        if (event.page == 1) {
          await hiveBox.clear();
        }
        for (var poll in polls) {
          hiveBox.put(poll.id, poll);
        }

        emit(PollState.loaded(polls, polls.length < total));
      } catch (e) {
        debugPrint('Error loading polls from backend: $e');

        // Fallback to Hive if backend is unreachable
        final cachedPolls = hiveBox.values.toList();
        if (cachedPolls.isNotEmpty) {
          debugPrint('Using cached polls: ${cachedPolls.length} polls');
          emit(PollState.loaded(cachedPolls, false));
        } else {
          emit(PollState.error('Fehler beim Laden der Umfragen. Bitte überprüfen Sie Ihre Internetverbindung.'));
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
      try {
        // Send vote to Supabase database
        await SupabaseService.sendVote(event.pollId, event.optionId);

        // Reload all polls to get updated vote counts
        final response = await SupabaseService.fetchPolls(1, 20);
        final polls = response['polls'] as List<Poll>;
        final total = response['total'];

        // Update cache
        await hiveBox.clear();
        for (var poll in polls) {
          hiveBox.put(poll.id, poll);
        }

        emit(PollState.loaded(polls, polls.length < total));
      } catch (e) {
        // Handle duplicate vote gracefully (unique constraint violation)
    final isDuplicate = e is PostgrestException && e.code == '23505' &&
      e.message.contains('user_votes_poll_id_user_id_key');
        if (isDuplicate) {
          // Ignore as "already voted"; keep current state
          debugPrint('Duplicate vote detected, ignoring: ${e.toString()}');
          if (state is Loaded) emit(state);
        } else {
          emit(PollState.error('Failed to submit vote: ${e.toString()}'));
        }
      }
    });

    on<VoteWithName>((event, emit) async {
      try {
        // Send vote to Supabase database with name info
        await SupabaseService.sendVote(
          event.pollId,
          event.optionId,
          voterName: event.voterName,
          isAnonymous: event.isAnonymous,
        );

        debugPrint('Vote submitted successfully for poll ${event.pollId}');

        // Reload all polls to get updated vote counts
        try {
          final response = await SupabaseService.fetchPolls(1, 20);
          final polls = response['polls'] as List<Poll>;
          final total = response['total'];

          // Update cache
          await hiveBox.clear();
          for (var poll in polls) {
            hiveBox.put(poll.id, poll);
          }

          emit(PollState.loaded(polls, polls.length < total));
        } catch (reloadError) {
          debugPrint('Error reloading polls after vote: $reloadError');

          // Fallback: Update only the specific poll locally
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

            // Emit all cached polls
            final allPolls = hiveBox.values.toList();
            emit(PollState.loaded(allPolls, false));
          }
        }
      } catch (e) {
        debugPrint('Error submitting vote: $e');
    final isDuplicate = e is PostgrestException && e.code == '23505' &&
      e.message.contains('user_votes_poll_id_user_id_key');
        if (isDuplicate) {
          // Bereits abgestimmt -> keinen Error-State zeigen
          debugPrint('Duplicate vote (single) ignored to avoid error state');
          if (state is Loaded) emit(state);
        } else {
          emit(PollState.error('Fehler beim Abstimmen: ${e.toString()}'));
        }
      }
    });

    on<VoteMultiple>((event, emit) async {
      try {
        // Send multiple votes to Supabase database
        await SupabaseService.sendMultipleVotes(
          event.pollId,
          event.optionIds,
          voterName: event.voterName,
          isAnonymous: event.isAnonymous,
        );

        debugPrint('Multiple votes submitted successfully for poll ${event.pollId}, options: ${event.optionIds}');

        // Reload all polls to get updated vote counts
        try {
          final response = await SupabaseService.fetchPolls(1, 20);
          final polls = response['polls'] as List<Poll>;
          final total = response['total'];

          // Update cache
          await hiveBox.clear();
          for (var poll in polls) {
            hiveBox.put(poll.id, poll);
          }

          emit(PollState.loaded(polls, polls.length < total));
        } catch (reloadError) {
          debugPrint('Error reloading polls after multiple votes: $reloadError');

          // Fallback: Update the specific poll locally
          final poll = hiveBox.get(event.pollId);
          if (poll != null) {
            final updatedOptions = poll.options.map((option) {
              if (event.optionIds.contains(option.id)) {
                return option.copyWith(votes: option.votes + 1);
              }
              return option;
            }).toList();
            final updatedPoll = poll.copyWith(options: updatedOptions);
            hiveBox.put(event.pollId, updatedPoll);

            // Emit all cached polls
            final allPolls = hiveBox.values.toList();
            emit(PollState.loaded(allPolls, false));
          }
        }
      } catch (e) {
        debugPrint('Error submitting multiple votes: $e');
    final isDuplicate = e is PostgrestException && e.code == '23505' &&
      e.message.contains('user_votes_poll_id_user_id_key');
        if (isDuplicate) {
          // Doppeltes Voten bei MC: Ignorieren oder ggf. einzelne bereits vorhandene Optionen überspringen
          debugPrint('Duplicate vote (multiple) ignored to avoid error state');
          if (state is Loaded) emit(state);
        } else {
          emit(PollState.error('Fehler beim Abstimmen: ${e.toString()}'));
        }
      }
    });

    on<DeletePoll>((event, emit) async {
      try {
        // Lösche Poll in Supabase (CASCADE löscht automatisch Options und Votes)
        await SupabaseService.deletePoll(event.pollId);

        // Entferne Poll aus lokalem Cache
        await hiveBox.delete(event.pollId);

        // Aktualisiere State - entferne Poll aus der aktuellen Liste
        if (state is Loaded) {
          final currentState = state as Loaded;
          final updatedPolls = currentState.polls.where((poll) => poll.id != event.pollId).toList();
          emit(PollState.loaded(updatedPolls, currentState.hasMore));
        }
      } catch (e) {
        emit(PollState.error('Failed to delete poll: ${e.toString()}'));
      }
    });

    on<ToggleLike>((event, emit) async {
      try {
        // Hole den aktuellen Like-Status
        final wasLiked = await LikeService.hasUserMadeLike(event.pollId);

        // Toggle den lokalen Like-Status
        final isNowLiked = await LikeService.toggleLike(event.pollId);

        // Sende Like-Toggle zur Datenbank
        await SupabaseService.toggleLike(event.pollId, wasLiked);

        // Aktualisiere den lokalen State optimistically
        if (state is Loaded) {
          final currentState = state as Loaded;
          final updatedPolls = currentState.polls.map((poll) {
            if (poll.id == event.pollId) {
              return poll.copyWith(
                likesCount: isNowLiked ? poll.likesCount + 1 : poll.likesCount - 1,
              );
            }
            return poll;
          }).toList();

          // Aktualisiere auch den Cache
          final updatedPoll = updatedPolls.firstWhere((poll) => poll.id == event.pollId);
          await hiveBox.put(event.pollId, updatedPoll);

          emit(PollState.loaded(updatedPolls, currentState.hasMore));
        }
      } catch (e) {
        // Bei Fehler: Reverseiere den lokalen Like-Status
        await LikeService.toggleLike(event.pollId);
        emit(PollState.error('Failed to toggle like: ${e.toString()}'));
      }
    });
  }

  Future<void> voteWithName(
    String pollId,
    String optionId, {
    bool isAnonymous = true,
    String? voterName,
  }) async {
    add(PollEvent.voteWithName(
      pollId,
      optionId,
      isAnonymous: isAnonymous,
      voterName: voterName,
    ));
  }
}
