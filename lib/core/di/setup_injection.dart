import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../app/features/tasks/data/data.dart';
import '../../app/features/tasks/domain/domain.dart';
import '../../app/features/tasks/presentation/bloc/patient_tasks_bloc.dart';
import '../network/clients/dio_client.dart';
import '../network/network.dart';
import 'clients/getit_client.dart';
import 'dependency_injection.dart';

Future<void> setupDependencies() async {
  final container = injector as GetItClient;
  final getIt = container.instance;

  // ---------------------------------------------------------------------------
  // Hive
  // ---------------------------------------------------------------------------
  await Hive.initFlutter();

  // ---------------------------------------------------------------------------
  // Network
  // ---------------------------------------------------------------------------
  getIt
    ..registerLazySingleton<Dio>(Dio.new)
    ..registerLazySingleton<Network>(() => DioClient(getIt<Dio>()))
    // ---------------------------------------------------------------------------
    // Data Sources
    // ---------------------------------------------------------------------------
    ..registerLazySingleton<PatientTasksRemoteDataSource>(
      () => PatientTasksRemoteDataSourceImpl(getIt<Network>()),
    )
    ..registerLazySingleton<PatientTasksLocalDataSource>(
      PatientTasksLocalDataSourceImpl.new,
    )
    // ---------------------------------------------------------------------------
    // Repositories
    // ---------------------------------------------------------------------------
    ..registerLazySingleton<PatientTasksRepository>(
      () => PatientTasksRepositoryImpl(
        local: getIt<PatientTasksLocalDataSource>(),
        remote: getIt<PatientTasksRemoteDataSource>(),
      ),
    )
    // ---------------------------------------------------------------------------
    // Blocs
    // ---------------------------------------------------------------------------
    ..registerFactory<PatientTasksBloc>(
      () => PatientTasksBloc(repository: getIt<PatientTasksRepository>()),
    );
}
