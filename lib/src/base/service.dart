import 'package:get_it/get_it.dart';

import 'repository.dart';

abstract class Service {
  T getRepository<T extends Repository>() => GetIt.I<T>();

  T getService<T extends Service>() => GetIt.I<T>();
}
