import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../app/features/tasks/data/data.dart';
import '../../app/features/tasks/data/sync/retry_police.dart';
import '../../app/features/tasks/data/sync/sync_manager.dart';
import '../../app/features/tasks/domain/domain.dart';
import '../../app/features/tasks/presentation/bloc/patient_tasks_bloc.dart';
import '../network/clients/dio_client.dart';
import '../network/network.dart';
import 'clients/getit_client.dart';
import 'dependency_injection.dart';

Future<void> setupDependencies() async {
  final getIt = (injector as GetItClient).instance;

  // -------------------------------------------------------------------------
  // Sync Manager
  // -------------------------------------------------------------------------
  getIt
    ..registerLazySingleton(RetryPolicy.new)
    ..registerLazySingleton(
      () => SyncManager(
        local: getIt(),
        remote: getIt(),
        repository: getIt(),
        retryPolicy: getIt(),
      ),
    );
  // -------------------------------------------------------------------------
  // Hive
  // -------------------------------------------------------------------------
  await Hive.initFlutter();

  Hive
    ..registerAdapter(PatientTasksLocalModelAdapter())
    ..registerAdapter(SyncOperationLocalModelAdapter());

  final tasksBox = await Hive.openBox<PatientTasksLocalModel>('patient_tasks');

  final queueBox = await Hive.openBox<SyncOperationLocalModel>('sync_queue');

  getIt
    ..registerLazySingleton(() => tasksBox)
    ..registerLazySingleton(() => queueBox)
    // -------------------------------------------------------------------------
    // Network
    // -------------------------------------------------------------------------
    ..registerLazySingleton<Dio>(Dio.new)
    ..registerLazySingleton<Network>(() => DioClient(getIt<Dio>()))
    // -------------------------------------------------------------------------
    // Data Sources
    // -------------------------------------------------------------------------
    ..registerLazySingleton<PatientTasksRemoteDataSource>(
      () => PatientTasksRemoteDataSourceImpl(getIt<Network>()),
    )
    ..registerLazySingleton<PatientTasksLocalDataSource>(
      () =>
          PatientTasksLocalDataSourceImpl(tasksBox: getIt(), queueBox: getIt()),
    )
    // -------------------------------------------------------------------------
    // Repositories
    // -------------------------------------------------------------------------
    ..registerLazySingleton<PatientTasksRepository>(
      () => PatientTasksRepositoryImpl(
        local: getIt<PatientTasksLocalDataSource>(),
        remote: getIt<PatientTasksRemoteDataSource>(),
      ),
    )
    // -------------------------------------------------------------------------
    // Blocs
    // -------------------------------------------------------------------------
    ..registerFactory<PatientTasksBloc>(
      () => PatientTasksBloc(repository: getIt<PatientTasksRepository>()),
    );
}
