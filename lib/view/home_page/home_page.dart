import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/home_page/home_viewmodel.dart';
import 'package:temulapak_app/view/list_merchant_page/list_merchant_viewmodel.dart';
import 'package:temulapak_app/view/widget/merchant_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(enhancedHomeStateNotifierProvider.notifier).initializeHomeData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enhancedState = ref.watch(enhancedHomeStateNotifierProvider);
    
    // Command listener
    ref.listen(
      enhancedHomeStateNotifierProvider.select((s) => s.command),
      (_, command) => _executeCommand(context, command),
    );

    return Scaffold(
      backgroundColor: MyColor.whitePlain,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            Logger.log("HOME_PAGE - Pull to refresh triggered");
            await ref.read(enhancedHomeStateNotifierProvider.notifier).refreshAllData();
            Logger.log("HOME_PAGE - Pull to refresh completed");
          },
          color: MyColor.orange,
          backgroundColor: Colors.white,
          displacement: 40,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHomepageAppBar(enhancedState),
                _buildHomepageCarousel(),
                _buildResponsiveCategory(context),
                _buildRecommendedSection(enhancedState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Command execution
  void _executeCommand(BuildContext context, ViewModelCommand? command) {
    if (command == null) return;
    
    if (command is NavigateCommand) {
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => command.page)
      );
    } else if (command is ShowSnackbarCommand) {
      Logger.log("HOME_PAGE - Showing snackbar: ${command.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(command.message),
          backgroundColor: command.backgroundColor,
          duration: Duration(seconds: command.durationSeconds),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Coba Lagi',
            textColor: Colors.white,
            onPressed: () {
              Logger.log("HOME_PAGE - Retry button clicked");
              ref.read(enhancedHomeStateNotifierProvider.notifier).refreshAllData();
            },
          ),
        ),
      );
    }
  }

  // App bar
  Widget _buildHomepageAppBar(EnhancedHomeState enhancedState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: enhancedState.user?.photoURL != null
                ? NetworkImage(enhancedState.user!.photoURL!)
                : const AssetImage("lib/assets/images/thumbnail.jpeg") as ImageProvider,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Lokasi saya"),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: MyColor.orange,
                      size: 20,
                    ),
                    Expanded(
                      child: _buildAddressDisplay(enhancedState),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Logger.log("Clicked on notifications icon");
              ref.read(enhancedHomeStateNotifierProvider.notifier).navigateToNotification();
            },
            icon: const Icon(Icons.notifications_none),
            color: MyColor.blackPlain,
            iconSize: 33,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressDisplay(EnhancedHomeState enhancedState) {
    if (enhancedState.isLoading && enhancedState.address == null) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 15,
          width: 100,
          color: Colors.white,
        ),
      );
    }

    return Text(
      enhancedState.address ?? "Location not available",
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Carousel
  Widget _buildHomepageCarousel() {
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
        ),
      ),
    );
  }

  // Category section
  Widget _buildResponsiveCategory(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 400;

    final horizontalPadding = isSmallScreen ? 16.0 : (isMediumScreen ? 20.0 : 25.0);
    final verticalPadding = isSmallScreen ? 8.0 : 10.0;

    final categoryHeight = isSmallScreen ? 65.0 : (isMediumScreen ? 68.0 : 72.0);
    final iconSize = isSmallScreen ? 22.0 : (isMediumScreen ? 24.0 : 25.0);
    final fontSize = isSmallScreen ? 10.0 : (isMediumScreen ? 11.0 : 12.0);
    final spacing = isSmallScreen ? 6.0 : 8.0;
    final textSpacing = isSmallScreen ? 5.0 : 7.0;

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
                ref.read(enhancedHomeStateNotifierProvider.notifier)
                    .navigateToListMerchant(MerchantCategory.nearest);
              },
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
                ref.read(enhancedHomeStateNotifierProvider.notifier)
                    .navigateToListMerchant(MerchantCategory.drinks);
              },
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
                ref.read(enhancedHomeStateNotifierProvider.notifier)
                    .navigateToListMerchant(MerchantCategory.food);
              },
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
                ref.read(enhancedHomeStateNotifierProvider.notifier)
                    .navigateToListMerchant(MerchantCategory.snacks);
              },
            ),
          ),
        ],
      ),
    );
  }

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
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: spacing,
            horizontal: 4,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              SizedBox(height: spacing),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Recommended section
  Widget _buildRecommendedSection(EnhancedHomeState enhancedState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Rekomendasi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          _buildRecommendedContent(enhancedState),
        ],
      ),
    );
  }

  Widget _buildRecommendedContent(EnhancedHomeState enhancedState) {
    if (enhancedState.isLoading && enhancedState.recommendations.isEmpty) {
      return _buildRecommendedShimmer();
    }

    if (enhancedState.recommendations.isEmpty) {
      return _buildEmptyRecommended();
    }

    if (enhancedState.errorMessage != null) {
      return _buildRecommendedError(enhancedState.errorMessage);
    }

    return _buildRecommendedList(enhancedState.recommendations);
  }

  Widget _buildRecommendedList(List<MerchantWithDistanceHome> merchantsWithDistance) {
    return Column(
      children: merchantsWithDistance.map<Widget>((merchantWithDistance) {
        final merchant = merchantWithDistance.merchant;
        final distance = merchantWithDistance.distance;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MerchantWidget(
            merchant: merchant,
            onTap: () {
              Logger.log("Clicked on recommended merchant: ${merchant.merchantName}");
              ref.read(enhancedHomeStateNotifierProvider.notifier)
                  .navigateToMerchantDetail(merchant);
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
      children: List.generate(
        3,
        (index) => Padding(
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
        color: MyColor.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyColor.red.withValues(alpha: 0.3)),
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
              Logger.log("HOME_PAGE - Retry recommendations button clicked");
              ref.read(enhancedHomeStateNotifierProvider.notifier).refreshAllData();
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
}