import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pollino/bloc/poll_bloc.dart';
import 'package:pollino/core/localization/i18n_service.dart';
import 'package:pollino/core/localization/language_switcher.dart';
import 'package:pollino/core/widgets/pollino_logo.dart';
import 'package:pollino/core/utils/responsive_helper.dart';
import 'package:pollino/core/widgets/responsive_wrapper.dart';
import 'package:pollino/env.dart' show Environment;
import 'package:pollino/services/like_service.dart';
import 'package:routemaster/routemaster.dart';
import 'package:pollino/services/comments_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pollino/widgets/poll_results_chart.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  final int _limit = 10;

  // Farben für die Poll Cards wie im Screenshot
  final List<Color> _optionColors = [
    const Color(0xFF4CAF50), // Grün
    const Color(0xFF64B5F6), // Hellblau
    const Color(0xFF9575CD), // Lila
    const Color(0xFFFFB74D), // Orange/Gelb
  ];

  // Demo-Avatare für die Poll Cards
  final List<List<String>> _demoVoters = [
    ['👩‍💻', '👨‍💼', '👩‍🎨'],
    ['👨‍💻', '👩‍💼'],
    ['👩‍🏫', '👨‍🎓', '👩‍⚕️'],
    ['👨‍🍳'],
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<PollBloc>().add(PollEvent.loadPolls(page: _currentPage, limit: _limit));
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final state = context.read<PollBloc>().state;
      if (state is Loaded && state.hasMore) {
        _currentPage++;
        context.read<PollBloc>().add(PollEvent.loadMore(page: _currentPage, limit: _limit));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mit Recent Activity
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Routemaster.of(context).push('/create'),
                    icon: const Icon(Icons.add, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Neue Umfrage erstellen',
                  ),
                  const SizedBox(width: 12),
                  const PollinoLogo(
                    size: 32,
                    showText: false,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'app.title'.tr(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                  const Spacer(),
                  const LanguageSwitcher(),
                ],
              ),
            ),

            // Poll List Content
            Expanded(
              child: BlocBuilder<PollBloc, PollState>(
                builder: (context, state) {
                  if (state is Loading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is Loaded) {
                    if (state.polls.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.poll_outlined, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'home.empty.title'.tr(),
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'home.empty.subtitle'.tr(),
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => Routemaster.of(context).push('/create'),
                              icon: const Icon(Icons.add),
                              label: Text('home.empty.button'.tr()),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<PollBloc>().add(const PollEvent.refreshPolls());
                      },
                      child: ResponsiveHelper.isMobile(context)
                          ? ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: state.polls.length + (state.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == state.polls.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }

                                final poll = state.polls[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _PollCard(
                                    poll: poll,
                                    colorIndex: index,
                                    optionColors: _optionColors,
                                    demoVoters: _demoVoters,
                                  ),
                                );
                              },
                            )
                          : SingleChildScrollView(
                              controller: _scrollController,
                              child: ResponsiveGrid(
                                children: [
                                  ...state.polls.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final poll = entry.value;
                                    return _PollCard(
                                      poll: poll,
                                      colorIndex: index,
                                      optionColors: _optionColors,
                                      demoVoters: _demoVoters,
                                    );
                                  }),
                                  if (state.hasMore) const Center(child: CircularProgressIndicator()),
                                ],
                              ),
                            ),
                    );
                  } else if (state is Error) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
                          const SizedBox(height: 16),
                          Text(
                            'home.error'.tr(),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.red[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(state.message, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<PollBloc>().add(const PollEvent.loadPolls(page: 1, limit: 10));
                            },
                            icon: const Icon(Icons.refresh),
                            label: Text('actions.retry'.tr()),
                          ),
                        ],
                      ),
                    );
                  }
                  return const Center(child: Text('Keine Umfragen verfügbar.'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _PollCard extends StatefulWidget {
  final dynamic poll;
  final int colorIndex;
  final List<Color> optionColors;
  final List<List<String>> demoVoters;
  const _PollCard({
    required this.poll,
    required this.colorIndex,
    required this.optionColors,
    required this.demoVoters,
  });

  @override
  State<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<_PollCard> {
  bool _showChart = true;

  void _sharePoll() {
    try {
      final String path = '/poll/${widget.poll.id}';
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
        final String message = 'Schau dir diese Umfrage an: ${widget.poll.title}\n$url';
        Share.share(message, subject: widget.poll.title);
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Routemaster.of(context).push('/poll/${widget.poll.id}'),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info (nur bei nicht-anonymen Umfragen anzeigen)
            if (!widget.poll.isAnonymous) ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE3F2FD),
                    child: Text(
                      widget.poll.createdByName != null
                          ? widget.poll.createdByName!.substring(0, 2).toUpperCase()
                          : '??',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.poll.createdByName ?? I18nService.instance.translate('poll.creator.anonymous'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          I18nService.instance.translate('time.relative.justNow'),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            // Poll Title
            Text(
              widget.poll.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Vote count and expiration info (count rows from user_votes for accuracy)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream:
                  Supabase.instance.client.from('user_votes').stream(primaryKey: ['id']).eq('poll_id', widget.poll.id),
              builder: (context, snapshot) {
                final votes = snapshot.hasData && snapshot.data != null ? snapshot.data!.length : 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      I18nService.instance.translate('poll.voting.votesSummary', params: {'votes': '$votes'}),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (widget.poll.expiresAt != null) ...[
                      const SizedBox(height: 4),
                      _ExpirationIndicator(poll: widget.poll),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Poll Results Chart (Stimmen aus user_votes aggregiert, analog Detailseite)
            // Poll Results Chart (Stimmen aus user_votes aggregiert, analog Detailseite)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('poll_options')
                  .stream(primaryKey: ['id']).eq('poll_id', widget.poll.id),
              builder: (context, optionsSnapshot) {
                List<dynamic> liveOptions = widget.poll.options;
                if (optionsSnapshot.hasData && optionsSnapshot.data != null) {
                  liveOptions = optionsSnapshot.data!;
                }

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client
                      .from('user_votes')
                      .stream(primaryKey: ['id']).eq('poll_id', widget.poll.id),
                  builder: (context, votesSnapshot) {
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
                    final showNames = !widget.poll.isAnonymous;
                    // Chart-Optionen erstellen und nach Votes absteigend sortieren
                    final chartOptions = liveOptions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      final optionIdStr = (optionsSnapshot.hasData ? option['id'].toString() : option.id.toString());
                      final votes = counts[optionIdStr] ??
                          (optionsSnapshot.hasData ? (option['votes'] as int? ?? 0) : (option.votes as int));
                      final text = optionsSnapshot.hasData ? option['text'] : option.text;
                      return PollOptionData(
                        text: text,
                        votes: votes,
                        color: widget.optionColors[index % widget.optionColors.length],
                        namedVoters: showNames ? (namesByOption[optionIdStr]?.toList() ?? const []) : const [],
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
                      return const SizedBox.shrink();
                    }

                    return ResponsiveChartContainer(
                      padding: const EdgeInsets.only(bottom: 8),
                      isInCard: true,
                      child: PollResultsChart(
                        options: chartOptions,
                        isVisible: _showChart,
                        onToggleVisibility: () {
                          setState(() => _showChart = !_showChart);
                        },
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // Bottom Actions mit Likes, Comments, Share
            Row(
              children: [
                // Like Button mit FutureBuilder für Like-Status
                FutureBuilder<bool>(
                  future: LikeService.hasUserMadeLike(widget.poll.id),
                  builder: (context, snapshot) {
                    final isLiked = snapshot.data ?? false;
                    return GestureDetector(
                      onTap: () {
                        context.read<PollBloc>().add(PollEvent.toggleLike(widget.poll.id));
                      },
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red[400] : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.poll.likesCount}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 4),
                    StreamBuilder<int>(
                      stream: CommentsService.streamCommentsCount(widget.poll.id.toString()),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Text('$count', style: const TextStyle(fontSize: 14));
                      },
                    ),
                  ],
                ),
                const Spacer(),
                Tooltip(
                  message: kIsWeb
                      ? I18nService.instance.translate('share.tooltip.copyLink')
                      : I18nService.instance.translate('share.tooltip.share'),
                  child: TextButton.icon(
                    onPressed: _sharePoll,
                    icon: Icon(Icons.share, color: Colors.grey[600], size: 20),
                    label: Text('actions.share'.tr()),
                  ),
                ),
              ],
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

    final now = DateTime.now();
    final expiresAt = poll.expiresAt!; // expiresAt ist bereits ein DateTime Objekt
    final isExpired = now.isAfter(expiresAt);
    final timeRemaining = expiresAt.difference(now);

    if (isExpired) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 12, color: Colors.red[600]),
          const SizedBox(width: 4),
          Text(
            'Abgelaufen',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (poll.autoDeleteAfterExpiry) ...[
            const SizedBox(width: 4),
            Icon(Icons.delete_outline, size: 12, color: Colors.red[600]),
            const SizedBox(width: 2),
            Text(
              '(wird automatisch gelöscht)',
              style: TextStyle(
                fontSize: 10,
                color: Colors.red[400],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      );
    }

    // Format time remaining
    String timeText;
    Color timeColor;

    if (timeRemaining.inDays > 0) {
      timeText = '${timeRemaining.inDays}d ${timeRemaining.inHours % 24}h verbleibend';
      timeColor = Colors.green[600]!;
    } else if (timeRemaining.inHours > 0) {
      timeText = '${timeRemaining.inHours}h ${timeRemaining.inMinutes % 60}min verbleibend';
      timeColor = timeRemaining.inHours < 24 ? Colors.orange[600]! : Colors.green[600]!;
    } else if (timeRemaining.inMinutes > 0) {
      timeText = '${timeRemaining.inMinutes}min verbleibend';
      timeColor = Colors.red[600]!;
    } else {
      timeText = 'Läuft bald ab';
      timeColor = Colors.red[700]!;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time, size: 12, color: timeColor),
        const SizedBox(width: 4),
        Text(
          timeText,
          style: TextStyle(
            fontSize: 12,
            color: timeColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
