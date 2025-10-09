import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:pollino/bloc/poll.dart';
import 'package:pollino/bloc/poll_bloc.dart';
import 'package:pollino/core/localization/i18n_service.dart';
import 'package:pollino/core/localization/rtl_support.dart';
import 'package:pollino/core/theme/app_theme.dart';
import 'package:pollino/env.dart';
import 'package:pollino/services/like_service.dart';
import 'package:routemaster/routemaster.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Routemaster.setPathUrlStrategy();

  // Initialize Hive for local caching and preferences
  await Hive.initFlutter();
  // Ensure a generic app preferences box is available for services (i18n, comments)
  await Hive.openBox('app_prefs');

  // Initialize i18n Service with automatic system locale detection (uses Hive)
  await I18nService.instance.initWithSystemLocale();
  Hive.registerAdapter<Poll>(PollAdapter());
  Hive.registerAdapter<Option>(OptionAdapter());
  final hiveBox = await Hive.openBox<Poll>('polls');

  // Initialize LikeService for local like storage
  await LikeService.init();

  // Initialize Supabase connection
  await Supabase.initialize(url: Environment.supabaseUrl, anonKey: Environment.supabaseAnonKey);

  // Initialize BLoC with local storage
  final pollBloc = PollBloc(hiveBox);

  runApp(MyApp(pollBloc: pollBloc));
}

class MyApp extends StatefulWidget {
  final PollBloc pollBloc;
  const MyApp({super.key, required this.pollBloc});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<String> _localeSubscription;
  String _currentLocale = I18nService.instance.currentLocale;

  @override
  void initState() {
    super.initState();
    // Höre auf Locale-Änderungen
    _localeSubscription = I18nService.instance.localeStream.listen((newLocale) {
      if (mounted && newLocale != _currentLocale) {
        setState(() {
          _currentLocale = newLocale;
        });
      }
    });
  }

  @override
  void dispose() {
    _localeSubscription.cancel();
    super.dispose();
  }

  /// Konvertiert unser Locale-Format zu Flutter Locale
  Locale _getFlutterLocale() {
    final parts = _currentLocale.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    // Fallback
    return const Locale('en', 'GB');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PollBloc(widget.pollBloc.hiveBox)..add(const PollEvent.loadPolls(page: 1, limit: 20)),
      child: RTLDirectionalityWrapper(
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: false,
          routerDelegate: RoutemasterDelegate(routesBuilder: (context) => routes),
          routeInformationParser: const RoutemasterParser(),
          supportedLocales: const [
            Locale('de', 'DE'),
            Locale('en', 'GB'),
            Locale('fr', 'FR'),
            Locale('es', 'ES'),
            Locale('ja', 'JP'),
            Locale('ar', 'SA'),
          ],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: _getFlutterLocale(), // Verwendet die erkannte System-Locale
          // Fallback falls System-Locale nicht unterstützt wird
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale != null) {
              // Prüfe exakte Übereinstimmung zuerst
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode &&
                    supportedLocale.countryCode == locale.countryCode) {
                  return supportedLocale;
                }
              }

              // Dann prüfe nur Sprachcode mit regionaler Präferenz
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode) {
                  return supportedLocale;
                }
              }
            }
            // Fallback zu Englisch
            return const Locale('en', 'GB');
          },
        ),
      ),
    );
  }
}
