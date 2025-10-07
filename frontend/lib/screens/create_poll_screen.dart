import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pollino/bloc/poll_bloc.dart';
import 'package:pollino/services/supabase_service.dart';
import 'package:routemaster/routemaster.dart';

class CreatePollScreen extends StatefulWidget {
  const CreatePollScreen({super.key});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _creatorNameController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  bool _isLoading = false;
  bool _allowMultipleOptions = false;
  bool _enableAnonymousVoting = true;

  @override
  void initState() {
    super.initState();
    // Starte mit zwei Optionen
    _addOption();
    _addOption();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _creatorNameController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  Future<void> _createPoll() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final question = _questionController.text.trim();
      final options =
          _optionControllers.map((controller) => controller.text.trim()).where((text) => text.isNotEmpty).toList();

      if (options.length < 2) {
        throw Exception('Mindestens 2 Optionen sind erforderlich');
      }

      await SupabaseService.createPoll(
        title: question,
        optionTexts: options,
        isAnonymous: _enableAnonymousVoting,
        allowsMultipleVotes: _allowMultipleOptions,
        creatorName: _enableAnonymousVoting ? null : _creatorNameController.text.trim(),
      );

      if (mounted) {
        context.read<PollBloc>().add(const PollEvent.refreshPolls());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Poll erfolgreich erstellt!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        Routemaster.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const Spacer(),
                    const Text(
                      'Create a Poll',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 24), // Balance for close icon
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ask a Question
                      const Text(
                        'Ask a Question*',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE9ECEF)),
                        ),
                        child: TextFormField(
                          controller: _questionController,
                          decoration: const InputDecoration(
                            hintText: 'Type Here...',
                            hintStyle: TextStyle(
                              color: Color(0xFFADB5BD),
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Bitte gib eine Frage ein';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Poll Options
                      const Text(
                        'Poll Options',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Options List
                      ...List.generate(_optionControllers.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              // Drag handle
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(right: 12),
                                child: Icon(
                                  Icons.drag_indicator,
                                  color: Colors.grey[400],
                                  size: 16,
                                ),
                              ),

                              // Option input
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE9ECEF)),
                                  ),
                                  child: TextFormField(
                                    controller: _optionControllers[index],
                                    decoration: InputDecoration(
                                      hintText: 'Option ${index + 1}',
                                      hintStyle: const TextStyle(
                                        color: Color(0xFFADB5BD),
                                        fontSize: 16,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Option darf nicht leer sein';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),

                              // Remove button
                              if (_optionControllers.length > 2)
                                IconButton(
                                  onPressed: () => _removeOption(index),
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),

                      // Add Another Option
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _addOption,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add Another Option',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Poll Settings
                      const Text(
                        'Poll Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Allow people to choose Multiple Options
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Allow people to choose Multiple Options',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'People can select more than one option.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _allowMultipleOptions,
                            onChanged: (value) {
                              setState(() {
                                _allowMultipleOptions = value;
                              });
                            },
                            activeColor: const Color(0xFF007AFF),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Enable Anonymous Voting
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE9ECEF)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Anonyme Umfrage',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _enableAnonymousVoting
                                        ? 'Umfrage wird anonym erstellt - kein Ersteller sichtbar'
                                        : 'Dein Name wird als Ersteller angezeigt',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _enableAnonymousVoting,
                              onChanged: (value) {
                                setState(() {
                                  _enableAnonymousVoting = value;
                                });
                              },
                              activeColor: const Color(0xFF007AFF),
                            ),
                          ],
                        ),
                      ),

                      // Creator Name Field (nur wenn nicht anonym)
                      if (!_enableAnonymousVoting) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Dein Name*',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE9ECEF)),
                          ),
                          child: TextFormField(
                            controller: _creatorNameController,
                            decoration: const InputDecoration(
                              hintText: 'Gib deinen Namen ein...',
                              hintStyle: TextStyle(
                                color: Color(0xFFADB5BD),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Color(0xFFADB5BD),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            validator: (value) {
                              if (!_enableAnonymousVoting && (value == null || value.trim().isEmpty)) {
                                return 'Bitte gib deinen Namen ein';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Set an Expiration Date & Time
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Set an Expiration Date & Time',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You can change this later via edit.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: false,
                            onChanged: (value) {
                              // Expiration functionality
                            },
                            activeColor: const Color(0xFF007AFF),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Next Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createPoll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
