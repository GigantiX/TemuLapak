// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$favoriteServiceHash() => r'e0de971c6a7758e4c4f39712ebf306e64c8cecb6';

/// See also [favoriteService].
@ProviderFor(favoriteService)
final favoriteServiceProvider = AutoDisposeProvider<FavoriteService>.internal(
  favoriteService,
  name: r'favoriteServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$favoriteServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FavoriteServiceRef = AutoDisposeProviderRef<FavoriteService>;
String _$merchantServiceFavHash() =>
    r'30e340f0ca4dd4f3491ea2b66a5c2661e216f895';

/// See also [merchantServiceFav].
@ProviderFor(merchantServiceFav)
final merchantServiceFavProvider =
    AutoDisposeProvider<MerchantService>.internal(
  merchantServiceFav,
  name: r'merchantServiceFavProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$merchantServiceFavHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MerchantServiceFavRef = AutoDisposeProviderRef<MerchantService>;
String _$locationServiceFavHash() =>
    r'950121425eef41948892ccf5abd76f6b3bd87943';

/// See also [locationServiceFav].
@ProviderFor(locationServiceFav)
final locationServiceFavProvider =
    AutoDisposeProvider<LocationService>.internal(
  locationServiceFav,
  name: r'locationServiceFavProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$locationServiceFavHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationServiceFavRef = AutoDisposeProviderRef<LocationService>;
String _$favoritesStreamHash() => r'4ec7d8a402e3fa616e8be1e1bffc6219709dc16e';

/// See also [favoritesStream].
@ProviderFor(favoritesStream)
final favoritesStreamProvider =
    AutoDisposeStreamProvider<List<FavoriteModel>>.internal(
  favoritesStream,
  name: r'favoritesStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$favoritesStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FavoritesStreamRef = AutoDisposeStreamProviderRef<List<FavoriteModel>>;
String _$locationStateHash() => r'9fb5e3c26d183fb5cc946e21d6a2fbffe5b5dd74';

/// See also [LocationState].
@ProviderFor(LocationState)
final locationStateProvider =
    AutoDisposeNotifierProvider<LocationState, Position?>.internal(
  LocationState.new,
  name: r'locationStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$locationStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LocationState = AutoDisposeNotifier<Position?>;
String _$favoriteViewModelHash() => r'994bcb258534f742a0d48437d281b91981620aa4';

/// See also [FavoriteViewModel].
@ProviderFor(FavoriteViewModel)
final favoriteViewModelProvider = AutoDisposeNotifierProvider<FavoriteViewModel,
    AppState<List<FavoriteModel>, Exception>>.internal(
  FavoriteViewModel.new,
  name: r'favoriteViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$favoriteViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FavoriteViewModel
    = AutoDisposeNotifier<AppState<List<FavoriteModel>, Exception>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
