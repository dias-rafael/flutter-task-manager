import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_manager_app/app/features/tasks/presentation/widgets/patient_tasks_card.dart';

import '../bloc/patient_tasks_bloc.dart';

class PatientTasksList extends StatelessWidget {
  const PatientTasksList({
    super.key,
    required this.scrollController,
    required this.onRefresh,
  });

  final ScrollController scrollController;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BlocBuilder<PatientTasksBloc, PatientTasksState>(
        builder: (context, state) {
          if (state is PatientTasksLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PatientTasksError) {
            return Center(child: Text(state.message));
          }
          if (state is PatientTasksLoaded) {
            if (state.tasks.isEmpty) {
              return const Center(child: Text('No tasks found'));
            }

            return RefreshIndicator(
              onRefresh: () async => onRefresh(),
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: state.tasks.length + (state.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.tasks.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final task = state.tasks[index];
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
