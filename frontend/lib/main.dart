import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:pollino/bloc/poll.dart';
import 'package:pollino/bloc/poll_bloc.dart';
import 'package:pollino/env.dart';
import 'package:routemaster/routemaster.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter<Poll>(PollAdapter());
  Hive.registerAdapter<Option>(OptionAdapter());
  final hiveBox = await Hive.openBox<Poll>('polls');

  final pollBloc = PollBloc(hiveBox);
  pollBloc.synchronizeWithBackend();

  await Supabase.initialize(url: Environment.supabaseUrl, anonKey: Environment.supabaseAnonKey);

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
        debugShowCheckedModeBanner: false,
        routerDelegate: RoutemasterDelegate(routesBuilder: (context) => routes),
        routeInformationParser: const RoutemasterParser(),
        // supportedLocales: const [Locale('en', 'GB'), Locale('de', 'DE')],
      ),
    );
  }
}
