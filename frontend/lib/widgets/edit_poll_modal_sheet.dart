import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pollino/widgets/poll_primary_button.dart';
import 'package:routemaster/routemaster.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:pollino/bloc/poll_bloc.dart';
import 'package:pollino/bloc/edit_poll_bloc.dart';
import 'package:pollino/widgets/poll_form.dart';
import 'package:pollino/core/localization/i18n_service.dart';

class EditPollModalSheet {
  /// Shows the edit poll modal sheet
  static Future<void> show(
    BuildContext context, {
    required String pollId,
    required String adminToken,
  }) {
    return WoltModalSheet.show<void>(
      context: context,
      pageListBuilder: (modalSheetContext) {
        final bloc = EditPollBloc(
          pollId: pollId,
          adminToken: adminToken,
        )..add(const EditPollEvent.loadPoll());

        return [
          _buildEditPollPage(modalSheetContext, bloc),
          _buildSuccessPage(modalSheetContext, bloc),
        ];
      },
      modalTypeBuilder: (context) {
        final size = MediaQuery.of(context).size;
        if (size.width < 600) {
          return WoltModalType.bottomSheet();
        } else {
          return WoltModalType.dialog();
        }
      },
      onModalDismissedWithBarrierTap: () {
        Navigator.of(context).pop();
      },
    );
  }

  static WoltModalSheetPage _buildEditPollPage(BuildContext context, EditPollBloc bloc) {
    return WoltModalSheetPage(
      hasSabGradient: false,
      topBarTitle: Text(
        I18nService.instance.translate('edit.title'),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      isTopBarLayerAlwaysVisible: true,
      trailingNavBarWidget: IconButton(
        padding: const EdgeInsets.all(8),
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(),
      ),
      stickyActionBar: BlocProvider.value(
        value: bloc,
        child: BlocBuilder<EditPollBloc, EditPollState>(
          builder: (context, state) {
            if (state is! EditPollLoaded) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: PollPrimaryButton(
                isLoading: state is EditPollUpdating,
                label: I18nService.instance.translate('actions.update'),
                onSubmit: () => _handleSubmitFromStickyBar(context),
              ),
            );
          },
        ),
      ),
      child: BlocProvider.value(
        value: bloc,
        child: const _EditPollContent(),
      ),
    );
  }

  static void _handleSubmitFromStickyBar(BuildContext context) {
    context.read<EditPollBloc>().add(
          const EditPollEvent.updatePoll(),
        );
  }

  static WoltModalSheetPage _buildSuccessPage(BuildContext context, EditPollBloc bloc) {
    return WoltModalSheetPage(
      hasSabGradient: false,
      topBarTitle: Text(
        I18nService.instance.translate('edit.success.title'),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      isTopBarLayerAlwaysVisible: true,
      trailingNavBarWidget: IconButton(
        padding: const EdgeInsets.all(8),
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: BlocProvider.value(
        value: bloc,
        child: const _SuccessContent(),
      ),
    );
  }
}

class _EditPollContent extends StatefulWidget {
  const _EditPollContent();

  @override
  State<_EditPollContent> createState() => _EditPollContentState();
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditPollBloc, EditPollState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.green[600],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  I18nService.instance.translate('edit.success.description'),
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              if (state is EditPollUpdated) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0EA5E9)),
                  ),
                  width: double.maxFinite,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        I18nService.instance.translate('edit.success.updatedPoll'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.updatedPoll.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${state.updatedPoll.options.length} ${I18nService.instance.translate('poll.options')}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (state is EditPollUpdated) {
                          Routemaster.of(context).replace('/poll/${state.updatedPoll.id}');
                        }
                      },
                      child: Text(I18nService.instance.translate('edit.success.viewPoll')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(I18nService.instance.translate('edit.success.backToAdmin')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EditPollContentState extends State<_EditPollContent> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditPollBloc, EditPollState>(
      listener: (context, state) {
        state.when(
          initial: () {},
          loading: () {},
          loaded: (poll) {},
          updating: () {},
          updated: (updatedPoll) {
            // Aktualisiere den PollBloc
            context.read<PollBloc>().add(const PollEvent.refreshPolls());

            // Gehe zur Success-Seite
            WoltModalSheet.of(context).showNext();
          },
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Umfrage wird geladen...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            loaded: (poll) => PollForm(
              initialData: PollFormData.fromPoll(poll),
              isEditMode: true,
              controller: context.read<EditPollBloc>().formController,
            ),
            updating: () => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Umfrage wird aktualisiert...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            updated: (updatedPoll) => const Center(
              child: Text('Erfolgreich aktualisiert'),
            ),
            error: (message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(I18nService.instance.translate('actions.back')),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
