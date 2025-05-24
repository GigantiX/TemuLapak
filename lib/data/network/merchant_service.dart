import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:temulapak_app/data/network/user_service.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/utils/logger.dart';

class MerchantService {
  final userService = UserService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
    final storageRef = _storage.ref().child("merchant/MRCN_$uid.$fileExtension");
    final file = File(imageFile.path);

    // Check if image already exists
    try {
      // Try to get metadata to check if file exists
      await storageRef.getMetadata();
      Logger.log("Existing merchant image found, replacing it...");
      // Delete existing image before uploading new one
      await storageRef.delete().catchError((e) {
        Logger.log("No existing image found or error deleting: $e");
      });
    } catch (e) {
      // File doesn't exist yet, which is fine for new merchants
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
    
    // Check if merchant document already exists
    final merchantDoc = await _merchantCollection.doc(merchantId).get();
    final bool isUpdate = merchantDoc.exists;
    
    Logger.log(isUpdate 
        ? "Updating existing merchant profile: $merchantId" 
        : "Creating new merchant profile: $merchantId");
    
    // Upload image and get URL
    String imageUrl = await uploadImageMerchant(imageFile);
    
    // Prepare merchant data
    Map<String, dynamic> merchantData = {
      'uid': uid,
      'merchantStatus': merchant.merchantStatus,
      'merchantName': merchant.merchantName,
      'merchantDesc': merchant.merchantDesc,
      'merchantLocLat': merchant.merchantLocLat,
      'merchantLocLong': merchant.merchantLocLong,
      'merchantImgUrl': imageUrl// Track when update happens
    };
    
    // If it's a new merchant, set popularity to 0
    if (!isUpdate) {
      merchantData['merchantPopularity'] = 0;
    }
    
    // Start a batch for atomic operations
    final batch = FirebaseFirestore.instance.batch();
    
    // Update or create merchant document
    final merchantRef = _merchantCollection.doc(merchantId);
    batch.set(merchantRef, merchantData, SetOptions(merge: true));
    
    // Handle products
    if (merchant.products != null && merchant.products!.isNotEmpty) {
      if (isUpdate) {
        // For updates, first delete existing products
        Logger.log("Updating products for merchant: $merchantId");
        
        // Get existing products collection
        final existingProductsSnapshot = 
            await merchantRef.collection('products').get();
            
        // Delete all existing products
        for (var doc in existingProductsSnapshot.docs) {
          batch.delete(doc.reference);
        }
      }
      
      // Add new products
      Logger.log("Adding ${merchant.products!.length} products");
      for (final product in merchant.products!) {
        final productRef = merchantRef.collection('products').doc();
        batch.set(productRef, product.toMap());
      }
    }
    
    // Commit all operations
    await batch.commit();
    
    // Make sure user has merchant status
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isMerchant': true,
      'merchantId': merchantId
    });
    
    Logger.log(isUpdate 
        ? "Merchant profile updated successfully" 
        : "Merchant registration completed successfully");

  } catch (e) {
    Logger.error("Error in merchant registration/update: $e");
    rethrow;
  }
}
}
