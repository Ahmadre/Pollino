import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pollino/core/utils/timezone_helper.dart';
import 'package:pollino/core/widgets/responsive_wrapper.dart';
import 'package:pollino/core/localization/i18n_service.dart';
import 'package:pollino/bloc/poll.dart';

class PollFormData {
  String question;
  String? description;
  List<String> options;
  String? creatorName;
  bool allowMultipleOptions;
  bool enableAnonymousVoting;
  bool hasExpirationDate;
  DateTime? selectedExpirationDate;
  bool autoDeleteAfterExpiry;

  PollFormData({
    this.question = '',
    this.description,
    this.options = const [],
    this.creatorName,
    this.allowMultipleOptions = false,
    this.enableAnonymousVoting = true,
    this.hasExpirationDate = false,
    this.selectedExpirationDate,
    this.autoDeleteAfterExpiry = false,
  });

  factory PollFormData.fromPoll(Poll poll) {
    return PollFormData(
      question: poll.title,
      description: poll.description,
      options: poll.options.map((option) => option.text).toList(),
      creatorName: poll.createdByName,
      allowMultipleOptions: poll.allowsMultipleVotes,
      enableAnonymousVoting: poll.isAnonymous,
      hasExpirationDate: poll.expiresAt != null,
      selectedExpirationDate: poll.expiresAt != null ? TimezoneHelper.utcToLocal(poll.expiresAt!) : null,
      autoDeleteAfterExpiry: poll.autoDeleteAfterExpiry,
    );
  }
}

class PollForm extends StatefulWidget {
  final PollFormData? initialData;
  final bool isEditMode;
  final Function(PollFormData)? onSubmit;
  final PollFormController? controller;

  const PollForm({
    super.key,
    this.initialData,
    this.isEditMode = false,
    this.onSubmit,
    this.controller,
  });

  @override
  State<PollForm> createState() => _PollFormState();
}

class PollFormController {
  _PollFormState? _state;

  bool get isValid => _state?._formKey.currentState?.validate() ?? false;

  PollFormData? get formData => _state?._getFormData();

  void submit() {
    _state?._submitForm();
  }
}

class _PollFormState extends State<PollForm> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _creatorNameController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  bool _allowMultipleOptions = false;
  bool _enableAnonymousVoting = true;
  bool _hasExpirationDate = false;
  DateTime? _selectedExpirationDate;
  bool _autoDeleteAfterExpiry = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _questionController.text = data.question;
      _descriptionController.text = data.description ?? '';
      _creatorNameController.text = data.creatorName ?? '';
      _allowMultipleOptions = data.allowMultipleOptions;
      _enableAnonymousVoting = data.enableAnonymousVoting;
      _hasExpirationDate = data.hasExpirationDate;
      _selectedExpirationDate = data.selectedExpirationDate;
      _autoDeleteAfterExpiry = data.autoDeleteAfterExpiry;

      // Initialize option controllers
      for (String option in data.options) {
        final controller = TextEditingController(text: option);
        _optionControllers.add(controller);
      }

      // Ensure minimum 2 options
      while (_optionControllers.length < 2) {
        _optionControllers.add(TextEditingController());
      }
    } else {
      // Default initialization for create mode
      _addOption();
      _addOption();
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _questionController.dispose();
    _descriptionController.dispose();
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

  void _reorderOptions(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final TextEditingController controller = _optionControllers.removeAt(oldIndex);
      _optionControllers.insert(newIndex, controller);
    });
  }

  void _setExpirationTime(Duration duration) {
    setState(() {
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

  PollFormData? _getFormData() {
    if (!_formKey.currentState!.validate()) return null;

    final question = _questionController.text.trim();
    final options =
        _optionControllers.map((controller) => controller.text.trim()).where((text) => text.isNotEmpty).toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(I18nService.instance.translate('create.validation.optionsMinimum')),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    return PollFormData(
      question: question,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      options: options,
      creatorName: _enableAnonymousVoting ? null : _creatorNameController.text.trim(),
      allowMultipleOptions: _allowMultipleOptions,
      enableAnonymousVoting: _enableAnonymousVoting,
      hasExpirationDate: _hasExpirationDate,
      selectedExpirationDate: _selectedExpirationDate,
      autoDeleteAfterExpiry: _hasExpirationDate ? _autoDeleteAfterExpiry : false,
    );
  }

  void _submitForm() {
    final formData = _getFormData();
    if (formData != null) {
      widget.onSubmit?.call(formData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: ResponsiveContainer(
          type: ResponsiveContainerType.form,
          centerContent: true,
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

              const SizedBox(height: 24),

              // Poll Description (optional)
              Text(
                I18nService.instance.translate('create.description.label'),
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
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: I18nService.instance.translate('create.description.placeholder'),
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

              // Options List - Reorderable
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _optionControllers.length,
                onReorder: _reorderOptions,
                buildDefaultDragHandles: false, // Deaktiviert automatische Drag-Handles
                itemBuilder: (context, index) {
                  return Padding(
                    key: ValueKey('option_$index'),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // Drag handle
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 12),
                          child: ReorderableDragStartListener(
                            index: index,
                            child: Icon(
                              Icons.drag_indicator,
                              color: Colors.grey[600],
                              size: 16,
                            ),
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
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFFE9ECEF),
                                width: _optionControllers[index].text.isNotEmpty ? 2 : 1,
                              ),
                            ),
                            child: TextFormField(
                              controller: _optionControllers[index],
                              onChanged: (value) => setState(() {}),
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
                },
              ),

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
                    CupertinoSwitch(
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
                    CupertinoSwitch(
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
                    CupertinoSwitch(
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
                      CupertinoSwitch(
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

              const SizedBox(height: kToolbarHeight),
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
