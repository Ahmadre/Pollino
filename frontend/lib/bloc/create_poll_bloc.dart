import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pollino/services/supabase_service.dart';
import 'package:pollino/widgets/poll_form.dart';
import 'package:pollino/core/utils/timezone_helper.dart';

part 'create_poll_bloc.freezed.dart';

@freezed
class CreatePollEvent with _$CreatePollEvent {
  const factory CreatePollEvent.createPoll() = CreatePoll;

  const factory CreatePollEvent.reset() = ResetCreatePoll;
}

@freezed
class CreatePollState with _$CreatePollState {
  const factory CreatePollState.initial() = CreatePollInitial;
  const factory CreatePollState.creating() = CreatePollCreating;
  const factory CreatePollState.created(Map<String, dynamic> pollResult) = CreatePollCreated;
  const factory CreatePollState.error(String message) = CreatePollError;
}

class CreatePollBloc extends Bloc<CreatePollEvent, CreatePollState> {
  final PollFormController formController = PollFormController();

  CreatePollBloc() : super(const CreatePollState.initial()) {
    on<CreatePoll>((event, emit) async {
      emit(const CreatePollState.creating());
      try {
        // Hole die FormData direkt vom Controller
        final formData = formController.formData;
        if (formData == null) {
          emit(const CreatePollState.error('Formulardaten sind ungültig'));
          return;
        }

        // Konvertiere lokale Expiration-Zeit zu UTC für Database-Speicherung
        DateTime? expiresAtUtc;
        if (formData.hasExpirationDate && formData.selectedExpirationDate != null) {
          expiresAtUtc = TimezoneHelper.localToUtc(formData.selectedExpirationDate!);
        }

        final result = await SupabaseService.createPoll(
          title: formData.question,
          optionTexts: formData.options,
          isAnonymous: formData.enableAnonymousVoting,
          allowsMultipleVotes: formData.allowMultipleOptions,
          expiresAt: expiresAtUtc,
          autoDeleteAfterExpiry: formData.hasExpirationDate ? formData.autoDeleteAfterExpiry : false,
          creatorName: formData.enableAnonymousVoting ? null : formData.creatorName,
        );

        emit(CreatePollState.created(result));
      } catch (e) {
        emit(CreatePollState.error('Fehler beim Erstellen der Umfrage: ${e.toString()}'));
      }
    });

    on<ResetCreatePoll>((event, emit) {
      emit(const CreatePollState.initial());
    });
  }
}
