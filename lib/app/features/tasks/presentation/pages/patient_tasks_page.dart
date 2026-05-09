import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/dependency_injection.dart';
import '../bloc/patient_tasks_bloc.dart';
import '../widgets/patient_tasks_card.dart';

class PatientTasksPage extends StatelessWidget {
  const PatientTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => injector.get<PatientTasksBloc>()..add(LoadTasks()),
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
          // ---------------------------------------------------------------
          // LOADING
          // ---------------------------------------------------------------

          if (state is PatientTasksLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // ---------------------------------------------------------------
          // ERROR
          // ---------------------------------------------------------------

          if (state is PatientTasksError) {
            return Center(child: Text(state.message));
          }

          // ---------------------------------------------------------------
          // LOADED
          // ---------------------------------------------------------------

          if (state is PatientTasksLoaded) {
            final tasks = state.tasks;

            if (tasks.isEmpty) {
              return const Center(child: Text('No tasks found'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<PatientTasksBloc>().add(LoadTasks());
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),

                itemCount: tasks.length,

                separatorBuilder: (_, __) {
                  return const SizedBox(height: 12);
                },

                itemBuilder: (context, index) {
                  final task = tasks[index];

                  return PatientTasksCard(task: task);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
