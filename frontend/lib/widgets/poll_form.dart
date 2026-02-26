import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pollino/core/utils/timezone_helper.dart';
import 'package:pollino/core/widgets/responsive_wrapper.dart';
import 'package:pollino/core/localization/i18n_service.dart';
import 'package:pollino/bloc/poll.dart';

class FeedbackQuestionData {
  String questionText;
  String questionType; // FREE_TEXT, SINGLE_CHOICE, MULTIPLE_CHOICE
  List<String> options;

  FeedbackQuestionData({
    this.questionText = '',
    this.questionType = 'FREE_TEXT',
    this.options = const [],
  });

  Map<String, dynamic> toJson() => {
        'questionText': questionText,
        'questionType': questionType,
        if (questionType != 'FREE_TEXT') 'options': options,
      };
}

class PollFormData {
  String question;
  String? description;
  String pollType; // STANDARD or FEEDBACK
  List<String> options;
  List<FeedbackQuestionData> feedbackQuestions;
  String? creatorName;
  String? creatorEmail;
  bool allowMultipleOptions;
  bool enableAnonymousVoting;
  bool hasExpirationDate;
  DateTime? selectedExpirationDate;
  bool autoDeleteAfterExpiry;

  PollFormData({
    this.question = '',
    this.description,
    this.pollType = 'STANDARD',
    this.options = const [],
    this.feedbackQuestions = const [],
    this.creatorName,
    this.creatorEmail,
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
      pollType: poll.pollType,
      options: poll.options.map((option) => option.text).toList(),
      creatorName: poll.createdByName,
      allowMultipleOptions: poll.allowsMultipleVotes,
      enableAnonymousVoting: poll.isAnonymous,
      hasExpirationDate: poll.expiresAt != null,
      selectedExpirationDate: poll.expiresAt != null
          ? TimezoneHelper.utcToLocal(poll.expiresAt!)
          : null,
      autoDeleteAfterExpiry: poll.autoDeleteAfterExpiry,
    );
  }

