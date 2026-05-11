import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/patient_tasks_bloc.dart';

class PatientTasksSync extends StatelessWidget {
  const PatientTasksSync({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PatientTasksBloc>();

    return StreamBuilder<int>(
      stream: bloc.watchPendingSyncCount(),
      initialData: 0,
      builder: (context, snapshot) {
        final pending = snapshot.data ?? 0;

        return Row(
          children: [
            const Text('Patient Tasks'),
            if (pending > 0) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Syncing ($pending)',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
