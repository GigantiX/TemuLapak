// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_merchant_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$merchantServiceHash() => r'eb2f2fad8aec6e35d3881093ceb6bdd59b023520';

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
String _$locationServicesHash() => r'5f59d3ce14a064f71db2306453e09aad0568f538';

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
String _$listMerchantViewModelHash() =>
    r'69bcd3776159e897d99a28360a7e577b29fe02f7';

/// See also [ListMerchantViewModel].
@ProviderFor(ListMerchantViewModel)
final listMerchantViewModelProvider = AutoDisposeNotifierProvider<
    ListMerchantViewModel, AppState<List<MerchantModel>, Exception>>.internal(
  ListMerchantViewModel.new,
  name: r'listMerchantViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$listMerchantViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ListMerchantViewModel
    = AutoDisposeNotifier<AppState<List<MerchantModel>, Exception>>;
String _$merchantFilterStateHash() =>
    r'b53f4ca77debb4476c103de43f039adc205759f2';

/// See also [MerchantFilterState].
@ProviderFor(MerchantFilterState)
final merchantFilterStateProvider =
    AutoDisposeNotifierProvider<MerchantFilterState, MerchantFilter>.internal(
  MerchantFilterState.new,
  name: r'merchantFilterStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$merchantFilterStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MerchantFilterState = AutoDisposeNotifier<MerchantFilter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
