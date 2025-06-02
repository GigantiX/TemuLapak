// File: lib/data/network/geo_merchant_service.dart
// SAFE IMPLEMENTATION: GeoFlutterFire Plus v0.0.32 compatible

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/product/product_model.dart';
import 'package:temulapak_app/utils/logger.dart';

class GeoMerchantService {
  static final GeoMerchantService _instance = GeoMerchantService._internal();
  static GeoMerchantService get instance => _instance;
  factory GeoMerchantService() => _instance;
  GeoMerchantService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GeoCollectionReference<Map<String, dynamic>> _geoCollection;
  bool _isInitialized = false;

  /// Initialize GeoFlutterFire Plus with proper error handling
  Future<bool> initialize() async {
    if (_isInitialized) {
      Logger.log("GEO_SERVICE - Already initialized");
      return true;
    }

    try {
      Logger.log("GEO_SERVICE - Initializing GeoFlutterFire Plus v0.0.32");
      
      // Initialize with proper v0.0.32 syntax
      _geoCollection = GeoCollectionReference(_firestore.collection('merchant'));
      
      _isInitialized = true;
      Logger.log("GEO_SERVICE - Successfully initialized!");
      return true;
      
    } catch (e) {
      Logger.error("GEO_SERVICE - Initialization failed", error: e);
      _isInitialized = false;
      return false;
    }
  }

  /// Check if geo service is available and initialized
  bool get isAvailable => _isInitialized;

  /// Get nearby merchants using GeoFlutterFire Plus
  Future<List<MerchantModel>> getNearbyMerchantsGeo({
    required double latitude,
    required double longitude,
    required double radiusInKm,
    int? limit,
    List<String>? categories,
    bool? isOpen,
  }) async {
    // SAFETY CHECK: Ensure initialization
    if (!_isInitialized) {
      Logger.log("GEO_SERVICE - Not initialized, attempting to initialize...");
      final initSuccess = await initialize();
      if (!initSuccess) {
        throw Exception("GEO_SERVICE - Failed to initialize geo service");
      }
    }

    try {
      Logger.log("GEO_SERVICE - Searching nearby merchants: lat=$latitude, lng=$longitude, radius=${radiusInKm}km");
      
      // Create GeoPoint for center location
      final center = GeoFirePoint(GeoPoint(latitude, longitude));
      
      // Build base geo query with proper v0.0.32 syntax
      Stream<List<DocumentSnapshot<Map<String, dynamic>>>> geoStream = _geoCollection
          .subscribeWithin(
            center: center, 
            radiusInKm: radiusInKm,
            field: 'geoPoint', // Field name in Firestore
            geopointFrom: (data) {
              final geo = data['geoPoint']['geopoint'];
              if (geo is GeoPoint) return geo;
              throw Exception("Invalid or missing GeoPoint in merchant document");
            },
            strictMode: true, // Enable strict mode for accuracy
          );

      // Get the first result from stream (convert to future)
      final List<DocumentSnapshot<Map<String, dynamic>>> documents = 
          await geoStream.first.timeout(
            Duration(seconds: 10),
            onTimeout: () {
              Logger.log("GEO_SERVICE - Query timeout, returning empty list");
              return <DocumentSnapshot<Map<String, dynamic>>>[];
            },
          );

      Logger.log("GEO_SERVICE - Raw geo query returned ${documents.length} documents");

      // Process documents to MerchantModel list
      List<MerchantModel> merchants = [];
      
      for (final doc in documents) {
        try {
          final data = doc.data();
          if (data == null) continue;

          // Apply additional filters
          if (_shouldFilterMerchant(data, categories, isOpen)) {
            continue;
          }

          // Fetch products subcollection
          final productsSnapshot = await doc.reference.collection('products').get();
          List<Product> products = [];
          
          for (var productDoc in productsSnapshot.docs) {
            try {
              final productData = productDoc.data();
              products.add(Product.fromMap(productData));
            } catch (e) {
              Logger.error("GEO_SERVICE - Error parsing product in ${doc.id}", error: e);
              continue;
            }
          }
          
          // Add products to merchant data
          data['products'] = products.map((p) => p.toMap()).toList();
          
          // Convert to MerchantModel
          final merchant = MerchantModel.fromMap(data);
          merchants.add(merchant);
          
        } catch (e) {
          Logger.error("GEO_SERVICE - Error parsing merchant document ${doc.id}", error: e);
          continue;
        }
      }

      // Apply limit if specified
      if (limit != null && merchants.length > limit) {
        merchants = merchants.take(limit).toList();
      }

      Logger.log("GEO_SERVICE - Successfully processed ${merchants.length} nearby merchants");
      return merchants;
      
    } catch (e) {
      Logger.error("GEO_SERVICE - Error in geo query", error: e);
      
      // FALLBACK: Return empty list instead of throwing
      Logger.log("GEO_SERVICE - Returning empty list due to error");
      return [];
    }
  }

