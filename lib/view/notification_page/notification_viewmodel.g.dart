// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationServiceHash() =>
    r'97ab8da2c4bf2b9340df306858ee0a49b5799c6d';

/// See also [notificationService].
@ProviderFor(notificationService)
final notificationServiceProvider =
    AutoDisposeProvider<NotificationService>.internal(
  notificationService,
  name: r'notificationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationServiceRef = AutoDisposeProviderRef<NotificationService>;
String _$notificationHistoryHash() =>
    r'37b4f4e15019ae7fe998bf212ef6abf6106039bf';

/// Stream provider for notification history
///
/// Copied from [notificationHistory].
@ProviderFor(notificationHistory)
final notificationHistoryProvider =
    AutoDisposeStreamProvider<List<NotificationModel>>.internal(
  notificationHistory,
  name: r'notificationHistoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationHistoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationHistoryRef
    = AutoDisposeStreamProviderRef<List<NotificationModel>>;
String _$notificationActionsViewModelHash() =>
    r'46b5833f162ad05b2d780a44f3b0bb2593994b58';

/// Notification actions viewmodel
///
/// Copied from [NotificationActionsViewModel].
@ProviderFor(NotificationActionsViewModel)
final notificationActionsViewModelProvider = AutoDisposeNotifierProvider<
    NotificationActionsViewModel, AppState<String, Exception>>.internal(
  NotificationActionsViewModel.new,
  name: r'notificationActionsViewModelProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationActionsViewModelHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NotificationActionsViewModel
    = AutoDisposeNotifier<AppState<String, Exception>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
