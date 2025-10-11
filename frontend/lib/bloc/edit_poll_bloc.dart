import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pollino/bloc/poll.dart';
import 'package:pollino/services/supabase_service.dart';
import 'package:pollino/widgets/poll_form.dart';
import 'package:pollino/core/utils/timezone_helper.dart';

part 'edit_poll_bloc.freezed.dart';

@freezed
class EditPollEvent with _$EditPollEvent {
  const factory EditPollEvent.loadPoll() = LoadPollForEdit;

  const factory EditPollEvent.updatePoll() = UpdatePoll;

  const factory EditPollEvent.reset() = Reset;
}

@freezed
class EditPollState with _$EditPollState {
  const factory EditPollState.initial() = EditPollInitial;
  const factory EditPollState.loading() = EditPollLoading;
  const factory EditPollState.loaded(Poll poll) = EditPollLoaded;
  const factory EditPollState.updating() = EditPollUpdating;
  const factory EditPollState.updated(Poll updatedPoll) = EditPollUpdated;
  const factory EditPollState.error(String message) = EditPollError;
}

class EditPollBloc extends Bloc<EditPollEvent, EditPollState> {
  final String pollId;
  final String adminToken;
  final PollFormController formController = PollFormController();

  EditPollBloc({
    required this.pollId,
    required this.adminToken,
  }) : super(const EditPollState.initial()) {
    on<LoadPollForEdit>((event, emit) async {
      emit(const EditPollState.loading());
      try {
        // Erst das Admin-Token validieren
        final isValidToken = await SupabaseService.validateAdminToken(pollId, adminToken);
        if (!isValidToken) {
          emit(const EditPollState.error('Ungültiges Admin-Token'));
          return;
        }

        // Dann die Umfrage laden
        final poll = await SupabaseService.fetchPoll(pollId);
        emit(EditPollState.loaded(poll));
      } catch (e) {
        emit(EditPollState.error('Fehler beim Laden der Umfrage: ${e.toString()}'));
      }
    });

    on<UpdatePoll>((event, emit) async {
      emit(const EditPollState.updating());
      try {
        // Hole die FormData direkt vom Controller
        final formData = formController.formData;
        if (formData == null) {
          emit(const EditPollState.error('Formulardaten sind ungültig'));
          return;
        }

        // Konvertiere lokale Expiration-Zeit zu UTC für Database-Speicherung
        DateTime? expiresAtUtc;
        if (formData.hasExpirationDate && formData.selectedExpirationDate != null) {
          expiresAtUtc = TimezoneHelper.localToUtc(formData.selectedExpirationDate!);
        }

        final updatedPoll = await SupabaseService.updatePoll(
          pollId: pollId,
          adminToken: adminToken,
          title: formData.question,
          description: formData.description,
          optionTexts: formData.options,
          isAnonymous: formData.enableAnonymousVoting,
          allowsMultipleVotes: formData.allowMultipleOptions,
          expiresAt: expiresAtUtc,
          autoDeleteAfterExpiry: formData.hasExpirationDate ? formData.autoDeleteAfterExpiry : false,
          creatorName: formData.enableAnonymousVoting ? null : formData.creatorName,
        );

        emit(EditPollState.updated(updatedPoll));
      } catch (e) {
        emit(EditPollState.error('Fehler beim Aktualisieren der Umfrage: ${e.toString()}'));
      }
    });

    on<Reset>((event, emit) {
      emit(const EditPollState.initial());
    });
  }
}