  /// Helper method to apply additional filters
  bool _shouldFilterMerchant(
    Map<String, dynamic> data, 
    List<String>? categories, 
    bool? isOpen
  ) {
    // Filter by status if specified
    if (isOpen != null) {
      final merchantStatus = data['merchantStatus'] as bool? ?? false;
      if (merchantStatus != isOpen) {
        return true; // Should filter out
      }
    }

    // Filter by categories if specified
    if (categories != null && categories.isNotEmpty) {
      final merchantCategories = data['merchantCategory'] as List<dynamic>? ?? [];
      final merchantCategoriesStr = merchantCategories.cast<String>();
      
      // Check if merchant has any of the specified categories
      final hasMatchingCategory = categories.any(
        (category) => merchantCategoriesStr.contains(category)
      );
      
      if (!hasMatchingCategory) {
        return true; // Should filter out
      }
    }

    return false; // Don't filter out
  }

  /// Get merchants by category with geo sorting
  Future<List<MerchantModel>> getMerchantsByCategoryGeo({
    required String category,
    double? userLatitude,
    double? userLongitude,
    double maxRadiusKm = 50.0, // Max search radius
    int? limit,
  }) async {
    try {
      Logger.log("GEO_SERVICE - Getting merchants by category: $category");
      
      if (userLatitude != null && userLongitude != null && _isInitialized) {
        // Use geo query if location available and geo service initialized
        Logger.log("GEO_SERVICE - Using geo-enhanced category search");
        
        return await getNearbyMerchantsGeo(
          latitude: userLatitude,
          longitude: userLongitude,
          radiusInKm: maxRadiusKm,
          categories: [category],
          limit: limit,
        );
      } else {
        // Fallback to regular Firestore query
        Logger.log("GEO_SERVICE - Using fallback category search");
        return await _getCategoryFallback(category, limit);
      }
      
    } catch (e) {
      Logger.error("GEO_SERVICE - Error in category geo search", error: e);
      
      // Always fallback to regular query
      Logger.log("GEO_SERVICE - Falling back to regular category query");
      return await _getCategoryFallback(category, limit);
    }
  }

  /// Fallback method for category search without geo
  Future<List<MerchantModel>> _getCategoryFallback(String category, int? limit) async {
    try {
      Query query = _firestore
          .collection('merchant')
          .where('merchantCategory', arrayContains: category);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final querySnapshot = await query.get();
      List<MerchantModel> merchants = [];

      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          
          // Fetch products subcollection
          final productsSnapshot = await doc.reference.collection('products').get();
          List<Product> products = [];
          
          for (var productDoc in productsSnapshot.docs) {
            try {
              final productData = productDoc.data();
              products.add(Product.fromMap(productData));
            } catch (e) {
              Logger.error("GEO_SERVICE - Error parsing product in fallback", error: e);
              continue;
            }
          }
          
          data['products'] = products.map((p) => p.toMap()).toList();
          final merchant = MerchantModel.fromMap(data);
          merchants.add(merchant);
          
        } catch (e) {
          Logger.error("GEO_SERVICE - Error parsing merchant in fallback", error: e);
          continue;
        }
      }

      Logger.log("GEO_SERVICE - Fallback query returned ${merchants.length} merchants");
      return merchants;
      
    } catch (e) {
      Logger.error("GEO_SERVICE - Error in fallback category query", error: e);
      return [];
    }
  }

  /// Test geo functionality
  Future<bool> testGeoFunctionality() async {
    try {
      if (!_isInitialized) {
        final initSuccess = await initialize();
        if (!initSuccess) return false;
      }

      Logger.log("GEO_SERVICE - Testing geo functionality...");
      
      // Test with Jakarta coordinates
      final testResults = await getNearbyMerchantsGeo(
        latitude: -6.2088,
        longitude: 106.8456,
        radiusInKm: 50.0,
        limit: 1,
      );
      
      Logger.log("GEO_SERVICE - Test completed, found ${testResults.length} merchants");
      return true;
      
    } catch (e) {
      Logger.error("GEO_SERVICE - Test failed", error: e);
      return false;
    }
  }

  /// Get service statistics
  Map<String, dynamic> getServiceStats() {
    return {
      'isInitialized': _isInitialized,
      'version': '0.0.32',
      'service': 'GeoMerchantService',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Dispose resources (if needed)
  void dispose() {
    Logger.log("GEO_SERVICE - Disposing resources");
    _isInitialized = false;
  }
}