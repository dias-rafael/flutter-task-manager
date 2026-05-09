import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/dependency_injection.dart';
import '../../domain/enums/task_status_enum.dart';
import '../bloc/patient_tasks_bloc.dart';

class PatientTasksPage extends StatelessWidget {
  const PatientTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => injector.get<PatientTasksBloc>()..add(FetchPatientTasks()),
      child: const PatientTasksView(),
    );
  }
}

class PatientTasksView extends StatelessWidget {
  const PatientTasksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Tasks')),
      body: BlocBuilder<PatientTasksBloc, PatientTasksState>(
        builder: (context, state) {
          if (state is PatientTasksLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PatientTasksError) {
            return Center(child: Text(state.message));
          }

          if (state is PatientTasksLoaded) {
            return ListView.builder(
              itemCount: state.tasks.length,
              itemBuilder: (context, index) {
                final task = state.tasks[index];

                return ListTile(
                  title: Text(task.title),
                  subtitle: Text(task.status.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      context.read<PatientTasksBloc>().add(
                        UpdatePatientTaskStatus(
                          taskId: task.id,
                          status: TaskStatus.completed,
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
