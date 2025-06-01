// File: lib/view/favorite_page/favorite_page.dart
// PROPER IMPLEMENTATION: Using ViewModel and real-time stream

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/data/network/merchant_service.dart';
import 'package:temulapak_app/model/favorite/favorite_model.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/favorite_page/favorite_viewmodel.dart';
import 'package:temulapak_app/view/favorite_page/favorite_status_viewmodel.dart';
import 'package:temulapak_app/view/merchant_detail_page/merchant_detail_page.dart';
import 'package:temulapak_app/view/widget/merchant_widget.dart';

class FavoritePage extends ConsumerStatefulWidget {
  const FavoritePage({super.key});

  @override
  ConsumerState<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends ConsumerState<FavoritePage> {
  final MerchantService _merchantService = MerchantService();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize favorites loading
    Future.microtask(() {
      ref.read(favoriteViewModelProvider.notifier).loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the real-time favorites stream
    final favoritesStream = ref.watch(favoritesStreamProvider);

    return Scaffold(
      backgroundColor: MyColor.whitePlain,
      appBar: AppBar(
        title: Text(
          'Favorit',
          style: TextStyle(
            color: MyColor.blackPlain,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        actions: [
          // Refresh button only
          IconButton(
            icon: Icon(Icons.refresh, color: MyColor.blackPlain),
            onPressed: () {
              Logger.log("FAVORITE_PAGE - Manual refresh triggered");
              ref.read(favoriteViewModelProvider.notifier).refreshFavorites();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          Logger.log("FAVORITE_PAGE - Pull to refresh triggered");
          await ref.read(favoriteViewModelProvider.notifier).refreshFavorites();
        },
        color: MyColor.orange,
        child: favoritesStream.when(
          data: (favorites) => _buildFavoritesContent(favorites),
          loading: () => _buildLoadingState(),
          error: (error, stack) {
            Logger.error("FAVORITE_PAGE - Stream error", error: error);
            return _buildErrorState(error.toString());
          },
        ),
      ),
    );
  }

  Widget _buildFavoritesContent(List<FavoriteModel> favorites) {
    if (favorites.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Info Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: MyColor.lightGrey,
          child: Row(
            children: [
              Icon(Icons.favorite, color: MyColor.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                "${favorites.length} merchant favorit",
                style: TextStyle(
                  fontSize: 14,
                  color: MyColor.blackPlain,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                "Geser kiri untuk hapus",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        
        // Favorites List
        Expanded(
          child: FutureBuilder<List<MerchantModel>>(
            future: _loadMerchantDetails(favorites),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildMerchantLoadingState();
              }
              
              if (snapshot.hasError) {
                Logger.error("FAVORITE_PAGE - Error loading merchant details", error: snapshot.error);
                return _buildMerchantErrorState(snapshot.error.toString());
              }
              
              final merchants = snapshot.data ?? [];
              return _buildMerchantsList(merchants, favorites);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMerchantsList(List<MerchantModel> merchants, List<FavoriteModel> favorites) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: merchants.length,
      itemBuilder: (context, index) {
        final merchant = merchants[index];
        final favorite = favorites.firstWhere(
          (fav) => fav.merchantId == "MRCN_${merchant.uid}",
          orElse: () => favorites[index], // Fallback
        );
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FavoriteMerchantWidget(
            merchant: merchant,
            onTap: () {
              Logger.log("FAVORITE_PAGE - Opening merchant detail: ${merchant.merchantName}");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MerchantDetailPage(merchant: merchant),
                ),
              );
            },
            onRemoveFavorite: () => _removeFavorite(favorite.merchantId, merchant.merchantName ?? 'Merchant'),
            distance: null, // Could be calculated if needed
          ),
        );
      },
    );
  }

  Future<List<MerchantModel>> _loadMerchantDetails(List<FavoriteModel> favorites) async {
    try {
      Logger.log("FAVORITE_PAGE - Loading merchant details for ${favorites.length} favorites");
      
      if (favorites.isEmpty) return [];
      
      // Get all merchants
      final allMerchants = await _merchantService.getAllMerchants();
      
      // Filter merchants that match favorites
      final List<MerchantModel> favoriteMerchants = [];
      
      for (final favorite in favorites) {
        final merchant = allMerchants.firstWhere(
          (m) => "MRCN_${m.uid}" == favorite.merchantId,
          orElse: () => _createPlaceholderMerchant(favorite),
        );
        favoriteMerchants.add(merchant);
      }
      
      Logger.log("FAVORITE_PAGE - Successfully loaded ${favoriteMerchants.length} merchant details");
      return favoriteMerchants;
      
    } catch (e) {
      Logger.error("FAVORITE_PAGE - Error loading merchant details", error: e);
      rethrow;
    }
  }

  MerchantModel _createPlaceholderMerchant(FavoriteModel favorite) {
    // Create placeholder merchant for favorites that might not exist anymore
    return MerchantModel(
      uid: favorite.merchantId.replaceFirst("MRCN_", ""),
      merchantName: favorite.merchantName ?? "Merchant Tidak Ditemukan",
      merchantStatus: false,
      merchantImgUrl: favorite.merchantImgUrl,
      merchantCategory: favorite.merchantCategory,
    );
  }

  Future<void> _removeFavorite(String merchantId, String merchantName) async {
    try {
      Logger.log("FAVORITE_PAGE - Removing favorite: $merchantId");
      
      // Show loading feedback
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
      
      // Remove from favorites
      await ref.read(favoriteHelperProvider.notifier)
          .quickRemoveFromFavorites(merchantId, merchantName);
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ $merchantName dihapus dari favorit"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
    } catch (e) {
      Logger.error("FAVORITE_PAGE - Error removing favorite", error: e);
      
      if (mounted) {
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

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Info Bar Shimmer
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: MyColor.lightGrey,
          child: Row(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // List Shimmer
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMerchantLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 3,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Empty Info Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: MyColor.lightGrey,
            child: Row(
              children: [
                Icon(Icons.favorite_border, color: Colors.grey[400], size: 20),
                const SizedBox(width: 8),
                Text(
                  "0 merchant favorit",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Empty Content
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: MyColor.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_outline,
                    size: 80,
                    color: MyColor.orange,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Belum Ada Favorit",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: MyColor.blackPlain,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    "Tambahkan merchant favorit dengan\nmenekan tombol ❤️ di halaman detail merchant",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate back to home to find merchants
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: Icon(Icons.explore),
                  label: Text("Jelajahi Merchant"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColor.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: MyColor.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 80,
                color: MyColor.red,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Gagal Memuat Favorit",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: MyColor.blackPlain,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                "Terjadi kesalahan saat memuat daftar favorit Anda",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(favoriteViewModelProvider.notifier).refreshFavorites();
              },
              icon: Icon(Icons.refresh),
              label: Text("Coba Lagi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColor.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              size: 64,
              color: MyColor.orange,
            ),
            const SizedBox(height: 16),
            Text(
              "Gagal Memuat Detail Merchant",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: MyColor.blackPlain,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Beberapa merchant mungkin sudah tidak tersedia",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {}); // Trigger rebuild to retry loading
              },
              icon: Icon(Icons.refresh),
              label: Text("Coba Lagi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColor.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}