// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../services/api_request_scheduler.dart' as _i630;
import '../services/api_service.dart' as _i137;
import '../services/cache_service.dart' as _i717;
import '../services/connectivity_service.dart' as _i47;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.lazySingleton<_i630.ApiRequestScheduler>(
        () => _i630.ApiRequestScheduler());
    gh.lazySingleton<_i47.ConnectivityService>(
        () => _i47.ConnectivityService());
    gh.lazySingleton<_i717.CacheService>(() => _i717.CacheService());
    gh.lazySingleton<_i137.ApiService>(() => _i137.ApiService.init(
          gh<_i47.ConnectivityService>(),
          gh<_i717.CacheService>(),
          gh<_i630.ApiRequestScheduler>(),
        ));
    return this;
  }
}
