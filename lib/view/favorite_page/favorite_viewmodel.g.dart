// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$favoriteServiceHash() => r'e0de971c6a7758e4c4f39712ebf306e64c8cecb6';

/// Provider untuk FavoriteService
///
/// Copied from [favoriteService].
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
String _$favoritesStreamHash() => r'4ade91835cdf517424dd5c5f842e84b3dc247eb9';

/// Stream Provider untuk real-time favorites updates
///
/// Copied from [favoritesStream].
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
String _$favoriteViewModelHash() => r'a27277f4c63dbce2b87667e212925b074d4cafc3';

/// Main Favorite Page ViewModel
///
/// Copied from [FavoriteViewModel].
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
String _$favoritesCountHash() => r'eee17adcfa4077a34265cd0d58d89b44ea4b8475';

/// Provider untuk mendapatkan total count favorites
///
/// Copied from [FavoritesCount].
@ProviderFor(FavoritesCount)
final favoritesCountProvider = AutoDisposeNotifierProvider<FavoritesCount,
    AppState<int, Exception>>.internal(
  FavoritesCount.new,
  name: r'favoritesCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$favoritesCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FavoritesCount = AutoDisposeNotifier<AppState<int, Exception>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
