import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:temulapak_app/data/network/user_service.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/product/product_model.dart';
import 'package:temulapak_app/utils/logger.dart';

class MerchantService {
  final userService = UserService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

      // ⭐ STEP 1 NEW: Add merchantPopularity field initialization
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
      // ⭐ END STEP 1 NEW

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

  // NEW METHODS FOR FETCHING DATA

  /// Fetch all merchants from Firebase
  Future<List<MerchantModel>> getAllMerchants() async {
    try {
      Logger.log("MS - Fetching all merchants");
      
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

  /// Fetch merchants by specific category
  Future<List<MerchantModel>> getMerchantsByCategory(String category) async {
    try {
      Logger.log("MS - Fetching merchants by category: $category");
      
      final querySnapshot = await _merchantCollection
          .where('merchantCategory', arrayContains: category)
          .get();
          
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

  /// Fetch nearby merchants based on user location
  Future<List<MerchantModel>> getNearbyMerchants({
    required double latitude,
    required double longitude,
    double radiusInKm = 10.0,
    int limit = 5,
  }) async {
    try {
      Logger.log("MS - Fetching nearby merchants within ${radiusInKm}km, limit: $limit");
      
      // Get all merchants first (simple approach)
      final allMerchants = await getAllMerchants();
      
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

      Logger.log("MS - Found ${nearbyMerchants.length} nearby merchants");
      return nearbyMerchants;
      
    } catch (e) {
      Logger.error("MS - Error fetching nearby merchants", error: e);
      throw Exception("Failed to fetch nearby merchants: $e");
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
}