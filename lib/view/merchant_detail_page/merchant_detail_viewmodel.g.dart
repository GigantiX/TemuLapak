// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_detail_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$locationServicesDetailHash() =>
    r'dd0f711f37993992f13ae8d7ebbd49e373fd7f8e';

/// See also [locationServicesDetail].
@ProviderFor(locationServicesDetail)
final locationServicesDetailProvider =
    AutoDisposeProvider<LocationServices>.internal(
  locationServicesDetail,
  name: r'locationServicesDetailProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$locationServicesDetailHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocationServicesDetailRef = AutoDisposeProviderRef<LocationServices>;
String _$merchantLiveStreamHash() =>
    r'54eb3e38cc8a0b5e022faf19c1192a0ff5276808';

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

/// See also [merchantLiveStream].
@ProviderFor(merchantLiveStream)
const merchantLiveStreamProvider = MerchantLiveStreamFamily();

/// See also [merchantLiveStream].
class MerchantLiveStreamFamily extends Family<AsyncValue<MerchantModel?>> {
  /// See also [merchantLiveStream].
  const MerchantLiveStreamFamily();

  /// See also [merchantLiveStream].
  MerchantLiveStreamProvider call(
    String merchantId,
  ) {
    return MerchantLiveStreamProvider(
      merchantId,
    );
  }

  @override
  MerchantLiveStreamProvider getProviderOverride(
    covariant MerchantLiveStreamProvider provider,
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
  String? get name => r'merchantLiveStreamProvider';
}

/// See also [merchantLiveStream].
class MerchantLiveStreamProvider
    extends AutoDisposeStreamProvider<MerchantModel?> {
  /// See also [merchantLiveStream].
  MerchantLiveStreamProvider(
    String merchantId,
  ) : this._internal(
          (ref) => merchantLiveStream(
            ref as MerchantLiveStreamRef,
            merchantId,
          ),
          from: merchantLiveStreamProvider,
          name: r'merchantLiveStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$merchantLiveStreamHash,
          dependencies: MerchantLiveStreamFamily._dependencies,
          allTransitiveDependencies:
              MerchantLiveStreamFamily._allTransitiveDependencies,
          merchantId: merchantId,
        );

  MerchantLiveStreamProvider._internal(
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
  Override overrideWith(
    Stream<MerchantModel?> Function(MerchantLiveStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MerchantLiveStreamProvider._internal(
        (ref) => create(ref as MerchantLiveStreamRef),
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
  AutoDisposeStreamProviderElement<MerchantModel?> createElement() {
    return _MerchantLiveStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MerchantLiveStreamProvider &&
        other.merchantId == merchantId;
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
mixin MerchantLiveStreamRef on AutoDisposeStreamProviderRef<MerchantModel?> {
  /// The parameter `merchantId` of this provider.
  String get merchantId;
}

class _MerchantLiveStreamProviderElement
    extends AutoDisposeStreamProviderElement<MerchantModel?>
    with MerchantLiveStreamRef {
  _MerchantLiveStreamProviderElement(super.provider);

  @override
  String get merchantId => (origin as MerchantLiveStreamProvider).merchantId;
}

String _$merchantDetailViewModelHash() =>
    r'e7836b16d9de4fd492075693a8083cc8b4ab394d';

/// See also [MerchantDetailViewModel].
@ProviderFor(MerchantDetailViewModel)
final merchantDetailViewModelProvider = AutoDisposeNotifierProvider<
    MerchantDetailViewModel,
    AppState<Map<String, dynamic>, Exception>>.internal(
  MerchantDetailViewModel.new,
  name: r'merchantDetailViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$merchantDetailViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MerchantDetailViewModel
    = AutoDisposeNotifier<AppState<Map<String, dynamic>, Exception>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
