// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userServiceHash() => r'd202c375439ba7e228837169af5a32c16c9ddb4a';

/// See also [userService].
@ProviderFor(userService)
final userServiceProvider = AutoDisposeProvider<UserService>.internal(
  userService,
  name: r'userServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserServiceRef = AutoDisposeProviderRef<UserService>;
String _$locationServicesHash() => r'5840383757050a5a1e0672270c865b1bf781ea3f';

/// See also [locationServices].
@ProviderFor(locationServices)
final locationServicesProvider = AutoDisposeProvider<LocationServices>.internal(
  locationServices,
  name: r'locationServicesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$locationServicesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationServicesRef = AutoDisposeProviderRef<LocationServices>;
String _$geocodingServiceHash() => r'0e3d99196c141e249f347338025a49e7cb6959a6';

/// See also [geocodingService].
@ProviderFor(geocodingService)
final geocodingServiceProvider = AutoDisposeProvider<GeocodingService>.internal(
  geocodingService,
  name: r'geocodingServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$geocodingServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GeocodingServiceRef = AutoDisposeProviderRef<GeocodingService>;
String _$merchantServiceHash() => r'79237eb395d9335c12033af63df641631c05bbe9';

/// See also [merchantService].
@ProviderFor(merchantService)
final merchantServiceProvider = AutoDisposeProvider<MerchantService>.internal(
  merchantService,
  name: r'merchantServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$merchantServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MerchantServiceRef = AutoDisposeProviderRef<MerchantService>;
String _$geoMerchantServiceHash() =>
    r'b6809483afc8c33a2e6e738677e54506be93ff22';

/// See also [geoMerchantService].
@ProviderFor(geoMerchantService)
final geoMerchantServiceProvider =
    AutoDisposeProvider<GeoMerchantService>.internal(
  geoMerchantService,
  name: r'geoMerchantServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$geoMerchantServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GeoMerchantServiceRef = AutoDisposeProviderRef<GeoMerchantService>;
String _$homeViewmodelHash() => r'7b2f50f1038bb192faf8115282936d4dcc9ae8dc';

/// See also [HomeViewmodel].
@ProviderFor(HomeViewmodel)
final homeViewmodelProvider = AutoDisposeNotifierProvider<HomeViewmodel,
    AppState<UserModel, Exception>>.internal(
  HomeViewmodel.new,
  name: r'homeViewmodelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$homeViewmodelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$HomeViewmodel = AutoDisposeNotifier<AppState<UserModel, Exception>>;
String _$addressViewModelHash() => r'dad7ff3311d58c9fc65971660002979a5a70d0d9';

/// See also [AddressViewModel].
@ProviderFor(AddressViewModel)
final addressViewModelProvider = AutoDisposeNotifierProvider<AddressViewModel,
    AppState<String, Exception>>.internal(
  AddressViewModel.new,
  name: r'addressViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$addressViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AddressViewModel = AutoDisposeNotifier<AppState<String, Exception>>;
String _$recommendedMerchantsHash() =>
    r'1a193c7ac3855e4f347ba3cf80f6fcd66f6e472c';

/// See also [RecommendedMerchants].
@ProviderFor(RecommendedMerchants)
final recommendedMerchantsProvider = AutoDisposeNotifierProvider<
    RecommendedMerchants,
    AppState<List<MerchantWithDistanceHome>, Exception>>.internal(
  RecommendedMerchants.new,
  name: r'recommendedMerchantsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recommendedMerchantsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RecommendedMerchants
    = AutoDisposeNotifier<AppState<List<MerchantWithDistanceHome>, Exception>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
