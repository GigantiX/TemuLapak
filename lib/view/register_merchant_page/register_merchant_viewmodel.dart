import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/data/network/merchant_service.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
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

  Future<void> registerMerchant({
    required MerchantModel data,
    required XFile imageFile,
  }) async {
    try {
      state = AppState.loading();
      Logger.log("VM - Starting merchant registration");
      
      final merchant = MerchantModel(
        uid: '',
        merchantStatus: true,
        merchantName: data.merchantName,
        merchantDesc: data.merchantDesc,
        merchantImgUrl: null,
        merchantLocLat: data.merchantLocLat,
        merchantLocLong: data.merchantLocLong,
        merchantCategory: data.merchantCategory,
        products: data.products,
      );
      
      Logger.log("VM - Calling registerMerchant service");
      await _merchantService.registerMerchant(imageFile, merchant);
      
      Logger.log("VM - Merchant registered successfully");
      state = AppState.success("Pendaftaran berhasil! Sekarang Anda sudah terdaftar sebagai penjual.");
      
    } catch (e) {
      Logger.error("VM - Error registering merchant", error: e);
      state = AppState.error(
        e is Exception ? e : Exception(e.toString()),
        message: "Gagal mendaftar: ${e.toString()}"
      );
    }
  }
}

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
    return AppState.idle();
  }
  
  Future<void> pickImage(ImageSource source) async {
    try {
      state = AppState.loading();
      Logger.log("Opening ${source == ImageSource.camera ? 'camera' : 'gallery'} to pick image");
      
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      
      if (pickedFile == null) {
        Logger.log("No image selected");
        state = state.data != null 
            ? AppState.success(state.data)
            : AppState.idle();
        return;
      }
      
      final File file = File(pickedFile.path);
      final int fileSize = await file.length();
      
      if (fileSize > maxFileSizeInBytes) {
        Logger.error(
          "File too large", 
          error: "File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB, max allowed: ${(maxFileSizeInBytes / 1024 / 1024).toStringAsFixed(2)}MB"
        );
        state = AppState.error(
          Exception('File too large'),
          message: 'Ukuran gambar melebihi batas 10MB. Silakan pilih file yang lebih kecil.'
        );
        return;
      }
      
      Logger.log("Image selected successfully: ${pickedFile.path}");
      Logger.log("Image size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB");
      state = AppState.success(file);
    } catch (e) {
      Logger.error("Error picking image", error: e);
      state = AppState.error(
        e is Exception ? e : Exception(e.toString()),
        message: 'Gagal memilih gambar. Silakan coba lagi.'
      );
    }
  }
}