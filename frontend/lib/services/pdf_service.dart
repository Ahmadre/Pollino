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

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _cell('Option', bold: true),
          _cell('Stimmen', bold: true),
          _cell('Anteil', bold: true),
          if (showNames) _cell('Teilnehmende (nicht anonym)', bold: true),
        ],
      ),
    ];

    for (final r in entries) {
      rows.add(
        pw.TableRow(children: [
          _cell(r.text),
          _cell(r.votes.toString()),
          _cell('${r.percent.toStringAsFixed(1)}%'),
          if (showNames) _cell(_formatNames(r.names)),
        ]),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  static String _formatNames(List<String> names) {
    if (names.isEmpty) return '-';
    if (names.length <= 10) return names.join(', ');
    final display = names.take(10).join(', ');
    return '$display +${names.length - 10}';
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
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
