import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/data/location/location_service.dart';
import 'package:temulapak_app/data/network/merchant_service.dart';
import 'package:temulapak_app/data/network/geo_merchant_service.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/home_page/home_viewmodel.dart';
import 'package:temulapak_app/view/merchant_detail_page/merchant_detail_view.dart';

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
        return "";
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

class MerchantWithDistance {
  final MerchantModel merchant;
  final double? distance; 
  final bool isGeoEnhanced;

  MerchantWithDistance({
    required this.merchant,
    this.distance,
    this.isGeoEnhanced = false, 
  });

  MerchantWithDistance copyWith({
    MerchantModel? merchant,
    double? distance,
    bool? isGeoEnhanced,
  }) {
    return MerchantWithDistance(
      merchant: merchant ?? this.merchant,
      distance: distance ?? this.distance,
      isGeoEnhanced: isGeoEnhanced ?? this.isGeoEnhanced,
    );
  }
}

@riverpod
MerchantService merchantService(ref) {
  return MerchantService();
}

@riverpod
LocationServiceslocationServices(ref) {
  return LocationService.instance;
}

@riverpod
GeoMerchantService geoMerchantService(ref) {
  return GeoMerchantService.instance;
}

@riverpod
class ListMerchantViewModel extends _$ListMerchantViewModel {
  List<MerchantWithDistance> _originalMerchants = [];
  Position? _userPosition;
  bool _geoServiceInitialized = false;
  
  @override
  AppState<List<MerchantWithDistance>, Exception> build() {
    return AppState.idle();
  }

  Future<void> initializeGeoService() async {
    if (_geoServiceInitialized) return;
    
    try {
      Logger.log("LISTVM_GEO - Initializing geo service");
      final geoService = ref.read(geoMerchantServiceProvider);
      _geoServiceInitialized = await geoService.initialize();
      
      if (_geoServiceInitialized) {
        Logger.log("LISTVM_GEO - Geo service initialized successfully");
      } else {
        Logger.log("LISTVM_GEO - Geo service initialization failed, will use fallback");
      }
    } catch (e) {
      Logger.error("LISTVM_GEO - Error initializing geo service", error: e);
      _geoServiceInitialized = false;
    }
  }

  Future<void> fetchMerchants(MerchantCategory category) async {
    _updateState(AppState.loading());
    
    try {
      Logger.log("LISTVM_GEO - Fetching merchants for category: ${category.displayName}");
      await initializeGeoService();
      await _getUserLocation();
      List<MerchantModel> merchants;
      bool isGeoEnhanced = false;
      switch (category) {
        case MerchantCategory.nearest:
          final result = await _fetchNearestMerchantsGeoEnhanced();
          merchants = result['merchants'];
          isGeoEnhanced = result['isGeoEnhanced'];
          break;
        case MerchantCategory.drinks:
        case MerchantCategory.food:
        case MerchantCategory.snacks:
          final result = await _fetchMerchantsByCategoryGeoEnhanced(category.firebaseCategory);
          merchants = result['merchants'];
          isGeoEnhanced = result['isGeoEnhanced'];
          break;
      }
      List<MerchantWithDistance> merchantsWithDistance = await _calculateDistances(merchants, isGeoEnhanced);
      if (_userPosition != null) {
        merchantsWithDistance.sort((a, b) {
          if (a.distance == null && b.distance == null) return 0;
          if (a.distance == null) return 1;
          if (b.distance == null) return -1;
          return a.distance!.compareTo(b.distance!);
        });
      }
      _originalMerchants = merchantsWithDistance;
      Logger.log("LISTVM_GEO - Successfully fetched ${merchantsWithDistance.length} merchants (geo: $isGeoEnhanced)");
      _updateState(AppState.success(merchantsWithDistance));
    } catch (e) {
      Logger.error("LISTVM_GEO - Error fetching merchants", error: e);
      _updateState(AppState.error(
        Exception(e.toString()),
        message: 'Failed to load merchants'
      ));
    }
  }

  Future<void> _getUserLocation() async {
    try {
      Logger.log("LISTVM_GEO - Getting user location for distance calculation");
      final locationService = ref.read(locationServicesProvider);
      _userPosition = await locationService.getCurrentLocation();
      if (_userPosition != null) {
        Logger.log("LISTVM_GEO - User location obtained: ${_userPosition!.latitude}, ${_userPosition!.longitude}");
      } else {
        Logger.log("LISTVM_GEO - Could not get user location, distances will not be calculated");
      }
    } catch (e) {
      Logger.error("LISTVM_GEO - Error getting user location", error: e);
      _userPosition = null;
    }
  }

