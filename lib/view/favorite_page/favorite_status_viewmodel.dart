import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/data/network/favorite_service.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/favorite_page/favorite_viewmodel.dart';

part 'favorite_status_viewmodel.g.dart';

@riverpod
FavoriteService favoriteServiceStatus(Ref ref) {  
  return FavoriteService();
}

@riverpod
class FavoriteStatus extends _$FavoriteStatus {
  @override
  AppState<bool, Exception> build(String merchantId) {
    Future.microtask(() => checkFavoriteStatus());
    return AppState.idle();
  }

  Future<void> checkFavoriteStatus() async {
    state = AppState.loading();
    
    try {
      final favoriteService = ref.read(favoriteServiceStatusProvider);
      final isFavorited = await favoriteService.isFavorited(merchantId);
      
      state = AppState.success(isFavorited);
      
    } catch (e) {
      Logger.error("FAVORITE_STATUS - Error checking status for $merchantId", error: e);
      state = AppState.error(
        Exception(e.toString()),
        message: 'Failed to check favorite status'
      );
    }
  }

  Future<void> toggleFavorite(MerchantModel merchant) async {
    try {
      Logger.log("FAVORITE_STATUS - Toggling favorite for ${merchant.merchantName}");
      
      final currentState = state;
      final currentStatus = currentState.data ?? false;
      state = AppState.success(!currentStatus);
      
      final favoriteService = ref.read(favoriteServiceStatusProvider);
      final newStatus = await favoriteService.toggleFavorite(merchant);
      
      state = AppState.success(newStatus);
      
      ref.invalidate(favoritesStreamProvider);
      
    } catch (e) {
      Logger.error("FAVORITE_STATUS - Error toggling favorite for ${merchant.merchantName}", error: e);
      
      await checkFavoriteStatus();
      
      state = AppState.error(
        Exception(e.toString()),
        message: 'Failed to update favorite'
      );
    }
  }

  Future<void> refreshStatus() async {
    await checkFavoriteStatus();
  }
}

@riverpod
class BatchFavoriteStatus extends _$BatchFavoriteStatus {
  @override
  AppState<Map<String, bool>, Exception> build() {
    return AppState.idle();
  }

  Future<void> checkMultipleFavoriteStatus(List<String> merchantIds) async {
    state = AppState.loading();
    
    try {
      final favoriteService = ref.read(favoriteServiceStatusProvider);
      Map<String, bool> statusMap = {};
      
      for (final merchantId in merchantIds) {
        try {
          final isLiked = await favoriteService.isFavorited(merchantId);
          statusMap[merchantId] = isLiked;
        } catch (e) {
          Logger.error("BATCH_FAVORITE_STATUS - Error checking $merchantId", error: e);
          statusMap[merchantId] = false; 
        }
      }
      
      state = AppState.success(statusMap);
      
    } catch (e) {
      Logger.error("BATCH_FAVORITE_STATUS - Error checking multiple statuses", error: e);
      state = AppState.error(
        Exception(e.toString()),
        message: 'Failed to check favorite statuses'
      );
    }
  }

  bool getFavoriteStatus(String merchantId) {
    final statusMap = state.data ?? {};
    return statusMap[merchantId] ?? false;
  }

  void updateSingleStatus(String merchantId, bool newStatus) {
    final currentMap = Map<String, bool>.from(state.data ?? {});
    currentMap[merchantId] = newStatus;
    state = AppState.success(currentMap);
  }
}

@riverpod
class FavoriteHelper extends _$FavoriteHelper {
  @override
  AppState<String, Exception> build() {
    return AppState.idle();
  }

  Future<void> quickAddToFavorites(MerchantModel merchant) async {
    state = AppState.loading();
    
    try {
      final favoriteService = ref.read(favoriteServiceStatusProvider);
      await favoriteService.addToFavorites(merchant);
      
      ref.invalidate(favoritesStreamProvider);
      ref.invalidate(favoriteStatusProvider("MRCN_${merchant.uid}"));
      
      state = AppState.success("${merchant.merchantName} berhasil ditambahkan ke favorit!");
      
    } catch (e) {
      Logger.error("FAVORITE_HELPER - Error quick adding to favorites", error: e);
      state = AppState.error(
        Exception(e.toString()),
        message: 'Gagal menambahkan ke favorit'
      );
    }
  }

  Future<void> quickRemoveFromFavorites(String merchantId, String merchantName) async {
    state = AppState.loading();
    
    try {
      final favoriteService = ref.read(favoriteServiceStatusProvider);
      await favoriteService.removeFromFavorites(merchantId);
      
      ref.invalidate(favoritesStreamProvider);
      ref.invalidate(favoriteStatusProvider(merchantId));
      
      state = AppState.success("$merchantName berhasil dihapus dari favorit!");
      
    } catch (e) {
      Logger.error("FAVORITE_HELPER - Error quick removing from favorites", error: e);
      state = AppState.error(
        Exception(e.toString()),
        message: 'Gagal menghapus dari favorit'
      );
    }
  }

  void clearMessage() {
    state = AppState.idle();
  }
}