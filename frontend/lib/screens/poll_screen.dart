import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pollino/bloc/poll_bloc.dart';
import 'package:pollino/core/utils/timezone_helper.dart';
import 'package:pollino/env.dart' show Environment;
import 'package:pollino/services/like_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pollino/core/localization/i18n_service.dart';
import 'package:pollino/widgets/poll_results_chart.dart';
import 'package:pollino/services/comments_service.dart';
import 'package:share_plus/share_plus.dart';

class PollScreen extends StatefulWidget {
  final String pollId;

  const PollScreen({super.key, required this.pollId});

  @override
  State<PollScreen> createState() => _PollScreenState();
}

class _PollScreenState extends State<PollScreen> {
  List<String> _selectedOptionIds = [];
  bool _hasVoted = false;
  bool _isAnonymousVote = true;
  bool _isNavigatingAway = false; // Flag um doppelte Navigation zu verhindern
  bool _showChart = true; // Chart Sichtbarkeit
  final _voterNameController = TextEditingController();

  void _sharePoll(dynamic poll) {
    try {
      final String path = '/poll/${poll.id}';
      final String url = Uri.base.origin.isNotEmpty ? '${Uri.base.origin}$path' : '${Environment.webAppUrl}$path';

      if (kIsWeb) {
        // Im Web: Link in die Zwischenablage kopieren und Snackbar anzeigen
        Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(I18nService.instance.translate('share.snackbar.copied'))),
          );
        }
      } else {
        // Native/sonstige Plattformen: Systemteilen verwenden
        final String message = 'Schau dir diese Umfrage an: ${poll.title}\n$url';
        Share.share(message, subject: poll.title);
      }
    } catch (e) {
      // Fehler beim Teilen leise ignorieren oder optional snackBar zeigen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Teilen fehlgeschlagen: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _voterNameController.dispose();
    super.dispose();
  }

  void _toggleOptionSelection(String optionId, bool allowsMultiple) {
    setState(() {
      if (allowsMultiple) {
        // Multiple selection
        if (_selectedOptionIds.contains(optionId)) {
          _selectedOptionIds.remove(optionId);
        } else {
          _selectedOptionIds.add(optionId);
        }
      } else {
        // Single selection
        if (_selectedOptionIds.contains(optionId)) {
          _selectedOptionIds.clear();
        } else {
          _selectedOptionIds = [optionId];
        }
      }
    });
  }

  bool _isPollExpired(dynamic poll) {
    if (poll.expiresAt == null) return false;
    // poll.expiresAt ist UTC von der DB, verwende TimezoneHelper für korrekten Vergleich
    return TimezoneHelper.isExpired(poll.expiresAt!);
  }

  Future<void> _submitVote() async {
    // Get current poll to check expiration
    final currentState = context.read<PollBloc>().state;
    if (currentState is Loaded && currentState.polls.isNotEmpty) {
      final poll = currentState.polls.first;
      if (_isPollExpired(poll)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diese Umfrage ist bereits abgelaufen und kann nicht mehr bearbeitet werden.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (_selectedOptionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte wähle mindestens eine Option')),
      );
      return;
    }

    if (!_isAnonymousVote && _voterNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib deinen Namen ein')),
      );
      return;
    }

    // Zeige Loading Indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      if (_selectedOptionIds.length == 1) {
        // Single vote
        context.read<PollBloc>().add(PollEvent.voteWithName(
              widget.pollId,
              _selectedOptionIds.first,
              isAnonymous: _isAnonymousVote,
              voterName: _isAnonymousVote ? null : _voterNameController.text.trim(),
            ));
      } else {
        // Multiple votes
        context.read<PollBloc>().add(PollEvent.voteMultiple(
              widget.pollId,
              _selectedOptionIds,
              isAnonymous: _isAnonymousVote,
              voterName: _isAnonymousVote ? null : _voterNameController.text.trim(),
            ));
      }

      setState(() {
        _hasVoted = true;
      });

      // Verstecke Loading Indicator
      if (mounted) Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_selectedOptionIds.length == 1
              ? 'Stimme erfolgreich abgegeben!'
              : '${_selectedOptionIds.length} Stimmen erfolgreich abgegeben!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Verstecke Loading Indicator
      if (mounted) Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${I18nService.instance.translate('poll.voting.error')}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Farben für die Optionen wie im Screenshot
  final List<Color> _optionColors = [
    const Color(0xFF4CAF50), // Grün für "A New Place!"
    const Color(0xFF64B5F6), // Hellblau für "At Office"
    const Color(0xFF9575CD), // Lila für "Regular Place"
    const Color(0xFFFFB74D), // Orange/Gelb für "Any will do"
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PollBloc>(
      create: (_) => PollBloc(context.read<PollBloc>().hiveBox)..add(PollEvent.loadPoll(widget.pollId)),
      child: PopScope(
        canPop: !_isNavigatingAway, // Erlaube Pop nur wenn nicht bereits navigiert wird
        onPopInvokedWithResult: (didPop, result) {
          // Optional: Zusätzliche Logik wenn Pop ausgeführt wurde
          if (didPop) {
            _isNavigatingAway = true;
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: _isNavigatingAway
                  ? null
                  : () {
                      _isNavigatingAway = true;
                      Navigator.of(context).pop();
                    },
              icon: Icon(
                Icons.arrow_back_ios,
                size: 20,
                color: _isNavigatingAway ? Colors.grey : null,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            centerTitle: false,
            title: Text(
              I18nService.instance.translate('navigation.recent_activity'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black),
            ),
            actions: [
              // Like + Share Buttons in AppBar
              BlocBuilder<PollBloc, PollState>(
                builder: (context, state) {
                  if (state is Loaded && state.polls.isNotEmpty) {
                    final poll = state.polls.first;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FutureBuilder<bool>(
                          future: LikeService.hasUserMadeLike(poll.id),
                          builder: (context, snapshot) {
                            final isLiked = snapshot.data ?? false;
                            return IconButton(
                              onPressed: () {
                                context.read<PollBloc>().add(PollEvent.toggleLike(poll.id));
                              },
                              icon: Badge(
                                label: Text(
                                  '${poll.likesCount}',
                                  style: const TextStyle(fontSize: 10, color: Colors.white),
                                ),
                                isLabelVisible: poll.likesCount > 0,
                                child: Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? Colors.red[400] : Colors.grey[600],
                                  size: 22,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: kIsWeb
                              ? I18nService.instance.translate('share.tooltip.copyLink')
                              : I18nService.instance.translate('share.tooltip.share'),
                          onPressed: () => _sharePoll(poll),
                          icon: const Icon(Icons.share, size: 22),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF8F9FA),
          resizeToAvoidBottomInset: true, // Mobile Keyboard Support
          body: SafeArea(
            child: ListView(
              children: [
                const SizedBox(height: 20),

                // Poll Content - Flexible statt Expanded
                BlocBuilder<PollBloc, PollState>(
                  builder: (context, state) {
                    if (state is Loading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is Loaded) {
                      final poll = state.polls.first;
                      return StreamBuilder<List<Map<String, dynamic>>>(
                        stream: Supabase.instance.client
                            .from('user_votes')
                            .stream(primaryKey: ['id']).eq('poll_id', widget.pollId),
                        builder: (context, votesSnapshot) {
                          // Erstelle eine veränderbare Kopie der Optionen
                          List<dynamic> liveOptions = List.from(poll.options);

                          // Zähle echte Stimmen aus user_votes
                          final Map<String, int> voteCountsByOption = {};
                          int totalVotes = 0;

                          if (votesSnapshot.hasData && votesSnapshot.data != null) {
                            for (final vote in votesSnapshot.data!) {
                              final optionId = vote['option_id']?.toString();
                              if (optionId != null) {
                                voteCountsByOption.update(optionId, (count) => count + 1, ifAbsent: () => 1);
                                totalVotes++;
                              }
                            }
                          }

                          // Sortiere Optionen absteigend nach echten Vote-Zahlen
                          liveOptions.sort((a, b) {
                            final aId = a.id?.toString() ?? a['id']?.toString() ?? '';
                            final bId = b.id?.toString() ?? b['id']?.toString() ?? '';
                            final aVotes = voteCountsByOption[aId] ?? 0;
                            final bVotes = voteCountsByOption[bId] ?? 0;

                            // Primäre Sortierung: Nach Votes absteigend
                            final voteComparison = bVotes.compareTo(aVotes);
                            if (voteComparison != 0) return voteComparison;

                            // Sekundäre Sortierung: Nach Text alphabetisch falls Votes gleich sind
                            final aText = a.text ?? a['text'] ?? '';
                            final bText = b.text ?? b['text'] ?? '';
                            return aText.toString().compareTo(bText.toString());
                          });

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // User Info
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFFE3F2FD),
                                      child: Text(
                                        poll.createdByName != null
                                            ? poll.createdByName!.substring(0, 2).toUpperCase()
                                            : '??',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          poll.createdByName ??
                                              I18nService.instance.translate('poll.creator.anonymous'),
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          poll.isAnonymous
                                              ? I18nService.instance.translate('poll.anonymous')
                                              : I18nService.instance.translate('poll.creator.named'),
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () {},
                                      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Poll Title
                                Text(
                                  poll.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Vote count and expiration info (Votes via user_votes gezählt)
                                StreamBuilder<List<Map<String, dynamic>>>(
                                  stream: Supabase.instance.client
                                      .from('user_votes')
                                      .stream(primaryKey: ['id']).eq('poll_id', widget.pollId),
                                  builder: (context, votesSnapshot) {
                                    final voteCount = votesSnapshot.hasData && votesSnapshot.data != null
                                        ? votesSnapshot.data!.length
                                        : totalVotes; // Fallback auf zuvor berechnete Summe
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          I18nService.instance
                                              .translate('poll.voting.votesSummary', params: {'votes': '$voteCount'}),
                                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                        ),
                                        if (poll.expiresAt != null) ...[
                                          const SizedBox(height: 4),
                                          _ExpirationIndicator(poll: poll),
                                        ],
                                      ],
                                    );
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Voting Controls (nur wenn noch nicht abgestimmt und nicht abgelaufen)
                                if (!_hasVoted && !_isPollExpired(poll)) ...[
                                  // Anonymous Toggle
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _isAnonymousVote
                                                ? I18nService.instance.translate('poll.voting.anonymous')
                                                : I18nService.instance.translate('poll.voting.named'),
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        CupertinoSwitch(
                                          value: !_isAnonymousVote,
                                          onChanged: (value) {
                                            setState(() {
                                              _isAnonymousVote = !value;
                                            });
                                          },
                                          activeColor: const Color(0xFF4F46E5),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Name Input (wenn nicht anonym) - Mobile-responsive
                                  if (!_isAnonymousVote)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      width: double.infinity,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return TextField(
                                            controller: _voterNameController,
                                            textInputAction: TextInputAction.done,
                                            decoration: InputDecoration(
                                              labelText: I18nService.instance.translate('poll.voting.nameLabel'),
                                              hintText: I18nService.instance.translate('poll.voting.nameHint'),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding: EdgeInsets.symmetric(
                                                horizontal: constraints.maxWidth < 400 ? 12 : 16,
                                                vertical: constraints.maxWidth < 400 ? 12 : 16,
                                              ),
                                              prefixIcon: const Icon(Icons.person_outline),
                                            ),
                                            style: TextStyle(
                                              fontSize: constraints.maxWidth < 400 ? 14 : 16,
                                            ),
                                            // Automatisches Scrollen wenn Tastatur aufgeht (Mobile-Fix)
                                            onTap: () {
                                              Future.delayed(const Duration(milliseconds: 300), () {
                                                Scrollable.ensureVisible(
                                                  context,
                                                  duration: const Duration(milliseconds: 300),
                                                  curve: Curves.easeInOut,
                                                );
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ),

                                  // Multiple Choice Info
                                  if (poll.allowsMultipleVotes)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue[200]!),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              I18nService.instance.translate('poll.voting.selectMultiple'),
                                              style: const TextStyle(color: Colors.blue, fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],

                                // Poll Options
                                Column(
                                  children: [
                                    ...List.generate(liveOptions.length, (index) {
                                      final option = liveOptions[index];
                                      final optionId = option.id?.toString() ?? option['id']?.toString() ?? '';
                                      final optionText = option.text ?? option['text'] ?? '';
                                      final optionVotes = voteCountsByOption[optionId] ?? 0;
                                      final percentage = totalVotes > 0 ? (optionVotes / totalVotes) : 0.0;
                                      final isSelected = _selectedOptionIds.contains(optionId);

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _PollOptionWithVoters(
                                          pollId: widget.pollId,
                                          optionId: optionId,
                                          text: optionText,
                                          votes: optionVotes,
                                          percentage: percentage,
                                          color: _optionColors[index % _optionColors.length],
                                          hasVoted: _hasVoted,
                                          isSelected: isSelected,
                                          allowsMultiple: poll.allowsMultipleVotes,
                                          isAnonymousPoll: poll.isAnonymous,
                                          onTap: (_hasVoted || _isPollExpired(poll))
                                              ? null
                                              : () => _toggleOptionSelection(optionId, poll.allowsMultipleVotes),
                                        ),
                                      );
                                    }),

                                    // Vote Button oder Expired Message
                                    if (!_hasVoted) ...[
                                      if (_isPollExpired(poll))
                                        Padding(
                                          padding: const EdgeInsets.only(top: 16),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.red[200]!),
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(Icons.access_time_filled, color: Colors.red[600], size: 24),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Diese Umfrage ist abgelaufen',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.red[700],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  I18nService.instance.translate('poll.voting.expired'),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.red[600],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else if (_selectedOptionIds.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 16),
                                          child: SizedBox(
                                            width: double.infinity,
                                            height: 50,
                                            child: ElevatedButton(
                                              onPressed: _submitVote,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: Text(
                                                poll.allowsMultipleVotes && _selectedOptionIds.length > 1
                                                    ? I18nService.instance.translate('poll.voting.submitMultiple',
                                                        params: {'count': '${_selectedOptionIds.length}'})
                                                    : I18nService.instance.translate('poll.voting.submit'),
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ],
                                ),

                                // Poll Results Chart (Stimmen aus user_votes aggregiert)
                                if (liveOptions.isNotEmpty)
                                  StreamBuilder<List<Map<String, dynamic>>>(
                                    stream: Supabase.instance.client
                                        .from('user_votes')
                                        .stream(primaryKey: ['id']).eq('poll_id', widget.pollId),
                                    builder: (context, votesSnapshot) {
                                      // Aggregiere Stimmenanzahl pro Option aus user_votes
                                      final Map<String, int> counts = {};
                                      final Map<String, Set<String>> namesByOption = {};
                                      if (votesSnapshot.hasData && votesSnapshot.data != null) {
                                        for (final row in votesSnapshot.data!) {
                                          final optId = row['option_id']?.toString();
                                          if (optId == null) continue;
                                          counts.update(optId, (v) => v + 1, ifAbsent: () => 1);
                                          final isAnon = row['is_anonymous'] == true;
                                          final voterName = row['voter_name'];
                                          if (!isAnon && voterName is String && voterName.trim().isNotEmpty) {
                                            namesByOption.putIfAbsent(optId, () => <String>{}).add(voterName.trim());
                                          }
                                        }
                                      }

                                      // Nur bei nicht-anonymer Umfrage Namen an Chart übergeben
                                      final showNames = !poll.isAnonymous;
                                      final chartOptions = liveOptions.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final option = entry.value;
                                        final optionIdStr = option.id?.toString() ?? option['id']?.toString() ?? '';
                                        final optionVotes = counts[optionIdStr] ?? voteCountsByOption[optionIdStr] ?? 0;
                                        return PollOptionData(
                                          text: option.text ?? option['text'] ?? '',
                                          votes: optionVotes,
                                          color: _optionColors[index % _optionColors.length],
                                          namedVoters:
                                              showNames ? (namesByOption[optionIdStr]?.toList() ?? const []) : const [],
                                        );
                                      }).toList()
                                        ..sort((a, b) {
                                          // Primäre Sortierung: Nach Votes absteigend
                                          final voteComparison = b.votes.compareTo(a.votes);
                                          if (voteComparison != 0) return voteComparison;
                                          // Sekundäre Sortierung: Alphabetisch nach Text falls Votes gleich sind
                                          return a.text.compareTo(b.text);
                                        });

                                      final totalFromCounts = chartOptions.fold<int>(0, (s, o) => s + o.votes);
                                      if (totalFromCounts == 0) {
                                        // Wenn immer noch 0, Chart ausblenden (keine Stimmen)
                                        return const SizedBox.shrink();
                                      }

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        child: PollResultsChart(
                                          options: chartOptions,
                                          isVisible: _showChart,
                                          onToggleVisibility: () {
                                            setState(() {
                                              _showChart = !_showChart;
                                            });
                                          },
                                        ),
                                      );
                                    },
                                  ),

                                const SizedBox(height: 20),

                                // Kommentare Sektion
                                _CommentsSection(pollId: poll.id),

                                // Bottom Actions
                                Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.only(bottom: 16),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    } else if (state is Error) {
                      return Center(child: Text(state.message));
                    }
                    return const Center(child: Text('Keine Umfragedaten verfügbar.'));
                  },
                ),
              ],
            ),
          ),
        ), // Schließt das Scaffold
      ), // Schließt das WillPopScope
    ); // Schließt das BlocProvider
  }
}

class _PollOptionWithVoters extends StatelessWidget {
  final String pollId;
  final String optionId;
  final String text;
  final int votes;
  final double percentage;
  final Color color;
  final bool hasVoted;
  final bool isSelected;
  final bool allowsMultiple;
  final bool isAnonymousPoll;
  final VoidCallback? onTap;

  const _PollOptionWithVoters({
    required this.pollId,
    required this.optionId,
    required this.text,
    required this.votes,
    required this.percentage,
    required this.color,
    required this.hasVoted,
    required this.isSelected,
    required this.allowsMultiple,
    required this.isAnonymousPoll,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('user_votes').stream(primaryKey: ['id']).eq('poll_id', pollId),
      builder: (context, snapshot) {
        final List<String> voterNames = [];

        // Nur für nicht-anonyme Umfragen Namen sammeln
        if (!isAnonymousPoll && snapshot.hasData && snapshot.data != null) {
          for (final vote in snapshot.data!) {
            // Nur Votes für diese Option berücksichtigen
            if (vote['option_id']?.toString() == optionId) {
              final isAnon = vote['is_anonymous'] == true;
              final voterName = vote['voter_name'];
              if (!isAnon && voterName is String && voterName.trim().isNotEmpty) {
                voterNames.add(voterName.trim());
              }
            }
          }
        }

        return _PollOption(
          text: text,
          votes: votes,
          percentage: percentage,
          color: color,
          voters: voterNames,
          hasVoted: hasVoted,
          isSelected: isSelected,
          allowsMultiple: allowsMultiple,
          onTap: onTap,
        );
      },
    );
  }
}

class _PollOption extends StatelessWidget {
  final String text;
  final int votes;
  final double percentage;
  final Color color;
  final List<String> voters;
  final bool hasVoted;
  final bool isSelected;
  final bool allowsMultiple;
  final VoidCallback? onTap;

  const _PollOption({
    required this.text,
    required this.votes,
    required this.percentage,
    required this.color,
    required this.voters,
    required this.hasVoted,
    required this.isSelected,
    required this.allowsMultiple,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          color: Colors.white,
          border: !hasVoted && isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Stack(
          children: [
            // Background progress bar - immer sichtbar, mit Transparenz vor dem Voting
            Container(
              height: 54,
              width: MediaQuery.of(context).size.width * 0.85 * percentage,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(27),
                  color:
                      color.withValues(alpha: hasVoted ? 1.0 : 0.3) // Transparent vor Voting, voll sichtbar nach Voting
                  ),
            ),

            // Content
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Selection indicator
                  if (!hasVoted)
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        shape: allowsMultiple ? BoxShape.rectangle : BoxShape.circle,
                        borderRadius: allowsMultiple ? BorderRadius.circular(4) : null,
                        border: Border.all(
                          color: isSelected ? color : Colors.grey[400]!,
                          width: 2,
                        ),
                        color: isSelected ? color : Colors.white,
                      ),
                      child: isSelected
                          ? Icon(
                              allowsMultiple ? Icons.check : Icons.circle,
                              size: allowsMultiple ? 14 : 10,
                              color: Colors.white,
                            )
                          : null,
                    )
                  // Check mark for voted option
                  else if (hasVoted)
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: percentage > 0 ? Colors.white : Colors.grey[300],
                      ),
                      child: percentage > 0 ? const Icon(Icons.check, size: 14, color: Colors.green) : null,
                    ),

                  // Option text
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87, // Immer dunkler Text für bessere Lesbarkeit
                      ),
                    ),
                  ),

                  // Voters avatars mit Initialen
                  if (hasVoted && voters.isNotEmpty) ...[
                    Row(
                      children: voters
                          .take(3)
                          .map(
                            (voterName) => Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(left: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF4F46E5),
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              child: Center(
                                  child: Text(voterName.isNotEmpty ? voterName[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                          fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Percentage - immer sichtbar
                  AnimatedOpacity(
                    opacity: hasVoted ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      '${(percentage * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87, // Immer dunkler Text für bessere Lesbarkeit
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpirationIndicator extends StatefulWidget {
  final dynamic poll;

  const _ExpirationIndicator({required this.poll});

  @override
  _ExpirationIndicatorState createState() => _ExpirationIndicatorState();
}

class _ExpirationIndicatorState extends State<_ExpirationIndicator> {
  late Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update every minute to show countdown
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poll = widget.poll;
    if (poll.expiresAt == null) return const SizedBox.shrink();

    // poll.expiresAt ist UTC, verwende TimezoneHelper für korrekte Berechnungen
    final expiresAt = poll.expiresAt!;
    final isExpired = TimezoneHelper.isExpired(expiresAt);
    final timeRemaining = TimezoneHelper.timeUntilExpiry(expiresAt) ?? Duration.zero;

    if (isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_filled, size: 14, color: Colors.red[600]),
            const SizedBox(width: 6),
            Text(
              'Diese Umfrage ist abgelaufen',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            if (poll.autoDeleteAfterExpiry) ...[
              const SizedBox(width: 8),
              Icon(Icons.auto_delete, size: 14, color: Colors.red[600]),
              const SizedBox(width: 4),
              Text(
                '(wird automatisch gelöscht)',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Format time remaining with correct singular/plural
    final timeText = TimezoneHelper.formatTimeRemaining(timeRemaining);
    Color backgroundColor;
    Color textColor;
    Color iconColor;

    if (timeRemaining.inDays > 0) {
      backgroundColor = Colors.green[50]!;
      textColor = Colors.green[700]!;
      iconColor = Colors.green[600]!;
    } else if (timeRemaining.inHours > 0) {
      if (timeRemaining.inHours < 24) {
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        iconColor = Colors.orange[600]!;
      } else {
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        iconColor = Colors.green[600]!;
      }
    } else if (timeRemaining.inMinutes > 0) {
      backgroundColor = Colors.red[50]!;
      textColor = Colors.red[700]!;
      iconColor = Colors.red[600]!;
    } else {
      backgroundColor = Colors.red[100]!;
      textColor = Colors.red[800]!;
      iconColor = Colors.red[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            I18nService.instance.translate('poll.voting.expiresIn', params: {'time': timeText}),
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- Comments UI --------------------
class _CommentsSection extends StatefulWidget {
  final String pollId;
  const _CommentsSection({required this.pollId});

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  final TextEditingController _controller = TextEditingController();
  bool _isAnonymous = true;
  final TextEditingController _nameController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await CommentsService.addComment(
        pollId: widget.pollId,
        content: text,
        userName: _isAnonymous ? null : _nameController.text.trim(),
        isAnonymous: _isAnonymous,
      );
      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(I18nService.instance.translate('comments.snackbar.add.error'))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.black54),
              const SizedBox(width: 8),
              StreamBuilder<int>(
                stream: CommentsService.streamCommentsCount(widget.pollId),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Text(
                    '${I18nService.instance.translate('comments.title')} ($count)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // List of comments (newest first)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: StreamBuilder<List<CommentModel>>(
              stream: CommentsService.streamComments(widget.pollId),
              builder: (context, AsyncSnapshot<List<CommentModel>> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)));
                }
                final List<CommentModel> comments = snapshot.data!;
                if (comments.isEmpty) {
                  return Text(
                    I18nService.instance.translate('comments.empty'),
                    style: TextStyle(color: Colors.grey[600]),
                  );
                }
                return ListView.separated(
                  reverse: false,
                  shrinkWrap: true,
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final c = comments[index];
                    final displayName = c.isAnonymous
                        ? I18nService.instance.translate('poll.anonymous')
                        : (c.userName?.isNotEmpty == true
                            ? c.userName!
                            : I18nService.instance.translate('comments.guest'));
                    final isFresh = DateTime.now().difference(c.createdAt).inMinutes < 5;
                    // Determine ownership by clientId
                    return FutureBuilder<String>(
                      future: CommentsService.clientId,
                      builder: (context, snapshotId) {
                        final own = snapshotId.hasData && c.clientId != null && c.clientId == snapshotId.data;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(radius: 14, child: Text(displayName[0].toUpperCase())),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            if (c.updatedAt != null) ...[
                                              const SizedBox(width: 6),
                                              Text('(${I18nService.instance.translate('comments.edited')})',
                                                  style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Text(
                                        TimeOfDay.fromDateTime(c.createdAt).format(context),
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                      ),
                                      if (isFresh) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.green[200]!),
                                          ),
                                          child: Text(
                                            I18nService.instance.translate('comments.badge.new'),
                                            style: const TextStyle(fontSize: 10, color: Colors.green),
                                          ),
                                        ),
                                      ],
                                      if (own) ...[
                                        const SizedBox(width: 4),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, size: 18),
                                          onSelected: (value) async {
                                            if (value == 'edit') {
                                              final controller = TextEditingController(text: c.content);
                                              final newText = await showDialog<String>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title:
                                                      Text(I18nService.instance.translate('comments.dialog.editTitle')),
                                                  content: TextField(
                                                    controller: controller,
                                                    minLines: 1,
                                                    maxLines: 5,
                                                    autofocus: true,
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(ctx),
                                                      child: Text(I18nService.instance.translate('actions.cancel')),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                                                      child: Text(I18nService.instance.translate('actions.save')),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (newText != null && newText != c.content) {
                                                try {
                                                  await CommentsService.updateComment(
                                                      commentId: c.id, newContent: newText);
                                                  if (mounted) setState(() {});
                                                } catch (e) {
                                                  if (!mounted) return;
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                        content: Text(I18nService.instance
                                                            .translate('comments.snackbar.edit.error'))),
                                                  );
                                                }
                                              }
                                            } else if (value == 'delete') {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: Text(
                                                      I18nService.instance.translate('comments.dialog.deleteTitle')),
                                                  content: Text(
                                                      I18nService.instance.translate('comments.dialog.deleteMessage')),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(ctx, false),
                                                      child: Text(I18nService.instance.translate('actions.cancel')),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () => Navigator.pop(ctx, true),
                                                      child: Text(I18nService.instance.translate('actions.delete')),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true) {
                                                try {
                                                  await CommentsService.deleteComment(commentId: c.id);
                                                  if (mounted) setState(() {});
                                                } catch (e) {
                                                  if (!mounted) return;
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                        content: Text(I18nService.instance
                                                            .translate('comments.snackbar.delete.error'))),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                          itemBuilder: (ctx) => [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Text(I18nService.instance.translate('actions.edit')),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Text(I18nService.instance.translate('actions.delete')),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 36),
                              child: Text(c.content),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: I18nService.instance.translate('comments.placeholder'),
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Mobile-responsive Layout für Kommentar-Name
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CupertinoSwitch(
                            value: !_isAnonymous,
                            onChanged: (v) => setState(() => _isAnonymous = !v),
                            activeColor: const Color(0xFF4F46E5),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              I18nService.instance.translate('comments.withName'),
                              style: TextStyle(fontSize: isMobile ? 14 : 16),
                            ),
                          ),
                        ],
                      ),
                      if (!_isAnonymous) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: I18nService.instance.translate('comments.nameOptional'),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 16,
                              vertical: isMobile ? 10 : 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.person_outline, size: 18),
                          ),
                          style: TextStyle(fontSize: isMobile ? 14 : 16),
                        ),
                      ],
                    ],
                  );
                },
              )
            ],
          )
        ],
      ),
    );
  }
}
