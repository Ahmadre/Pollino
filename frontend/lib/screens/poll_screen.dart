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
  List<String> _selectedOptionIds = [];
  bool _hasVoted = false;
  bool _isAnonymousVote = true;
  final _voterNameController = TextEditingController();

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

  Future<void> _submitVote() async {
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

      // Kurz warten dann zurück zur Hauptübersicht navigieren
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      // Verstecke Loading Indicator
      if (mounted) Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Abstimmen: ${e.toString()}'),
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

                                // Voting Controls (nur wenn noch nicht abgestimmt)
                                if (!_hasVoted) ...[
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
                                            _isAnonymousVote ? 'Anonym abstimmen' : 'Mit Name abstimmen',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        Switch(
                                          value: !_isAnonymousVote,
                                          onChanged: (value) {
                                            setState(() {
                                              _isAnonymousVote = !value;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Name Input (wenn nicht anonym)
                                  if (!_isAnonymousVote)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: TextField(
                                        controller: _voterNameController,
                                        decoration: InputDecoration(
                                          labelText: 'Dein Name',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
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
                                      child: const Row(
                                        children: [
                                          Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Du kannst mehrere Optionen wählen',
                                              style: TextStyle(color: Colors.blue, fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],

                                // Poll Options
                                Expanded(
                                  child: Column(
                                    children: [
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
                                            final isSelected = _selectedOptionIds.contains(optionId);

                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 12),
                                              child: _PollOption(
                                                text: optionText,
                                                votes: optionVotes,
                                                percentage: percentage,
                                                color: _optionColors[index % _optionColors.length],
                                                voters: _demoVoters[index % _demoVoters.length],
                                                hasVoted: _hasVoted,
                                                isSelected: isSelected,
                                                allowsMultiple: poll.allowsMultipleVotes,
                                                onTap: _hasVoted
                                                    ? null
                                                    : () => _toggleOptionSelection(optionId, poll.allowsMultipleVotes),
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      // Vote Button (nur wenn noch nicht abgestimmt)
                                      if (!_hasVoted && _selectedOptionIds.isNotEmpty)
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
                                                    ? 'Abstimmen (${_selectedOptionIds.length} ausgewählt)'
                                                    : 'Abstimmen',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
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
