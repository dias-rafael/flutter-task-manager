import 'dart:math';

class RetryPolicy {
  const RetryPolicy({this.maxRetries = 5, Random? random}) : _random = random;

  final int maxRetries;

  final Random? _random;

  Duration nextDelay(int retryCount) {
    final exponential = Duration(seconds: 1 << retryCount);

    // jitter

    final randomMs = (_random ?? Random()).nextInt(1000);

    return exponential + Duration(milliseconds: randomMs);
  }
}
