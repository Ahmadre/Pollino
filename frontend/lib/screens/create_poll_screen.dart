import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pollino/bloc/poll_bloc.dart';
import 'package:pollino/services/supabase_service.dart';
import 'package:routemaster/routemaster.dart';
import 'package:pollino/core/utils/timezone_helper.dart';
import 'package:pollino/core/localization/i18n_service.dart';

class CreatePollScreen extends StatefulWidget {
  const CreatePollScreen({super.key});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _creatorNameController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  bool _isLoading = false;
  bool _allowMultipleOptions = false;
  bool _enableAnonymousVoting = true;
  bool _hasExpirationDate = false;
  DateTime? _selectedExpirationDate;
  bool _autoDeleteAfterExpiry = false;

  @override
  void initState() {
    super.initState();
    // Starte mit zwei Optionen
    _addOption();
    _addOption();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _creatorNameController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  void _setExpirationTime(Duration duration) {
    setState(() {
      // Verwende lokale Zeit für User-Interface, wird später zu UTC konvertiert
      _selectedExpirationDate = TimezoneHelper.nowLocal().add(duration);
    });
  }

  Future<void> _selectCustomDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: TimezoneHelper.nowLocal().add(const Duration(days: 1)),
      firstDate: TimezoneHelper.nowLocal(),
      lastDate: TimezoneHelper.nowLocal().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedExpirationDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 0) {
      return I18nService.instance.translate('time.format.dateTime', params: {
        'day': '${dateTime.day}',
        'month': '${dateTime.month}',
        'year': '${dateTime.year}',
        'hour': dateTime.hour.toString().padLeft(2, '0'),
        'minute': dateTime.minute.toString().padLeft(2, '0')
      });
    } else {
      final timeStr = I18nService.instance.translate('time.format.timeOnly', params: {
        'hour': dateTime.hour.toString().padLeft(2, '0'),
        'minute': dateTime.minute.toString().padLeft(2, '0')
      });
      return '${I18nService.instance.translate('time.relative.today')} $timeStr';
    }
  }

  Future<void> _createPoll() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final question = _questionController.text.trim();
      final options =
          _optionControllers.map((controller) => controller.text.trim()).where((text) => text.isNotEmpty).toList();

      if (options.length < 2) {
        throw Exception(I18nService.instance.translate('create.validation.optionsMinimum'));
      }

      // Konvertiere lokale Expiration-Zeit zu UTC für Database-Speicherung
      DateTime? expiresAtUtc;
      if (_hasExpirationDate && _selectedExpirationDate != null) {
        expiresAtUtc = TimezoneHelper.localToUtc(_selectedExpirationDate!);
      }

      await SupabaseService.createPoll(
        title: question,
        optionTexts: options,
        isAnonymous: _enableAnonymousVoting,
        allowsMultipleVotes: _allowMultipleOptions,
        expiresAt: expiresAtUtc,
        autoDeleteAfterExpiry: _hasExpirationDate ? _autoDeleteAfterExpiry : false,
        creatorName: _enableAnonymousVoting ? null : _creatorNameController.text.trim(),
      );

      if (mounted) {
        context.read<PollBloc>().add(const PollEvent.refreshPolls());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(I18nService.instance.translate('create.success')),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        Routemaster.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
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

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ask a Question
                      Text(
                        I18nService.instance.translate('create.question.label') + '*',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE9ECEF)),
                        ),
                        child: TextFormField(
                          controller: _questionController,
                          decoration: InputDecoration(
                            hintText: I18nService.instance.translate('create.question.placeholder'),
                            hintStyle: const TextStyle(
                              color: Color(0xFFADB5BD),
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return I18nService.instance.translate('create.validation.questionRequired');
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Poll Options
                      Text(
                        I18nService.instance.translate('create.options.title'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Options List
                      ...List.generate(_optionControllers.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              // Drag handle
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(right: 12),
                                child: Icon(
                                  Icons.drag_indicator,
                                  color: Colors.grey[400],
                                  size: 16,
                                ),
                              ),

                              // Option input
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _optionControllers[index].text.isNotEmpty
                                          ? const Color(0xFF4F46E5) // Blaue Umrandung wenn aktiv
                                          : const Color(0xFFE9ECEF), // Graue Umrandung wenn leer
                                      width: _optionControllers[index].text.isNotEmpty ? 2 : 1,
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: _optionControllers[index],
                                    onChanged: (value) => setState(() {}), // Aktualisiere UI bei Eingabe
                                    decoration: InputDecoration(
                                      hintText: I18nService.instance
                                          .translate('create.options.placeholder', params: {'number': '${index + 1}'}),
                                      hintStyle: const TextStyle(
                                        color: Color(0xFFADB5BD),
                                        fontSize: 16,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return I18nService.instance.translate('create.validation.optionEmpty');
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),

                              // Remove button
                              if (_optionControllers.length > 2)
                                IconButton(
                                  onPressed: () => _removeOption(index),
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),

                      // Add Another Option
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _addOption,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE9ECEF)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add,
                                color: Color(0xFF4F46E5),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                I18nService.instance.translate('create.options.add'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF4F46E5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Poll Settings
                      Text(
                        I18nService.instance.translate('create.settings.title'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Allow people to choose Multiple Options
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _allowMultipleOptions ? const Color(0xFF4F46E5) : const Color(0xFFE9ECEF),
                            width: _allowMultipleOptions ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    I18nService.instance.translate('create.settings.multiple.title'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    I18nService.instance.translate('create.settings.multiple.description'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _allowMultipleOptions,
                              onChanged: (value) {
                                setState(() {
                                  _allowMultipleOptions = value;
                                });
                              },
                              activeColor: const Color(0xFF4F46E5),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Enable Anonymous Voting
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _enableAnonymousVoting ? const Color(0xFF4F46E5) : const Color(0xFFE9ECEF),
                            width: _enableAnonymousVoting ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    I18nService.instance.translate('create.settings.anonymous.title'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    I18nService.instance.translate('create.settings.anonymous.description'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _enableAnonymousVoting,
                              onChanged: (value) {
                                setState(() {
                                  _enableAnonymousVoting = value;
                                });
                              },
                              activeColor: const Color(0xFF4F46E5),
                            ),
                          ],
                        ),
                      ),

                      // Creator Name Field (nur wenn nicht anonym)
                      if (!_enableAnonymousVoting) ...[
                        const SizedBox(height: 20),
                        Text(
                          I18nService.instance.translate('create.settings.creator.label') + '*',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE9ECEF)),
                          ),
                          child: TextFormField(
                            controller: _creatorNameController,
                            decoration: InputDecoration(
                              hintText: I18nService.instance.translate('create.settings.creator.placeholder'),
                              hintStyle: const TextStyle(
                                color: Color(0xFFADB5BD),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: Color(0xFFADB5BD),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            validator: (value) {
                              if (!_enableAnonymousVoting && (value == null || value.trim().isEmpty)) {
                                return I18nService.instance.translate('validation.required');
                              }
                              return null;
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Set an Expiration Date & Time
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hasExpirationDate ? const Color(0xFF4F46E5) : const Color(0xFFE9ECEF),
                            width: _hasExpirationDate ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    I18nService.instance.translate('create.expiration.title'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    I18nService.instance.translate('create.expiration.description'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _hasExpirationDate,
                              onChanged: (value) {
                                setState(() {
                                  _hasExpirationDate = value;
                                  if (!value) {
                                    _selectedExpirationDate = null;
                                    _autoDeleteAfterExpiry = false;
                                  }
                                });
                              },
                              activeColor: const Color(0xFF4F46E5),
                            ),
                          ],
                        ),
                      ),

                      // Expiration Date Settings (nur wenn aktiviert)
                      if (_hasExpirationDate) ...[
                        const SizedBox(height: 20),

                        // Date & Time Picker
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE9ECEF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                I18nService.instance.translate('create.expiration.customDate'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Quick Options
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _ExpirationChip(
                                    label: I18nService.instance.translate('create.expiration.presets.1hour'),
                                    onTap: () => _setExpirationTime(const Duration(hours: 1)),
                                    isSelected: _selectedExpirationDate != null &&
                                        _selectedExpirationDate!.difference(DateTime.now()).inHours == 1,
                                  ),
                                  _ExpirationChip(
                                    label: I18nService.instance.translate('create.expiration.presets.1day'),
                                    onTap: () => _setExpirationTime(const Duration(days: 1)),
                                    isSelected: _selectedExpirationDate != null &&
                                        _selectedExpirationDate!.difference(DateTime.now()).inDays == 1,
                                  ),
                                  _ExpirationChip(
                                    label: I18nService.instance.translate('create.expiration.presets.1week'),
                                    onTap: () => _setExpirationTime(const Duration(days: 7)),
                                    isSelected: _selectedExpirationDate != null &&
                                        _selectedExpirationDate!.difference(DateTime.now()).inDays == 7,
                                  ),
                                  _ExpirationChip(
                                    label: I18nService.instance.translate('create.expiration.presets.custom'),
                                    onTap: _selectCustomDateTime,
                                    isSelected: false,
                                  ),
                                ],
                              ),

                              if (_selectedExpirationDate != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.schedule, color: Colors.blue[700], size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${I18nService.instance.translate('poll.expiration.expiresAt')}: ${_formatDateTime(_selectedExpirationDate!)}',
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => setState(() => _selectedExpirationDate = null),
                                        icon: Icon(Icons.close, color: Colors.blue[700], size: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Auto-Delete Option
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFC107)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      I18nService.instance.translate('create.expiration.autoDelete.title'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      I18nService.instance.translate('create.expiration.autoDelete.description'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.orange[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _autoDeleteAfterExpiry,
                                onChanged: (value) {
                                  setState(() {
                                    _autoDeleteAfterExpiry = value;
                                  });
                                },
                                activeColor: const Color(0xFFFFC107),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Next Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createPoll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            I18nService.instance.translate('actions.next'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpirationChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const _ExpirationChip({
    required this.label,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE9ECEF),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
