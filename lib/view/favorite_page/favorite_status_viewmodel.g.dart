// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_status_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$favoriteServiceStatusHash() =>
    r'6014a0a35aa1173eec0c4933f87e308c3b3b4db2';

/// Provider untuk FavoriteService (shared)
///
/// Copied from [favoriteServiceStatus].
@ProviderFor(favoriteServiceStatus)
final favoriteServiceStatusProvider =
    AutoDisposeProvider<FavoriteService>.internal(
  favoriteServiceStatus,
  name: r'favoriteServiceStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$favoriteServiceStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FavoriteServiceStatusRef = AutoDisposeProviderRef<FavoriteService>;
String _$favoriteStatusHash() => r'94c1e4bad0ebadb2c1fac1de8f0ac42595145a99';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$FavoriteStatus
    extends BuildlessAutoDisposeNotifier<AppState<bool, Exception>> {
  late final String merchantId;

  AppState<bool, Exception> build(
    String merchantId,
  );
}

/// Favorite Status Provider untuk specific merchant
/// Ini akan digunakan untuk tombol favorite di merchant detail
///
/// Copied from [FavoriteStatus].
@ProviderFor(FavoriteStatus)
const favoriteStatusProvider = FavoriteStatusFamily();

/// Favorite Status Provider untuk specific merchant
/// Ini akan digunakan untuk tombol favorite di merchant detail
///
/// Copied from [FavoriteStatus].
class FavoriteStatusFamily extends Family<AppState<bool, Exception>> {
  /// Favorite Status Provider untuk specific merchant
  /// Ini akan digunakan untuk tombol favorite di merchant detail
  ///
  /// Copied from [FavoriteStatus].
  const FavoriteStatusFamily();

  /// Favorite Status Provider untuk specific merchant
  /// Ini akan digunakan untuk tombol favorite di merchant detail
  ///
  /// Copied from [FavoriteStatus].
  FavoriteStatusProvider call(
    String merchantId,
  ) {
    return FavoriteStatusProvider(
      merchantId,
    );
  }

  @override
  FavoriteStatusProvider getProviderOverride(
    covariant FavoriteStatusProvider provider,
  ) {
    return call(
      provider.merchantId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'favoriteStatusProvider';
}

/// Favorite Status Provider untuk specific merchant
/// Ini akan digunakan untuk tombol favorite di merchant detail
///
/// Copied from [FavoriteStatus].
class FavoriteStatusProvider extends AutoDisposeNotifierProviderImpl<
    FavoriteStatus, AppState<bool, Exception>> {
  /// Favorite Status Provider untuk specific merchant
  /// Ini akan digunakan untuk tombol favorite di merchant detail
  ///
  /// Copied from [FavoriteStatus].
  FavoriteStatusProvider(
    String merchantId,
  ) : this._internal(
          () => FavoriteStatus()..merchantId = merchantId,
          from: favoriteStatusProvider,
          name: r'favoriteStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$favoriteStatusHash,
          dependencies: FavoriteStatusFamily._dependencies,
          allTransitiveDependencies:
              FavoriteStatusFamily._allTransitiveDependencies,
          merchantId: merchantId,
        );

  FavoriteStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.merchantId,
  }) : super.internal();

  final String merchantId;

  @override
  AppState<bool, Exception> runNotifierBuild(
    covariant FavoriteStatus notifier,
  ) {
    return notifier.build(
      merchantId,
    );
  }

  @override
  Override overrideWith(FavoriteStatus Function() create) {
    return ProviderOverride(
      origin: this,
      override: FavoriteStatusProvider._internal(
        () => create()..merchantId = merchantId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        merchantId: merchantId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<FavoriteStatus, AppState<bool, Exception>>
      createElement() {
    return _FavoriteStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FavoriteStatusProvider && other.merchantId == merchantId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, merchantId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FavoriteStatusRef
    on AutoDisposeNotifierProviderRef<AppState<bool, Exception>> {
  /// The parameter `merchantId` of this provider.
  String get merchantId;
}

class _FavoriteStatusProviderElement extends AutoDisposeNotifierProviderElement<
    FavoriteStatus, AppState<bool, Exception>> with FavoriteStatusRef {
  _FavoriteStatusProviderElement(super.provider);

  @override
  String get merchantId => (origin as FavoriteStatusProvider).merchantId;
}

String _$batchFavoriteStatusHash() =>
    r'b80b604b3deafd8d135271bd2395b1f22b84951a';

/// Provider untuk batch checking multiple merchants
/// Berguna untuk list page yang menampilkan banyak merchant
///
/// Copied from [BatchFavoriteStatus].
@ProviderFor(BatchFavoriteStatus)
final batchFavoriteStatusProvider = AutoDisposeNotifierProvider<
    BatchFavoriteStatus, AppState<Map<String, bool>, Exception>>.internal(
  BatchFavoriteStatus.new,
  name: r'batchFavoriteStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$batchFavoriteStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BatchFavoriteStatus
    = AutoDisposeNotifier<AppState<Map<String, bool>, Exception>>;
String _$favoriteHelperHash() => r'8de6db6e807f7a4bc3d1e294f59262acf5ecf86e';

/// Helper provider untuk quick access ke favorite service
///
/// Copied from [FavoriteHelper].
@ProviderFor(FavoriteHelper)
final favoriteHelperProvider = AutoDisposeNotifierProvider<FavoriteHelper,
    AppState<String, Exception>>.internal(
  FavoriteHelper.new,
  name: r'favoriteHelperProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$favoriteHelperHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FavoriteHelper = AutoDisposeNotifier<AppState<String, Exception>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