  void navigateToMerchantDetail(BuildContext context, MerchantModel merchant) {
  Logger.log("LISTVM - Navigating to merchant detail: ${merchant.merchantName}");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MerchantDetailPage(merchant: merchant),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchNearestMerchantsGeoEnhanced() async {
    final locationService = ref.read(locationServicesProvider);
    final position = await locationService.getCurrentLocation();
    if (position == null) {
      throw Exception('Location not available. Please enable GPS.');
    }
    final merchantService = ref.read(merchantServiceProvider);
    try {
      Logger.log("LISTVM_GEO - Attempting geo-enhanced nearest search with 20km radius");
      final merchants = await merchantService.getNearbyMerchants(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusInKm: 20.0, 
        limit: 50,
      );
      final isGeoEnhanced = _geoServiceInitialized && merchants.isNotEmpty;
      Logger.log("LISTVM_GEO - Nearest search completed: ${merchants.length} merchants (geo: $isGeoEnhanced)");
      return {
        'merchants': merchants,
        'isGeoEnhanced': isGeoEnhanced,
      };
    } catch (e) {
      Logger.error("LISTVM_GEO - Error in nearest search", error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _fetchMerchantsByCategoryGeoEnhanced(String category) async {
    final merchantService = ref.read(merchantServiceProvider);
    try {
      Logger.log("LISTVM_GEO - Attempting geo-enhanced category search for: $category with 20km radius");
      final merchants = await merchantService.getMerchantsByCategory(
        category,
        userLatitude: _userPosition?.latitude,
        userLongitude: _userPosition?.longitude,
        maxRadiusKm: 20.0, 
        limit: 50, 
      );
      final isGeoEnhanced = _geoServiceInitialized && _userPosition != null && merchants.isNotEmpty;
      Logger.log("LISTVM_GEO - Category search completed: ${merchants.length} merchants (geo: $isGeoEnhanced)");
      return {
        'merchants': merchants,
        'isGeoEnhanced': isGeoEnhanced,
      };
    } catch (e) {
      Logger.error("LISTVM_GEO - Error in category search", error: e);
      rethrow;
    }
  }

  Future<List<MerchantWithDistance>> _calculateDistances(List<MerchantModel> merchants, bool isGeoEnhanced) async {
    if (_userPosition == null) {
      Logger.log("LISTVM_GEO - No user position, returning merchants without distances");
      return merchants.map((m) => MerchantWithDistance(
        merchant: m, 
        distance: null,
        isGeoEnhanced: isGeoEnhanced,
      )).toList();
    }
    Logger.log("LISTVM_GEO - Calculating distances for ${merchants.length} merchants");
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
        isGeoEnhanced: isGeoEnhanced,
      ));
    }
    Logger.log("LISTVM_GEO - Distance calculation completed (geo: $isGeoEnhanced)");
    return result;
  }

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

  void applyFilter(MerchantFilter filter) {
    if (_originalMerchants.isEmpty) {
      Logger.log("LISTVM_GEO - Cannot apply filter, no merchants loaded");
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
    
    Logger.log("LISTVM_GEO - Applied filter ${filter.displayName}, ${filteredMerchants.length} merchants");
    _updateState(AppState.success(filteredMerchants));
  }

  Future<void> refreshMerchants(MerchantCategory category) async {
    Logger.log("LISTVM_GEO - Refreshing merchants for category: ${category.displayName}");
    await fetchMerchants(category);
  }

  Future<bool> testGeoFunctionality() async {
    try {
      Logger.log("LISTVM_GEO - Testing geo functionality");
      
      await initializeGeoService();
      if (!_geoServiceInitialized) {
        Logger.log("LISTVM_GEO - Geo service not initialized");
        return false;
      }
      
      final merchantService = ref.read(merchantServiceProvider);
      return await merchantService.testGeoFunctionality();
      
    } catch (e) {
      Logger.error("LISTVM_GEO - Geo test failed", error: e);
      return false;
    }
  }

  Map<String, dynamic> getGeoServiceStatus() {
    final merchantService = ref.read(merchantServiceProvider);
    final status = merchantService.getGeoServiceStatus();
    status['viewModelInitialized'] = _geoServiceInitialized;
    return status;
  }

  void _updateState(AppState<List<MerchantWithDistance>, Exception> newState) {
    state = newState;
  }
}

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