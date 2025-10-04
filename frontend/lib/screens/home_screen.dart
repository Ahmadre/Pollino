import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pollino/bloc/pull_bloc.dart';
import 'package:routemaster/routemaster.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  final int _limit = 10;

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
      appBar: AppBar(title: const Text('Polls')),
      body: BlocBuilder<PollBloc, PollState>(
        builder: (context, state) {
          if (state is Loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is Loaded) {
            return ListView.builder(
              controller: _scrollController,
              itemCount: state.polls.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.polls.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final poll = state.polls[index];
                return ListTile(
                  title: Text(poll.title),
                  subtitle: Text('Votes: ${poll.options.fold<int>(0, (sum, option) => sum + option.votes)}'),
                  onTap: () => Routemaster.of(context).push('/poll/${poll.id}'),
                );
              },
            );
          } else if (state is Error) {
            return Center(child: Text(state.message));
          } else {
            return const Center(child: Text('No polls available.'));
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}