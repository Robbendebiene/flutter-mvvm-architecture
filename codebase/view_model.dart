import 'package:get_it/get_it.dart';

import 'service.dart';

abstract class ViewModel {
  T getService<T extends Service>() => GetIt.I<T>();

  void dispose() {}
}
