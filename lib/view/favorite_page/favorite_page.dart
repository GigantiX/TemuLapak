import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/model/favorite/favorite_model.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/favorite_page/favorite_viewmodel.dart';
import 'package:temulapak_app/view/widget/merchant_widget.dart';

class FavoritePage extends ConsumerStatefulWidget {
  const FavoritePage({super.key});

  @override
  ConsumerState<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends ConsumerState<FavoritePage> {
  @override
  void initState() {
    super.initState();
    
    Future.microtask(() async {
      await ref.read(favoriteViewModelProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: MyColor.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
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
        _buildInfoBar(favorites.length),
        Expanded(
          child: FutureBuilder<List<MerchantModel>>(
            future: ref.read(favoriteViewModelProvider.notifier).loadMerchantDetails(favorites),
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

  Widget _buildInfoBar(int favoritesCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: MyColor.lightGrey,
      child: Row(
        children: [
          Icon(Icons.favorite, color: MyColor.orange, size: 20),
          const SizedBox(width: 8),
          Text(
            "$favoritesCount pedagang favorit",
            style: TextStyle(
              fontSize: 14,
              color: MyColor.blackPlain,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Consumer(
            builder: (context, ref, child) {
              final locationState = ref.watch(locationStateProvider);
              final hasLocation = locationState != null;
              
              if (!hasLocation) {
                return Row(
                  children: [
                    Icon(Icons.location_off, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      "Lokasi tidak tersedia",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                );
              } else {
                return Text(
                  "Geser kiri untuk hapus",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantsList(List<MerchantModel> merchants, List<FavoriteModel> favorites) {
    return Consumer(
      builder: (context, ref, child) {
        ref.watch(locationStateProvider);
        final viewModel = ref.read(favoriteViewModelProvider.notifier);
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: merchants.length,
          itemBuilder: (context, index) {
            final merchant = merchants[index];
            final favorite = favorites.firstWhere(
              (fav) => fav.merchantId == "MRCN_${merchant.uid}",
              orElse: () => favorites[index],
            );
            final distance = viewModel.calculateDistance(merchant);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FavoriteMerchantWidget(
                merchant: merchant,
                onTap: () {
                  Logger.log("FAVORITE_PAGE - Clicked on merchant: ${merchant.merchantName}");
                  viewModel.navigateToMerchantDetail(context, merchant);
                },
                onRemoveFavorite: () {
                  Logger.log("FAVORITE_PAGE - Swipe to remove favorite: ${merchant.merchantName}");
                  viewModel.removeFavoriteComplete(context, favorite.merchantId, merchant.merchantName ?? 'Merchant');
                },
                distance: distance,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
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
                    "Tambahkan merchant favorit dengan\nmenekan ikon ❤️ di halaman detail merchant",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
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
                Logger.log("FAVORITE_PAGE - Retry button clicked");
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
                Logger.log("FAVORITE_PAGE - Merchant error retry button clicked");
                setState(() {});
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