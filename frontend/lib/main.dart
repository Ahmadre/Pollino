import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:pollino/bloc/poll.dart';
import 'package:pollino/bloc/pull_bloc.dart';
import 'package:routemaster/routemaster.dart';
import 'package:i18next/i18next.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter<Poll>(PollAdapter());
  Hive.registerAdapter<Option>(OptionAdapter());
  final hiveBox = await Hive.openBox<Poll>('polls');

  final pollBloc = PollBloc(hiveBox);
  pollBloc.synchronizeWithBackend();

  runApp(MyApp(pollBloc: pollBloc));
}

class MyApp extends StatelessWidget {
  final PollBloc pollBloc;
  const MyApp({super.key, required this.pollBloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PollBloc(pollBloc.hiveBox)..add(const PollEvent.loadPolls(page: 1, limit: 20)),
      child: MaterialApp.router(
        routerDelegate: RoutemasterDelegate(routesBuilder: (context) => routes),
        routeInformationParser: const RoutemasterParser(),
        // supportedLocales: const [Locale('en', 'GB'), Locale('de', 'DE')],
      ),
    );
  }
}