  bool get isFeedback => pollType == 'FEEDBACK';
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
  final _creatorEmailController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  bool _allowMultipleOptions = false;
  bool _enableAnonymousVoting = true;
  bool _hasExpirationDate = false;
  DateTime? _selectedExpirationDate;
  bool _autoDeleteAfterExpiry = false;
  String? _selectedPreset;
  String _pollType = 'STANDARD';
  final List<_FeedbackQuestionState> _feedbackQuestions = [];

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
    _creatorEmailController.dispose();
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
      final TextEditingController controller =
          _optionControllers.removeAt(oldIndex);
      _optionControllers.insert(newIndex, controller);
    });
  }

  void _setExpirationTime(Duration duration, String preset) {
    setState(() {
      _selectedExpirationDate = TimezoneHelper.nowLocal().add(duration);
      _selectedPreset = preset;
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
        initialEntryMode: TimePickerEntryMode.dial,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
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
          _selectedPreset = 'custom';
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
      final timeStr =
          I18nService.instance.translate('time.format.timeOnly', params: {
        'hour': dateTime.hour.toString().padLeft(2, '0'),
        'minute': dateTime.minute.toString().padLeft(2, '0')
      });
      return '${I18nService.instance.translate('time.relative.today')} $timeStr';
    }
  }

  PollFormData? _getFormData() {
    if (!_formKey.currentState!.validate()) return null;

    final question = _questionController.text.trim();

    if (_pollType == 'FEEDBACK') {
      // Validate feedback questions
      final feedbackQuestions = <FeedbackQuestionData>[];
      for (final fq in _feedbackQuestions) {
        final qText = fq.questionController.text.trim();
        if (qText.isEmpty) continue;

        final opts = fq.optionControllers
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList();

        if (fq.questionType != 'FREE_TEXT' && opts.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(I18nService.instance
                  .translate('feedback.validation.optionsMinimum')),
              backgroundColor: Colors.red,
            ),
          );
          return null;
        }

        feedbackQuestions.add(FeedbackQuestionData(
          questionText: qText,
          questionType: fq.questionType,
          options: opts,
        ));
      }

      if (feedbackQuestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(I18nService.instance
                .translate('feedback.validation.questionRequired')),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }

      return PollFormData(
        question: question,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        pollType: 'FEEDBACK',
        options: [],
        feedbackQuestions: feedbackQuestions,
        creatorName:
            _enableAnonymousVoting ? null : _creatorNameController.text.trim(),
        creatorEmail: _creatorEmailController.text.trim().isEmpty
            ? null
            : _creatorEmailController.text.trim(),
        allowMultipleOptions: false,
        enableAnonymousVoting: _enableAnonymousVoting,
        hasExpirationDate: _hasExpirationDate,
        selectedExpirationDate: _selectedExpirationDate,
        autoDeleteAfterExpiry:
            _hasExpirationDate ? _autoDeleteAfterExpiry : false,
      );
    }

    // Standard poll
    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(I18nService.instance
              .translate('create.validation.optionsMinimum')),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    return PollFormData(
      question: question,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      pollType: 'STANDARD',
      options: options,
      creatorName:
          _enableAnonymousVoting ? null : _creatorNameController.text.trim(),
      creatorEmail: _creatorEmailController.text.trim().isEmpty
          ? null
          : _creatorEmailController.text.trim(),
      allowMultipleOptions: _allowMultipleOptions,
      enableAnonymousVoting: _enableAnonymousVoting,
      hasExpirationDate: _hasExpirationDate,
      selectedExpirationDate: _selectedExpirationDate,
      autoDeleteAfterExpiry:
          _hasExpirationDate ? _autoDeleteAfterExpiry : false,
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
                '${I18nService.instance.translate('create.question.label')}*',
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
                    hintText: I18nService.instance
                        .translate('create.question.placeholder'),
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
                      return I18nService.instance
                          .translate('create.validation.questionRequired');
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
                    hintText: I18nService.instance
                        .translate('create.description.placeholder'),
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

              // Poll Type Selector (only in create mode)
              if (!widget.isEditMode) ...[
                Text(
                  I18nService.instance.translate('create.pollType.label'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _pollType = 'STANDARD'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _pollType == 'STANDARD'
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _pollType == 'STANDARD'
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFFE9ECEF),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.poll_outlined,
                                color: _pollType == 'STANDARD'
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                I18nService.instance
                                    .translate('create.pollType.standard'),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _pollType == 'STANDARD'
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _pollType = 'FEEDBACK';
                            if (_feedbackQuestions.isEmpty) {
                              _feedbackQuestions.add(_FeedbackQuestionState());
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _pollType == 'FEEDBACK'
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _pollType == 'FEEDBACK'
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFFE9ECEF),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.feedback_outlined,
                                color: _pollType == 'FEEDBACK'
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                I18nService.instance
                                    .translate('create.pollType.feedback'),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _pollType == 'FEEDBACK'
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],

              // Standard Poll Options
              if (_pollType == 'STANDARD') ...[
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
                  buildDefaultDragHandles: false,
                  itemBuilder: (context, index) {
                    return Padding(
                      key: ValueKey('option_$index'),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
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
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      _optionControllers[index].text.isNotEmpty
                                          ? const Color(0xFF4F46E5)
                                          : const Color(0xFFE9ECEF),
                                  width:
                                      _optionControllers[index].text.isNotEmpty
                                          ? 2
                                          : 1,
                                ),
                              ),
                              child: TextFormField(
                                controller: _optionControllers[index],
                                onChanged: (value) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: I18nService.instance.translate(
                                      'create.options.placeholder',
                                      params: {'number': '${index + 1}'}),
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
                                  if (_pollType == 'STANDARD' &&
                                      (value == null || value.trim().isEmpty)) {
                                    return I18nService.instance.translate(
                                        'create.validation.optionEmpty');
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
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
              ],

              // Feedback Questions Builder
              if (_pollType == 'FEEDBACK') ...[
                Text(
                  I18nService.instance.translate('feedback.questions.title'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                ..._buildFeedbackQuestionWidgets(),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _feedbackQuestions.add(_FeedbackQuestionState());
                    });
                  },
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
                        const Icon(Icons.add,
                            color: Color(0xFF4F46E5), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          I18nService.instance
                              .translate('feedback.questions.add'),
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
              ],

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

              if (_pollType == 'STANDARD') ...[
                // Allow people to choose Multiple Options
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _allowMultipleOptions
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFFE9ECEF),
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
                              I18nService.instance
                                  .translate('create.settings.multiple.title'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              I18nService.instance.translate(
                                  'create.settings.multiple.description'),
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
                        activeTrackColor: const Color(0xFF4F46E5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],

              // Enable Anonymous Voting
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _enableAnonymousVoting
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFE9ECEF),
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
                            I18nService.instance
                                .translate('create.settings.anonymous.title'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            I18nService.instance.translate(
                                'create.settings.anonymous.description'),
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
                      activeTrackColor: const Color(0xFF4F46E5),
                    ),
                  ],
                ),
              ),

              // Creator Name Field (nur wenn nicht anonym)
              if (!_enableAnonymousVoting) ...[
                const SizedBox(height: 20),
                Text(
                  '${I18nService.instance.translate('create.settings.creator.label')}*',
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
                      hintText: I18nService.instance
                          .translate('create.settings.creator.placeholder'),
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
                      if (!_enableAnonymousVoting &&
                          (value == null || value.trim().isEmpty)) {
                        return I18nService.instance
                            .translate('validation.required');
                      }
                      return null;
                    },
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // E-Mail Adresse (optional) - nur beim Erstellen
              if (!widget.isEditMode) ...[
                Text(
                  I18nService.instance.translate('create.email.label'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  I18nService.instance.translate('create.email.description'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
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
                    controller: _creatorEmailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: I18nService.instance
                          .translate('create.email.placeholder'),
                      hintStyle: const TextStyle(
                        color: Color(0xFFADB5BD),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFFADB5BD),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final emailRegex =
                            RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return I18nService.instance
                              .translate('create.email.invalid');
                        }
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
                    color: _hasExpirationDate
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFE9ECEF),
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
                            I18nService.instance
                                .translate('create.expiration.title'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            I18nService.instance
                                .translate('create.expiration.description'),
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
                            _selectedPreset = null;
                          }
                        });
                      },
                      activeTrackColor: const Color(0xFF4F46E5),
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
                        I18nService.instance
                            .translate('create.expiration.customDate'),
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
                            label: I18nService.instance
                                .translate('create.expiration.presets.1hour'),
                            onTap: () => _setExpirationTime(
                                const Duration(hours: 1), '1hour'),
                            isSelected: _selectedPreset == '1hour',
                          ),
                          _ExpirationChip(
                            label: I18nService.instance
                                .translate('create.expiration.presets.1day'),
                            onTap: () => _setExpirationTime(
                                const Duration(days: 1), '1day'),
                            isSelected: _selectedPreset == '1day',
                          ),
                          _ExpirationChip(
                            label: I18nService.instance
                                .translate('create.expiration.presets.1week'),
                            onTap: () => _setExpirationTime(
                                const Duration(days: 7), '1week'),
                            isSelected: _selectedPreset == '1week',
                          ),
                          _ExpirationChip(
                            label: I18nService.instance
                                .translate('create.expiration.presets.custom'),
                            onTap: _selectCustomDateTime,
                            isSelected: _selectedPreset == 'custom',
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
                              Icon(Icons.schedule,
                                  color: Colors.blue[700], size: 20),
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
                                onPressed: () => setState(() {
                                  _selectedExpirationDate = null;
                                  _selectedPreset = null;
                                }),
                                icon: Icon(Icons.close,
                                    color: Colors.blue[700], size: 18),
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
                              I18nService.instance.translate(
                                  'create.expiration.autoDelete.title'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              I18nService.instance.translate(
                                  'create.expiration.autoDelete.description'),
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
                        activeTrackColor: const Color(0xFFFFC107),
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

  // ──────────────────────────────────────────────
  // Feedback Question Builder
  // ──────────────────────────────────────────────

  List<Widget> _buildFeedbackQuestionWidgets() {
    final widgets = <Widget>[];
    for (int i = 0; i < _feedbackQuestions.length; i++) {
      final fq = _feedbackQuestions[i];
      widgets.add(
        Container(
          key: ValueKey('feedback_q_$i'),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE9ECEF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Color(0xFF4F46E5),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${I18nService.instance.translate('feedback.questions.question')} ${i + 1}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (_feedbackQuestions.length > 1)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _feedbackQuestions[i].dispose();
                          _feedbackQuestions.removeAt(i);
                        });
                      },
                      icon:
                          Icon(Icons.close, color: Colors.grey[400], size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Question text input
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE9ECEF)),
                ),
                child: TextFormField(
                  controller: fq.questionController,
                  decoration: InputDecoration(
                    hintText: I18nService.instance
                        .translate('feedback.questions.placeholder'),
                    hintStyle:
                        const TextStyle(color: Color(0xFFADB5BD), fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  style: const TextStyle(fontSize: 15, color: Colors.black),
                  validator: (value) {
                    if (_pollType == 'FEEDBACK' &&
                        (value == null || value.trim().isEmpty)) {
                      return I18nService.instance
                          .translate('feedback.validation.questionRequired');
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Question type selector
              Text(
                I18nService.instance.translate('feedback.questions.type'),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildQuestionTypeChip(
                      i,
                      'FREE_TEXT',
                      I18nService.instance.translate('feedback.type.freeText'),
                      Icons.text_fields),
                  _buildQuestionTypeChip(
                      i,
                      'SINGLE_CHOICE',
                      I18nService.instance
                          .translate('feedback.type.singleChoice'),
                      Icons.radio_button_checked),
                  _buildQuestionTypeChip(
                      i,
                      'MULTIPLE_CHOICE',
                      I18nService.instance
                          .translate('feedback.type.multipleChoice'),
                      Icons.check_box),
                ],
              ),

              // Options for choice questions
              if (fq.questionType != 'FREE_TEXT') ...[
                const SizedBox(height: 12),
                ...List.generate(fq.optionControllers.length, (optIdx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          fq.questionType == 'SINGLE_CHOICE'
                              ? Icons.radio_button_unchecked
                              : Icons.check_box_outline_blank,
                          color: Colors.grey[400],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFE9ECEF)),
                            ),
                            child: TextFormField(
                              controller: fq.optionControllers[optIdx],
                              decoration: InputDecoration(
                                hintText: I18nService.instance.translate(
                                    'feedback.questions.optionPlaceholder',
                                    params: {'number': '${optIdx + 1}'}),
                                hintStyle: const TextStyle(
                                    color: Color(0xFFADB5BD), fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black),
                            ),
                          ),
                        ),
                        if (fq.optionControllers.length > 2)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                fq.optionControllers[optIdx].dispose();
                                fq.optionControllers.removeAt(optIdx);
                              });
                            },
                            icon: Icon(Icons.close,
                                color: Colors.grey[400], size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  );
                }),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      fq.optionControllers.add(TextEditingController());
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.add,
                            color: Color(0xFF4F46E5), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          I18nService.instance
                              .translate('feedback.questions.addOption'),
                          style: const TextStyle(
                            color: Color(0xFF4F46E5),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildQuestionTypeChip(
      int questionIndex, String type, String label, IconData icon) {
    final isSelected = _feedbackQuestions[questionIndex].questionType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _feedbackQuestions[questionIndex].questionType = type;
          // Reset options when switching to FREE_TEXT
          if (type == 'FREE_TEXT') {
            for (final c
                in _feedbackQuestions[questionIndex].optionControllers) {
              c.dispose();
            }
            _feedbackQuestions[questionIndex].optionControllers.clear();
          } else if (_feedbackQuestions[questionIndex]
              .optionControllers
              .isEmpty) {
            _feedbackQuestions[questionIndex]
                .optionControllers
                .addAll([TextEditingController(), TextEditingController()]);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4F46E5).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE9ECEF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[700],
              ),
            ),
          ],
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
            color:
                isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE9ECEF),
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

/// Internal state for a feedback question in the form builder.
class _FeedbackQuestionState {
  final TextEditingController questionController = TextEditingController();
  String questionType = 'FREE_TEXT';
  final List<TextEditingController> optionControllers = [];

  void dispose() {
    questionController.dispose();
    for (final c in optionControllers) {
      c.dispose();
    }
  }
}
