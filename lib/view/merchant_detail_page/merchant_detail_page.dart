// File: lib/view/merchant_detail_page/merchant_detail_page.dart
// UPDATE: Add ScrollController and map interaction management

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/product/product_model.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/merchant_detail_page/merchant_detail_viewmodel.dart';
import 'package:temulapak_app/view/widget/live_tracking_map.dart';
import 'package:temulapak_app/view/widget/location_update_indicator.dart';

class MerchantDetailPage extends ConsumerStatefulWidget {
  final MerchantModel merchant;

  const MerchantDetailPage({
    super.key,
    required this.merchant,
  });

  @override
  ConsumerState<MerchantDetailPage> createState() => _MerchantDetailPageState();
}

class _MerchantDetailPageState extends ConsumerState<MerchantDetailPage> {
  
  // NEW: ScrollController and map interaction state
  final ScrollController _scrollController = ScrollController();
  bool _isMapInteracting = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize merchant detail
    Future.microtask(() {
      final notifier = ref.read(merchantDetailViewModelProvider.notifier);
      notifier.initializeMerchantDetail(widget.merchant);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getMerchantId(MerchantModel merchant) {
    return "MRCN_${merchant.uid}";
  }

  // NEW: Map interaction handlers
  void _disableParentScroll() {
    if (!_isMapInteracting) {
      setState(() {
        _isMapInteracting = true;
      });
      Logger.log("MAP_INTERACTION - Parent scroll disabled");
    }
  }
  
  void _enableParentScroll() {
    if (_isMapInteracting) {
      setState(() {
        _isMapInteracting = false;
      });
      Logger.log("MAP_INTERACTION - Parent scroll enabled");
    }
  }

  Future<void> _openInGoogleMaps(double latitude, double longitude, String? merchantName) async {
    try {
      Logger.log("Opening location in Google Maps: $latitude, $longitude");
      
      String url;
      if (Platform.isIOS) {
        // iOS: Try Google Maps first, fallback to Apple Maps
        url = "comgooglemaps://?center=$latitude,$longitude&zoom=16";
        
        if (!await canLaunchUrl(Uri.parse(url))) {
          // Fallback to Apple Maps
          url = "http://maps.apple.com/?q=$latitude,$longitude";
        }
      } else {
        // Android: Use geo intent for Google Maps
        url = "geo:$latitude,$longitude?q=$latitude,$longitude(${merchantName ?? 'Merchant'})";
      }

      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Logger.log("Successfully opened Google Maps");
      } else {
        // Fallback to web Google Maps
        final webUrl = "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";
        await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
        Logger.log("Opened web Google Maps as fallback");
      }
      
    } catch (e) {
      Logger.error("Error opening Google Maps", error: e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Tidak dapat membuka Google Maps"),
            backgroundColor: MyColor.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(merchantDetailViewModelProvider);

    return Scaffold(
      backgroundColor: MyColor.whitePlain,
      body: Stack(
        children: [
          // Main scrollable content - WITH SMART SCROLL PHYSICS
          detailState.when(
            idle: () => _buildLoadingState(),
            loading: () => _buildLoadingState(),
            success: (detailData) => _buildDetailContent(detailData),
            error: (error, message) => _buildErrorState(message),
          ),
          
          // Floating controls - Always on top
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // Favorite button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.favorite_border, color: Colors.white),
                    onPressed: () {
                      Logger.log("Favorite button clicked");
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Floating Chat Button
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: MyColor.orange,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: MyColor.orange.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () {
            Logger.log("Chat button clicked for ${widget.merchant.merchantName}");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Fitur chat akan segera hadir!"),
                backgroundColor: MyColor.orange,
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: Icon(
            Icons.chat,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildDetailContent(Map<String, dynamic> detailData) {
    final merchant = detailData['merchant'] as MerchantModel;
    final distance = detailData['distance'] as double?;
    final totalProducts = detailData['totalProducts'] as int;
    final hasLocation = detailData['hasLocation'] as bool;
    final priceRangeText = detailData['priceRangeText'] as String;

    return SingleChildScrollView(
      controller: _scrollController,
      // NEW: Smart scroll physics based on map interaction
      physics: _isMapInteracting 
          ? NeverScrollableScrollPhysics() 
          : AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Image - Scrollable
          SizedBox(
            height: 300,
            width: double.infinity,
            child: merchant.merchantImgUrl != null && merchant.merchantImgUrl!.isNotEmpty
                ? Image.network(
                    merchant.merchantImgUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderImage();
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildLoadingImage();
                    },
                  )
                : _buildPlaceholderImage(),
          ),

          // Content Container
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Merchant Name & Categories
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Merchant Name
                      Text(
                        merchant.merchantName ?? 'Merchant',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: MyColor.blackPlain,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Categories
                      if (merchant.merchantCategory != null && merchant.merchantCategory!.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: merchant.merchantCategory!.map((category) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: MyColor.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: MyColor.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: MyColor.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Status Badge with Location Update Indicator
                      Row(
                        children: [
                          // Merchant Status Badge (existing)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: merchant.merchantStatus
                                  ? Colors.green
                                  : Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              merchant.merchantStatus ? 'BUKA' : 'TUTUP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          
                          // Location Update Indicator
                           StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('merchant')
                                .doc(_getMerchantId(merchant))
                                .snapshots(),
                            builder: (context, snapshot) {
                              DateTime lastUpdate = DateTime.now();
                              ConnectionStatus status = ConnectionStatus.live;
                              
                              if (snapshot.hasError) {
                                status = ConnectionStatus.offline;
                                lastUpdate = DateTime.now().subtract(Duration(minutes: 10));
                              } else if (!snapshot.hasData || !snapshot.data!.exists) {
                                status = ConnectionStatus.offline;
                                lastUpdate = DateTime.now().subtract(Duration(minutes: 5));
                              } else if (snapshot.connectionState == ConnectionState.waiting) {
                                status = ConnectionStatus.recent;
                                lastUpdate = DateTime.now().subtract(Duration(seconds: 30));
                              } else {
                                // Data received successfully
                                final data = snapshot.data!.data() as Map<String, dynamic>?;
                                if (data != null) {
                                  // Check if location data exists and is valid
                                  final lat = data['merchantLocLat'];
                                  final lng = data['merchantLocLong'];
                                  
                                  if (lat != null && lng != null) {
                                    status = ConnectionStatus.live;
                                    lastUpdate = DateTime.now(); // Fresh data
                                  } else {
                                    status = ConnectionStatus.recent;
                                    lastUpdate = DateTime.now().subtract(Duration(minutes: 1));
                                  }
                                }
                              }
                              
                              return LocationUpdateIndicator(
                                lastUpdate: lastUpdate,
                                status: status,
                                compact: true,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // NEW: Enhanced Map Section with gesture handling
                if (hasLocation) ...[
                  GestureDetector(
                    onPanDown: (_) => _disableParentScroll(),
                    onPanEnd: (_) => _enableParentScroll(),
                    onPanCancel: () => _enableParentScroll(),
                    onTapDown: (_) => _disableParentScroll(),
                    onTapUp: (_) => _enableParentScroll(),
                    onTapCancel: () => _enableParentScroll(),
                    child: SizedBox(
                      height: 250,                       
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LiveTrackingMap(
                          merchantId: _getMerchantId(merchant),
                          initialMerchant: merchant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Info Cards Row - Combined Price/Distance + Google Maps Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Combined Price Range & Distance Card
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: MyColor.orange),
                          ),
                          child: Row(
                            children: [
                              // Price Range
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      _formatPriceRange(priceRangeText),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: MyColor.blackPlain,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Kisaran harga",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: MyColor.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Divider
                              Container(
                                height: 40,
                                width: 1,
                                color: MyColor.orange,
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                              ),

                              // Distance
                              if (distance != null)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "${distance.toStringAsFixed(2)} km",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: MyColor.blackPlain,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Jarak",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: MyColor.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "- km",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[400],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Jarak",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),

                      // Google Maps Button - Sejajar dengan info card
                      if (hasLocation)
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () => _openInGoogleMaps(
                              merchant.merchantLocLat!,
                              merchant.merchantLocLong!,
                              merchant.merchantName,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: MyColor.orange),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Buka di",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: MyColor.blackPlain,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.map,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Google Maps",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: MyColor.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Description
                if (merchant.merchantDesc != null && merchant.merchantDesc!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Deskripsi",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: MyColor.blackPlain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          merchant.merchantDesc!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Products Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Produk ($totalProducts)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: MyColor.blackPlain,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Products List
                      if (merchant.products != null && merchant.products!.isNotEmpty)
                        ...merchant.products!.map((product) => _buildProductItem(product))
                      else
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: MyColor.lightGrey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Belum ada produk tersedia",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Space for floating action button
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Format price range to use "k" for thousands
  String _formatPriceRange(String priceRangeText) {
    // Convert "Rp 5.000 - 25.000" to "Rp 5k - 25k"
    return priceRangeText
        .replaceAllMapped(RegExp(r'(\d+)\.000'), (match) {
          return '${match.group(1)}k';
        })
        .replaceAllMapped(RegExp(r'(\d+)\.(\d+)00'), (match) {
          // Handle cases like 12.500 -> 12.5k
          String beforeDot = match.group(1)!;
          String afterDot = match.group(2)!;
          if (afterDot == '0') {
            return '${beforeDot}k';
          } else {
            return '$beforeDot.${afterDot}k';
          }
        });
  }

  Widget _buildProductItem(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: MyColor.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.fastfood,
              color: MyColor.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName ?? 'Produk',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MyColor.blackPlain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Rp ${product.productPrice ?? '0'}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: MyColor.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: _isMapInteracting 
          ? NeverScrollableScrollPhysics() 
          : AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Loading image
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 300,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
          
          // Loading content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 32,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 20,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? message) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detail Merchant"),
        backgroundColor: MyColor.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: MyColor.red,
              ),
              const SizedBox(height: 24),
              Text(
                "Gagal Memuat Detail",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: MyColor.blackPlain,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message ?? "Terjadi kesalahan saat memuat detail merchant",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  final notifier = ref.read(merchantDetailViewModelProvider.notifier);
                  notifier.refreshMerchantDetail(widget.merchant);
                },
                icon: Icon(Icons.refresh),
                label: Text("Coba Lagi"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColor.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[200],
      child: Icon(
        Icons.store,
        color: Colors.grey[400],
        size: 64,
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
      ),
    );
  }
}