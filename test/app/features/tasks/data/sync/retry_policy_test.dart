import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_app/app/features/tasks/data/sync/retry_policy.dart';

class FakeRandom extends Fake implements Random {
  @override
  int nextInt(int max) {
    return 500;
  }
}

void main() {
  group('RetryPolicy', () {
    test(
      '''
nextDelay is deterministic
with injected random
''',
      () {
        final retryPolicy = RetryPolicy(random: FakeRandom());

        final delay1 = retryPolicy.nextDelay(1);

        final delay2 = retryPolicy.nextDelay(2);

        final delay3 = retryPolicy.nextDelay(3);

        expect(delay1, const Duration(seconds: 2, milliseconds: 500));

        expect(delay2, const Duration(seconds: 4, milliseconds: 500));

        expect(delay3, const Duration(seconds: 8, milliseconds: 500));
      },
    );
  });
}
