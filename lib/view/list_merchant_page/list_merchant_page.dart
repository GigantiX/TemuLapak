// File: lib/view/list_merchant_page/list_merchant_page.dart
// VERIFIED: Fixed MerchantWidget constructor calls with proper parameters

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:temulapak_app/assets/mycolor.dart';
// import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/list_merchant_page/list_merchant_viewmodel.dart';
import 'package:temulapak_app/view/merchant_detail_page/merchant_detail_page.dart';
import 'package:temulapak_app/view/widget/merchant_widget.dart';

class ListMerchantPage extends ConsumerStatefulWidget {
  final MerchantCategory category;
  
  const ListMerchantPage({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<ListMerchantPage> createState() => _ListMerchantPageState();
}

class _ListMerchantPageState extends ConsumerState<ListMerchantPage> {
  
  @override
  void initState() {
    super.initState();
    
    // Auto-fetch merchants when page loads
    Future.microtask(() {
      ref.read(listMerchantViewModelProvider.notifier).fetchMerchants(widget.category);
    });
  }

  @override
  Widget build(BuildContext context) {
    final merchantState = ref.watch(listMerchantViewModelProvider);
    final currentFilter = ref.watch(merchantFilterStateProvider);

    return Scaffold(
      backgroundColor: MyColor.whitePlain,
      appBar: AppBar(
        title: Text(
          widget.category.displayName,
          style: TextStyle(
            color: MyColor.blackPlain,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: MyColor.blackPlain),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Filter Button
          PopupMenuButton<MerchantFilter>(
            icon: Icon(
              Icons.filter_list,
              color: MyColor.blackPlain,
            ),
            onSelected: (filter) {
              Logger.log("Filter selected: ${filter.displayName}");
              // Update filter state
              ref.read(merchantFilterStateProvider.notifier).setFilter(filter);
              // Apply filter in ViewModel
              ref.read(listMerchantViewModelProvider.notifier).applyFilter(filter);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: MerchantFilter.all,
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inbox,
                      color: currentFilter == MerchantFilter.all 
                          ? MyColor.orange 
                          : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      MerchantFilter.all.displayName,
                      style: TextStyle(
                        color: currentFilter == MerchantFilter.all 
                            ? MyColor.orange 
                            : MyColor.blackPlain,
                        fontWeight: currentFilter == MerchantFilter.all 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: MerchantFilter.open,
                child: Row(
                  children: [
                    Icon(
                      Icons.store,
                      color: currentFilter == MerchantFilter.open 
                          ? MyColor.orange 
                          : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      MerchantFilter.open.displayName,
                      style: TextStyle(
                        color: currentFilter == MerchantFilter.open 
                            ? MyColor.orange 
                            : MyColor.blackPlain,
                        fontWeight: currentFilter == MerchantFilter.open 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: MerchantFilter.closed,
                child: Row(
                  children: [
                    Icon(
                      Icons.store_mall_directory,
                      color: currentFilter == MerchantFilter.closed 
                          ? MyColor.orange 
                          : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      MerchantFilter.closed.displayName,
                      style: TextStyle(
                        color: currentFilter == MerchantFilter.closed 
                            ? MyColor.orange 
                            : MyColor.blackPlain,
                        fontWeight: currentFilter == MerchantFilter.closed 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          Logger.log("Pull to refresh triggered");
          await ref.read(listMerchantViewModelProvider.notifier)
              .refreshMerchants(widget.category);
        },
        color: MyColor.orange,
        child: merchantState.when(
          idle: () => _buildEmptyState(),
          loading: () => _buildLoadingState(),
          success: (merchants) {
            if (merchants.isEmpty) {
              return _buildEmptyState();
            }
            
            return _buildMerchantList(merchants);
          },
          error: (error, message) => _buildErrorState(message),
        ),
      ),
    );
  }

  Widget _buildMerchantList(List<MerchantWithDistance> merchantsWithDistance) {
    final currentFilter = ref.watch(merchantFilterStateProvider);
    
    return Column(
      children: [
        // Filter Info Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: MyColor.lightGrey,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${merchantsWithDistance.length} penjual ditemukan",
                style: TextStyle(
                  fontSize: 14,
                  color: MyColor.blackPlain,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MyColor.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MyColor.orange.withValues(alpha: 0.3)),
                ),
                child: Text(
                  "Filter: ${currentFilter.displayName}",
                  style: TextStyle(
                    fontSize: 12,
                    color: MyColor.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Merchant List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: merchantsWithDistance.length,
            itemBuilder: (context, index) {
              final merchantWithDistance = merchantsWithDistance[index];
              final merchant = merchantWithDistance.merchant;
              final distance = merchantWithDistance.distance;
              
              return MerchantWidget(
                merchant: merchant,
                onTap: () {
                  Logger.log("Clicked on merchant: ${merchant.merchantName}");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MerchantDetailPage(merchant: merchant),
                    ),
                  );
                },
                // ENHANCED: Now passing real calculated distance
                showFavoriteButton: true, // Show favorite button in list
                distance: distance, // Real calculated distance from ViewModel
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 100,
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
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: MyColor.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.category == MerchantCategory.nearest 
                    ? Icons.location_off 
                    : Icons.store_outlined,
                size: 64,
                color: MyColor.orange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getEmptyTitle(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: MyColor.blackPlain,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _getEmptySubtitle(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(listMerchantViewModelProvider.notifier)
                    .refreshMerchants(widget.category);
              },
              icon: Icon(Icons.refresh),
              label: Text("Coba Lagi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColor.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String? message) {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: MyColor.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: MyColor.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Gagal Memuat Data",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: MyColor.blackPlain,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message ?? "Terjadi kesalahan saat memuat data merchant",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(listMerchantViewModelProvider.notifier)
                    .fetchMerchants(widget.category);
              },
              icon: Icon(Icons.refresh),
              label: Text("Coba Lagi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColor.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmptyTitle() {
    switch (widget.category) {
      case MerchantCategory.nearest:
        return "Tidak Ada Merchant Terdekat";
      case MerchantCategory.drinks:
        return "Tidak Ada Penjual Minuman";
      case MerchantCategory.food:
        return "Tidak Ada Penjual Makanan";
      case MerchantCategory.snacks:
        return "Tidak Ada Penjual Cemilan";
    }
  }

  String _getEmptySubtitle() {
    switch (widget.category) {
      case MerchantCategory.nearest:
        return "Belum ada merchant yang berjualan di sekitar lokasi Anda saat ini";
      case MerchantCategory.drinks:
        return "Belum ada penjual minuman yang tersedia di area Anda";
      case MerchantCategory.food:
        return "Belum ada penjual makanan yang tersedia di area Anda";
      case MerchantCategory.snacks:
        return "Belum ada penjual cemilan yang tersedia di area Anda";
    }
  }
}