// File: lib/view/list_merchant_page/list_merchant_viewmodel.dart
// ENHANCED: Added distance calculation for merchant list

import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/data/location/location_services.dart';
import 'package:temulapak_app/data/network/merchant_service.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/logger.dart';

part 'list_merchant_viewmodel.g.dart';

enum MerchantCategory { nearest, drinks, food, snacks }

enum MerchantFilter { all, open, closed }

extension MerchantCategoryExtension on MerchantCategory {
  String get displayName {
    switch (this) {
      case MerchantCategory.nearest:
        return "Terdekat";
      case MerchantCategory.drinks:
        return "Minuman";
      case MerchantCategory.food:
        return "Makanan";
      case MerchantCategory.snacks:
        return "Cemilan";
    }
  }

  String get firebaseCategory {
    switch (this) {
      case MerchantCategory.nearest:
        return ""; // Special case, not used for Firebase query
      case MerchantCategory.drinks:
        return "Minuman";
      case MerchantCategory.food:
        return "Makanan";
      case MerchantCategory.snacks:
        return "Cemilan";
    }
  }
}

extension MerchantFilterExtension on MerchantFilter {
  String get displayName {
    switch (this) {
      case MerchantFilter.all:
        return "Semua";
      case MerchantFilter.open:
        return "Buka";
      case MerchantFilter.closed:
        return "Tutup";
    }
  }
}

// NEW: Enhanced MerchantWithDistance model
class MerchantWithDistance {
  final MerchantModel merchant;
  final double? distance; // Distance in kilometers

  MerchantWithDistance({
    required this.merchant,
    this.distance,
  });

  MerchantWithDistance copyWith({
    MerchantModel? merchant,
    double? distance,
  }) {
    return MerchantWithDistance(
      merchant: merchant ?? this.merchant,
      distance: distance ?? this.distance,
    );
  }
}

// Provider for MerchantService
@riverpod
MerchantService merchantService(ref) {
  return MerchantService();
}

// Provider for LocationServices
@riverpod
LocationServices locationServices(ref) {
  return LocationServices.instance;
}

// ENHANCED: ViewModel now returns MerchantWithDistance
@riverpod
class ListMerchantViewModel extends _$ListMerchantViewModel {
  List<MerchantWithDistance> _originalMerchants = [];
  Position? _userPosition;
  
  @override
  AppState<List<MerchantWithDistance>, Exception> build() {
    return AppState.idle();
  }

  /// Fetch merchants based on category with distance calculation
  Future<void> fetchMerchants(MerchantCategory category) async {
    _updateState(AppState.loading());
    
    try {
      Logger.log("LISTVM - Fetching merchants for category: ${category.displayName}");
      
      // Step 1: Get user location for distance calculation
      await _getUserLocation();
      
      // Step 2: Fetch merchants based on category
      List<MerchantModel> merchants;
      switch (category) {
        case MerchantCategory.nearest:
          merchants = await _fetchNearestMerchants();
          break;
        case MerchantCategory.drinks:
        case MerchantCategory.food:
        case MerchantCategory.snacks:
          merchants = await _fetchMerchantsByCategory(category.firebaseCategory);
          break;
      }
      
      // Step 3: Calculate distances and create MerchantWithDistance objects
      List<MerchantWithDistance> merchantsWithDistance = await _calculateDistances(merchants);
      
      // Step 4: Sort by distance if user location is available
      if (_userPosition != null) {
        merchantsWithDistance.sort((a, b) {
          if (a.distance == null && b.distance == null) return 0;
          if (a.distance == null) return 1;
          if (b.distance == null) return -1;
          return a.distance!.compareTo(b.distance!);
        });
      }
      
      // Store original data for filtering
      _originalMerchants = merchantsWithDistance;
      
      Logger.log("LISTVM - Successfully fetched ${merchantsWithDistance.length} merchants with distances");
      _updateState(AppState.success(merchantsWithDistance));
      
    } catch (e) {
      Logger.error("LISTVM - Error fetching merchants", error: e);
      _updateState(AppState.error(
        Exception(e.toString()),
        message: 'Failed to load merchants'
      ));
    }
  }

