// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../core/network/network_client.dart' as _i492;
import '../features/auth/data/datasources/auth_remote_data_source.dart'
    as _i719;
import '../features/cart/data/datasources/cart_remote_data_source.dart'
    as _i1029;
import '../features/common/data/datasources/location_remote_data_source.dart'
    as _i31;
import '../features/notifications/data/datasources/notification_remote_data_source.dart'
    as _i509;
import '../features/orders/data/datasources/order_remote_data_source.dart'
    as _i961;
import '../features/products/data/datasources/product_remote_data_source.dart'
    as _i41;
import '../features/profile/data/datasources/user_remote_data_source.dart'
    as _i961;
import '../features/reviews/data/datasources/review_remote_data_source.dart'
    as _i763;
import '../features/vendors/data/datasources/vendor_remote_data_source.dart'
    as _i1030;
import '../services/api_request_scheduler.dart' as _i630;
import '../services/api_service.dart' as _i137;
import '../services/cache_service.dart' as _i717;
import '../services/connectivity_service.dart' as _i47;
import '../services/logger_service.dart' as _i141;
import '../services/sync_service.dart' as _i979;

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
    gh.lazySingleton<_i979.SyncService>(
        () => _i979.SyncService(gh<_i47.ConnectivityService>()));
    gh.lazySingleton<_i492.NetworkClient>(() => _i492.NetworkClient(
          gh<_i47.ConnectivityService>(),
          gh<_i630.ApiRequestScheduler>(),
        ));
    gh.lazySingleton<_i141.LoggerService>(
        () => _i141.LoggerService.create(gh<_i47.ConnectivityService>()));
    gh.lazySingleton<_i1030.VendorRemoteDataSource>(
        () => _i1030.VendorRemoteDataSource(gh<_i492.NetworkClient>()));
    gh.lazySingleton<_i41.ProductRemoteDataSource>(
        () => _i41.ProductRemoteDataSource(gh<_i492.NetworkClient>()));
    gh.lazySingleton<_i719.AuthRemoteDataSource>(
        () => _i719.AuthRemoteDataSource(gh<_i492.NetworkClient>()));
    gh.lazySingleton<_i31.LocationRemoteDataSource>(
        () => _i31.LocationRemoteDataSource(gh<_i492.NetworkClient>()));
    gh.lazySingleton<_i961.UserRemoteDataSource>(
        () => _i961.UserRemoteDataSource(gh<_i492.NetworkClient>()));
    gh.lazySingleton<_i1029.CartRemoteDataSource>(
        () => _i1029.CartRemoteDataSource(gh<_i492.NetworkClient>()));
    gh.lazySingleton<_i961.OrderRemoteDataSource>(
        () => _i961.OrderRemoteDataSource(gh<_i492.NetworkClient>()));
    gh.lazySingleton<_i509.NotificationRemoteDataSource>(
        () => _i509.NotificationRemoteDataSource(gh<_i492.NetworkClient>()));
    gh.lazySingleton<_i763.ReviewRemoteDataSource>(
        () => _i763.ReviewRemoteDataSource(gh<_i492.NetworkClient>()));
    gh.lazySingleton<_i137.ApiService>(() => _i137.ApiService.init(
          gh<_i492.NetworkClient>(),
          gh<_i719.AuthRemoteDataSource>(),
          gh<_i41.ProductRemoteDataSource>(),
          gh<_i961.OrderRemoteDataSource>(),
          gh<_i1030.VendorRemoteDataSource>(),
          gh<_i1029.CartRemoteDataSource>(),
          gh<_i31.LocationRemoteDataSource>(),
          gh<_i763.ReviewRemoteDataSource>(),
          gh<_i509.NotificationRemoteDataSource>(),
          gh<_i961.UserRemoteDataSource>(),
          gh<_i717.CacheService>(),
        ));
    return this;
  }
}
