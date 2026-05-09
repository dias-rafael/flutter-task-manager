import 'package:flutter/material.dart';

import 'app/features/tasks/presentation/pages/patient_tasks_page.dart';
import 'core/di/dependency_injection.dart';
import 'core/di/setup_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  await injector.allReady();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const PatientTasksPage(),
    );
  }
}
