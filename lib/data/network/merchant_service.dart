import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:temulapak_app/data/network/user_service.dart';
import 'package:temulapak_app/data/network/geo_merchant_service.dart'; // NEW IMPORT
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/product/product_model.dart';
import 'package:temulapak_app/utils/logger.dart';

class MerchantService {
  final userService = UserService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // NEW: Geo service integration
  final GeoMerchantService _geoService = GeoMerchantService.instance;

  // Collection name sesuai dengan Firebase actual
  final CollectionReference _merchantCollection =
      FirebaseFirestore.instance.collection('merchant');

  Future<String> uploadImageMerchant(XFile imageFile) async {
    try {
      final uid = userService.getCurrentUID();
      if (uid == null) {
        Logger.error("User not authenticated");
        throw Exception("User not authenticated");
      }

      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final storageRef =
          _storage.ref().child("merchant/MRCN_$uid.$fileExtension");
      final file = File(imageFile.path);

      try {
        await storageRef.getMetadata();
        Logger.log("Existing merchant image found, replacing it...");

        await storageRef.delete().catchError((e) {
          Logger.log("No existing image found or error deleting: $e");
        });
      } catch (e) {
        Logger.log("No existing merchant image found, creating new one.");
      }

      Logger.log("Uploading image to Firebase Storage: ${storageRef.fullPath}");

      final uploadTask = storageRef.putFile(
          file,
          SettableMetadata(
              contentType: "image/$fileExtension",
              customMetadata: {
                'userId': uid,
                'uploadDate': DateTime.now().toIso8601String()
              }));

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      Logger.log("Image uploaded successfully: $downloadUrl");

      return downloadUrl;
    } catch (e) {
      Logger.error("Failed to upload image: $e");
      throw Exception("Failed to upload image: $e");
    }
  }

  Future<void> registerMerchant(XFile imageFile, MerchantModel merchant) async {
    try {
      Logger.log("MS - Starting merchant registration/update process");
      final uid = userService.getCurrentUID();

      if (uid == null) {
        Logger.error("User not authenticated");
        throw Exception("User not authenticated");
      }

      final merchantId = "MRCN_$uid";
      final merchantDoc = await _merchantCollection.doc(merchantId).get();
      final bool isUpdate = merchantDoc.exists;

      Logger.log(isUpdate
          ? "Updating existing merchant profile: $merchantId"
          : "Creating new merchant profile: $merchantId");

      GeoFirePoint? geoPoint;
      if (merchant.merchantLocLat != null && merchant.merchantLocLong != null) {
        double lat = merchant.merchantLocLat!;
        double long = merchant.merchantLocLong!;
        geoPoint = GeoFirePoint(GeoPoint(lat, long));
      }

      String imageUrl = await uploadImageMerchant(imageFile);

      Map<String, dynamic> merchantData = {
        'uid': uid,
        'merchantStatus': merchant.merchantStatus,
        'merchantName': merchant.merchantName,
        'merchantDesc': merchant.merchantDesc,
        'merchantLocLat': merchant.merchantLocLat,
        'merchantLocLong': merchant.merchantLocLong,
        'merchantCategory': merchant.merchantCategory,
        'merchantImgUrl': imageUrl,
      };

      // ⭐ Initialize merchantPopularity field
      if (!isUpdate) {
        merchantData['merchantPopularity'] = 0;
        Logger.log("MS - Initializing merchantPopularity to 0 for new merchant");
      } else {
        // For existing merchants being updated, ensure popularity field exists
        final existingData = merchantDoc.data() as Map<String, dynamic>?;
        if (existingData != null && !existingData.containsKey('merchantPopularity')) {
          merchantData['merchantPopularity'] = 0;
          Logger.log("MS - Adding missing merchantPopularity field to existing merchant");
        }
      }

      if (geoPoint != null) {
        merchantData['geoPoint'] = geoPoint.data;
      } else {
        Logger.log("No location provided, geoPoint will not be set.");
      }

      //batch for atomic operations
      final batch = FirebaseFirestore.instance.batch();

      final merchantRef = _merchantCollection.doc(merchantId);
      batch.set(merchantRef, merchantData, SetOptions(merge: true));

      if (merchant.products != null && merchant.products!.isNotEmpty) {
        if (isUpdate) {
          Logger.log("Updating products for merchant: $merchantId");

          final existingProductsSnapshot =
              await merchantRef.collection('products').get();

          for (var doc in existingProductsSnapshot.docs) {
            batch.delete(doc.reference);
          }
        }

        Logger.log("Adding ${merchant.products!.length} products");
        for (final product in merchant.products!) {
          final productRef = merchantRef.collection('products').doc();
          batch.set(productRef, product.toMap());
        }
      }

      await batch.commit();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'isMerchant': true, 'merchantId': merchantId});

