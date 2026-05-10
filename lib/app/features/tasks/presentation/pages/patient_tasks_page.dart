import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/dependency_injection.dart';
import '../../domain/enums/task_filter_enum.dart';
import '../bloc/patient_tasks_bloc.dart';
import '../widgets/patient_tasks_card.dart';

class PatientTasksPage extends StatelessWidget {
  const PatientTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PatientTasksBloc>(
      create: (_) => injector.get<PatientTasksBloc>()..add(LoadTasks()),

      child: const _PatientTasksView(),
    );
  }
}

// ============================================================
// INTERNAL VIEW
// ============================================================

class _PatientTasksView extends StatefulWidget {
  const _PatientTasksView();

  @override
  State<_PatientTasksView> createState() => _PatientTasksViewState();
}

class _PatientTasksViewState extends State<_PatientTasksView> {
  late final ScrollController _scrollController;

  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController()..addListener(_onScroll);

    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.dispose();

    _searchController.dispose();

    super.dispose();
  }

  // =========================================================
  // PAGINATION
  // =========================================================

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent - 200;

    if (_scrollController.position.pixels >= threshold) {
      context.read<PatientTasksBloc>().add(LoadNextPage());
    }
  }

  // =========================================================
  // REFRESH
  // =========================================================

  Future<void> _onRefresh() async {
    context.read<PatientTasksBloc>().add(LoadTasks());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PatientTasksBloc, PatientTasksState>(
      listener: (context, state) {
        if (state is PatientTasksUiMessage) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.alertMessage)));
        }
      },

      child: Scaffold(
        appBar: AppBar(title: const _SyncingTitle()),

        body: Column(
          children: [
            // SEARCH
            Padding(
              padding: const EdgeInsets.all(16),

              child: TextField(
                controller: _searchController,

                decoration: InputDecoration(
                  hintText: 'Search tasks',

                  prefixIcon: const Icon(Icons.search),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                onChanged: (value) {
                  context.read<PatientTasksBloc>().add(SearchTasks(value));
                },
              ),
            ),

            // FILTERS
            BlocBuilder<PatientTasksBloc, PatientTasksState>(
              builder: (context, state) {
                if (state is! PatientTasksLoaded) {
                  return const SizedBox();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
            ),

            // CONTENT
            Expanded(
              child: BlocBuilder<PatientTasksBloc, PatientTasksState>(
                builder: (context, state) {
                  // LOADING

                  if (state is PatientTasksLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // ERROR

                  if (state is PatientTasksError) {
                    return Center(child: Text(state.message));
                  }

                  // LOADED

                  if (state is PatientTasksLoaded) {
                    if (state.tasks.isEmpty) {
                      return const Center(child: Text('No tasks found'));
                    }

                    return RefreshIndicator(
                      onRefresh: _onRefresh,

                      child: ListView.builder(
                        controller: _scrollController,

                        padding: const EdgeInsets.only(bottom: 24),

                        itemCount:
                            state.tasks.length + (state.isLoadingMore ? 1 : 0),

                        itemBuilder: (context, index) {
                          // PAGINATION LOADER

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
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SYNC TITLE
// ============================================================

class _SyncingTitle extends StatelessWidget {
  const _SyncingTitle();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PatientTasksBloc>();

    return StreamBuilder<int>(
      stream: bloc.repository.watchPendingSyncCount(),

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
