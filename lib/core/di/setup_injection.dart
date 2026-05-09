import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_manager_app/core/di/injection.dart';

Future<void> setupDependencies() async {
  final container = injector as GetItContainer;
  final getIt = container.instance;

  // 1. Initialize Hive
  await Hive.initFlutter();

  // 2. Open Boxes

  // 3. Data Sources & API

  // 4. Repositories

  // 5. Blocs
}
