import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_manager_app/app/features/tasks/presentation/widgets/patient_tasks_filter.dart';
import 'package:task_manager_app/app/features/tasks/presentation/widgets/patient_tasks_list.dart';
import 'package:task_manager_app/app/features/tasks/presentation/widgets/patient_tasks_search.dart';
import 'package:task_manager_app/app/features/tasks/presentation/widgets/patient_tasks_sync.dart';

import '../../../../../core/di/dependency_injection.dart';
import '../bloc/patient_tasks_bloc.dart';

class PatientTasksPage extends StatelessWidget {
  const PatientTasksPage({super.key, this.blocForTesting});

  /// Optional bloc for widget tests (skips [injector]).
  final PatientTasksBloc? blocForTesting;

  @override
  Widget build(BuildContext context) {
    final bloc = blocForTesting ?? injector.get<PatientTasksBloc>();

    return _PatientTasksBlocHost(bloc: bloc, child: const _PatientTasksView());
  }
}

/// Provides an existing bloc without closing it when the route disposes
/// (required for the app-wide GetIt singleton).
class _PatientTasksBlocHost extends StatefulWidget {
  const _PatientTasksBlocHost({required this.bloc, required this.child});

  final PatientTasksBloc bloc;
  final Widget child;

  @override
  State<_PatientTasksBlocHost> createState() => _PatientTasksBlocHostState();
}

class _PatientTasksBlocHostState extends State<_PatientTasksBlocHost> {
  @override
  void initState() {
    super.initState();

    widget.bloc.add(LoadTasks());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PatientTasksBloc>.value(
      value: widget.bloc,
      child: widget.child,
    );
  }
}

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

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent - 200;

    if (_scrollController.position.pixels >= threshold) {
      context.read<PatientTasksBloc>().add(LoadNextPage());
    }
  }

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
        appBar: AppBar(title: const PatientTasksSync()),
        body: Column(
          children: [
            PatientTasksSearch(searchController: _searchController),
            const PatientTasksFilter(),
            PatientTasksList(
              scrollController: _scrollController,
              onRefresh: _onRefresh,
            ),
          ],
        ),
      ),
    );
  }
}
