import 'dart:math';

class RetryPolicy {
  const RetryPolicy({this.maxRetries = 5, Random? random}) : _random = random;

  /// After a failed sync, backoff uses this policy's `nextDelay` schedule.
  ///
  /// When the new attempt count would exceed [maxRetries], the sync manager
  /// stops retrying, removes the operation, and reverts from the server if
  /// possible.
  final int maxRetries;

  final Random? _random;

  Duration nextDelay(int retryCount) {
    final exponential = Duration(seconds: 1 << retryCount);

    // jitter

    final randomMs = (_random ?? Random()).nextInt(1000);

    return exponential + Duration(milliseconds: randomMs);
  }
}
