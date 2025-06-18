import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:temulapak_app/data/network/user_service.dart';
import 'package:temulapak_app/model/favorite/favorite_model.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/utils/logger.dart';

class FavoriteService {
  final userService = UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _favoritesCollection => 
      _firestore.collection('favorites');
  
  CollectionReference get _merchantCollection => 
      _firestore.collection('merchant');

  /// Add merchant to favorites WITH popularity increment
  Future<void> addToFavorites(MerchantModel merchant) async {
    try {
      final uid = userService.getCurrentUID();
      if (uid == null) {
        throw Exception("User not authenticated");
      }

      final merchantId = "MRCN_${merchant.uid}";
      Logger.log("🚀 FAVORITE_SERVICE - Starting add to favorites for $merchantId");

      // Check if already favorited
      final isAlreadyFavorited = await isFavorited(merchantId);
      if (isAlreadyFavorited) {
        Logger.log("⚠️ FAVORITE_SERVICE - Merchant already in favorites");
        return;
      }

      // Get current favorites count to determine order
      final userFavoritesRef = _favoritesCollection
          .doc(uid)
          .collection('merchants');

      final snapshot = await userFavoritesRef.get();
      final order = snapshot.size + 1;

      final favorite = FavoriteModel(
        merchantId: merchantId,
        addedAt: DateTime.now(),
        order: order,
        merchantName: merchant.merchantName,
        merchantImgUrl: merchant.merchantImgUrl,
        merchantStatus: merchant.merchantStatus,
        merchantCategory: merchant.merchantCategory,
      );

      // Check if merchant document exists first
      final merchantDocRef = _merchantCollection.doc(merchantId);
      final merchantDocSnapshot = await merchantDocRef.get();
      
      if (!merchantDocSnapshot.exists) {
        Logger.error("❌ DEBUG - Merchant document NOT FOUND: $merchantId");
        throw Exception("Merchant document not found: $merchantId");
      }

      final merchantData = merchantDocSnapshot.data() as Map<String, dynamic>?;
      final currentPopularity = merchantData?['merchantPopularity'] ?? 0;
      Logger.log("🔍 DEBUG - Current popularity before increment: $currentPopularity");

      // Create batch operation
      final batch = _firestore.batch();

      // 1. Add to favorites
      batch.set(userFavoritesRef.doc(merchantId), favorite.toMap());

      // 2. Update favorites metadata
      batch.set(
        _favoritesCollection.doc(uid),
        {
          'totalFavorites': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 3. ⭐ INCREMENT MERCHANT POPULARITY ⭐
      batch.update(
        merchantDocRef,
        {
          'merchantPopularity': FieldValue.increment(1),
        },
      );

      // Execute all operations atomically
      Logger.log("🚀 DEBUG - Committing batch operation...");
      await batch.commit();
      Logger.log("✅ DEBUG - Batch committed successfully!");

      // Verify the update
      final updatedMerchantDoc = await merchantDocRef.get();
      if (updatedMerchantDoc.exists) {
        final updatedData = updatedMerchantDoc.data() as Map<String, dynamic>?;
        Logger.log("🔍 DEBUG - After increment popularity: ${updatedData?['merchantPopularity']}");
      }

      Logger.log("✅ FAVORITE_SERVICE - Successfully added to favorites and incremented popularity");

    } catch (e) {
      Logger.error("❌ FAVORITE_SERVICE - Error adding to favorites", error: e);
      await _handlePopularityErrorRecovery(merchant.uid, increment: true);
      rethrow;
    }
  }

  /// Remove merchant from favorites WITH popularity decrement (SAFE)
  Future<void> removeFromFavorites(String merchantId) async {
    try {
      final uid = userService.getCurrentUID();
      if (uid == null) {
        throw Exception("User not authenticated");
      }

      Logger.log("🚀 FAVORITE_SERVICE - Starting remove from favorites for $merchantId");

      final userFavoritesRef = _favoritesCollection
          .doc(uid)
          .collection('merchants');

      // Get the favorite to be removed to get its order
      final favoriteDoc = await userFavoritesRef.doc(merchantId).get();
      if (!favoriteDoc.exists) {
        Logger.log("⚠️ FAVORITE_SERVICE - Merchant not in favorites");
        return;
      }

      final favoriteData = favoriteDoc.data() as Map<String, dynamic>;
      final removedOrder = favoriteData['order'] as int;

      // Check merchant document and current popularity
      final merchantDocRef = _merchantCollection.doc(merchantId);
      final merchantDocSnapshot = await merchantDocRef.get();
      
      if (!merchantDocSnapshot.exists) {
        Logger.error("❌ DEBUG - Merchant document NOT FOUND: $merchantId");
        throw Exception("Merchant document not found: $merchantId");
      }

      final merchantData = merchantDocSnapshot.data() as Map<String, dynamic>?;
      final currentPopularity = merchantData?['merchantPopularity'] ?? 0;
      Logger.log("🔍 DEBUG - Current popularity before decrement: $currentPopularity");

      // ⭐ SAFETY CHECK: Don't decrement if already 0 or negative ⭐
      if (currentPopularity <= 0) {
        Logger.log("⚠️ SAFETY - Popularity already 0 or negative ($currentPopularity), will set to 0");
        
        // Safe removal without popularity decrement
        final batch = _firestore.batch();

        // 1. Remove the favorite
        batch.delete(userFavoritesRef.doc(merchantId));

        // 2. Update favorites metadata  
        batch.set(
          _favoritesCollection.doc(uid),
          {
            'totalFavorites': FieldValue.increment(-1),
            'lastUpdated': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // 3. ⭐ SET POPULARITY TO 0 (SAFE) ⭐
        batch.update(
          merchantDocRef,
          {
            'merchantPopularity': 0, // Explicitly set to 0
          },
        );

        await batch.commit();
        Logger.log("✅ SAFETY - Removed favorite and set popularity to 0");

      } else {
        // Normal decrement (popularity > 0)
        Logger.log("✅ NORMAL - Will decrement popularity from $currentPopularity to ${currentPopularity - 1}");
        
        final batch = _firestore.batch();

        // 1. Remove the favorite
        batch.delete(userFavoritesRef.doc(merchantId));

        // 2. Update favorites metadata  
        batch.set(
          _favoritesCollection.doc(uid),
          {
            'totalFavorites': FieldValue.increment(-1),
            'lastUpdated': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // 3. ⭐ SAFE DECREMENT MERCHANT POPULARITY ⭐
        batch.update(
          merchantDocRef,
          {
            'merchantPopularity': FieldValue.increment(-1),
          },
        );

        await batch.commit();
        Logger.log("✅ NORMAL - Safely decremented popularity");
      }

      // Verify the update
      final updatedMerchantDoc = await merchantDocRef.get();
      if (updatedMerchantDoc.exists) {
        final updatedData = updatedMerchantDoc.data() as Map<String, dynamic>?;
        final finalPopularity = updatedData?['merchantPopularity'] ?? 0;
        Logger.log("🔍 DEBUG - Final popularity after removal: $finalPopularity");
        
        // Additional safety check
        if (finalPopularity < 0) {
          Logger.log("🚨 EMERGENCY FIX - Popularity went negative ($finalPopularity), fixing to 0");
          await merchantDocRef.update({'merchantPopularity': 0});
        }
      }

      // Re-order remaining favorites
      await _reorderAfterRemoval(uid, removedOrder);

      Logger.log("✅ FAVORITE_SERVICE - Successfully removed from favorites with safe popularity handling");

    } catch (e) {
      Logger.error("❌ FAVORITE_SERVICE - Error removing from favorites", error: e);
      await _handlePopularityErrorRecovery(
        merchantId.replaceFirst("MRCN_", ""), 
        increment: false
      );
      rethrow;
    }
  }

  /// Enhanced error recovery for popularity updates
  Future<void> _handlePopularityErrorRecovery(String merchantUid, {required bool increment}) async {
    try {
      Logger.log("🔄 FAVORITE_SERVICE - Attempting popularity error recovery for $merchantUid");
      
      final merchantId = "MRCN_$merchantUid";
      final merchantDoc = await _merchantCollection.doc(merchantId).get();
      
      if (merchantDoc.exists) {
        final data = merchantDoc.data() as Map<String, dynamic>?;
        final currentPopularity = data?['merchantPopularity'] ?? 0;
        
        if (increment) {
          final newPopularity = currentPopularity + 1;
          await _merchantCollection.doc(merchantId).update({
            'merchantPopularity': newPopularity,
          });
          Logger.log("🔄 RECOVERY - Incremented popularity to $newPopularity");
        } else {
          // ⭐ SAFE DECREMENT IN RECOVERY ⭐
          final newPopularity = currentPopularity > 0 ? currentPopularity - 1 : 0;
          await _merchantCollection.doc(merchantId).update({
            'merchantPopularity': newPopularity,
          });
          Logger.log("🔄 RECOVERY - Safely decremented popularity to $newPopularity");
        }
      }
    } catch (recoveryError) {
      Logger.error("❌ RECOVERY - Error recovery failed", error: recoveryError);
    }
  }

  // Keep all existing methods the same...
  Future<bool> isFavorited(String merchantId) async {
    try {
      final uid = userService.getCurrentUID();
      if (uid == null) {
        return false;
      }

      final doc = await _favoritesCollection
          .doc(uid)
          .collection('merchants')
          .doc(merchantId)
          .get();

      return doc.exists;
    } catch (e) {
      Logger.error("FAVORITE_SERVICE - Error checking favorite status", error: e);
      return false;
    }
  }

  Future<List<FavoriteModel>> getUserFavorites() async {
    try {
      final uid = userService.getCurrentUID();
      if (uid == null) {
        throw Exception("User not authenticated");
      }

      final snapshot = await _favoritesCollection
          .doc(uid)
          .collection('merchants')
          .orderBy('order')
          .get();

      final favorites = snapshot.docs
          .map((doc) {
            try {
              return FavoriteModel.fromMap(doc.data());
            } catch (e) {
              Logger.error("FAVORITE_SERVICE - Error parsing favorite ${doc.id}", error: e);
              return null;
            }
          })
          .where((favorite) => favorite != null)
          .cast<FavoriteModel>()
          .toList();

      return favorites;
    } catch (e) {
      Logger.error("FAVORITE_SERVICE - Error fetching favorites", error: e);
      rethrow;
    }
  }

  Stream<List<FavoriteModel>> getUserFavoritesStream() {
    final uid = userService.getCurrentUID();
    if (uid == null) {
      return Stream.value([]);
    }

    return _favoritesCollection
        .doc(uid)
        .collection('merchants')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return FavoriteModel.fromMap(doc.data());
            } catch (e) {
              Logger.error("FAVORITE_SERVICE - Error parsing favorite ${doc.id} in stream", error: e);
              return null;
            }
          })
          .where((favorite) => favorite != null)
          .cast<FavoriteModel>()
          .toList();
    });
  }

  Future<bool> toggleFavorite(MerchantModel merchant) async {
    try {
      final merchantId = "MRCN_${merchant.uid}";
      final isCurrentlyFavorited = await isFavorited(merchantId);

      Logger.log("FAVORITE_SERVICE - 🔄 Toggling favorite for ${merchant.merchantName}, currently: $isCurrentlyFavorited");

      if (isCurrentlyFavorited) {
        await removeFromFavorites(merchantId);
        Logger.log("FAVORITE_SERVICE - ➖ Removed from favorites");
        return false;
      } else {
        await addToFavorites(merchant);
        Logger.log("FAVORITE_SERVICE - ➕ Added to favorites");
        return true;
      }
    } catch (e) {
      Logger.error("FAVORITE_SERVICE - Error toggling favorite", error: e);
      rethrow;
    }
  }

  Future<void> _reorderAfterRemoval(String uid, int removedOrder) async {
    try {
      final batch = _firestore.batch();
      
      final snapshot = await _favoritesCollection
          .doc(uid)
          .collection('merchants')
          .where('order', isGreaterThan: removedOrder)
          .get();

      for (final doc in snapshot.docs) {
        final currentOrder = (doc.data()['order'] as int);
        final newOrder = currentOrder - 1;
        batch.update(doc.reference, {'order': newOrder});
      }

      await batch.commit();
    } catch (e) {
      Logger.error("FAVORITE_SERVICE - Error reordering favorites", error: e);
    }
  }

  Future<int> getFavoritesCount() async {
    try {
      final uid = userService.getCurrentUID();
      if (uid == null) return 0;

      final doc = await _favoritesCollection.doc(uid).get();
      if (!doc.exists) return 0;

      final data = doc.data() as Map<String, dynamic>;
      return data['totalFavorites'] ?? 0;
    } catch (e) {
      Logger.error("FAVORITE_SERVICE - Error getting favorites count", error: e);
      return 0;
    }
  }

  Future<List<String>> getUserFavoriteMerchantIds() async {
    try {
      final uid = userService.getCurrentUID();
      if (uid == null) {
        return [];
      }

      final snapshot = await _favoritesCollection
          .doc(uid)
          .collection('merchants')
          .get();

      final merchantIds = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              return data['merchantId'] as String?;
            } catch (e) {
              Logger.error("FAVORITE_SERVICE - Error parsing merchant ID from ${doc.id}", error: e);
              return null;
            }
          })
          .where((id) => id != null)
          .cast<String>()
          .toList();

      return merchantIds;
    } catch (e) {
      Logger.error("FAVORITE_SERVICE - Error fetching favorite merchant IDs", error: e);
      return [];
    }
  }
}