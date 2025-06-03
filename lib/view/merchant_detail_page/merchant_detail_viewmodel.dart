import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/data/location/location_services.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'dart:math';

part 'merchant_detail_viewmodel.g.dart';

@riverpod
LocationServices locationServicesDetail(Ref ref) {
  return LocationServices.instance;
}

// NEW: StreamProvider untuk live merchant data
@riverpod
Stream<MerchantModel?> merchantLiveStream(Ref ref, String merchantId) {
  Logger.log("STREAM - Starting live stream for merchant: $merchantId");
  
  return FirebaseFirestore.instance
      .collection('merchant')
      .doc(merchantId)
      .snapshots()
      .map((documentSnapshot) {
    
    if (!documentSnapshot.exists) {
      Logger.log("STREAM - Merchant document not found: $merchantId");
      return null;
    }
    
    try {
      final data = documentSnapshot.data() as Map<String, dynamic>;
      final merchant = MerchantModel.fromMap(data);
      
      Logger.log("STREAM - Merchant data updated: ${merchant.merchantName}");
      Logger.log("STREAM - Location: ${merchant.merchantLocLat}, ${merchant.merchantLocLong}");
      
      return merchant;
      
    } catch (e) {
      Logger.error("STREAM - Error parsing merchant data", error: e);
      return null;
    }
  }).handleError((error) {
    Logger.error("STREAM - Firebase stream error", error: error);
    throw Exception("Failed to load merchant data: $error");
  });
}

// EXISTING: Keep existing MerchantDetailViewModel
@riverpod
class MerchantDetailViewModel extends _$MerchantDetailViewModel {
  @override
  AppState<Map<String, dynamic>, Exception> build() {
    return AppState.idle();
  }

  /// Initialize merchant detail with distance calculation
  Future<void> initializeMerchantDetail(MerchantModel merchant) async {
    _updateState(AppState.loading());
    
    try {
      Logger.log("DETAILVM - Initializing merchant detail: ${merchant.merchantName}");
      
      // Calculate distance from user location
      double? distance;
      try {
        distance = await _calculateDistanceFromUser(merchant);
      } catch (e) {
        Logger.error("DETAILVM - Error calculating distance", error: e);
        // Continue without distance if location fails
        distance = null;
      }
      
      // Calculate price range from products
      Map<String, dynamic> priceRange = _calculatePriceRange(merchant.products);
      
      // Prepare detail data
      Map<String, dynamic> detailData = {
        'merchant': merchant,
        'distance': distance,
        'totalProducts': merchant.products?.length ?? 0,
        'hasLocation': merchant.merchantLocLat != null && merchant.merchantLocLong != null,
        'minPrice': priceRange['minPrice'],
        'maxPrice': priceRange['maxPrice'],
        'priceRangeText': priceRange['priceRangeText'],
      };
      
      Logger.log("DETAILVM - Merchant detail initialized successfully");
      Logger.log("DETAILVM - Distance: ${distance?.toStringAsFixed(2)} km");
      Logger.log("DETAILVM - Total products: ${detailData['totalProducts']}");
      Logger.log("DETAILVM - Price range: ${detailData['priceRangeText']}");
      
      _updateState(AppState.success(detailData));
      
    } catch (e) {
      Logger.error("DETAILVM - Error initializing merchant detail", error: e);
      _updateState(AppState.error(
        Exception(e.toString()),
        message: 'Failed to load merchant details'
      ));
    }
  }

  /// Calculate price range from merchant products
  Map<String, dynamic> _calculatePriceRange(List<dynamic>? products) {
    if (products == null || products.isEmpty) {
      return {
        'minPrice': null,
        'maxPrice': null,
        'priceRangeText': 'Harga tidak tersedia',
      };
    }
    
    List<int> prices = [];
    
    for (var product in products) {
      try {
        String? priceString = product.productPrice?.toString();
        if (priceString != null && priceString.isNotEmpty) {
          // Remove any non-digit characters and parse
          String cleanPrice = priceString.replaceAll(RegExp(r'[^\d]'), '');
          if (cleanPrice.isNotEmpty) {
            int price = int.parse(cleanPrice);
            prices.add(price);
          }
        }
      } catch (e) {
        Logger.error("Error parsing price: ${product.productPrice}", error: e);
        // Skip invalid prices
        continue;
      }
    }
    
    if (prices.isEmpty) {
      return {
        'minPrice': null,
        'maxPrice': null,
        'priceRangeText': 'Harga tidak tersedia',
      };
    }
    
    prices.sort();
    int minPrice = prices.first;
    int maxPrice = prices.last;
    
    String priceRangeText;
    if (minPrice == maxPrice) {
      priceRangeText = "Rp ${_formatPrice(minPrice)}";
    } else {
      priceRangeText = "Rp ${_formatPrice(minPrice)} - ${_formatPrice(maxPrice)}";
    }
    
    return {
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'priceRangeText': priceRangeText,
    };
  }

  /// Format price with thousand separator
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  /// Calculate distance from user's current location to merchant
  Future<double?> _calculateDistanceFromUser(MerchantModel merchant) async {
    if (merchant.merchantLocLat == null || merchant.merchantLocLong == null) {
      return null;
    }
    
    final locationService = ref.read(locationServicesDetailProvider);
    final position = await locationService.getCurrentLocation();
    
    if (position == null) {
      throw Exception('Unable to get current location');
    }
    
    // Calculate distance using Haversine formula
    return _calculateDistance(
      position.latitude,
      position.longitude,
      merchant.merchantLocLat!,
      merchant.merchantLocLong!,
    );
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

  /// Refresh merchant detail
  Future<void> refreshMerchantDetail(MerchantModel merchant) async {
    Logger.log("DETAILVM - Refreshing merchant detail");
    await initializeMerchantDetail(merchant);
  }

  /// Private method to update state safely
  void _updateState(AppState<Map<String, dynamic>, Exception> newState) {
    state = newState;
  }
}