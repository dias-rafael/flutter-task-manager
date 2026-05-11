import 'package:get_it/get_it.dart';

import '../dependency_injection.dart';

class GetItClient implements DI {
  final _getIt = GetIt.instance;

  @override
  T get<T extends Object>() => _getIt.get<T>();

  @override
  Future<void> allReady() => _getIt.allReady();

  GetIt get instance => _getIt;
}
