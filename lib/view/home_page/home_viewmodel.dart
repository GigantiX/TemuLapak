import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:temulapak_app/data/location/geocoding_service.dart';
import 'package:temulapak_app/data/location/location_services.dart';
import 'package:temulapak_app/data/network/user_service.dart';
import 'package:temulapak_app/data/network/merchant_service.dart';
import 'package:temulapak_app/data/network/geo_merchant_service.dart';
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
GeoMerchantService geoMerchantService(Ref ref) {
  return GeoMerchantService.instance;
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

// MerchantWithDistance class with geo enhancement info
class MerchantWithDistanceHome {
  final MerchantModel merchant;
  final double? distance; // Distance in kilometers
  final bool isGeoEnhanced; // Track if result came from geo query

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

// RecommendedMerchants with GeoFlutterFire Plus integration
@riverpod
class RecommendedMerchants extends _$RecommendedMerchants {
  Position? _userPosition;
  bool _geoServiceInitialized = false;
  
  @override
  AppState<List<MerchantWithDistanceHome>, Exception> build() {
    return AppState.idle();
  }

  /// Initialize geo service for recommendations
  Future<void> _initializeGeoService() async {
    if (_geoServiceInitialized) return;
    
    try {
      Logger.log("HOMEVM_GEO - Initializing geo service for recommendations");
      final geoService = ref.read(geoMerchantServiceProvider);
      _geoServiceInitialized = await geoService.initialize();
      
      if (_geoServiceInitialized) {
        Logger.log("HOMEVM_GEO - Geo service initialized successfully for recommendations");
      } else {
        Logger.log("HOMEVM_GEO - Geo service initialization failed, will use fallback");
      }
    } catch (e) {
      Logger.error("HOMEVM_GEO - Error initializing geo service", error: e);
      _geoServiceInitialized = false;
    }
  }

  Future<void> getRecommendedMerchants() async {
    state = AppState.loading();
    try {
      Logger.log("🚀 HOMEVM_GEO - Starting recommendation fetch");
      
      // STEP 1: Initialize geo service
      await _initializeGeoService();
      Logger.log("📡 HOMEVM_GEO - Geo service initialized: $_geoServiceInitialized");
      
      // STEP 2: Get current location first
      final locationService = ref.read(locationServicesProvider);
      final position = await locationService.getCurrentLocation();
      
      if (position == null) {
        Logger.error("❌ HOMEVM_GEO - No location available for recommendations");
        state = AppState.error(
          Exception('Location not available'),
          message: 'Cannot get recommendations without location'
        );
        return;
      }
      
      _userPosition = position;
      Logger.log("📍 HOMEVM_GEO - User location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}");
      
      // STEP 3: Get nearby merchants with detailed logging
      final merchantService = ref.read(merchantServiceProvider);
      bool isGeoEnhanced = false;
      List<MerchantModel> nearbyMerchants;
      
      try {
        Logger.log("🔍 HOMEVM_GEO - Searching merchants within 20km radius");
        
        nearbyMerchants = await merchantService.getNearbyMerchants(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusInKm: 20.0, // 20km radius
          limit: 15, // Get more to have options for sorting
        );
        
        isGeoEnhanced = _geoServiceInitialized && nearbyMerchants.isNotEmpty;
        
        Logger.log("📊 HOMEVM_GEO - Raw search result: ${nearbyMerchants.length} merchants found (geo: $isGeoEnhanced)");
        
        // DEBUG: Log each found merchant
        for (int i = 0; i < nearbyMerchants.length; i++) {
          final merchant = nearbyMerchants[i];
          Logger.log("   🏪 [$i] ${merchant.merchantName} - Status: ${merchant.merchantStatus ? 'OPEN' : 'CLOSED'} - Popularity: ${merchant.merchantPopularity ?? 0}");
          Logger.log("       📍 Location: ${merchant.merchantLocLat}, ${merchant.merchantLocLong}");
        }
        
        if (nearbyMerchants.isEmpty) {
          Logger.log("⚠️ HOMEVM_GEO - No merchants found within 20km, trying larger radius for debug");
          
          // DEBUG: Try larger radius to see if merchants exist
          final debugMerchants = await merchantService.getNearbyMerchants(
            latitude: position.latitude,
            longitude: position.longitude,
            radiusInKm: 50.0, // Larger radius for debug
            limit: 50,
          );
          
          Logger.log("🔍 DEBUG - Found ${debugMerchants.length} merchants within 50km");
          for (final merchant in debugMerchants) {
            if (merchant.merchantLocLat != null && merchant.merchantLocLong != null) {
              final distance = _calculateDistance(
                position.latitude,
                position.longitude,
                merchant.merchantLocLat!,
                merchant.merchantLocLong!,
              );
              Logger.log("   🏪 DEBUG - ${merchant.merchantName}: ${distance.toStringAsFixed(2)}km, popularity: ${merchant.merchantPopularity ?? 0}");
            }
          }
        }
        
      } catch (e) {
        Logger.error("❌ HOMEVM_GEO - Error in merchant search", error: e);
        
        // Fallback: Try basic search
        Logger.log("🔄 HOMEVM_GEO - Trying fallback search");
        nearbyMerchants = await merchantService.getNearbyMerchants(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusInKm: 20.0,
          limit: 15,
        );
        isGeoEnhanced = false;
        Logger.log("📊 HOMEVM_GEO - Fallback result: ${nearbyMerchants.length} merchants");
      }
      
      // STEP 4: Calculate distances with detailed logging
      Logger.log("📏 HOMEVM_GEO - Calculating distances for ${nearbyMerchants.length} merchants");
      
      List<MerchantWithDistanceHome> merchantsWithDistance = [];
      
      for (final merchant in nearbyMerchants) {
        double? distance;
        
        if (merchant.merchantLocLat != null && merchant.merchantLocLong != null) {
          distance = _calculateDistance(
            _userPosition!.latitude,
            _userPosition!.longitude,
            merchant.merchantLocLat!,
            merchant.merchantLocLong!,
          );
          
          Logger.log("📏 Distance calc - ${merchant.merchantName}: ${distance.toStringAsFixed(2)}km");
        } else {
          Logger.log("⚠️ No location data for ${merchant.merchantName}");
        }
        
        merchantsWithDistance.add(MerchantWithDistanceHome(
          merchant: merchant,
          distance: distance,
          isGeoEnhanced: isGeoEnhanced,
        ));
      }
      
      // STEP 5: PROPER SORTING with detailed logging
      Logger.log("🔄 HOMEVM_GEO - Sorting ${merchantsWithDistance.length} merchants by popularity DESC + distance ASC");
      
      // Log before sorting
      Logger.log("📊 Before sorting:");
      for (int i = 0; i < merchantsWithDistance.length; i++) {
        final m = merchantsWithDistance[i];
        Logger.log("   [$i] ${m.merchant.merchantName} - Pop: ${m.merchant.merchantPopularity ?? 0}, Dist: ${m.distance?.toStringAsFixed(2)}km");
      }
      
      merchantsWithDistance.sort((a, b) {
        // Primary sort: merchantPopularity DESC (higher popularity first)
        final popularityA = a.merchant.merchantPopularity ?? 0;
        final popularityB = b.merchant.merchantPopularity ?? 0;
        
        if (popularityA != popularityB) {
          // Higher popularity wins
          Logger.log("🔄 Sorting by popularity: ${a.merchant.merchantName}($popularityA) vs ${b.merchant.merchantName}($popularityB) -> ${popularityB.compareTo(popularityA)}");
          return popularityB.compareTo(popularityA); // DESC
        }
        
        // Secondary sort: distance ASC (closer distance first) when popularity is same
        if (a.distance == null && b.distance == null) return 0;
        if (a.distance == null) return 1;
        if (b.distance == null) return -1;
        
        Logger.log("🔄 Sorting by distance: ${a.merchant.merchantName}(${a.distance?.toStringAsFixed(2)}km) vs ${b.merchant.merchantName}(${b.distance?.toStringAsFixed(2)}km)");
        return a.distance!.compareTo(b.distance!); // ASC
      });
      
      // Log after sorting
      Logger.log("📊 After sorting:");
      for (int i = 0; i < merchantsWithDistance.length; i++) {
        final m = merchantsWithDistance[i];
        Logger.log("   [$i] ${m.merchant.merchantName} - Pop: ${m.merchant.merchantPopularity ?? 0}, Dist: ${m.distance?.toStringAsFixed(2)}km");
      }
      
      // STEP 6: Take only top 5 merchants for recommendations
      final recommendations = merchantsWithDistance.take(5).toList();
      
      Logger.log("✅ HOMEVM_GEO - Final recommendations (${recommendations.length}/5):");
      for (int i = 0; i < recommendations.length; i++) {
        final rec = recommendations[i];
        Logger.log("   ${i + 1}. ${rec.merchant.merchantName}");
        Logger.log("      📊 Popularity: ${rec.merchant.merchantPopularity ?? 0}");
        Logger.log("      📏 Distance: ${rec.distance?.toStringAsFixed(2)}km");
        Logger.log("      🟢 Status: ${rec.merchant.merchantStatus ? 'OPEN' : 'CLOSED'}");
      }
      
      if (recommendations.isEmpty) {
        Logger.log("❌ HOMEVM_GEO - No recommendations found! Check:");
        Logger.log("   1. Are merchants within 20km radius?");
        Logger.log("   2. Do merchants have location data?");
        Logger.log("   3. Is user location accurate?");
        Logger.log("   4. Are there any merchants in database?");
      }
      
      state = AppState.success(recommendations);
      
    } catch (e) {
      Logger.error("❌ HOMEVM_GEO - Error fetching recommended merchants", error: e);
      state = AppState.error(
        Exception(e.toString()),
        message: 'Failed to load recommended merchants'
      );
    }
  }

  /// Calculate distance between two points using Haversine formula
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

  /// Test geo functionality for recommendations
  Future<bool> testGeoFunctionality() async {
    try {
      Logger.log("HOMEVM_GEO - Testing geo functionality for recommendations");
      
      await _initializeGeoService();
      if (!_geoServiceInitialized) {
        Logger.log("HOMEVM_GEO - Geo service not initialized");
        return false;
      }
      
      final merchantService = ref.read(merchantServiceProvider);
      return await merchantService.testGeoFunctionality();
      
    } catch (e) {
      Logger.error("HOMEVM_GEO - Geo test failed", error: e);
      return false;
    }
  }

  /// Get geo service status for recommendations
  Map<String, dynamic> getGeoServiceStatus() {
    final merchantService = ref.read(merchantServiceProvider);
    final status = merchantService.getGeoServiceStatus();
    status['recommendationsInitialized'] = _geoServiceInitialized;
    status['userPosition'] = _userPosition != null ? {
      'latitude': _userPosition!.latitude,
      'longitude': _userPosition!.longitude,
    } : null;
    return status;
  }
}