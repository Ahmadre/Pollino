import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Core
import 'core/network/network_info.dart';

// Features - Domain
import 'features/polls/domain/repositories/poll_repository.dart';
import 'features/polls/domain/usecases/get_polls.dart';
import 'features/polls/domain/usecases/create_poll.dart';
import 'features/polls/domain/usecases/cast_vote.dart';

// Features - Data
import 'features/polls/data/datasources/poll_local_data_source.dart';
import 'features/polls/data/datasources/poll_remote_data_source.dart';
import 'features/polls/data/repositories/poll_repository_impl.dart';
import 'features/polls/data/models/poll_model.dart';

final sl = GetIt.instance; // Service Locator

Future<void> init() async {
  //! Features - Polls

  // Use cases
  sl.registerLazySingleton(() => GetPolls(sl()));
  sl.registerLazySingleton(() => CreatePoll(sl()));
  sl.registerLazySingleton(() => CastVote(sl()));

  // Repository
  sl.registerLazySingleton<PollRepository>(
    () => PollRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<PollRemoteDataSource>(
    () => PollRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<PollLocalDataSource>(
    () => PollLocalDataSourceImpl(box: sl()),
  );

  //! Core

  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );

  //! External

  // Supabase
  sl.registerLazySingleton(() => Supabase.instance.client);

  // Connectivity
  sl.registerLazySingleton(() => Connectivity());
}

/// Initialize Hive box separately since it requires async initialization
Future<void> initializeHiveBox() async {
  await Hive.initFlutter();
  final box = await Hive.openBox<PollModel>('polls_cache');
  sl.registerLazySingleton<Box<PollModel>>(() => box);
}
