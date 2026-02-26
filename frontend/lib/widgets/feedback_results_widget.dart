import 'package:flutter/material.dart';
import 'package:pollino/services/api_service.dart';
import 'package:pollino/core/localization/i18n_service.dart';

/// Widget for displaying feedback results and AI summary in the admin screen.
class FeedbackResultsWidget extends StatefulWidget {
  final String pollId;
  final String adminToken;

  const FeedbackResultsWidget({
    super.key,
    required this.pollId,
    required this.adminToken,
  });

  @override
  State<FeedbackResultsWidget> createState() => _FeedbackResultsWidgetState();
}

class _FeedbackResultsWidgetState extends State<FeedbackResultsWidget> {
  bool _isLoading = true;
  bool _isLoadingSummary = false;
  bool _isRegenerating = false;
  String? _error;
  Map<String, dynamic>? _results;
  Map<String, dynamic>? _aiSummary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await ApiService.getFeedbackResults(
        widget.pollId,
        widget.adminToken,
      );

      Map<String, dynamic>? summary;
      try {
        summary = await ApiService.getAiSummary(
          widget.pollId,
          widget.adminToken,
        );
      } catch (_) {
        // AI summary may not be available
      }

      if (mounted) {
        setState(() {
          _results = results;
          _aiSummary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _regenerateSummary() async {
    setState(() => _isRegenerating = true);
    try {
      await ApiService.regenerateAiSummary(
        widget.pollId,
        widget.adminToken,
      );
      // Wait a bit for generation to start, then poll
      await Future.delayed(const Duration(seconds: 3));
      await _loadSummary();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegenerating = false);
    }
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoadingSummary = true);
    try {
      final summary = await ApiService.getAiSummary(
        widget.pollId,
        widget.adminToken,
      );
      if (mounted) {
        setState(() {
          _aiSummary = summary;
          _isLoadingSummary = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSummary = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Text(_error!, style: TextStyle(color: Colors.red[700])),
      );
    }

    if (_results == null) return const SizedBox.shrink();

    final responseCount = _results!['responseCount'] ?? 0;
    final questions = (_results!['questions'] as List?) ?? [];
    final responses = (_results!['responses'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Response count header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.feedback_outlined,
                  color: Color(0xFF4F46E5), size: 24),
              const SizedBox(width: 12),
              Text(
                I18nService.instance.translate(
                  'feedback.results.responseCount',
                  params: {'count': '$responseCount'},
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // AI Summary Section
        _buildAiSummarySection(),

        const SizedBox(height: 24),

        // Individual question results
        Text(
          I18nService.instance.translate('feedback.results.detailedTitle'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),

        ...questions.map((q) => _buildQuestionResults(q, responses)),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAiSummarySection() {
    final summaryAvailable =
        _aiSummary != null && (_aiSummary!['available'] == true);
    final summaryText = _aiSummary?['summaryText'] as String?;
    final responseCount = _aiSummary?['responseCount'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4F46E5).withOpacity(0.03),
            const Color(0xFF7C3AED).withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Color(0xFF4F46E5), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      I18nService.instance.translate('feedback.ai.title'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    if (responseCount != null)
                      Text(
                        I18nService.instance.translate(
                          'feedback.ai.basedOn',
                          params: {'count': '$responseCount'},
                        ),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
              if (summaryAvailable)
                IconButton(
                  onPressed: _isRegenerating ? null : _regenerateSummary,
                  tooltip:
                      I18nService.instance.translate('feedback.ai.regenerate'),
                  icon: _isRegenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, color: Color(0xFF4F46E5)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingSummary || _isRegenerating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFF4F46E5)),
                    SizedBox(height: 12),
                    Text(
                      '🤖 KI-Zusammenfassung wird erstellt...',
                      style: TextStyle(color: Color(0xFF4F46E5), fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else if (summaryAvailable && summaryText != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: SelectableText(
                summaryText,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: Color(0xFF374151),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.auto_awesome_outlined,
                      color: Colors.grey[400], size: 32),
                  const SizedBox(height: 8),
                  Text(
                    I18nService.instance.translate('feedback.ai.notAvailable'),
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isRegenerating ? null : _regenerateSummary,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(
                      I18nService.instance.translate('feedback.ai.generate'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionResults(dynamic question, List responses) {
    final questionId = question['questionId'] as String? ?? '';
    final questionText = question['questionText'] as String? ?? '';
    final questionType = question['questionType'] as String? ?? '';
    final options = (question['options'] as List?)?.cast<String>() ?? [];

    // Collect all answers for this question
    final List<Map<String, dynamic>> answersForQuestion = [];
    for (final response in responses) {
      final respondentName = response['respondentName'] as String?;
      final answers = (response['answers'] as List?) ?? [];
      for (final answer in answers) {
        if (answer['questionId'] == questionId) {
          answersForQuestion.add({
            'respondentName': respondentName,
            'textAnswer': answer['textAnswer'],
            'selectedOptions': answer['selectedOptions'],
          });
        }
      }
    }

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
            children: [
              Icon(
                _getQuestionIcon(questionType),
                color: const Color(0xFF4F46E5),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  questionText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getQuestionTypeLabel(questionType),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Results
          if (questionType == 'FREE_TEXT')
            _buildFreeTextResults(answersForQuestion)
          else
            _buildChoiceResults(options, answersForQuestion, questionType),
        ],
      ),
    );
  }

  Widget _buildFreeTextResults(List<Map<String, dynamic>> answers) {
    if (answers.isEmpty) {
      return Text(
        I18nService.instance.translate('feedback.results.noAnswers'),
        style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
      );
    }

    return Column(
      children: answers.map((answer) {
        final name = answer['respondentName'] as String?;
        final text = answer['textAnswer'] as String? ?? '';
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE9ECEF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name != null && name.isNotEmpty) ...[
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                text,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChoiceResults(List<String> options,
      List<Map<String, dynamic>> answers, String questionType) {
    // Tally up option selections
    final Map<String, int> optionCounts = {};
    for (final option in options) {
      optionCounts[option] = 0;
    }

    for (final answer in answers) {
      final selected =
          (answer['selectedOptions'] as List?)?.cast<String>() ?? [];
      for (final opt in selected) {
        optionCounts[opt] = (optionCounts[opt] ?? 0) + 1;
      }
    }

    final totalResponses = answers.length;

    return Column(
      children: options.map((option) {
        final count = optionCounts[option] ?? 0;
        final percentage = totalResponses > 0 ? count / totalResponses : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    '$count (${(percentage * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 12,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF4F46E5).withOpacity(0.7 + percentage * 0.3),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getQuestionIcon(String type) {
    switch (type) {
      case 'FREE_TEXT':
        return Icons.text_fields;
      case 'SINGLE_CHOICE':
        return Icons.radio_button_checked;
      case 'MULTIPLE_CHOICE':
        return Icons.check_box;
      default:
        return Icons.help_outline;
    }
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
