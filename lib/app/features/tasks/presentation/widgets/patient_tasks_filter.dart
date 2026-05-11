import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_manager_app/app/features/tasks/domain/enums/task_filter_enum.dart';

import '../bloc/patient_tasks_bloc.dart';

class PatientTasksFilter extends StatelessWidget {
  const PatientTasksFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientTasksBloc, PatientTasksState>(
      builder: (context, state) {
        if (state is! PatientTasksLoaded) {
          return const SizedBox();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TaskFilter.values.map((filter) {
                final selected = state.filter == filter;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(switch (filter) {
                      TaskFilter.all => 'All',
                      TaskFilter.pending => 'Pending',
                      TaskFilter.completed => 'Completed',
                      TaskFilter.cancelled => 'Cancelled',
                    }),
                    selected: selected,
                    onSelected: (_) {
                      context.read<PatientTasksBloc>().add(
                        FilterChanged(filter),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