      Logger.log(isUpdate
          ? "Merchant profile updated successfully (with popularity field check)"
          : "Merchant registration completed successfully (with popularity field)");
    } catch (e) {
      Logger.error("Error in merchant registration/update: $e");
      rethrow;
    }
  }

  // ENHANCED METHODS FOR FETCHING DATA WITH GEO SUPPORT

  /// Fetch all merchants from Firebase (fallback method)
  Future<List<MerchantModel>> getAllMerchants() async {
    try {
      Logger.log("MS - Fetching all merchants (fallback method)");
      
      final querySnapshot = await _merchantCollection.get();
      List<MerchantModel> merchants = [];

      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          
          // Fetch products subcollection
          final productsSnapshot = await doc.reference.collection('products').get();
          List<Product> products = [];
          
          for (var productDoc in productsSnapshot.docs) {
            final productData = productDoc.data();
            products.add(Product.fromMap(productData));
          }
          
          // Add products to merchant data untuk fromMap
          data['products'] = products.map((p) => p.toMap()).toList();
          
          final merchant = MerchantModel.fromMap(data);
          merchants.add(merchant);
          
        } catch (e) {
          Logger.error("Error parsing merchant document ${doc.id}", error: e);
          continue; // Skip this document and continue with others
        }
      }

      Logger.log("MS - Successfully fetched ${merchants.length} merchants");
      return merchants;
      
    } catch (e) {
      Logger.error("MS - Error fetching all merchants", error: e);
      throw Exception("Failed to fetch merchants: $e");
    }
  }

  /// ENHANCED: Fetch merchants by category with GEO support
  Future<List<MerchantModel>> getMerchantsByCategory(
    String category, {
    double? userLatitude,
    double? userLongitude,
    double maxRadiusKm = 50.0,
    int? limit,
  }) async {
    try {
      Logger.log("MS - Fetching merchants by category: $category (GEO-enhanced)");
      
      // TRY GEO-ENHANCED SEARCH FIRST
      if (userLatitude != null && userLongitude != null) {
        try {
          Logger.log("MS - Attempting geo-enhanced category search");
          
          final geoMerchants = await _geoService.getMerchantsByCategoryGeo(
            category: category,
            userLatitude: userLatitude,
            userLongitude: userLongitude,
            maxRadiusKm: maxRadiusKm,
            limit: limit,
          );
          
          if (geoMerchants.isNotEmpty) {
            Logger.log("MS - Geo search successful, found ${geoMerchants.length} merchants");
            return geoMerchants;
          } else {
            Logger.log("MS - Geo search returned empty, falling back to regular search");
          }
          
        } catch (e) {
          Logger.error("MS - Geo search failed, falling back to regular search", error: e);
        }
      }
      
      // FALLBACK TO REGULAR SEARCH
      Logger.log("MS - Using regular category search");
      
      Query query = _merchantCollection.where('merchantCategory', arrayContains: category);
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
            final productData = productDoc.data();
            products.add(Product.fromMap(productData));
          }
          
          data['products'] = products.map((p) => p.toMap()).toList();
          
          final merchant = MerchantModel.fromMap(data);
          merchants.add(merchant);
          
        } catch (e) {
          Logger.error("Error parsing merchant document ${doc.id}", error: e);
          continue;
        }
      }

      Logger.log("MS - Successfully fetched ${merchants.length} merchants for category: $category");
      return merchants;
      
    } catch (e) {
      Logger.error("MS - Error fetching merchants by category", error: e);
      throw Exception("Failed to fetch merchants by category: $e");
    }
  }

  /// ENHANCED: Fetch nearby merchants with GEO support
  Future<List<MerchantModel>> getNearbyMerchants({
    required double latitude,
    required double longitude,
    double radiusInKm = 10.0,
    int limit = 5,
    List<String>? categories,
    bool? isOpen,
  }) async {
    try {
      Logger.log("MS - Fetching nearby merchants (GEO-enhanced): radius=${radiusInKm}km, limit=$limit");
      
      // TRY GEO-ENHANCED SEARCH FIRST
      try {
        Logger.log("MS - Attempting geo query");
        
        final geoMerchants = await _geoService.getNearbyMerchantsGeo(
          latitude: latitude,
          longitude: longitude,
          radiusInKm: radiusInKm,
          limit: limit,
          categories: categories,
          isOpen: isOpen,
        );
        
        if (geoMerchants.isNotEmpty) {
          Logger.log("MS - Geo query successful, found ${geoMerchants.length} nearby merchants");
          return geoMerchants;
        } else {
          Logger.log("MS - Geo query returned empty, falling back to Haversine calculation");
        }
        
      } catch (e) {
        Logger.error("MS - Geo query failed, falling back to Haversine calculation", error: e);
      }
      
      // FALLBACK TO HAVERSINE CALCULATION
      Logger.log("MS - Using Haversine fallback method");
      
      // Get all merchants first (or apply basic filters)
      Query query = _merchantCollection;
      
      // Apply status filter if specified
      if (isOpen != null) {
        query = query.where('merchantStatus', isEqualTo: isOpen);
      }
      
      // Apply category filter if specified
      if (categories != null && categories.isNotEmpty) {
        query = query.where('merchantCategory', arrayContainsAny: categories);
      }
      
      final allMerchants = await _fetchMerchantsFromQuery(query);
      
      List<Map<String, dynamic>> merchantsWithDistance = [];
      
      for (var merchant in allMerchants) {
        if (merchant.merchantLocLat == null || merchant.merchantLocLong == null) {
          continue; // Skip merchants without location
        }
        
        // Calculate distance using Haversine formula
        final distance = _calculateDistance(
          latitude, 
          longitude, 
          merchant.merchantLocLat!, 
          merchant.merchantLocLong!
        );
        
        if (distance <= radiusInKm) {
          merchantsWithDistance.add({
            'merchant': merchant,
            'distance': distance,
          });
        }
      }
      
      // Sort by distance
      merchantsWithDistance.sort((a, b) => 
        (a['distance'] as double).compareTo(b['distance'] as double)
      );
      
      // Apply limit and extract merchants
      final nearbyMerchants = merchantsWithDistance
          .take(limit)
          .map((item) => item['merchant'] as MerchantModel)
          .toList();

      Logger.log("MS - Haversine calculation found ${nearbyMerchants.length} nearby merchants");
      return nearbyMerchants;
      
    } catch (e) {
      Logger.error("MS - Error fetching nearby merchants", error: e);
      throw Exception("Failed to fetch nearby merchants: $e");
    }
  }

  /// Helper method to fetch merchants from a query
  Future<List<MerchantModel>> _fetchMerchantsFromQuery(Query query) async {
    final querySnapshot = await query.get();
    List<MerchantModel> merchants = [];

    for (var doc in querySnapshot.docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        
        // Fetch products subcollection
        final productsSnapshot = await doc.reference.collection('products').get();
        List<Product> products = [];
        
        for (var productDoc in productsSnapshot.docs) {
          final productData = productDoc.data();
          products.add(Product.fromMap(productData));
        }
        
        data['products'] = products.map((p) => p.toMap()).toList();
        
        final merchant = MerchantModel.fromMap(data);
        merchants.add(merchant);
        
      } catch (e) {
        Logger.error("Error parsing merchant document ${doc.id}", error: e);
        continue;
      }
    }

    return merchants;
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

  /// NEW: Test geo functionality
  Future<bool> testGeoFunctionality() async {
    try {
      Logger.log("MS - Testing geo functionality");
      return await _geoService.testGeoFunctionality();
    } catch (e) {
      Logger.error("MS - Geo test failed", error: e);
      return false;
    }
  }

  /// NEW: Get geo service status
  Map<String, dynamic> getGeoServiceStatus() {
    return _geoService.getServiceStats();
  }
}