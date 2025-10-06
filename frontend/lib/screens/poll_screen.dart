import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pollino/bloc/poll_bloc.dart';

class PollScreen extends StatelessWidget {
  final String pollId;

  const PollScreen({super.key, required this.pollId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PollBloc>(
      create: (_) => PollBloc(context.read<PollBloc>().hiveBox)..add(PollEvent.loadPoll(pollId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Poll')),
        body: BlocBuilder<PollBloc, PollState>(
          builder: (context, state) {
            if (state is Loading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is Loaded) {
              final poll = state.polls.first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(poll.title, style: Theme.of(context).textTheme.headlineLarge),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: poll.options.length,
                      itemBuilder: (context, index) {
                        final option = poll.options[index];
                        return ListTile(
                          title: Text(option.text),
                          trailing: Text('${option.votes} votes'),
                          onTap: () {
                            context.read<PollBloc>().add(PollEvent.vote(pollId, option.id));
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            } else if (state is Error) {
              return Center(child: Text(state.message));
            } else {
              return const Center(child: Text('No poll data available.'));
            }
          },
        ),
      ),
    );
  }
}
