import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pollino/bloc/poll_bloc.dart';
import 'package:routemaster/routemaster.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
                  const Text(
                    'Pollino',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                  const Spacer(),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.tune, size: 20)),
                ],
              ),
            ),

            // Filter Tabs (Pins, Polls, Files, Photos)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterTab(icon: Icons.push_pin, label: 'Pins', isSelected: false),
                  _FilterTab(icon: Icons.poll, label: 'Umfragen', isSelected: true),
                  _FilterTab(icon: Icons.description, label: 'Dateien', isSelected: false),
                  _FilterTab(icon: Icons.photo, label: 'Fotos', isSelected: false),
                ],
              ),
            ),

            const SizedBox(height: 20),

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
                              'Keine Umfragen vorhanden',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Erstelle deine erste Umfrage!',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => Routemaster.of(context).push('/create'),
                              icon: const Icon(Icons.add),
                              label: const Text('Umfrage erstellen'),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<PollBloc>().add(const PollEvent.refreshPolls());
                      },
                      child: ListView.builder(
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
                            'Fehler beim Laden',
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
                            label: const Text('Erneut versuchen'),
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

class _FilterTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _FilterTab({required this.icon, required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _PollCard extends StatelessWidget {
  final dynamic poll;
  final int colorIndex;
  final List<Color> optionColors;
  final List<List<String>> demoVoters;

  const _PollCard({required this.poll, required this.colorIndex, required this.optionColors, required this.demoVoters});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Routemaster.of(context).push('/poll/${poll.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Text('LU', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lara Ulrich', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text('21 minutes ago', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Poll Title
            Text(
              poll.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
            ),

            const SizedBox(height: 8),

            // Vote count
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client.from('poll_options').stream(primaryKey: ['id']).eq('poll_id', poll.id),
              builder: (context, snapshot) {
                int totalVotes = 0;
                if (snapshot.hasData && snapshot.data != null) {
                  for (var option in snapshot.data!) {
                    totalVotes += (option['votes'] as int? ?? 0);
                  }
                } else {
                  for (var option in poll.options) {
                    totalVotes += (option.votes as int);
                  }
                }

                return Text(
                  '$totalVotes votes • Vote to see results',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                );
              },
            ),

            const SizedBox(height: 16),

            // Poll Options Preview (wie im Screenshot)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client.from('poll_options').stream(primaryKey: ['id']).eq('poll_id', poll.id),
              builder: (context, snapshot) {
                List<dynamic> liveOptions = poll.options;
                int totalVotes = 0;
                for (var option in poll.options) {
                  totalVotes += (option.votes as int);
                }

                if (snapshot.hasData && snapshot.data != null) {
                  liveOptions = snapshot.data!;
                  totalVotes = 0;
                  for (var option in liveOptions) {
                    totalVotes += (option['votes'] as int? ?? 0);
                  }
                }

                return Column(
                  children: List.generate(liveOptions.length > 4 ? 4 : liveOptions.length, (index) {
                    final option = liveOptions[index];
                    final optionText = snapshot.hasData ? option['text'] : option.text;
                    final optionVotes = snapshot.hasData ? (option['votes'] as int? ?? 0) : (option.votes as int);
                    final percentage = totalVotes > 0 ? (optionVotes / totalVotes) : 0.0;
                    final color = optionColors[index % optionColors.length];
                    final voters = demoVoters[index % demoVoters.length];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: Colors.white),
                        child: Stack(
                          children: [
                            // Background progress bar
                            Container(
                              height: 44,
                              width: MediaQuery.of(context).size.width * 0.85 * percentage,
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: color),
                            ),

                            // Content
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  // Check mark for highest voted option
                                  if (percentage > 0.3)
                                    Container(
                                      width: 16,
                                      height: 16,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                                      child: const Icon(Icons.check, size: 12, color: Colors.green),
                                    ),

                                  // Option text
                                  Expanded(
                                    child: Text(
                                      optionText,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: percentage > 0.3 ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),

                                  // Voters avatars (nur für höhere Prozentwerte)
                                  if (percentage > 0.2 && voters.isNotEmpty) ...[
                                    Row(
                                      children: voters
                                          .take(3)
                                          .map(
                                            (voter) => Container(
                                              width: 20,
                                              height: 20,
                                              margin: const EdgeInsets.only(left: 1),
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                              child: Center(child: Text(voter, style: const TextStyle(fontSize: 10))),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                    const SizedBox(width: 8),
                                  ],

                                  // Percentage
                                  Text(
                                    '${(percentage * 100).round()}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: percentage > 0.3 ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),

            const SizedBox(height: 16),

            // Bottom Actions
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                const SizedBox(width: 4),
                Text('3 days remaining', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const Spacer(),
              ],
            ),

            const SizedBox(height: 16),

            // Bottom Actions mit Likes, Comments, Share
            Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.red[400], size: 20),
                    const SizedBox(width: 4),
                    const Text('12', style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 4),
                    const Text('12', style: TextStyle(fontSize: 14)),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    const Text('Share', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Icon(Icons.share, color: Colors.grey[600], size: 20),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Separator line
            Container(height: 1, color: Colors.grey[200]),
          ],
        ),
      ),
    );
  }
}
