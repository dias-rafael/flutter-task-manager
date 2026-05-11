import 'package:task_manager_app/app/features/tasks/domain/domain.dart';
import 'package:task_manager_app/core/network/network_types.dart';

/// Short, user-facing copy for optimistic update failures (snackbar / dialog).
String taskUpdateErrorMessage(Object error) {
  if (error is InvalidTaskTransitionException) {
    return 'That status change is not allowed for this task.';
  }

  if (error is NetworkException) {
    return 'Network problem. Check your connection and try again.';
  }

  if (error is UnknownException) {
    return error.message;
  }

  return 'Something went wrong. Please try again.';
}
