import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_app/app/features/tasks/domain/domain.dart';
import 'package:task_manager_app/app/features/tasks/presentation/utils/task_update_error_message.dart';
import 'package:task_manager_app/core/network/network_types.dart';

void main() {
  group('taskUpdateErrorMessage', () {
    test('maps invalid transition', () {
      expect(
        taskUpdateErrorMessage(
          InvalidTaskTransitionException(
            current: TaskStatus.completed,
            attempted: TaskStatus.inProgress,
          ),
        ),
        'That status change is not allowed for this task.',
      );
    });

    test('maps network errors', () {
      expect(
        taskUpdateErrorMessage(NetworkException(message: 'timeout')),
        'Network problem. Check your connection and try again.',
      );
    });

    test('passes through unknown exception message', () {
      expect(
        taskUpdateErrorMessage(UnknownException(message: 'Custom')),
        'Custom',
      );
    });

    test('uses generic fallback', () {
      expect(
        taskUpdateErrorMessage(Exception('conflict')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
