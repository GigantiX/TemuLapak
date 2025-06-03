import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/home_page/home_viewmodel.dart';
import 'package:temulapak_app/view/list_merchant_page/list_merchant_page.dart';
import 'package:temulapak_app/view/list_merchant_page/list_merchant_viewmodel.dart';
import 'package:temulapak_app/view/merchant_detail_page/merchant_detail_page.dart';
import 'package:temulapak_app/view/widget/merchant_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // ADDED: ScrollController for better scroll behavior
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ADDED: Method to load all initial data
  void _loadInitialData() {
    ref.read(homeViewmodelProvider.notifier).getUser();
    ref.read(addressViewModelProvider.notifier).getAddress();
    ref.read(recommendedMerchantsProvider.notifier).getRecommendedMerchants();
  }

  // ADDED: Pull-to-refresh method
  Future<void> _onRefresh() async {
    try {
      Logger.log("HOME_PAGE - Pull to refresh triggered");
      
      // Refresh all data sources
      await Future.wait([
        ref.read(homeViewmodelProvider.notifier).getUser(),
        ref.read(addressViewModelProvider.notifier).getAddress(),
        ref.read(recommendedMerchantsProvider.notifier).getRecommendedMerchants(),
      ]);
      
      Logger.log("HOME_PAGE - Pull to refresh completed");
    } catch (e) {
      Logger.error("HOME_PAGE - Error during refresh", error: e);
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui data. Silakan coba lagi.'),
            backgroundColor: MyColor.red,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: _onRefresh,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(homeViewmodelProvider);
    final addressState = ref.watch(addressViewModelProvider);
    final recommendedState = ref.watch(recommendedMerchantsProvider);

    return Scaffold(
      backgroundColor: MyColor.whitePlain,
      body: SafeArea(
        child: RefreshIndicator(
          // ADDED: Pull-to-refresh functionality
          onRefresh: _onRefresh,
          color: MyColor.orange,
          backgroundColor: Colors.white,
          displacement: 40,
          child: SingleChildScrollView(
            controller: _scrollController,
            // IMPORTANT: Always scrollable for pull-to-refresh to work
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                homepageAppBar(userState, addressState),
                homepageCarousel(ref),
                // UPDATED: Responsive category section
                _buildResponsiveCategory(context),
                _buildRecommendedSection(recommendedState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // UPDATED: Responsive category section that adapts to screen size
  Widget _buildResponsiveCategory(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate responsive values based on screen size
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 400;
    
    // Responsive padding
    final horizontalPadding = isSmallScreen ? 16.0 : (isMediumScreen ? 20.0 : 25.0);
    final verticalPadding = isSmallScreen ? 8.0 : 10.0;
    
    // Responsive category item size
    final categoryHeight = isSmallScreen ? 65.0 : (isMediumScreen ? 68.0 : 72.0);
    final iconSize = isSmallScreen ? 22.0 : (isMediumScreen ? 24.0 : 25.0);
    final fontSize = isSmallScreen ? 10.0 : (isMediumScreen ? 11.0 : 12.0);
    final spacing = isSmallScreen ? 6.0 : 8.0;
    final textSpacing = isSmallScreen ? 5.0 : 7.0;
    
    Logger.log("HOME_PAGE - Screen dimensions: ${screenWidth}x$screenHeight, isSmall: $isSmallScreen");

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildResponsiveCategoryItem(
              context: context,
              icon: Icon(Icons.share_location, color: MyColor.orange, size: iconSize),
              label: "Terdekat",
              height: categoryHeight,
              fontSize: fontSize,
              spacing: textSpacing,
              onTap: () {
                Logger.log("Clicked on Terdekat");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListMerchantPage(
                      category: MerchantCategory.nearest,
                    ),
                  ),
                );
              }
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _buildResponsiveCategoryItem(
              context: context,
              icon: FaIcon(FontAwesomeIcons.whiskeyGlass, color: MyColor.orange, size: iconSize),
              label: "Minuman",
              height: categoryHeight,
              fontSize: fontSize,
              spacing: textSpacing,
              onTap: () {
                Logger.log("Clicked on Minuman");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListMerchantPage(
                      category: MerchantCategory.drinks,
                    ),
                  ),
                );
              }
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _buildResponsiveCategoryItem(
              context: context,
              icon: FaIcon(FontAwesomeIcons.bowlFood, color: MyColor.orange, size: iconSize),
              label: "Makanan",
              height: categoryHeight,
              fontSize: fontSize,
              spacing: textSpacing,
              onTap: () {
                Logger.log("Clicked on Makanan");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListMerchantPage(
                      category: MerchantCategory.food,
                    ),
                  ),
                );
              }
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _buildResponsiveCategoryItem(
              context: context,
              icon: FaIcon(FontAwesomeIcons.cookieBite, color: MyColor.orange, size: iconSize),
              label: "Cemilan",
              height: categoryHeight,
              fontSize: fontSize,
              spacing: textSpacing,
              onTap: () {
                Logger.log("Clicked on Cemilan");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListMerchantPage(
                      category: MerchantCategory.snacks,
                    ),
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  // ADDED: Responsive category item widget with adaptive sizing
  Widget _buildResponsiveCategoryItem({
    required BuildContext context,
    required Widget icon,
    required String label,
    required VoidCallback onTap,
    required double height,
    required double fontSize,
    required double spacing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: MyColor.white,
          borderRadius: BorderRadius.circular(7),
          // ADDED: Subtle shadow for better visual appeal
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: spacing,
            horizontal: 4, // Minimal horizontal padding to prevent overflow
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              SizedBox(height: spacing),
              // UPDATED: Responsive text with overflow protection
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // ADDED: Scale text down if needed to fit
                  textScaleFactor: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // EXISTING: Build Recommended Section with MerchantWithDistance support
  Widget _buildRecommendedSection(AppState recommendedState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Rekomendasi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          recommendedState.when(
            idle: () => _buildEmptyRecommended(),
            loading: () => _buildRecommendedShimmer(),
            success: (merchantsWithDistance) {
              if (merchantsWithDistance.isEmpty) {
                return _buildEmptyRecommended();
              }
              return _buildRecommendedList(merchantsWithDistance);
            },
            error: (error, message) => _buildRecommendedError(message),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedList(List<MerchantWithDistanceHome> merchantsWithDistance) {
    Logger.log("🏠 HOME_PAGE - Building recommended list with ${merchantsWithDistance.length} merchants");
    
    return Column(
      children: merchantsWithDistance.map<Widget>((merchantWithDistance) {
        final merchant = merchantWithDistance.merchant;
        final distance = merchantWithDistance.distance;
        
        Logger.log("🏪 HOME_PAGE - Displaying: ${merchant.merchantName} (${distance?.toStringAsFixed(2)}km, pop: ${merchant.merchantPopularity ?? 0})");
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MerchantWidget(
            merchant: merchant,
            onTap: () {
              Logger.log("Clicked on recommended merchant: ${merchant.merchantName}");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MerchantDetailPage(merchant: merchant),
                ),
              );
            },
            showFavoriteButton: true, 
            distance: distance,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecommendedShimmer() {
    return Column(
      children: List.generate(3, (index) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
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
      ),
    );
  }

  Widget _buildEmptyRecommended() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: MyColor.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_outlined,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            "Belum ada merchant terdekat",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedError(String? message) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: MyColor.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyColor.red.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: MyColor.red,
          ),
          const SizedBox(height: 8),
          Text(
            message ?? "Gagal memuat rekomendasi",
            style: TextStyle(
              color: MyColor.red,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ref.read(recommendedMerchantsProvider.notifier)
                  .getRecommendedMerchants();
            },
            child: Text(
              "Coba Lagi",
              style: TextStyle(
                color: MyColor.orange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget homepageAppBar(AppState userState, AppState<String, Exception> address) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: userState.maybeWhen(
                success: (user) => user != null
                    ? NetworkImage(user.photoURL!)
                    : AssetImage("lib/assets/images/thumbnail.jpeg"),
                orElse: () => AssetImage("lib/assets/images/thumbnail.jpeg")),
          ),
          SizedBox(width: 10),
          Expanded(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Lokasi saya"),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: MyColor.orange,
                    size: 20,
                  ),
                  Expanded(
                    child: address.maybeWhen(
                      idle: () => Text("Fetching location...",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      loading: () => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 15,
                          width: 100,
                          color: Colors.white,
                        ),
                      ),
                      success: (addressText) => Text(
                        addressText,
                        style:
                            TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      error: (_, __) => Text(
                        "Error fetching location",
                        style:
                            TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      orElse: () => Text(
                        "Location not available",
                        style:
                            TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )),
          IconButton(
            onPressed: () {
              Logger.log("Clicked on notifications icon");
            },
            icon: const Icon(Icons.notifications_none),
            color: MyColor.blackPlain,
            iconSize: 33,
          ),
        ],
      ),
    );
  }
}

// EXISTING: Carousel widget remains the same
Widget homepageCarousel(WidgetRef ref) {
  final List<String> imgList = [
    'lib/assets/images/thumbnail.jpeg',
    'lib/assets/images/thumbnail.jpeg',
    'lib/assets/images/thumbnail.jpeg',
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: CarouselSlider.builder(
        itemCount: imgList.length,
        itemBuilder: (context, index, realIndex) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imgList[index],
              fit: BoxFit.cover,
              width: 280,
              height: 160,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildShimmer();
              },
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  "lib/assets/images/thumbnail.jpeg",
                  fit: BoxFit.cover,
                  width: 280,
                  height: 160,
                );
              },
            ),
          );
        },
        options: CarouselOptions(
          height: 160,
          aspectRatio: 16 / 9,
          autoPlay: true,
          onPageChanged: (index, reason) {
            ref.read(carouselIndexProvider.notifier).state = index;
          },
        )),
  );
}

Widget _buildShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
      ),
    ),
  );
}