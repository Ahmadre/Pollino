import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pollino/bloc/poll_bloc.dart';
import 'package:pollino/services/supabase_service.dart';
import 'package:pollino/widgets/poll_form.dart';
import 'package:pollino/core/utils/timezone_helper.dart';
import 'package:pollino/core/localization/i18n_service.dart';
import 'package:routemaster/routemaster.dart';

class CreatePollScreen extends StatefulWidget {
  const CreatePollScreen({super.key});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  bool _isLoading = false;

  Future<void> _createPoll(PollFormData formData) async {
    setState(() {
      _isLoading = true;
    });

    try {
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

      if (mounted) {
        context.read<PollBloc>().add(const PollEvent.refreshPolls());

        // Zeige Admin-URL Dialog
        _showAdminUrlDialog(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${I18nService.instance.translate('create.error')}: ${e.toString()}'),
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

  Future<void> _showAdminUrlDialog(Map<String, dynamic> result) async {
    final adminUrl = result['admin_url'] as String;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: Color(0xFF4F46E5)),
            const SizedBox(width: 8),
            Text(I18nService.instance.translate('create.admin.title')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              I18nService.instance.translate('create.admin.description'),
              style: const TextStyle(fontSize: 16),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Routemaster.of(context).pop();
            },
            child: Text(I18nService.instance.translate('actions.close')),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: adminUrl));
              Navigator.of(context).pop();
              Routemaster.of(context).pop();
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
                    icon: const Icon(Icons.close, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                  Text(
                    I18nService.instance.translate('create.title'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 24), // Balance for close icon
                ],
              ),
            ),

            // Content
            Flexible(
              child: PollForm(
                onSubmit: _createPoll,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
