import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pollino/services/supabase_service.dart';
import 'package:pollino/bloc/poll.dart';

class PdfService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Öffentlicher Export: begrenzte Informationen ohne personenbezogene Daten
  static Future<void> exportPublicPoll(String pollId) async {
    final poll = await SupabaseService.fetchPoll(pollId);
    final data = await _loadAggregates(pollId);
    final doc = await _buildPublicDocument(poll, data);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: _safeFileName('poll_${poll.title}_public.pdf'),
    );
  }

  // Admin-Export: vollständige Informationen inkl. namensbasierter Stimmen
  static Future<void> exportAdminPoll(String pollId) async {
    final poll = await SupabaseService.fetchPoll(pollId);
    final data = await _loadAggregates(pollId, includeNames: true);
    final doc = await _buildAdminDocument(poll, data);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: _safeFileName('poll_${poll.title}_admin.pdf'),
    );
  }

  static String _safeFileName(String name) {
    return name.replaceAll(RegExp(r"[^a-zA-Z0-9._-]+"), '_');
  }

  // Aggregierte Daten aus user_votes und poll_options
  static Future<_PollAggregates> _loadAggregates(String pollId, {bool includeNames = false}) async {
    // Optionen laden (id, text)
    final optionsResp =
        await _client.from('poll_options').select('id, text').eq('poll_id', pollId).order('option_order, id');

    final options = <String, String>{};
    for (final row in (optionsResp as List)) {
      options[row['id'].toString()] = (row['text'] ?? '').toString();
    }

    // Alle user_votes zu dieser Umfrage laden
    final votesResp = await _client
        .from('user_votes')
        .select('option_id, is_anonymous, voter_name, created_at')
        .eq('poll_id', pollId);

    final counts = <String, int>{};
    final namesByOption = <String, List<String>>{};
    for (final row in (votesResp as List)) {
      final optId = row['option_id']?.toString();
      if (optId == null) continue;
      counts.update(optId, (v) => v + 1, ifAbsent: () => 1);
      if (includeNames) {
        final isAnon = row['is_anonymous'] == true;
        final voterName = (row['voter_name'] ?? '').toString().trim();
        if (!isAnon && voterName.isNotEmpty) {
          namesByOption.putIfAbsent(optId, () => <String>[]).add(voterName);
        }
      }
    }

    final total = counts.values.fold<int>(0, (s, v) => s + v);
    return _PollAggregates(options: options, counts: counts, total: total, namesByOption: namesByOption);
  }

  static Future<pw.Document> _buildPublicDocument(Poll poll, _PollAggregates data) async {
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

  static Future<pw.Document> _buildAdminDocument(Poll poll, _PollAggregates data) async {
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
        pw.Text('Pollino', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(date, style: const pw.TextStyle(fontSize: 10))
        ]),
      ],
    );
  }

  static pw.Widget _pollMeta(Poll poll, {required bool public}) {
    final meta = <pw.Widget>[
      pw.Text(poll.title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
    ];
    if ((poll.description ?? '').isNotEmpty) {
      meta.add(pw.SizedBox(height: 4));
      meta.add(pw.Text(poll.description!, style: const pw.TextStyle(fontSize: 11)));
    }
    if (!public) {
      meta.add(pw.SizedBox(height: 6));
      meta.add(
        pw.Wrap(spacing: 8, runSpacing: 4, children: [
          _chip('Anonym: ${poll.isAnonymous ? 'Ja' : 'Nein'}'),
          _chip('Mehrfachauswahl: ${poll.allowsMultipleVotes ? 'Ja' : 'Nein'}'),
          if (poll.expiresAt != null)
            _chip('Ablauf: ${DateFormat('dd.MM.yyyy HH:mm').format(poll.expiresAt!.toLocal())}'),
          if (poll.autoDeleteAfterExpiry) _chip('Auto-Löschung nach Ablauf'),
          if ((poll.createdByName ?? '').isNotEmpty) _chip('Erstellt von: ${poll.createdByName}')
        ]),
      );
    }
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: meta);
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

  static pw.Widget _resultsTable(_PollAggregates data, {required bool showNames}) {
    // Sort by votes desc, then text
    final entries = data.options.entries.map((e) {
      final id = e.key;
      final text = e.value;
      final v = data.counts[id] ?? 0;
      final pct = data.total > 0 ? (v * 100 / data.total) : 0.0;
      final names = showNames ? (data.namesByOption[id] ?? const <String>[]) : const <String>[];
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
              flex: 6, child: pw.Text('Option', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(
              flex: 2, child: pw.Text('Stimmen', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Expanded(
              flex: 2, child: pw.Text('Anteil', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
          if (showNames)
            pw.Expanded(
                flex: 5,
                child: pw.Text('Teilnehmende (nicht anonym)',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
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
            pw.Expanded(flex: pctFlex > 0 ? pctFlex : 0, child: pw.Container(color: barColor)),
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
                  child: pw.Text(r.text, style: const pw.TextStyle(fontSize: 10)),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('${r.votes}', style: const pw.TextStyle(fontSize: 10)),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('${r.percent.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 10)),
                  ),
                ),
                if (showNames)
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text(_formatNames(r.names), style: const pw.TextStyle(fontSize: 9)),
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
      child: pw.Text('Generiert mit Pollino', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
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
  _RowData({required this.text, required this.votes, required this.percent, required this.names});
}
