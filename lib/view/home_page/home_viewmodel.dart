import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:temulapak_app/data/location/geocoding_service.dart';
import 'package:temulapak_app/data/location/location_service.dart';
import 'package:temulapak_app/data/network/user_service.dart';
import 'package:temulapak_app/data/network/merchant_service.dart';
import 'package:temulapak_app/data/network/geo_merchant_service.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/user/user_model.dart';
import 'package:temulapak_app/view/list_merchant_page/list_merchant_view.dart';
import 'package:temulapak_app/view/list_merchant_page/list_merchant_viewmodel.dart';
import 'package:temulapak_app/view/merchant_detail_page/merchant_detail_view.dart';
import 'package:temulapak_app/view/notification_page/notification_view.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'dart:math';

part 'home_viewmodel.g.dart';

final carouselIndexProvider = StateProvider<int>((ref) => 0);

@riverpod
UserService userService(Ref ref) {
  return UserService();
}

@riverpod
LocationService locationServices(Ref ref) {
  return LocationService.instance;
}

@riverpod
GeocodingService geocodingService(Ref ref) {
  return GeocodingService();
}

@riverpod
MerchantService merchantService(Ref ref) {
  return MerchantService();
}

@riverpod
GeoMerchantService geoMerchantService(Ref ref) {
  return GeoMerchantService.instance;
}

// Enhanced State Model
class EnhancedHomeState {
  final UserModel? user;
  final String? address;
  final List<MerchantWithDistanceHome> recommendations;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final ViewModelCommand? command;

  const EnhancedHomeState({
    this.user,
    this.address,
    this.recommendations = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.command,
  });

  EnhancedHomeState copyWith({
    UserModel? user,
    String? address,
    List<MerchantWithDistanceHome>? recommendations,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    ViewModelCommand? command,
  }) {
    return EnhancedHomeState(
      user: user ?? this.user,
      address: address ?? this.address,
      recommendations: recommendations ?? this.recommendations,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage ?? this.errorMessage,
      command: command,
    );
  }
}

// Command Pattern
abstract class ViewModelCommand {
  const ViewModelCommand();
}

class NavigateCommand extends ViewModelCommand {
  final Widget page;
  const NavigateCommand(this.page);
}

class ShowSnackbarCommand extends ViewModelCommand {
  final String message;
  final Color backgroundColor;
  final int durationSeconds;
  const ShowSnackbarCommand(
      this.message, this.backgroundColor, this.durationSeconds);
}

// Enhanced Home State Notifier
@riverpod
class EnhancedHomeStateNotifier extends _$EnhancedHomeStateNotifier {
  @override
  EnhancedHomeState build() {
    ref.onDispose(() {
      _cleanup();
    });

    return const EnhancedHomeState();
  }

  void _cleanup() {
    Logger.log("ENHANCED_HOME_VM - Disposing resources");
  }