  /// Get user's current location for distance calculation
  Future<void> _getUserLocation() async {
    try {
      Logger.log("LISTVM - Getting user location for distance calculation");
      
      final locationService = ref.read(locationServicesProvider);
      _userPosition = await locationService.getCurrentLocation();
      
      if (_userPosition != null) {
        Logger.log("LISTVM - User location obtained: ${_userPosition!.latitude}, ${_userPosition!.longitude}");
      } else {
        Logger.log("LISTVM - Could not get user location, distances will not be calculated");
      }
    } catch (e) {
      Logger.error("LISTVM - Error getting user location", error: e);
      _userPosition = null;
    }
  }

  /// Calculate distances for all merchants
  Future<List<MerchantWithDistance>> _calculateDistances(List<MerchantModel> merchants) async {
    if (_userPosition == null) {
      Logger.log("LISTVM - No user position, returning merchants without distances");
      return merchants.map((m) => MerchantWithDistance(merchant: m, distance: null)).toList();
    }

    Logger.log("LISTVM - Calculating distances for ${merchants.length} merchants");
    
    List<MerchantWithDistance> result = [];
    
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
      
      result.add(MerchantWithDistance(
        merchant: merchant,
        distance: distance,
      ));
    }
    
    Logger.log("LISTVM - Distance calculation completed");
    return result;
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

  /// Apply filter to current merchants
  void applyFilter(MerchantFilter filter) {
    if (_originalMerchants.isEmpty) {
      Logger.log("LISTVM - Cannot apply filter, no merchants loaded");
      return;
    }
    
    List<MerchantWithDistance> filteredMerchants;
    
    switch (filter) {
      case MerchantFilter.all:
        filteredMerchants = _originalMerchants;
        break;
      case MerchantFilter.open:
        filteredMerchants = _originalMerchants.where((m) => m.merchant.merchantStatus == true).toList();
        break;
      case MerchantFilter.closed:
        filteredMerchants = _originalMerchants.where((m) => m.merchant.merchantStatus == false).toList();
        break;
    }
    
    Logger.log("LISTVM - Applied filter ${filter.displayName}, ${filteredMerchants.length} merchants");
    _updateState(AppState.success(filteredMerchants));
  }

  /// Refresh merchants data
  Future<void> refreshMerchants(MerchantCategory category) async {
    Logger.log("LISTVM - Refreshing merchants for category: ${category.displayName}");
    await fetchMerchants(category);
  }

  /// Private method to update state safely
  void _updateState(AppState<List<MerchantWithDistance>, Exception> newState) {
    state = newState;
  }

  /// Fetch nearest merchants
  Future<List<MerchantModel>> _fetchNearestMerchants() async {
    final locationService = ref.read(locationServicesProvider);
    final position = await locationService.getCurrentLocation();
    
    if (position == null) {
      throw Exception('Location not available. Please enable GPS.');
    }
    
    final merchantService = ref.read(merchantServiceProvider);
    return await merchantService.getNearbyMerchants(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusInKm: 20.0, // 20km radius for list page
      limit: 50, // Higher limit for list page
    );
  }

  /// Fetch merchants by category
  Future<List<MerchantModel>> _fetchMerchantsByCategory(String category) async {
    final merchantService = ref.read(merchantServiceProvider);
    return await merchantService.getMerchantsByCategory(category);
  }
}

// Provider for current filter state
@riverpod
class MerchantFilterState extends _$MerchantFilterState {
  @override
  MerchantFilter build() {
    return MerchantFilter.all;
  }

  void setFilter(MerchantFilter filter) {
    Logger.log("Filter changed to: ${filter.displayName}");
    state = filter;
  }
}