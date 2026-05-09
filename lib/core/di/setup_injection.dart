import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../network/clients/dio_client.dart';
import '../network/network.dart';
import 'clients/getit_client.dart';
import 'dependency_injection.dart';

Future<void> setupDependencies() async {
  final container = injector as GetItClient;
  final getIt = container.instance;

  // 1. Initialize Hive
  await Hive.initFlutter();

  // Network
  getIt.registerLazySingleton<Network>(() => DioClient(getIt<Dio>()));

  // 2. Open Boxes

  // 3. Data Sources & API

  // 4. Repositories

  // 5. Blocs
}
