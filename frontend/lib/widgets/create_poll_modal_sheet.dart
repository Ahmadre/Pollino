import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'package:pollino/bloc/poll_bloc.dart';
import 'package:pollino/bloc/poll.dart';
import 'package:pollino/bloc/create_poll_bloc.dart';
import 'package:pollino/widgets/poll_primary_button.dart';
import 'package:pollino/widgets/poll_form.dart';
import 'package:pollino/core/localization/i18n_service.dart';

class CreatePollModalSheet {
  /// Shows the create poll modal sheet
  static Future<void> show(BuildContext context) {
    final bloc = CreatePollBloc();

    return WoltModalSheet.show<void>(
      context: context,
      pageListBuilder: (context) => [
        _buildCreatePollPage(context, bloc),
        _buildSuccessPage(context, bloc),
      ],
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

  static WoltModalSheetPage _buildCreatePollPage(BuildContext context, CreatePollBloc bloc) {
    return WoltModalSheetPage(
      hasSabGradient: false,
      topBarTitle: Text(
        I18nService.instance.translate('create.title'),
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
        child: BlocBuilder<CreatePollBloc, CreatePollState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: PollPrimaryButton(
                isLoading: state is CreatePollCreating,
                label: I18nService.instance.translate('create.submit'),
                onSubmit: () => _handleSubmitFromStickyBar(context),
              ),
            );
          },
        ),
      ),
      child: BlocProvider.value(
        value: bloc,
        child: const _CreatePollContent(),
      ),
    );
  }

  static WoltModalSheetPage _buildSuccessPage(BuildContext context, CreatePollBloc bloc) {
    return WoltModalSheetPage(
      hasSabGradient: false,
      topBarTitle: Text(
        I18nService.instance.translate('create.success.title'),
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
        child: BlocBuilder<CreatePollBloc, CreatePollState>(
          builder: (context, state) {
            if (state is CreatePollCreated) {
              return _SuccessContent(pollResult: state.pollResult);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  static void _handleSubmitFromStickyBar(BuildContext context) {
    context.read<CreatePollBloc>().add(
          const CreatePollEvent.createPoll(),
        );
  }
}

class _CreatePollContent extends StatefulWidget {
  const _CreatePollContent();

  @override
  State<_CreatePollContent> createState() => _CreatePollContentState();
}

class _SuccessContent extends StatelessWidget {
  final Map<String, dynamic> pollResult;

  const _SuccessContent({
    required this.pollResult,
  });

  @override
  Widget build(BuildContext context) {
    final adminUrl = pollResult['admin_url'] as String;
    final poll = pollResult['poll'] as Poll;

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
              I18nService.instance.translate('create.success.description'),
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
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
                  I18nService.instance.translate('create.success.createdPoll'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0369A1),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  poll.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0369A1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  I18nService.instance.translate('create.admin.url'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        adminUrl,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: adminUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(I18nService.instance.translate('create.admin.copied')),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: I18nService.instance.translate('create.admin.copy'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD97706)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Color(0xFFD97706), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    I18nService.instance.translate('create.admin.warning'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to the poll (implement if needed)
                  },
                  child: Text(I18nService.instance.translate('create.success.viewPoll')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: adminUrl));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(I18nService.instance.translate('create.success.withAdmin')),
                          ],
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(I18nService.instance.translate('create.admin.copyAndClose')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreatePollContentState extends State<_CreatePollContent> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreatePollBloc, CreatePollState>(
      listener: (context, state) {
        state.when(
          initial: () {},
          creating: () {},
          created: (pollResult) {
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
          child: PollForm(
            controller: context.read<CreatePollBloc>().formController,
          ),
        );
      },
    );
  }
}