  // Initialize all home data
  Future<void> initializeHomeData() async {
    Logger.log("ENHANCED_HOME_VM - Initializing home data");

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await Future.wait([
        _loadUser(),
        _loadAddress(),
        _loadRecommendations(),
      ]);

      state = state.copyWith(isLoading: false);
      Logger.log("ENHANCED_HOME_VM - Home data initialization completed");
    } catch (e) {
      Logger.error("ENHANCED_HOME_VM - Error initializing home data", error: e);
      state = state.copyWith(
          isLoading: false, errorMessage: 'Failed to load home data');
    }
  }

  // Refresh all data
  Future<void> refreshAllData() async {
    Logger.log("ENHANCED_HOME_VM - Refreshing all data");

    state = state.copyWith(isRefreshing: true, errorMessage: null);

    try {
      await Future.wait([
        _loadUser(),
        _loadAddress(),
        _loadRecommendations(),
      ]);

      state = state.copyWith(isRefreshing: false);
      Logger.log("ENHANCED_HOME_VM - Refresh completed successfully");
    } catch (e) {
      Logger.error("ENHANCED_HOME_VM - Error during refresh", error: e);

      state = state.copyWith(
          isRefreshing: false,
          errorMessage: 'Gagal memperbarui data. Silakan coba lagi.');

      _emitCommand(ShowSnackbarCommand(
        'Gagal memperbarui data. Silakan coba lagi.',
        MyColor.red,
        3,
      ));
    }
  }

  // Navigation methods
  void navigateToMerchantDetail(MerchantModel merchant) {
    _emitCommand(NavigateCommand(MerchantDetailPage(merchant: merchant)));
  }

  void navigateToNotification() {
    _emitCommand(NavigateCommand(const NotificationPage()));
  }

  void navigateToListMerchant(MerchantCategory category) {
    _emitCommand(NavigateCommand(ListMerchantPage(category: category)));
  }

  // Private helper methods
  Future<void> _loadUser() async {
    try {
      final userService = ref.read(userServiceProvider);
      final user = await userService.getCurrentUser();

      if (user != null) {
        state = state.copyWith(user: user);
      }
    } catch (e) {
      Logger.error("ENHANCED_HOME_VM - Error loading user", error: e);
      rethrow;
    }
  }

  Future<void> _loadAddress() async {
    try {
      final locationService = ref.read(locationServicesProvider);
      final position = await locationService.getCurrentLocation();

      if (position == null) {
        state = state.copyWith(address: "No location");
        return;
      }

      final geocodingService = ref.read(geocodingServiceProvider);
      try {
        final address = await geocodingService.getAddressFromLatLng(
            position.latitude, position.longitude);

        state = state.copyWith(address: address);
      } catch (geocodingError) {
        Logger.error("ENHANCED_HOME_VM - Error in geocoding",
            error: geocodingError);
        state = state.copyWith(address: "Error fetching address");
      }
    } catch (e) {
      Logger.error("ENHANCED_HOME_VM - Error fetching address", error: e);
      state = state.copyWith(address: "No location");
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final locationService = ref.read(locationServicesProvider);
      final position = await locationService.getCurrentLocation();

      if (position == null) {
        Logger.error(
            "ENHANCED_HOME_VM - No location available for recommendations");
        return;
      }

      final merchantService = ref.read(merchantServiceProvider);
      final nearbyMerchants = await merchantService.getNearbyMerchants(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusInKm: 20.0,
        limit: 15,
      );

      List<MerchantWithDistanceHome> merchantsWithDistance = [];

      for (final merchant in nearbyMerchants) {
        double? distance;

        if (merchant.merchantLocLat != null &&
            merchant.merchantLocLong != null) {
          distance = _calculateDistance(
            position.latitude,
            position.longitude,
            merchant.merchantLocLat!,
            merchant.merchantLocLong!,
          );
        }

        merchantsWithDistance.add(MerchantWithDistanceHome(
          merchant: merchant,
          distance: distance,
          isGeoEnhanced: true,
        ));
      }

      // Sort by popularity DESC, then distance ASC
      merchantsWithDistance.sort((a, b) {
        final popularityA = a.merchant.merchantPopularity ?? 0;
        final popularityB = b.merchant.merchantPopularity ?? 0;

        if (popularityA != popularityB) {
          return popularityB.compareTo(popularityA);
        }

        if (a.distance == null && b.distance == null) return 0;
        if (a.distance == null) return 1;
        if (b.distance == null) return -1;

        return a.distance!.compareTo(b.distance!);
      });

      final recommendations = merchantsWithDistance.take(5).toList();

      state = state.copyWith(recommendations: recommendations);
      Logger.log(
          "ENHANCED_HOME_VM - Loaded ${recommendations.length} recommendations");
    } catch (e) {
      Logger.error("ENHANCED_HOME_VM - Error loading recommendations",
          error: e);
      rethrow;
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  void _emitCommand(ViewModelCommand command) {
    state = state.copyWith(command: command);
    Future.microtask(() {
      if (_isMounted) {
        state = state.copyWith(command: null);
      }
    });
  }

  bool get _isMounted {
    try {
      ref.exists;
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Existing ViewModels (backward compatibility)
@riverpod
class HomeViewmodel extends _$HomeViewmodel {
  @override
  AppState<UserModel, Exception> build() {
    return AppState.idle();
  }

  Future<void> getUser() async {
    state = AppState.loading();
    try {
      final userService = ref.read(userServiceProvider);
      final user = await userService.getCurrentUser();
      if (user != null) {
        state = AppState.success(user);
      } else {
        state = AppState.error(Exception('User profile not found'),
            message: 'Could not find your profile');
        return;
      }
    } catch (e) {
      Logger.error("Error fetching user profile", error: e);
      state = AppState.error(Exception(e.toString()));
      rethrow;
    }
  }
}

@riverpod
class AddressViewModel extends _$AddressViewModel {
  @override
  AppState<String, Exception> build() {
    return AppState.idle();
  }

  Future<void> getAddress() async {
    state = AppState.loading();
    try {
      final locationService = ref.read(locationServicesProvider);
      final position = await locationService.getCurrentLocation();

      if (position == null) {
        Logger.error("Failed to get current location (permission denied or service disabled).");
        state = AppState.error(
          Exception('Location not available'),
          message: 'Izinkan lokasi untuk menampilkan alamat'
        );
        return;
      }

      final geocodingService = ref.read(geocodingServiceProvider);
      try {
        final address = await geocodingService.getAddressFromLatLng(
            position.latitude, position.longitude);

        state = AppState.success(address);
      } catch (geocodingError) {
        state = AppState.success("Error fetching address");
      }
    } catch (e) {
      Logger.error("Error fetching address", error: e);
      state = AppState.error(
        Exception('Failed to get address'),
        message: 'Gagal mendapatkan alamat'
      );
    }
  }
}

class MerchantWithDistanceHome {
  final MerchantModel merchant;
  final double? distance;
  final bool isGeoEnhanced;

  MerchantWithDistanceHome({
    required this.merchant,
    this.distance,
    this.isGeoEnhanced = false,
  });

  MerchantWithDistanceHome copyWith({
    MerchantModel? merchant,
    double? distance,
    bool? isGeoEnhanced,
  }) {
    return MerchantWithDistanceHome(
      merchant: merchant ?? this.merchant,
      distance: distance ?? this.distance,
      isGeoEnhanced: isGeoEnhanced ?? this.isGeoEnhanced,
    );
  }
}

@riverpod
class RecommendedMerchants extends _$RecommendedMerchants {
  Position? _userPosition;
  bool _geoServiceInitialized = false;

  @override
  AppState<List<MerchantWithDistanceHome>, Exception> build() {
    return AppState.idle();
  }

  Future<void> _initializeGeoService() async {
    if (_geoServiceInitialized) return;

    try {
      final geoService = ref.read(geoMerchantServiceProvider);
      _geoServiceInitialized = await geoService.initialize();
    } catch (e) {
      Logger.error("HOMEVM_GEO - Error initializing geo service", error: e);
      _geoServiceInitialized = false;
    }
  }

  Future<void> getRecommendedMerchants() async {
    state = AppState.loading();
    try {
      await _initializeGeoService();

      final locationService = ref.read(locationServicesProvider);
      final position = await locationService.getCurrentLocation();

      if (position == null) {
        Logger.error("HOMEVM_GEO - No location available for recommendations");
        state = AppState.error(Exception('Location not available'),
            message: 'Cannot get recommendations without location');
        return;
      }

      _userPosition = position;

      final merchantService = ref.read(merchantServiceProvider);
      bool isGeoEnhanced = false;
      List<MerchantModel> nearbyMerchants;

      try {
        nearbyMerchants = await merchantService.getNearbyMerchants(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusInKm: 20.0,
          limit: 15,
        );

        isGeoEnhanced = _geoServiceInitialized && nearbyMerchants.isNotEmpty;
      } catch (e) {
        Logger.error("HOMEVM_GEO - Error in merchant search", error: e);

        nearbyMerchants = await merchantService.getNearbyMerchants(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusInKm: 20.0,
          limit: 15,
        );
        isGeoEnhanced = false;
      }

      List<MerchantWithDistanceHome> merchantsWithDistance = [];

      for (final merchant in nearbyMerchants) {
        double? distance;

        if (merchant.merchantLocLat != null &&
            merchant.merchantLocLong != null) {
          distance = _calculateDistance(
            _userPosition!.latitude,
            _userPosition!.longitude,
            merchant.merchantLocLat!,
            merchant.merchantLocLong!,
          );
        }

        merchantsWithDistance.add(MerchantWithDistanceHome(
          merchant: merchant,
          distance: distance,
          isGeoEnhanced: isGeoEnhanced,
        ));
      }

      merchantsWithDistance.sort((a, b) {
        final popularityA = a.merchant.merchantPopularity ?? 0;
        final popularityB = b.merchant.merchantPopularity ?? 0;

        if (popularityA != popularityB) {
          return popularityB.compareTo(popularityA);
        }

        if (a.distance == null && b.distance == null) return 0;
        if (a.distance == null) return 1;
        if (b.distance == null) return -1;

        return a.distance!.compareTo(b.distance!);
      });

      final recommendations = merchantsWithDistance.take(5).toList();

      state = AppState.success(recommendations);
    } catch (e) {
      Logger.error("HOMEVM_GEO - Error fetching recommended merchants",
          error: e);
      state = AppState.error(Exception(e.toString()),
          message: 'Failed to load recommended merchants');
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  Future<bool> testGeoFunctionality() async {
    try {
      await _initializeGeoService();
      if (!_geoServiceInitialized) {
        return false;
      }

      final merchantService = ref.read(merchantServiceProvider);
      return await merchantService.testGeoFunctionality();
    } catch (e) {
      Logger.error("HOMEVM_GEO - Geo test failed", error: e);
      return false;
    }
  }

  Map<String, dynamic> getGeoServiceStatus() {
    final merchantService = ref.read(merchantServiceProvider);
    final status = merchantService.getGeoServiceStatus();
    status['recommendationsInitialized'] = _geoServiceInitialized;
    status['userPosition'] = _userPosition != null
        ? {
            'latitude': _userPosition!.latitude,
            'longitude': _userPosition!.longitude,
          }
        : null;
    return status;
  }
}
