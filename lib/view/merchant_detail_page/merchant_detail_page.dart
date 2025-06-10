import 'dart:async';
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
import 'package:temulapak_app/view/widget/favorite_button.dart';
import 'package:flutter_svg/svg.dart';

class MerchantDetailPage extends ConsumerStatefulWidget {
  final MerchantModel merchant;

  const MerchantDetailPage({
    super.key,
    required this.merchant,
  });

  @override
  ConsumerState<MerchantDetailPage> createState() => _MerchantDetailPageState();
}

class _MerchantDetailPageState extends ConsumerState<MerchantDetailPage>
    with WidgetsBindingObserver {
  
  final ScrollController _scrollController = ScrollController();
  bool _isMapInteracting = false;

  @override
  void initState() {
    super.initState();

    Logger.log("DETAIL_PAGE - Initializing with enhanced ViewModel");

    WidgetsBinding.instance.addObserver(this);

    Future.microtask(() {
      final originalNotifier = ref.read(merchantDetailViewModelProvider.notifier);
      final enhancedNotifier = ref.read(enhancedMerchantDetailStateNotifierProvider.notifier);
      
      originalNotifier.initializeMerchantDetail(widget.merchant);
      
      enhancedNotifier.initializeUserLocationTracking();
      enhancedNotifier.initializePerformanceOptimizations();
    });
  }

  @override
  void dispose() {
    Logger.log("DETAIL_PAGE - Disposing UI resources");
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    ref.read(enhancedMerchantDetailStateNotifierProvider.notifier)
        .handleAppLifecycleChange(state);
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(merchantDetailViewModelProvider);
    final enhancedState = ref.watch(enhancedMerchantDetailStateNotifierProvider);
    final enhancedNotifier = ref.read(enhancedMerchantDetailStateNotifierProvider.notifier);

     ref.listen(
      enhancedMerchantDetailStateNotifierProvider.select((s) => s.command),
      (_, command) => _executeCommand(context, command),
    );

    return Scaffold(
      backgroundColor: MyColor.whitePlain,
      body: Stack(
        children: [
          detailState.when(
            idle: () => _buildLoadingState(),
            loading: () => _buildLoadingState(),
            success: (detailData) => _buildDetailContent(detailData, enhancedState, enhancedNotifier),
            error: (error, message) => _buildErrorState(message),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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

                FavoriteButton.floating(
                  merchant: widget.merchant,
                  showFeedback: true,
                  onToggle: () {
                    Logger.log("Favorite toggled for ${widget.merchant.merchantName}");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
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
            ref.read(enhancedMerchantDetailStateNotifierProvider.notifier)
                .navigateToChatDetail();
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

  void _executeCommand(BuildContext context, ViewModelCommand? command) {
    if (command == null) return;
    
    if (command is NavigateCommand) {
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => command.page)
      );
    } else if (command is ShowSnackbarCommand) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(command.message),
          backgroundColor: command.backgroundColor,
          duration: Duration(seconds: command.durationSeconds),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (command is OpenUrlCommand) {
      launchUrl(Uri.parse(command.url));
    }
  }

  Widget _buildDetailContent(
    Map<String, dynamic> detailData, 
    EnhancedMerchantDetailState enhancedState, 
    EnhancedMerchantDetailStateNotifier enhancedNotifier, 
  ) {
    final merchant = detailData['merchant'] as MerchantModel;
    final distance = enhancedNotifier.getDisplayDistance(); 
    final totalProducts = detailData['totalProducts'] as int;
    final hasLocation = detailData['hasLocation'] as bool;
    final priceRangeText = detailData['priceRangeText'] as String;

    return SingleChildScrollView(
      controller: _scrollController,
      physics: _isMapInteracting
          ? NeverScrollableScrollPhysics()
          : AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 300,
            width: double.infinity,
            child: merchant.merchantImgUrl != null &&
                    merchant.merchantImgUrl!.isNotEmpty
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

          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMerchantInfo(merchant, enhancedNotifier),

                if (hasLocation) ...[
                  _buildMapSection(merchant, enhancedNotifier),
                  const SizedBox(height: 16),
                ],

                _buildInfoCards(merchant, priceRangeText, distance, enhancedState, hasLocation, enhancedNotifier),

                const SizedBox(height: 20),

                if (merchant.merchantDesc != null && merchant.merchantDesc!.isNotEmpty) ...[
                  _buildDescription(merchant),
                  const SizedBox(height: 20),
                ],

                _buildProductsSection(merchant, totalProducts),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantInfo(MerchantModel merchant, EnhancedMerchantDetailStateNotifier enhancedNotifier) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            merchant.merchantName ?? 'Merchant',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: MyColor.blackPlain,
            ),
          ),
          const SizedBox(height: 8),

          if (merchant.merchantCategory != null &&
              merchant.merchantCategory!.isNotEmpty) ...[
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

          Row(
            children: [
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

              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('merchant')
                    .doc(enhancedNotifier.getMerchantId(merchant))
                    .snapshots(),
                builder: (context, snapshot) {
                  DateTime lastUpdate = DateTime.now();
                  ConnectionStatus status = ConnectionStatus.live;

                  if (snapshot.hasError) {
                    status = ConnectionStatus.offline;
                    lastUpdate = DateTime.now()
                        .subtract(Duration(minutes: 10));
                  } else if (!snapshot.hasData ||
                      !snapshot.data!.exists) {
                    status = ConnectionStatus.offline;
                    lastUpdate = DateTime.now()
                        .subtract(Duration(minutes: 5));
                  } else if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    status = ConnectionStatus.recent;
                    lastUpdate = DateTime.now()
                        .subtract(Duration(seconds: 30));
                  } else {
                    final data = snapshot.data!.data()
                        as Map<String, dynamic>?;
                    if (data != null) {
                      final lat = data['merchantLocLat'];
                      final lng = data['merchantLocLong'];

                      if (lat != null && lng != null) {
                        status = ConnectionStatus.live;
                        lastUpdate = DateTime.now();
                      } else {
                        status = ConnectionStatus.recent;
                        lastUpdate = DateTime.now()
                            .subtract(Duration(minutes: 1));
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
    );
  }

  Widget _buildMapSection(MerchantModel merchant, EnhancedMerchantDetailStateNotifier enhancedNotifier) {
    return GestureDetector(
      onPanDown: (_) {
        _disableParentScroll();
        enhancedNotifier.handleDistanceUpdate(null);
      },
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
            merchantId: enhancedNotifier.getMerchantId(merchant),
            initialMerchant: merchant,
            onDistanceUpdate: enhancedNotifier.handleDistanceUpdate,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCards(
    MerchantModel merchant, 
    String priceRangeText, 
    double? distance, 
    EnhancedMerchantDetailState enhancedState, 
    bool hasLocation, 
    EnhancedMerchantDetailStateNotifier enhancedNotifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          enhancedNotifier.formatPriceRange(priceRangeText),
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

                  Container(
                    height: 40,
                    width: 1,
                    color: MyColor.orange,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (enhancedState.isDistanceCalculating) ...[
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      MyColor.orange),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              distance != null
                                  ? "${distance.toStringAsFixed(2)} km"
                                  : "- km",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: distance != null
                                    ? MyColor.blackPlain
                                    : Colors.grey[400],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Jarak",
                              style: TextStyle(
                                fontSize: 12,
                                color: distance != null
                                    ? MyColor.orange
                                    : Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (distance != null && !enhancedState.isDistanceCalculating) ...[
                              const SizedBox(width: 4),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: enhancedState.isUsingFallbackDistance
                                      ? Colors.orange 
                                      : Colors.green, 
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                            if (!enhancedState.hasLocationPermission ||
                                !enhancedState.isLocationServiceEnabled) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.location_off,
                                size: 10,
                                color: Colors.red,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 5),

          if (hasLocation)
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () {
                  ref.read(enhancedMerchantDetailStateNotifierProvider.notifier)
                      .openInGoogleMaps(
                    merchant.merchantLocLat!,
                    merchant.merchantLocLong!,
                    merchant.merchantName,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MyColor.orange),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Buka di",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: MyColor.blackPlain,
                              ),
                            ),
                            Text(
                              "Google Maps",
                              style: TextStyle(
                                fontSize: 10,
                                color: MyColor.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: SvgPicture.asset(
                            "lib/assets/icons/pin_icon.svg",
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDescription(MerchantModel merchant) {
    return Padding(
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
    );
  }

  Widget _buildProductsSection(MerchantModel merchant, int totalProducts) {
    return Padding(
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
    );
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
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 300,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
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

  void _disableParentScroll() {
    if (!_isMapInteracting) {
      setState(() {
        _isMapInteracting = true;
      });
      
      ref.read(enhancedMerchantDetailStateNotifierProvider.notifier)
          .pauseLocationUpdates();
    }
  }

  void _enableParentScroll() {
    if (_isMapInteracting) {
      setState(() {
        _isMapInteracting = false;
      });
      
      ref.read(enhancedMerchantDetailStateNotifierProvider.notifier)
          .resumeLocationUpdates();
    }
  }
}