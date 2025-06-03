import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/data/network/merchant_service.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/product/product_model.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/logger.dart';

part 'edit_merchant_profile_viewmodel.g.dart';

@riverpod
class EditMerchantProfileViewModel extends _$EditMerchantProfileViewModel {
  final _merchantService = MerchantService();
  
  @override
  AppState<String, Exception> build() {
    return AppState.idle();
  }

  Future<void> updateMerchantProfile({
    required String merchantName,
    required String merchantDesc,
    required List<String> merchantCategory,
    required List<Product> products,
    XFile? imageFile,
  }) async {
    try {
      state = AppState.loading();
      Logger.log("VM - Starting merchant profile update");
      
      // Get current merchant data to preserve location and other fields
      final currentMerchant = await _merchantService.getUserMerchant();
      
      final updatedMerchant = MerchantModel(
        uid: currentMerchant.uid,
        merchantStatus: currentMerchant.merchantStatus,
        merchantName: merchantName,
        merchantDesc: merchantDesc,
        merchantImgUrl: currentMerchant.merchantImgUrl, // Will be updated if new image provided
        merchantLocLat: currentMerchant.merchantLocLat, // Preserve location
        merchantLocLong: currentMerchant.merchantLocLong, // Preserve location
        merchantPopularity: currentMerchant.merchantPopularity,
        merchantCategory: merchantCategory,
        products: products,
        geoPoint: currentMerchant.geoPoint, // Preserve geoPoint
      );
      
      Logger.log("VM - Calling updateMerchant service");
      
      if (imageFile != null) {
        // Update with new image
        await _merchantService.registerMerchant(imageFile, updatedMerchant);
      } else {
        // Update without changing image
        await _merchantService.updateMerchantProfileOnly(updatedMerchant);
      }
      
      Logger.log("VM - Merchant profile updated successfully");
      state = AppState.success("Profil penjual berhasil diperbarui!");
      
    } catch (e) {
      Logger.error("VM - Error updating merchant profile", error: e);
      state = AppState.error(
        e is Exception ? e : Exception(e.toString()),
        message: "Gagal memperbarui profil: ${e.toString()}"
      );
    }
  }
}

@riverpod
class EditMerchantDataViewModel extends _$EditMerchantDataViewModel {
  final _merchantService = MerchantService();
  
  @override
  AppState<MerchantModel, Exception> build() {
    return AppState.idle();
  }

  Future<void> loadMerchantData() async {
    try {
      state = AppState.loading();
      Logger.log("VM - Loading merchant data for edit");
      
      final merchantData = await _merchantService.getUserMerchant();
      Logger.log("VM - Merchant data loaded successfully for edit");
      
      state = AppState.success(merchantData);
    } catch (e) {
      Logger.error("VM - Error loading merchant data for edit", error: e);
      state = AppState.error(
        e is Exception ? e : Exception(e.toString()),
        message: "Gagal memuat data merchant: ${e.toString()}"
      );
    }
  }
}

@riverpod
class EditPickImageViewModel extends _$EditPickImageViewModel {
  final ImagePicker _picker = ImagePicker();
  // Max file size: 10MB
  final int maxFileSizeInBytes = 10 * 1024 * 1024;
  
  @override
  AppState<File?, Exception> build() {
    return AppState.idle();
  }
  
  Future<void> pickImage(ImageSource source) async {
    try {
      state = AppState.loading();
      Logger.log("Opening ${source == ImageSource.camera ? 'camera' : 'gallery'} to pick image for edit");
      
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      
      if (pickedFile == null) {
        Logger.log("No image selected for edit");
        state = state.data != null 
            ? AppState.success(state.data)
            : AppState.idle();
        return;
      }
      
      final File file = File(pickedFile.path);
      final int fileSize = await file.length();
      
      if (fileSize > maxFileSizeInBytes) {
        Logger.error(
          "File too large for edit", 
          error: "File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB, max allowed: ${(maxFileSizeInBytes / 1024 / 1024).toStringAsFixed(2)}MB"
        );
        state = AppState.error(
          Exception('File too large'),
          message: 'Ukuran gambar melebihi batas 10MB. Silakan pilih file yang lebih kecil.'
        );
        return;
      }
      
      Logger.log("Image selected successfully for edit: ${pickedFile.path}");
      Logger.log("Image size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB");
      state = AppState.success(file);
    } catch (e) {
      Logger.error("Error picking image for edit", error: e);
      state = AppState.error(
        e is Exception ? e : Exception(e.toString()),
        message: 'Gagal memilih gambar. Silakan coba lagi.'
      );
    }
  }
  
  void clearImage() {
    state = AppState.idle();
  }
}