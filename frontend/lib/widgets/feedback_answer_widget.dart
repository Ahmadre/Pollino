import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pollino/bloc/poll.dart';
import 'package:pollino/services/api_service.dart';
import 'package:pollino/core/localization/i18n_service.dart';

/// Widget for answering a feedback poll. Shown on the poll_screen when pollType == FEEDBACK.
class FeedbackAnswerWidget extends StatefulWidget {
  final Poll poll;
  final VoidCallback onSubmitted;

  const FeedbackAnswerWidget({
    super.key,
    required this.poll,
    required this.onSubmitted,
  });

  @override
  State<FeedbackAnswerWidget> createState() => _FeedbackAnswerWidgetState();
}

class _FeedbackAnswerWidgetState extends State<FeedbackAnswerWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  bool _isAnonymous = true;

  // Answers: questionId -> answer data
  final Map<String, TextEditingController> _textAnswers = {};
  final Map<String, List<String>> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    // Initialize answer containers for each question
    for (final q in widget.poll.feedbackQuestions) {
      if (q.questionType == 'FREE_TEXT') {
        _textAnswers[q.id] = TextEditingController();
      } else {
        _selectedOptions[q.id] = [];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _textAnswers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate all questions are answered
    for (final q in widget.poll.feedbackQuestions) {
      if (q.questionType == 'FREE_TEXT') {
        if (_textAnswers[q.id]?.text.trim().isEmpty ?? true) {
          _showError(
              I18nService.instance.translate('feedback.submit.answerRequired'));
          return;
        }
      } else {
        if (_selectedOptions[q.id]?.isEmpty ?? true) {
          _showError(
              I18nService.instance.translate('feedback.submit.selectRequired'));
          return;
        }
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final answers = widget.poll.feedbackQuestions.map((q) {
        if (q.questionType == 'FREE_TEXT') {
          return {
            'questionId': q.id,
            'textAnswer': _textAnswers[q.id]!.text.trim(),
          };
        } else {
          return {
            'questionId': q.id,
            'selectedOptions': _selectedOptions[q.id],
          };
        }
      }).toList();

      await ApiService.submitFeedback(
        pollId: widget.poll.id,
        respondentName: _isAnonymous ? null : _nameController.text.trim(),
        answers: answers,
      );

      if (mounted) {
        setState(() {
          _hasSubmitted = true;
          _isSubmitting = false;
        });
        widget.onSubmitted();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError(e.toString());
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSubmitted) {
      return _buildSuccessView();
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.feedback_outlined,
                    color: Color(0xFF4F46E5), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    I18nService.instance.translate('feedback.info.banner'),
                    style: TextStyle(
                        color: Colors.grey[700], fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Anonymous toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isAnonymous
                        ? I18nService.instance
                            .translate('poll.voting.anonymous')
                        : I18nService.instance.translate('poll.voting.named'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                CupertinoSwitch(
                  value: !_isAnonymous,
                  onChanged: (v) => setState(() => _isAnonymous = !v),
                  activeTrackColor: const Color(0xFF4F46E5),
                ),
              ],
            ),
          ),

          if (!_isAnonymous) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText:
                    I18nService.instance.translate('poll.voting.nameLabel'),
                hintText:
                    I18nService.instance.translate('poll.voting.nameHint'),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Feedback Questions
          ...widget.poll.feedbackQuestions.map((q) => _buildQuestionCard(q)),

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      I18nService.instance.translate('feedback.submit.button'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(FeedbackQuestion question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    '${question.order}',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.questionText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getQuestionTypeLabel(question.questionType),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Answer input
          if (question.questionType == 'FREE_TEXT')
            _buildFreeTextAnswer(question)
          else if (question.questionType == 'SINGLE_CHOICE')
            _buildSingleChoiceAnswer(question)
          else
            _buildMultipleChoiceAnswer(question),
        ],
      ),
    );
  }

  Widget _buildFreeTextAnswer(FeedbackQuestion question) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: TextFormField(
        controller: _textAnswers[question.id],
        maxLines: 4,
        maxLength: 5000,
        decoration: InputDecoration(
          hintText: I18nService.instance.translate('feedback.answer.textHint'),
          hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
          counterStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
        ),
        style: const TextStyle(fontSize: 14, color: Colors.black),
      ),
    );
  }

  Widget _buildSingleChoiceAnswer(FeedbackQuestion question) {
    final selected = _selectedOptions[question.id] ?? [];
    return Column(
      children: question.options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedOptions[question.id] = [option];
            });
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4F46E5).withOpacity(0.08)
                  : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFFE9ECEF),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color:
                      isSelected ? const Color(0xFF4F46E5) : Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isSelected ? const Color(0xFF4F46E5) : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleChoiceAnswer(FeedbackQuestion question) {
    final selected = _selectedOptions[question.id] ?? [];
    return Column(
      children: question.options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () {
            setState(() {
              final list = _selectedOptions[question.id] ?? [];
              if (isSelected) {
                list.remove(option);
              } else {
                list.add(option);
              }
              _selectedOptions[question.id] = list;
            });
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4F46E5).withOpacity(0.08)
                  : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFFE9ECEF),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color:
                      isSelected ? const Color(0xFF4F46E5) : Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          isSelected ? const Color(0xFF4F46E5) : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuccessView() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, color: Colors.green[400], size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            I18nService.instance.translate('feedback.submit.success'),
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            I18nService.instance.translate('feedback.submit.thankYou'),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'FREE_TEXT':
        return I18nService.instance.translate('feedback.type.freeText');
      case 'SINGLE_CHOICE':
        return I18nService.instance.translate('feedback.type.singleChoice');
      case 'MULTIPLE_CHOICE':
        return I18nService.instance.translate('feedback.type.multipleChoice');
      default:
        return type;
    }
  }
}
