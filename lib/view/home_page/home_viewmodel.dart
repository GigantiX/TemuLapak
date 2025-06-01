import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:temulapak_app/data/location/geocoding_service.dart';
import 'package:temulapak_app/data/location/location_services.dart';
import 'package:temulapak_app/data/network/user_service.dart';
import 'package:temulapak_app/data/network/merchant_service.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/model/user/user_model.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'dart:math';

part 'home_viewmodel.g.dart';

final carouselIndexProvider = StateProvider<int>((ref) => 0);

@riverpod
UserService userService(Ref ref) {
  return UserService();
}

@riverpod
LocationServices locationServices(Ref ref) {
  return LocationServices.instance;
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
class HomeViewmodel extends _$HomeViewmodel {
  @override
  AppState<UserModel, Exception> build() {
    return AppState.idle();
  }

  Future<void> getUser() async {
    Logger.log("HOMEVM - Fetching user profile");
    state = AppState.loading();
    try {
      final userService = ref.read(userServiceProvider);
      final user = await userService.getCurrentUser();
      if (user != null) {
        Logger.log("User profile fetched successfully");
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
      Logger.log("Address VM - Getting current location");
      final locationService = ref.read(locationServicesProvider);
      final position = await locationService.getCurrentLocation();
      
      if (position == null) {
        Logger.error("Failed to get current location");
        state = AppState.success("No location");
        return;
      }
      
      Logger.log("Address VM - Location obtained: ${position.latitude}, ${position.longitude}");
      
      final geocodingService = ref.read(geocodingServiceProvider);
      try {
        final address = await geocodingService.getAddressFromLatLng(
          position.latitude, 
          position.longitude
        );
        
        Logger.log("Address VM - Address obtained: $address");
        state = AppState.success(address);
      } catch (geocodingError) {
        Logger.error("Error in geocoding", error: geocodingError);
        state = AppState.success("Error fetching address");
      }
    } catch (e) {
      Logger.error("Error fetching address", error: e);
      state = AppState.success("No location");
    }
  }
}

// NEW: Add MerchantWithDistance class directly in home_viewmodel.dart to avoid import issues
class MerchantWithDistanceHome {
  final MerchantModel merchant;
  final double? distance; // Distance in kilometers

  MerchantWithDistanceHome({
    required this.merchant,
    this.distance,
  });

  MerchantWithDistanceHome copyWith({
    MerchantModel? merchant,
    double? distance,
  }) {
    return MerchantWithDistanceHome(
      merchant: merchant ?? this.merchant,
      distance: distance ?? this.distance,
    );
  }
}

// FIXED: RecommendedMerchants now returns MerchantWithDistanceHome instead of importing from list_merchant_viewmodel
@riverpod
class RecommendedMerchants extends _$RecommendedMerchants {
  Position? _userPosition;
  
  @override
  AppState<List<MerchantWithDistanceHome>, Exception> build() {
    return AppState.idle();
  }

  Future<void> getRecommendedMerchants() async {
    state = AppState.loading();
    try {
      Logger.log("HOMEVM - Fetching recommended merchants with distance calculation");
      
      // Get current location first
      final locationService = ref.read(locationServicesProvider);
      final position = await locationService.getCurrentLocation();
      
      if (position == null) {
        Logger.error("No location available for recommendations");
        state = AppState.error(
          Exception('Location not available'),
          message: 'Cannot get recommendations without location'
        );
        return;
      }
      
      _userPosition = position;
      Logger.log("HOMEVM - User location: ${position.latitude}, ${position.longitude}");
      
      // Get nearby merchants
      final merchantService = ref.read(merchantServiceProvider);
      final nearbyMerchants = await merchantService.getNearbyMerchants(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusInKm: 10.0, // 10km radius
        limit: 5, // limit 5 merchants
      );
      
      Logger.log("HOMEVM - Fetched ${nearbyMerchants.length} nearby merchants");
      
      // FIXED: Calculate distances like in ListMerchantViewModel
      List<MerchantWithDistanceHome> merchantsWithDistance = await _calculateDistances(nearbyMerchants);
      
      // Sort by distance
      merchantsWithDistance.sort((a, b) {
        if (a.distance == null && b.distance == null) return 0;
        if (a.distance == null) return 1;
        if (b.distance == null) return -1;
        return a.distance!.compareTo(b.distance!);
      });
      
      Logger.log("HOMEVM - Successfully calculated distances for ${merchantsWithDistance.length} recommended merchants");
      state = AppState.success(merchantsWithDistance);
      
    } catch (e) {
      Logger.error("HOMEVM - Error fetching recommended merchants", error: e);
      state = AppState.error(
        Exception(e.toString()),
        message: 'Failed to load recommended merchants'
      );
    }
  }

  // FIXED: Add distance calculation method (copied from ListMerchantViewModel)
  Future<List<MerchantWithDistanceHome>> _calculateDistances(List<MerchantModel> merchants) async {
    if (_userPosition == null) {
      Logger.log("HOMEVM - No user position, returning merchants without distances");
      return merchants.map((m) => MerchantWithDistanceHome(merchant: m, distance: null)).toList();
    }

    Logger.log("HOMEVM - Calculating distances for ${merchants.length} merchants");
    
    List<MerchantWithDistanceHome> result = [];
    
    for (final merchant in merchants) {
      double? distance;
      
      if (merchant.merchantLocLat != null && merchant.merchantLocLong != null) {
        distance = _calculateDistance(
          _userPosition!.latitude,
          _userPosition!.longitude,
          merchant.merchantLocLat!,
          merchant.merchantLocLong!,
        );
      }
      
      result.add(MerchantWithDistanceHome(
        merchant: merchant,
        distance: distance,
      ));
    }
    
    Logger.log("HOMEVM - Distance calculation completed for recommendations");
    return result;
  }

  // FIXED: Add distance calculation helper method (copied from ListMerchantViewModel)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}