import 'dart:math';

class RetryPolicy {
  const RetryPolicy({this.maxRetries = 5});

  final int maxRetries;

  Duration nextDelay(int retryCount) {
    final exponential = Duration(seconds: 1 << retryCount);

    // jitter

    final randomMs = Random().nextInt(1000);

    return exponential + Duration(milliseconds: randomMs);
  }
}
