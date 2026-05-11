import 'dart:async';

import 'package:flutter/material.dart';

import 'app/features/tasks/data/sync/sync_manager.dart';
import 'app/features/tasks/presentation/pages/patient_tasks_page.dart';
import 'core/di/dependency_injection.dart';
import 'core/di/setup_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  await injector.allReady();

  unawaited(injector.get<SyncManager>().start());

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final sync = injector.get<SyncManager>();

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        unawaited(sync.stop());
        break;
      case AppLifecycleState.resumed:
        unawaited(sync.start());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const PatientTasksPage(),
    );
  }
}
