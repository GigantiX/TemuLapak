// File: lib/view/favorite_page/favorite_status_viewmodel.dart
// UPDATED: Fixed deprecation warnings

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/data/network/favorite_service.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/favorite_page/favorite_viewmodel.dart';

part 'favorite_status_viewmodel.g.dart';

/// Provider untuk FavoriteService (shared)
@riverpod
FavoriteService favoriteServiceStatus(Ref ref) {  // Fixed: FavoriteServiceStatusRef -> Ref
  return FavoriteService();
}

/// Favorite Status Provider untuk specific merchant
/// Ini akan digunakan untuk tombol favorite di merchant detail
@riverpod
class FavoriteStatus extends _$FavoriteStatus {
  @override
  AppState<bool, Exception> build(String merchantId) {
    // Auto-load status saat provider dibuat
    Future.microtask(() => checkFavoriteStatus());
    return AppState.idle();
  }

  /// Check if merchant is favorited
  Future<void> checkFavoriteStatus() async {
    state = AppState.loading();
    
    try {
      Logger.log("FAVORITE_STATUS - Checking status for $merchantId");
      
      final favoriteService = ref.read(favoriteServiceStatusProvider);
      final isFavorited = await favoriteService.isFavorited(merchantId);
      
      Logger.log("FAVORITE_STATUS - Status for $merchantId: $isFavorited");
      state = AppState.success(isFavorited);
      
    } catch (e) {
      Logger.error("FAVORITE_STATUS - Error checking status for $merchantId", error: e);
      state = AppState.error(
        Exception(e.toString()),
        message: 'Failed to check favorite status'
      );
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(MerchantModel merchant) async {
    try {
      Logger.log("FAVORITE_STATUS - Toggling favorite for ${merchant.merchantName}");
      
      // Optimistic update - update UI immediately
      final currentState = state;
      final currentStatus = currentState.data ?? false;
      state = AppState.success(!currentStatus);
      
      final favoriteService = ref.read(favoriteServiceStatusProvider);
      final newStatus = await favoriteService.toggleFavorite(merchant);
      
      Logger.log("FAVORITE_STATUS - New status for ${merchant.merchantName}: $newStatus");
      state = AppState.success(newStatus);
      
      // Invalidate related providers to refresh data
      ref.invalidate(favoritesStreamProvider);
      
    } catch (e) {
      Logger.error("FAVORITE_STATUS - Error toggling favorite for ${merchant.merchantName}", error: e);
      
      // Revert optimistic update on error
      await checkFavoriteStatus();
      
      state = AppState.error(
        Exception(e.toString()),
        message: 'Failed to update favorite'
      );
    }
  }

  /// Force refresh status
  Future<void> refreshStatus() async {
    Logger.log("FAVORITE_STATUS - Force refreshing status for $merchantId");
    await checkFavoriteStatus();
  }
}

/// Provider untuk batch checking multiple merchants
/// Berguna untuk list page yang menampilkan banyak merchant
@riverpod
class BatchFavoriteStatus extends _$BatchFavoriteStatus {
  @override
  AppState<Map<String, bool>, Exception> build() {
    return AppState.idle();
  }

  /// Check favorite status untuk multiple merchants
  Future<void> checkMultipleFavoriteStatus(List<String> merchantIds) async {
    state = AppState.loading();
    
    try {
      Logger.log("BATCH_FAVORITE_STATUS - Checking status for ${merchantIds.length} merchants");
      
      final favoriteService = ref.read(favoriteServiceStatusProvider);
      Map<String, bool> statusMap = {};
      
      // Check each merchant status
      for (final merchantId in merchantIds) {
        try {
          final isLiked = await favoriteService.isFavorited(merchantId);
          statusMap[merchantId] = isLiked;
        } catch (e) {
          Logger.error("BATCH_FAVORITE_STATUS - Error checking $merchantId", error: e);
          statusMap[merchantId] = false; // Default to false on error
        }
      }
      
      Logger.log("BATCH_FAVORITE_STATUS - Checked ${statusMap.length} merchants");
      state = AppState.success(statusMap);
      
    } catch (e) {
      Logger.error("BATCH_FAVORITE_STATUS - Error checking multiple statuses", error: e);
      state = AppState.error(
        Exception(e.toString()),
        message: 'Failed to check favorite statuses'
      );
    }
  }

  /// Get status untuk specific merchant dari map
  bool getFavoriteStatus(String merchantId) {
    final statusMap = state.data ?? {};
    return statusMap[merchantId] ?? false;
  }

  /// Update single merchant status dalam map
  void updateSingleStatus(String merchantId, bool newStatus) {
    final currentMap = Map<String, bool>.from(state.data ?? {});
    currentMap[merchantId] = newStatus;
    state = AppState.success(currentMap);
  }
}

/// Helper provider untuk quick access ke favorite service
@riverpod
class FavoriteHelper extends _$FavoriteHelper {
  @override
  AppState<String, Exception> build() {
    return AppState.idle();
  }

  /// Quick add to favorites dengan feedback
  Future<void> quickAddToFavorites(MerchantModel merchant) async {
    state = AppState.loading();
    
    try {
      Logger.log("FAVORITE_HELPER - Quick adding ${merchant.merchantName} to favorites");
      
      final favoriteService = ref.read(favoriteServiceStatusProvider);
      await favoriteService.addToFavorites(merchant);
      
      // Invalidate related providers
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

  /// Quick remove from favorites dengan feedback
  Future<void> quickRemoveFromFavorites(String merchantId, String merchantName) async {
    state = AppState.loading();
    
    try {
      Logger.log("FAVORITE_HELPER - Quick removing $merchantName from favorites");
      
      final favoriteService = ref.read(favoriteServiceStatusProvider);
      await favoriteService.removeFromFavorites(merchantId);
      
      // Invalidate related providers
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

  /// Clear message state
  void clearMessage() {
    state = AppState.idle();
  }
}