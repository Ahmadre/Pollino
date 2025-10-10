import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pollino/bloc/poll_bloc.dart';
import 'package:pollino/bloc/poll.dart';
import 'package:pollino/services/supabase_service.dart';
import 'package:pollino/widgets/poll_form.dart';
import 'package:pollino/core/utils/timezone_helper.dart';
import 'package:pollino/core/localization/i18n_service.dart';
import 'package:routemaster/routemaster.dart';

class EditPollScreen extends StatefulWidget {
  final String pollId;
  final String adminToken;

  const EditPollScreen({
    super.key,
    required this.pollId,
    required this.adminToken,
  });

  @override
  State<EditPollScreen> createState() => _EditPollScreenState();
}

class _EditPollScreenState extends State<EditPollScreen> {
  Poll? _currentPoll;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _validateAndLoadPoll();
  }

  Future<void> _validateAndLoadPoll() async {
    try {
      // Erst das Admin-Token validieren
      final isValidToken = await SupabaseService.validateAdminToken(widget.pollId, widget.adminToken);
      if (!isValidToken) {
        setState(() {
          _errorMessage = I18nService.instance.translate('admin.error.invalidToken');
          _isInitializing = false;
        });
        return;
      }

      // Dann die Umfrage laden
      final poll = await SupabaseService.fetchPoll(widget.pollId);
      setState(() {
        _currentPoll = poll;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '${I18nService.instance.translate('admin.error.loadFailed')}: ${e.toString()}';
        _isInitializing = false;
      });
    }
  }

  Future<void> _updatePoll(PollFormData formData) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Konvertiere lokale Expiration-Zeit zu UTC für Database-Speicherung
      DateTime? expiresAtUtc;
      if (formData.hasExpirationDate && formData.selectedExpirationDate != null) {
        expiresAtUtc = TimezoneHelper.localToUtc(formData.selectedExpirationDate!);
      }

      final updatedPoll = await SupabaseService.updatePoll(
        pollId: widget.pollId,
        adminToken: widget.adminToken,
        title: formData.question,
        optionTexts: formData.options,
        isAnonymous: formData.enableAnonymousVoting,
        allowsMultipleVotes: formData.allowMultipleOptions,
        expiresAt: expiresAtUtc,
        autoDeleteAfterExpiry: formData.hasExpirationDate ? formData.autoDeleteAfterExpiry : false,
        creatorName: formData.enableAnonymousVoting ? null : formData.creatorName,
      );

      if (mounted) {
        // Aktualisiere den Bloc
        context.read<PollBloc>().add(const PollEvent.refreshPolls());

        // Zeige Erfolgs-Dialog
        _showSuccessDialog(updatedPoll);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${I18nService.instance.translate('edit.error')}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showSuccessDialog(Poll updatedPoll) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(I18nService.instance.translate('edit.success.title')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              I18nService.instance.translate('edit.success.description'),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0EA5E9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    updatedPoll.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0369A1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${updatedPoll.options.length} ${I18nService.instance.translate('poll.options')}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0369A1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigiere zur Umfrage
              Routemaster.of(context).push('/poll/${widget.pollId}');
            },
            child: Text(I18nService.instance.translate('edit.success.viewPoll')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigiere zurück zur Admin-Seite
              Routemaster.of(context).push('/admin/${widget.pollId}/${widget.adminToken}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: Text(I18nService.instance.translate('edit.success.backToAdmin')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                  Text(
                    I18nService.instance.translate('edit.title'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 24), // Balance for back button
                ],
              ),
            ),

            // Content
            Flexible(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isInitializing) {
      return const Center(
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
      );
    }

    if (_errorMessage != null) {
      return Center(
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
              _errorMessage!,
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
      );
    }

    if (_currentPoll == null) {
      return Center(
        child: Text(
          I18nService.instance.translate('edit.error.pollNotFound'),
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    // Zeige das Bearbeitungsformular
    return PollForm(
      initialData: PollFormData.fromPoll(_currentPoll!),
      isEditMode: true,
      onSubmit: _updatePoll,
      isLoading: _isLoading,
    );
  }
}
