import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/domain.dart';
import '../bloc/patient_tasks_bloc.dart';

class PatientTasksCard extends StatelessWidget {
  const PatientTasksCard({super.key, required this.task});

  final PatientTasks task;

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == TaskStatus.completed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------------------------------------------------
            // TITLE
            // ---------------------------------------------------------
            Text(task.title, style: Theme.of(context).textTheme.titleMedium),

            const SizedBox(height: 8),

            // ---------------------------------------------------------
            // STATUS
            // ---------------------------------------------------------
            Text('Status: ${task.status.name}'),

            // ---------------------------------------------------------
            // PRIORITY
            // ---------------------------------------------------------
            Text('Priority: ${task.priority.name}'),

            // ---------------------------------------------------------
            // PATIENT
            // ---------------------------------------------------------
            Text('Patient: ${task.patientReference}'),

            // ---------------------------------------------------------
            // ASSIGNEE
            // ---------------------------------------------------------
            if (task.assignee != null) Text('Assigned to: ${task.assignee}'),

            // ---------------------------------------------------------
            // DUE DATE
            // ---------------------------------------------------------
            if (task.dueDate != null) Text('Due: ${task.dueDate}'),

            const SizedBox(height: 16),

            // ---------------------------------------------------------
            // ACTIONS
            // ---------------------------------------------------------
            Row(
              children: [
                // START TASK
                if (task.status == TaskStatus.requested)
                  ElevatedButton(
                    onPressed: () {
                      context.read<PatientTasksBloc>().add(
                        UpdateTaskStatus(
                          taskId: task.id,
                          status: TaskStatus.inProgress,
                        ),
                      );
                    },
                    child: const Text('Start'),
                  ),

                // COMPLETE TASK
                if (task.status == TaskStatus.inProgress)
                  ElevatedButton(
                    onPressed: () {
                      context.read<PatientTasksBloc>().add(
                        UpdateTaskStatus(
                          taskId: task.id,
                          status: TaskStatus.completed,
                        ),
                      );
                    },
                    child: const Text('Complete'),
                  ),

                // COMPLETED LABEL
                if (isCompleted) const Chip(label: Text('Completed')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
