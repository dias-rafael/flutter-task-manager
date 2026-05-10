import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/domain.dart';
import '../bloc/patient_tasks_bloc.dart';

class PatientTasksCard extends StatelessWidget {
  const PatientTasksCard({required this.task, super.key});

  final PatientTasks task;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ------------------------------------------------
            // TITLE + PRIORITY
            // ------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,

                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),

                Chip(label: Text(task.priority.name)),
              ],
            ),

            const SizedBox(height: 8),

            // ------------------------------------------------
            // STATUS
            // ------------------------------------------------
            Text(
              'Status: '
              '${task.status.name}',
            ),

            const SizedBox(height: 8),

            // ------------------------------------------------
            // PATIENT
            // ------------------------------------------------
            Text(
              'Patient: '
              '${task.patientReference}',
            ),

            const SizedBox(height: 16),

            // ------------------------------------------------
            // ACTIONS
            // ------------------------------------------------
            Wrap(
              spacing: 8,

              children: TaskStatus.values
                  .where((status) => status != task.status)
                  .map((status) {
                    return ElevatedButton(
                      onPressed: () {
                        context.read<PatientTasksBloc>().add(
                          UpdateTaskStatus(taskId: task.id, status: status),
                        );
                      },

                      child: Text(status.name),
                    );
                  })
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
