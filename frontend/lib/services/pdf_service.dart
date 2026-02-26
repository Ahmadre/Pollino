import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pollino/services/api_service.dart';
import 'package:pollino/bloc/poll.dart';

class PdfService {
  // Public export: limited information without personal data
  static Future<void> exportPublicPoll(String pollId) async {
    final poll = await ApiService.fetchPoll(pollId);
    if (poll.pollType == 'FEEDBACK') {
      await exportPublicFeedbackPoll(pollId);
      return;
    }
    final data = await _loadAggregates(pollId);
    final doc = await _buildPublicDocument(poll, data);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: _safeFileName('poll_${poll.title}_public.pdf'),
    );
  }

  // Admin export: full information including name-based votes
  static Future<void> exportAdminPoll(String pollId,
      {String? adminToken}) async {
    final poll = await ApiService.fetchPoll(pollId);
    if (poll.pollType == 'FEEDBACK' && adminToken != null) {
      await exportAdminFeedbackPoll(pollId, adminToken);
      return;
    }
    final data = await _loadAggregates(pollId, includeNames: true);
    final doc = await _buildAdminDocument(poll, data);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: _safeFileName('poll_${poll.title}_admin.pdf'),
    );
  }

  // ──────────────────────────────────────────────
  // Feedback PDF exports
  // ──────────────────────────────────────────────

  /// Public feedback PDF: poll info, AI summary and questions (no individual answers).
  static Future<void> exportPublicFeedbackPoll(String pollId) async {
    final poll = await ApiService.fetchPoll(pollId);
    Map<String, dynamic>? aiSummary;
    try {
      aiSummary = await ApiService.getPublicAiSummary(pollId);
    } catch (_) {}

    final doc = pw.Document();
    final now = DateTime.now();
    final df = DateFormat('dd.MM.yyyy HH:mm');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          _header('Feedback Export (Öffentlich)', df.format(now)),
          pw.SizedBox(height: 8),
          _pollMeta(poll, public: true),
          pw.SizedBox(height: 6),
          pw.Text(
            '${poll.feedbackResponseCount} Antwort${poll.feedbackResponseCount == 1 ? '' : 'en'}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 14),
          if (aiSummary != null && aiSummary['available'] == true) ...[  
            _sectionTitle('KI-Zusammenfassung'),
            pw.SizedBox(height: 6),
            _summaryBox(aiSummary['summaryText']?.toString() ?? ''),
            pw.SizedBox(height: 14),
          ],
          _sectionTitle('Fragen (${poll.feedbackQuestions.length})'),
          pw.SizedBox(height: 6),
          ...poll.feedbackQuestions.asMap().entries.map((e) {
            final i = e.key;
            final q = e.value;
            return _feedbackQuestionPublicRow(i + 1, q);
          }),
          pw.SizedBox(height: 10),
          _footer(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: _safeFileName('feedback_${poll.title}_public.pdf'),
    );
  }

  /// Admin feedback PDF: full results with all individual answers + AI summary.
  static Future<void> exportAdminFeedbackPoll(
      String pollId, String adminToken) async {
    final poll = await ApiService.fetchPoll(pollId);
    Map<String, dynamic>? results;
    Map<String, dynamic>? aiSummary;
    try {
      results = await ApiService.getFeedbackResults(pollId, adminToken);
    } catch (_) {}
    try {
      aiSummary = await ApiService.getAiSummary(pollId, adminToken);
    } catch (_) {}

    final doc = pw.Document();
    final now = DateTime.now();
    final df = DateFormat('dd.MM.yyyy HH:mm');

    final questions =
        (results?['questions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final responses =
        (results?['responses'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          _header('Feedback Export (Admin)', df.format(now)),
          pw.SizedBox(height: 8),
          _pollMeta(poll, public: false),
          pw.SizedBox(height: 6),
          pw.Text(
            '${responses.length} Antwort${responses.length == 1 ? '' : 'en'} eingegangen',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 14),
          if (aiSummary != null && aiSummary['available'] == true) ...[  
            _sectionTitle('KI-Zusammenfassung'),
            pw.SizedBox(height: 6),
            _summaryBox(aiSummary['summaryText']?.toString() ?? ''),
            pw.SizedBox(height: 14),
          ],
          _sectionTitle('Detaillierte Ergebnisse'),
          pw.SizedBox(height: 8),
          ..._buildFeedbackAdminResults(questions, responses),
          pw.SizedBox(height: 10),
          _footer(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: _safeFileName('feedback_${poll.title}_admin.pdf'),
    );
  }

  // ──────────────────────────────────────────────
  // Feedback helpers
  // ──────────────────────────────────────────────

  static pw.Widget _sectionTitle(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(
        color: PdfColors.indigo50,
        border: pw.Border(
          left: pw.BorderSide(color: PdfColors.indigo300, width: 3),
        ),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _summaryBox(String text) {
    // Strip common markdown to keep PDF readable
    final clean = text
        .replaceAll(RegExp(r'#{1,6}\s*'), '')
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'')
        .replaceAll(RegExp(r'\*(.+?)\*'), r'')
        .replaceAll('---', '')
        .trim();
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Text(clean,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
    );
  }

  static pw.Widget _feedbackQuestionPublicRow(
      int index, FeedbackQuestion q) {
    final typeLabel = _questionTypeLabel(q.questionType);
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 20,
                height: 20,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.indigo100,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text('$index',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(q.questionText,
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Text(typeLabel,
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          if (q.options.isNotEmpty) ...[  
            pw.SizedBox(height: 6),
            ...q.options.map((opt) => pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 28, bottom: 3),
                  child: pw.Row(
                    children: [
                      pw.Container(
                          width: 5,
                          height: 5,
                          decoration: const pw.BoxDecoration(
                              color: PdfColors.indigo300,
                              shape: pw.BoxShape.circle)),
                      pw.SizedBox(width: 6),
                      pw.Text(opt,
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey800)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  static List<pw.Widget> _buildFeedbackAdminResults(
      List<Map<String, dynamic>> questions,
      List<Map<String, dynamic>> responses) {
    final widgets = <pw.Widget>[];

    for (final q in questions) {
      final qId = q['questionId']?.toString() ?? '';
      final qText = q['questionText']?.toString() ?? '';
      final qType = q['questionType']?.toString() ?? 'FREE_TEXT';
      final opts = (q['options'] as List?)?.cast<String>() ?? [];
      final typeLabel = _questionTypeLabel(qType);

      // Collect all answers for this question
      final List<String> textAnswers = [];
      final Map<String, int> optionCounts = {};
      for (final opt in opts) optionCounts[opt] = 0;

      for (final resp in responses) {
        final answers =
            (resp['answers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        for (final ans in answers) {
          if (ans['questionId']?.toString() != qId) continue;
          final text = ans['textAnswer']?.toString();
          if (text != null && text.isNotEmpty) textAnswers.add(text);
          final selected =
              (ans['selectedOptions'] as List?)?.cast<String>() ?? [];
          for (final s in selected) {
            optionCounts[s] = (optionCounts[s] ?? 0) + 1;
          }
        }
      }

      // Question header
      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 4),
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.indigo50,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(qText,
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Text(typeLabel,
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
        ),
      );

      if (qType == 'FREE_TEXT') {
        if (textAnswers.isEmpty) {
          widgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 8, bottom: 12),
              child: pw.Text('Keine Antworten',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey500)),
            ),
          );
        } else {
          for (int i = 0; i < textAnswers.length; i++) {
            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(left: 8, bottom: 4),
                padding: const pw.EdgeInsets.all(7),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${i + 1}. ',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600)),
                    pw.Expanded(
                      child: pw.Text(textAnswers[i],
                          style: const pw.TextStyle(fontSize: 10)),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      } else {
        // SINGLE_CHOICE / MULTIPLE_CHOICE — show bar chart
        final total = optionCounts.values.fold<int>(0, (s, v) => s + v);
        for (final opt in opts) {
          final count = optionCounts[opt] ?? 0;
          final pct = total > 0 ? (count * 100.0 / total) : 0.0;
          final barFlex = (pct * 10).round().clamp(0, 1000);
          final restFlex = 1000 - barFlex;
          widgets.add(
            pw.Container(
              height: 22,
              margin: const pw.EdgeInsets.only(left: 8, bottom: 3),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 0.3),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Stack(
                children: [
                  pw.Row(children: [
                    if (barFlex > 0)
                      pw.Expanded(
                          flex: barFlex,
                          child: pw.Container(color: PdfColors.indigo100)),
                    if (restFlex > 0)
                      pw.Expanded(flex: restFlex, child: pw.SizedBox()),
                  ]),
                  pw.Padding(
                    padding:
                        const pw.EdgeInsets.symmetric(horizontal: 8),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 7,
                          child: pw.Text(opt,
                              style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Text('$count  ${pct.toStringAsFixed(1)}%',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
      widgets.add(pw.SizedBox(height: 10));
    }
    return widgets;
  }

  static String _questionTypeLabel(String type) {
    switch (type) {
      case 'SINGLE_CHOICE':
        return 'Einfachauswahl';
      case 'MULTIPLE_CHOICE':
        return 'Mehrfachauswahl';
      default:
        return 'Freitext';
    }
  }

  static String _safeFileName(String name) {
    return name.replaceAll(RegExp(r"[^a-zA-Z0-9._-]+"), '_');
  }

  // Aggregated data from API
  static Future<_PollAggregates> _loadAggregates(String pollId,
      {bool includeNames = false}) async {
    // Load poll to get options
    final poll = await ApiService.fetchPoll(pollId);
    final options = <String, String>{};
    for (final option in poll.options) {
      options[option.id] = option.text;
    }

    // Load all votes for this poll
    final votesResp = await ApiService.getVotesForPoll(pollId);

    final counts = <String, int>{};
    final namesByOption = <String, List<String>>{};
    for (final row in votesResp) {
      final optId = row['optionId']?.toString();
      if (optId == null) continue;
      counts.update(optId, (v) => v + 1, ifAbsent: () => 1);
      if (includeNames) {
        final isAnon = row['anonymous'] == true;
        final voterName = (row['voterName'] ?? '').toString().trim();
        if (!isAnon && voterName.isNotEmpty) {
          namesByOption.putIfAbsent(optId, () => <String>[]).add(voterName);
        }
      }
    }

    final total = counts.values.fold<int>(0, (s, v) => s + v);
    return _PollAggregates(
        options: options,
        counts: counts,
        total: total,
        namesByOption: namesByOption);
  }

  static Future<pw.Document> _buildPublicDocument(
      Poll poll, _PollAggregates data) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final df = DateFormat('dd.MM.yyyy HH:mm');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) {
          return [
            _header('Umfrage Export (Öffentlich)', df.format(now)),
            pw.SizedBox(height: 8),
            _pollMeta(poll, public: true),
            pw.SizedBox(height: 12),
            _resultsTable(data, showNames: false),
            pw.SizedBox(height: 10),
            _footer(),
          ];
        },
      ),
    );

    return doc;
  }

  static Future<pw.Document> _buildAdminDocument(
      Poll poll, _PollAggregates data) async {
    final doc = pw.Document();
    final now = DateTime.now();
    final df = DateFormat('dd.MM.yyyy HH:mm');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) {
          return [
            _header('Umfrage Export (Admin)', df.format(now)),
            pw.SizedBox(height: 8),
            _pollMeta(poll, public: false),
            pw.SizedBox(height: 12),
            _resultsTable(data, showNames: true),
            pw.SizedBox(height: 10),
            _footer(),
          ];
        },
      ),
    );

    return doc;
  }

  static pw.Widget _header(String title, String date) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Pollino',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(date, style: const pw.TextStyle(fontSize: 10))
        ]),
      ],
    );
  }

  static pw.Widget _pollMeta(Poll poll, {required bool public}) {
    final meta = <pw.Widget>[
      pw.Text(poll.title,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
    ];
    if ((poll.description ?? '').isNotEmpty) {
      meta.add(pw.SizedBox(height: 4));
      meta.add(
          pw.Text(poll.description!, style: const pw.TextStyle(fontSize: 11)));
    }
    if (!public) {
      meta.add(pw.SizedBox(height: 6));
      meta.add(
        pw.Wrap(spacing: 8, runSpacing: 4, children: [
          _chip('Anonym: ${poll.isAnonymous ? 'Ja' : 'Nein'}'),
          _chip('Mehrfachauswahl: ${poll.allowsMultipleVotes ? 'Ja' : 'Nein'}'),
          if (poll.expiresAt != null)
            _chip(
                'Ablauf: ${DateFormat('dd.MM.yyyy HH:mm').format(poll.expiresAt!.toLocal())}'),
          if (poll.autoDeleteAfterExpiry) _chip('Auto-Löschung nach Ablauf'),
          if ((poll.createdByName ?? '').isNotEmpty)
            _chip('Erstellt von: ${poll.createdByName}')
        ]),
      );
    }
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start, children: meta);
  }

  static pw.Widget _chip(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static pw.Widget _resultsTable(_PollAggregates data,
      {required bool showNames}) {
    // Sort by votes desc, then text
    final entries = data.options.entries.map((e) {
      final id = e.key;
      final text = e.value;
      final v = data.counts[id] ?? 0;
      final pct = data.total > 0 ? (v * 100 / data.total) : 0.0;
      final names = showNames
          ? (data.namesByOption[id] ?? const <String>[])
          : const <String>[];
      return _RowData(text: text, votes: v, percent: pct, names: names);
    }).toList()
      ..sort((a, b) {
        final c = b.votes.compareTo(a.votes);
        if (c != 0) return c;
        return a.text.compareTo(b.text);
      });

    // Header
    final header = pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        border: pw.Border.all(color: PdfColors.grey300, width: 0.2),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
              flex: 6,
              child: pw.Text('Option',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(
              flex: 2,
              child: pw.Text('Stimmen',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(
              flex: 2,
              child: pw.Text('Anteil',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10))),
          if (showNames)
            pw.Expanded(
                flex: 5,
                child: pw.Text('Teilnehmende (nicht anonym)',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10))),
        ],
      ),
    );

    // Rows with background bars
    final List<pw.Widget> rows = [header];
    for (final r in entries) {
      rows.add(_barRow(r, showNames: showNames));
    }

    return pw.Column(children: rows);
  }

  static pw.Widget _barRow(_RowData r, {required bool showNames}) {
    final baseFlex = 1000;
    final pctFlex = (r.percent.clamp(0, 100) * 10).round(); // 0..1000
    final restFlex = baseFlex - pctFlex;
    final barColor = PdfColors.indigo100; // dezent und transparent

    return pw.Container(
      height: 22,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: PdfColors.grey300, width: 0.3),
          right: pw.BorderSide(color: PdfColors.grey300, width: 0.3),
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.3),
        ),
      ),
      child: pw.Stack(
        children: [
          // Background bar
          pw.Row(children: [
            pw.Expanded(
                flex: pctFlex > 0 ? pctFlex : 0,
                child: pw.Container(color: barColor)),
            if (restFlex > 0) pw.Expanded(flex: restFlex, child: pw.SizedBox()),
          ]),
          // Foreground content
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  flex: 6,
                  child:
                      pw.Text(r.text, style: const pw.TextStyle(fontSize: 10)),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('${r.votes}',
                        style: const pw.TextStyle(fontSize: 10)),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('${r.percent.toStringAsFixed(1)}%',
                        style: const pw.TextStyle(fontSize: 10)),
                  ),
                ),
                if (showNames)
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text(_formatNames(r.names),
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatNames(List<String> names) {
    if (names.isEmpty) return '-';
    if (names.length <= 10) return names.join(', ');
    final display = names.take(10).join(', ');
    return '$display +${names.length - 10}';
  }

  static pw.Widget _footer() {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text('Generiert mit Pollino',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
    );
  }
}

class _PollAggregates {
  final Map<String, String> options; // optionId -> text
  final Map<String, int> counts; // optionId -> votes
  final int total;
  final Map<String, List<String>> namesByOption; // optionId -> names

  _PollAggregates({
    required this.options,
    required this.counts,
    required this.total,
    required this.namesByOption,
  });
}

class _RowData {
  final String text;
  final int votes;
  final double percent;
  final List<String> names;
  _RowData(
      {required this.text,
      required this.votes,
      required this.percent,
      required this.names});
}
