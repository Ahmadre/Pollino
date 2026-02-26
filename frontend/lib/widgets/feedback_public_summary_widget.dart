import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:pollino/services/api_service.dart';
import 'package:pollino/core/localization/i18n_service.dart';

/// Public-facing AI summary widget shown to all participants on the poll page.
/// Loads summary without requiring an admin token.
class FeedbackPublicSummaryWidget extends StatefulWidget {
  final String pollId;

  const FeedbackPublicSummaryWidget({super.key, required this.pollId});

  @override
  State<FeedbackPublicSummaryWidget> createState() =>
      _FeedbackPublicSummaryWidgetState();
}

class _FeedbackPublicSummaryWidgetState
    extends State<FeedbackPublicSummaryWidget> {
  bool _isLoading = true;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getPublicAiSummary(widget.pollId);
      if (mounted) {
        setState(() {
          _summary = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _summary?['available'] == true;
    final summaryText = _summary?['summaryText'] as String?;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4F46E5).withOpacity(0.04),
            const Color(0xFF7C3AED).withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Color(0xFF4F46E5), size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  I18nService.instance.translate('feedback.ai.title'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildBody(available, summaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool available, String? summaryText) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(
            color: Color(0xFF4F46E5),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (available && summaryText != null && summaryText.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: MarkdownBody(
          data: summaryText,
          selectable: true,
          extensionSet: md.ExtensionSet(
            md.ExtensionSet.gitHubFlavored.blockSyntaxes,
            <md.InlineSyntax>[
              md.EmojiSyntax(),
              ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
            ],
          ),
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              fontSize: 14,
              height: 1.7,
              color: Color(0xFF374151),
            ),
            h2: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E1B4B),
            ),
            h3: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1B4B),
            ),
            strong: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
            em: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Color(0xFF374151),
            ),
            listBullet: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4F46E5),
            ),
            blockSpacing: 6,
            listIndent: 18,
            horizontalRuleDecoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE9ECEF), width: 1),
              ),
            ),
          ),
        ),
      );
    }

    // Not yet available
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_outlined, color: Colors.grey[400], size: 28),
          const SizedBox(height: 8),
          Text(
            I18nService.instance.translate('feedback.ai.notAvailable'),
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
