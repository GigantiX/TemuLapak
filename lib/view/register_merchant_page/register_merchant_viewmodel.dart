import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/data/network/merchant_service.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/product/product_model.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'register_merchant_viewmodel.g.dart';

@riverpod
class RegisterMerchantViewModel extends _$RegisterMerchantViewModel {
  final _merchantService = MerchantService();
  @override
  AppState<String, Exception> build() {
    return AppState.idle();
  }

  /// Handles all logic for validating and registering a new merchant.
  Future<void> registerMerchant({
    required String name,
    required String description,
    required List<String> categories,
    required List<ProductField> productFields,
    required LatLng? location,
    required XFile? imageFile,
  }) async {
    try {
      state = AppState.loading();
      Logger.log("VM - Starting merchant registration");

      // --- Business Logic & Validation moved to ViewModel ---
      if (imageFile == null) {
        throw Exception("Silakan pilih foto toko terlebih dahulu");
      }
      if (categories.isEmpty) {
        throw Exception("Silakan pilih minimal satu kategori");
      }
      if (location == null) {
        throw Exception("Silakan pilih lokasi toko");
      }
      // --- End of Validation ---

      final products = productFields
          .map((field) => Product(
                productName: field.nameController.text,
                productPrice: field.priceController.text,
              ))
          .toList();

      final merchantData = MerchantModel(
        uid: '', // The service will get the UID
        merchantStatus: true,
        merchantName: name,
        merchantDesc: description,
        merchantImgUrl: null, // This will be set by the service after upload
        merchantLocLat: location.latitude,
        merchantLocLong: location.longitude,
        merchantCategory: categories,
        products: products,
      );

      Logger.log("VM - Calling registerMerchant service");
      await _merchantService.registerMerchant(imageFile, merchantData);

      Logger.log("VM - Merchant registered successfully");
      state = AppState.success(
          "Pendaftaran berhasil! Sekarang Anda sudah terdaftar sebagai penjual.");
          
    } catch (e) {
      Logger.error("VM - Error registering merchant", error: e);
      state = AppState.error(
        e is Exception ? e : Exception(e.toString()),
        message: e.toString(), // Use the exception message directly for UI
      );
    }
  }

  void navigateToProfile(BuildContext context) {
    Navigator.of(context).pop(true);
  }
}

// No changes needed for LocationPickerViewModel or PickImageViewModel
@riverpod
class LocationPickerViewModel extends _$LocationPickerViewModel {
  static const defaultLocation = LatLng(-6.2088, 106.8456);

  @override
  AppState<LatLng, Exception> build() {
    return AppState.idle();
  }

  void setLocation(LatLng location) {
    Logger.log("Location set to: $location");
    state = AppState.success(location);
  }

  void resetLocation() {
    Logger.log("Location reset to default: $defaultLocation");
    state = AppState.success(defaultLocation);
  }
}

@riverpod
class PickImageViewModel extends _$PickImageViewModel {
  final ImagePicker _picker = ImagePicker();
  // Max file size: 10MB
  final int maxFileSizeInBytes = 10 * 1024 * 1024;

  @override
  AppState<File?, Exception> build() {
    Logger.log("PickImageViewModel - Initializing with idle state");
    return AppState.idle();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      state = AppState.loading();
      Logger.log(
          "Opening ${source == ImageSource.camera ? 'camera' : 'gallery'} to pick image");

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (pickedFile == null) {
        Logger.log("No image selected");
        state = AppState.idle();
        return;
      }

      final File file = File(pickedFile.path);
      final int fileSize = await file.length();

      if (fileSize > maxFileSizeInBytes) {
        Logger.error("File too large",
            error:
                "File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB, max allowed: ${(maxFileSizeInBytes / 1024 / 1024).toStringAsFixed(2)}MB");
        state = AppState.error(Exception('File too large'),
            message:
                'Ukuran gambar melebihi batas 10MB. Silakan pilih file yang lebih kecil.');
        return;
      }

      Logger.log("Image selected successfully: ${pickedFile.path}");
      Logger.log(
          "Image size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB");
      state = AppState.success(file);
    } catch (e) {
      Logger.error("Error picking image", error: e);
      state = AppState.error(
          e is Exception ? e : Exception(e.toString()),
          message: 'Gagal memilih gambar. Silakan coba lagi.');
    }
  }

  void resetImage() {
    Logger.log("PickImageViewModel - Resetting image state");
    state = AppState.idle();
  }

  void clearError() {
    if (state.isError) {
      Logger.log("PickImageViewModel - Clearing error state");
      state = AppState.idle();
    }
  }
}