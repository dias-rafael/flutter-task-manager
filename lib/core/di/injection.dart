import 'package:get_it/get_it.dart';

abstract class DI {
  T get<T extends Object>();

  Future<void> allReady();
}

class GetItContainer implements DI {
  final _getIt = GetIt.instance;

  @override
  T get<T extends Object>() => _getIt.get<T>();

  @override
  Future<void> allReady() => _getIt.allReady();

  GetIt get instance => _getIt;
}

// Global reference
final DI injector = GetItContainer();
