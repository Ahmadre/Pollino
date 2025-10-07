import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pollino/bloc/poll_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PollScreen extends StatefulWidget {
  final String pollId;

  const PollScreen({super.key, required this.pollId});

  @override
  State<PollScreen> createState() => _PollScreenState();
}

class _PollScreenState extends State<PollScreen> {
  String? _selectedOptionId;
  bool _hasVoted = false;
  bool _isAnonymousVote = true;
  String _voterName = '';
  final _voterNameController = TextEditingController();

  @override
  void dispose() {
    _voterNameController.dispose();
    super.dispose();
  }

  Future<void> _showVotingDialog(BuildContext context, poll, String optionId, String optionText) async {
    bool tempIsAnonymous = true;
    final tempController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Abstimmen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Du wählst: "$optionText"'),
                  const SizedBox(height: 20),

                  // Anonymous Toggle
                  Row(
                    children: [
                      Checkbox(
                        value: tempIsAnonymous,
                        onChanged: (value) {
                          setDialogState(() {
                            tempIsAnonymous = value ?? true;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text('Anonym abstimmen'),
                      ),
                    ],
                  ),

                  // Name Input (if not anonymous)
                  if (!tempIsAnonymous) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: tempController,
                      decoration: const InputDecoration(
                        labelText: 'Dein Name',
                        border: OutlineInputBorder(),
                        hintText: 'Gib deinen Namen ein...',
                      ),
                    ),
                  ],
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Abbrechen'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!tempIsAnonymous && tempController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bitte gib deinen Namen ein')),
                      );
                      return;
                    }

                    try {
                      await context.read<PollBloc>().voteWithName(
                            widget.pollId,
                            optionId,
                            isAnonymous: tempIsAnonymous,
                            voterName: tempIsAnonymous ? null : tempController.text.trim(),
                          );

                      setState(() {
                        _selectedOptionId = optionId;
                        _hasVoted = true;
                        _isAnonymousVote = tempIsAnonymous;
                        _voterName = tempIsAnonymous ? '' : tempController.text.trim();
                      });

                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Stimme erfolgreich abgegeben!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Fehler beim Abstimmen: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }

                    tempController.dispose();
                  },
                  child: const Text('Abstimmen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Farben für die Optionen wie im Screenshot
  final List<Color> _optionColors = [
    const Color(0xFF4CAF50), // Grün für "A New Place!"
    const Color(0xFF64B5F6), // Hellblau für "At Office"
    const Color(0xFF9575CD), // Lila für "Regular Place"
    const Color(0xFFFFB74D), // Orange/Gelb für "Any will do"
  ];

  // Demo-Avatare wie im Screenshot (Emojis)
  final List<List<String>> _demoVoters = [
    ['👩‍💻', '👨‍💼', '👩‍🎨'], // A New Place
    ['👨‍💻', '👩‍💼'], // At Office
    ['👩‍🏫', '👨‍🎓', '👩‍⚕️'], // Regular Place
    ['👨‍🍳'], // Any will do
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PollBloc>(
      create: (_) => PollBloc(context.read<PollBloc>().hiveBox)..add(PollEvent.loadPoll(widget.pollId)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mit Back Button und Recent Activity
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Recent Activity',
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterTab(icon: Icons.push_pin, label: 'Pins', isSelected: false),
                      _FilterTab(icon: Icons.poll, label: 'Umfragen', isSelected: true),
                      _FilterTab(icon: Icons.description, label: 'Dateien', isSelected: false),
                      _FilterTab(icon: Icons.photo, label: 'Fotos', isSelected: false),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Poll Content
              Expanded(
                child: BlocBuilder<PollBloc, PollState>(
                  builder: (context, state) {
                    if (state is Loading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is Loaded) {
                      final poll = state.polls.first;
                      return StreamBuilder<List<Map<String, dynamic>>>(
                        stream: Supabase.instance.client
                            .from('poll_options')
                            .stream(primaryKey: ['id']).eq('poll_id', widget.pollId),
                        builder: (context, snapshot) {
                          List<dynamic> liveOptions = poll.options;
                          int totalVotes = poll.options.fold<int>(0, (sum, option) => sum + option.votes);

                          if (snapshot.hasData && snapshot.data != null) {
                            liveOptions = snapshot.data!;
                            totalVotes = liveOptions.fold<int>(
                              0,
                              (sum, option) => sum + (option['votes'] as int? ?? 0),
                            );
                          }

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
                                          poll.createdByName ?? 'Anonymer Ersteller',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          poll.isAnonymous ? 'Anonyme Umfrage' : 'Nicht-anonyme Umfrage',
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

                                const SizedBox(height: 8),

                                // Vote count
                                Text(
                                  '$totalVotes votes • Vote to see results',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),

                                const SizedBox(height: 20),

                                // Poll Options
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: liveOptions.length,
                                    itemBuilder: (context, index) {
                                      final option = liveOptions[index];
                                      final optionId = snapshot.hasData ? option['id'].toString() : option.id;
                                      final optionText = snapshot.hasData ? option['text'] : option.text;
                                      final optionVotes =
                                          snapshot.hasData ? (option['votes'] as int? ?? 0) : option.votes;
                                      final percentage = totalVotes > 0 ? (optionVotes / totalVotes) : 0.0;

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _PollOption(
                                          text: optionText,
                                          votes: optionVotes,
                                          percentage: percentage,
                                          color: _optionColors[index % _optionColors.length],
                                          voters: _demoVoters[index % _demoVoters.length],
                                          hasVoted: _hasVoted,
                                          onTap: _hasVoted
                                              ? null
                                              : () => _showVotingDialog(context, poll, optionId, optionText),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // Bottom Actions
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
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
              ),
            ],
          ),
        ),
      ),
    );
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

class _PollOption extends StatelessWidget {
  final String text;
  final int votes;
  final double percentage;
  final Color color;
  final List<String> voters;
  final bool hasVoted;
  final VoidCallback? onTap;

  const _PollOption({
    required this.text,
    required this.votes,
    required this.percentage,
    required this.color,
    required this.voters,
    required this.hasVoted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(27), color: Colors.white),
        child: Stack(
          children: [
            // Background progress bar
            if (hasVoted)
              Container(
                height: 54,
                width: MediaQuery.of(context).size.width * 0.85 * percentage,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(27), color: color),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Check mark for voted option
                  if (hasVoted)
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: hasVoted && percentage > 0 ? Colors.white : Colors.black,
                      ),
                    ),
                  ),

                  // Voters avatars
                  if (hasVoted && voters.isNotEmpty) ...[
                    Row(
                      children: voters
                          .take(3)
                          .map(
                            (voter) => Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(left: 2),
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                              child: Center(child: Text(voter, style: const TextStyle(fontSize: 12))),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Percentage
                  if (hasVoted)
                    Text(
                      '${(percentage * 100).round()}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: percentage > 0 ? Colors.white : Colors.black,
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
