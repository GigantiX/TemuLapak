// File: lib/view/favorite_page/favorite_viewmodel.dart
// UPDATED: Fixed deprecation warnings

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/data/network/favorite_service.dart';
import 'package:temulapak_app/model/favorite/favorite_model.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/logger.dart';
part 'favorite_viewmodel.g.dart';

/// Provider untuk FavoriteService
@riverpod
FavoriteService favoriteService(Ref ref) {  // Fixed: FavoriteServiceRef -> Ref
  return FavoriteService();
}

/// Main Favorite Page ViewModel
@riverpod
class FavoriteViewModel extends _$FavoriteViewModel {
  @override
  AppState<List<FavoriteModel>, Exception> build() {
    return AppState.idle();
  }

  /// Load user favorites
  Future<void> loadFavorites() async {
    state = AppState.loading();
    
    try {
      Logger.log("FAVORITE_VM - Loading user favorites");
      
      final favoriteService = ref.read(favoriteServiceProvider);
      final favorites = await favoriteService.getUserFavorites();
      
      Logger.log("FAVORITE_VM - Loaded ${favorites.length} favorites");
      state = AppState.success(favorites);
      
    } catch (e) {
      Logger.error("FAVORITE_VM - Error loading favorites", error: e);
      state = AppState.error(
        Exception(e.toString()),
        message: 'Failed to load favorites'
      );
    }
  }

  /// Remove favorite
  Future<void> removeFavorite(String merchantId) async {
    try {
      Logger.log("FAVORITE_VM - Removing favorite: $merchantId");
      
      final favoriteService = ref.read(favoriteServiceProvider);
      await favoriteService.removeFromFavorites(merchantId);
      
      // Reload favorites to reflect changes
      await loadFavorites();
      
      Logger.log("FAVORITE_VM - Successfully removed favorite");
    } catch (e) {
      Logger.error("FAVORITE_VM - Error removing favorite", error: e);
      state = AppState.error(
        Exception(e.toString()),
        message: 'Failed to remove favorite'
      );
    }
  }

  /// Refresh favorites
  Future<void> refreshFavorites() async {
    Logger.log("FAVORITE_VM - Refreshing favorites");
    await loadFavorites();
  }

  /// Clear all favorites (for testing purposes)
  Future<void> clearAllFavorites() async {
    try {
      Logger.log("FAVORITE_VM - Clearing all favorites");
      
      final currentFavorites = state.data ?? [];
      final favoriteService = ref.read(favoriteServiceProvider);
      
      for (final favorite in currentFavorites) {
        await favoriteService.removeFromFavorites(favorite.merchantId);
      }
      
      await loadFavorites();
      Logger.log("FAVORITE_VM - All favorites cleared");
    } catch (e) {
      Logger.error("FAVORITE_VM - Error clearing favorites", error: e);
      state = AppState.error(
        Exception(e.toString()),
        message: 'Failed to clear favorites'
      );
    }
  }
}

/// Stream Provider untuk real-time favorites updates
@riverpod
Stream<List<FavoriteModel>> favoritesStream(Ref ref) {  // Fixed: FavoritesStreamRef -> Ref
  Logger.log("FAVORITES_STREAM - Starting favorites stream");
  
  final favoriteService = ref.read(favoriteServiceProvider);
  return favoriteService.getUserFavoritesStream();
}

/// Provider untuk mendapatkan total count favorites
@riverpod
class FavoritesCount extends _$FavoritesCount {
  @override
  AppState<int, Exception> build() {
    return AppState.idle();
  }

  /// Load favorites count
  Future<void> loadCount() async {
    state = AppState.loading();
    
    try {
      Logger.log("FAVORITES_COUNT - Loading favorites count");
      
      final favoriteService = ref.read(favoriteServiceProvider);
      final count = await favoriteService.getFavoritesCount();
      
      Logger.log("FAVORITES_COUNT - Count: $count");
      state = AppState.success(count);
      
    } catch (e) {
      Logger.error("FAVORITES_COUNT - Error loading count", error: e);
      state = AppState.error(
        Exception(e.toString()),
        message: 'Failed to load favorites count'
      );
    }
  }

  /// Refresh count
  Future<void> refreshCount() async {
    await loadCount();
  }
}