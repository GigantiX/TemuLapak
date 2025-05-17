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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
