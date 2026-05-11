import 'clients/getit_client.dart';

abstract class DI {
  T get<T extends Object>();

  Future<void> allReady();
}

// Global reference
final DI injector = GetItClient();
