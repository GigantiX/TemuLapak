import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/data/location/location_service.dart';
import 'package:temulapak_app/data/network/favorite_service.dart';
import 'package:temulapak_app/data/network/merchant_service.dart';
import 'package:temulapak_app/model/favorite/favorite_model.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/favorite_page/favorite_status_viewmodel.dart';
import 'package:temulapak_app/view/merchant_detail_page/merchant_detail_view.dart';
part 'favorite_viewmodel.g.dart';

@riverpod
FavoriteService favoriteService(Ref ref) {
  return FavoriteService();
}

@riverpod
MerchantService merchantServiceFav(Ref ref) {
  return MerchantService();
}

@riverpod
LocationService locationServiceFav(Ref ref) {
  return LocationService.instance;
}

@riverpod
class LocationState extends _$LocationState {
  @override
  Position? build() {
    return null;
  }

  void updateLocation(Position? position) {
    state = position;
  }
}

@riverpod
class FavoriteViewModel extends _$FavoriteViewModel {
  @override
  AppState<List<FavoriteModel>, Exception> build() {
    return AppState.idle();
  }

  Future<void> initialize() async {
    try {
      await loadFavorites();
      await getUserLocation();
    } catch (e) {
      Logger.error("FAVORITE_VM - Initialization failed", error: e);
    }
  }

  Future<void> getUserLocation() async {
    try {
      final locationService = ref.read(locationServiceFavProvider);
      final position = await locationService.getCurrentLocation();
      ref.read(locationStateProvider.notifier).updateLocation(position);
    } catch (e) {
      Logger.error("FAVORITE_VM - Error getting user location", error: e);
    }
  }

  double? calculateDistance(MerchantModel merchant) {
    final userPosition = ref.read(locationStateProvider);
    if (userPosition == null || 
        merchant.merchantLocLat == null || 
        merchant.merchantLocLong == null) {
      return null;
    }
    const double earthRadius = 6371;
    double dLat = _degreesToRadians(merchant.merchantLocLat! - userPosition.latitude);
    double dLon = _degreesToRadians(merchant.merchantLocLong! - userPosition.longitude);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(userPosition.latitude)) * 
        cos(_degreesToRadians(merchant.merchantLocLat!)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  Future<List<MerchantModel>> loadMerchantDetails(List<FavoriteModel> favorites) async {
    try {
      if (favorites.isEmpty) return [];
      final merchantService = ref.read(merchantServiceFavProvider);
      final allMerchants = await merchantService.getAllMerchants();
      final List<MerchantModel> favoriteMerchants = [];
      for (final favorite in favorites) {
        final merchant = allMerchants.firstWhere(
          (m) => "MRCN_${m.uid}" == favorite.merchantId,
          orElse: () => createPlaceholderMerchant(favorite),
        );
        favoriteMerchants.add(merchant);
      }
      return favoriteMerchants;
    } catch (e) {
      Logger.error("FAVORITE_VM - Error loading merchant details", error: e);
      rethrow;
    }
  }

  MerchantModel createPlaceholderMerchant(FavoriteModel favorite) {
    return MerchantModel(
      uid: favorite.merchantId.replaceFirst("MRCN_", ""),
      merchantName: favorite.merchantName ?? "Merchant Tidak Ditemukan",
      merchantStatus: false,
      merchantImgUrl: favorite.merchantImgUrl,
      merchantCategory: favorite.merchantCategory,
    );
  }

  void navigateToMerchantDetail(BuildContext context, MerchantModel merchant) {
    Logger.log("FAVORITE_VM - Navigating to merchant detail: ${merchant.merchantName}");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MerchantDetailPage(merchant: merchant),
      ),
    );
  }

  Future<void> removeFavoriteComplete(
    BuildContext context, 
    String merchantId, 
    String merchantName
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text("Menghapus $merchantName..."),
          ],
        ),
        backgroundColor: MyColor.orange,
        duration: Duration(seconds: 1),
      ),
    );
    
    try {
      Logger.log("FAVORITE_VM - Processing complete remove favorite: $merchantId");
      
      final favoriteService = ref.read(favoriteServiceProvider);
      await favoriteService.removeFromFavorites(merchantId);
      
      try {
        await ref.read(favoriteHelperProvider.notifier)
            .quickRemoveFromFavorites(merchantId, merchantName);
      } catch (e) {
        Logger.log("FAVORITE_VM - Warning: Could not update favorite status provider: $e");
      }
      
      await loadFavorites();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ $merchantName dihapus dari favorit"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      Logger.log("FAVORITE_VM - Successfully completed remove favorite: $merchantName");
      
    } catch (e) {
      Logger.error("FAVORITE_VM - Error in complete remove favorite", error: e);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Gagal menghapus dari favorit"),
            backgroundColor: MyColor.red,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> loadFavorites() async {
    state = AppState.loading();
    
    try {
      final favoriteService = ref.read(favoriteServiceProvider);
      final favorites = await favoriteService.getUserFavorites();
      
      state = AppState.success(favorites);
      
    } catch (e) {
      Logger.error("FAVORITE_VM - Error loading favorites", error: e);
      state = AppState.error(
        Exception(e.toString()),
        message: 'Failed to load favorites'
      );
    }
  }

  Future<void> refreshFavorites() async {
    await Future.wait([
      loadFavorites(),
      getUserLocation(),
    ]);
  }
}

@riverpod
Stream<List<FavoriteModel>> favoritesStream(Ref ref) {
  final favoriteService = ref.read(favoriteServiceProvider);
  return favoriteService.getUserFavoritesStream();
}