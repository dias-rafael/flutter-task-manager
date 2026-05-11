import '../enums/enums.dart';

class InvalidTaskTransitionException implements Exception {
  InvalidTaskTransitionException({
    required this.current,
    required this.attempted,
  });

  final TaskStatus current;
  final TaskStatus attempted;

  @override
  String toString() {
    return '''
Invalid transition:
$current -> $attempted
''';
  }
}
