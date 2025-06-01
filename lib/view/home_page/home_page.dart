// File: lib/view/home_page/home_page.dart
// FIXED: Updated to handle MerchantWithDistance from recommendations

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
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(homeViewmodelProvider.notifier).getUser();
      ref.read(addressViewModelProvider.notifier).getAddress();
      // FIXED: Fetch recommended merchants with distance calculation
      ref.read(recommendedMerchantsProvider.notifier).getRecommendedMerchants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(homeViewmodelProvider);
    final addressState = ref.watch(addressViewModelProvider);
    final recommendedState = ref.watch(recommendedMerchantsProvider);

    return Scaffold(
      backgroundColor: MyColor.whitePlain,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              homepageAppBar(userState, addressState),
              homepageCarousel(ref),
              _homepageCategory(),
              const SizedBox(height: 10),
              // FIXED: Recommended Section with distance support
              _buildRecommendedSection(recommendedState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homepageCategory() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: _categoryItem(
            icon: Icon(Icons.share_location, color: MyColor.orange, size: 25), 
            label: "Terdekat", 
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
        const SizedBox(width: 8),
        Expanded(
          child: _categoryItem(
            icon: FaIcon(FontAwesomeIcons.whiskeyGlass, color: MyColor.orange, size: 25), 
            label: "Minuman", 
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
        const SizedBox(width: 8),
        Expanded(
          child: _categoryItem(
            icon: FaIcon(FontAwesomeIcons.bowlFood, color: MyColor.orange, size: 25), 
            label: "Makanan", 
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
        const SizedBox(width: 8),
        Expanded(
          child: _categoryItem(
            icon: FaIcon(FontAwesomeIcons.cookieBite, color: MyColor.orange, size: 25), 
            label: "Cemilan", 
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

  // FIXED: Build Recommended Section with MerchantWithDistance support
  Widget _buildRecommendedSection(AppState recommendedState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
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
              TextButton(
                onPressed: () {
                  Logger.log("Clicked on Lihat Semua");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListMerchantPage(
                        category: MerchantCategory.nearest,
                      ),
                    ),
                  );
                },
                child: Text(
                  "Lihat Semua",
                  style: TextStyle(
                    color: MyColor.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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

  // FIXED: Handle MerchantWithDistanceHome instead of MerchantModel
  Widget _buildRecommendedList(List<dynamic> merchantsWithDistance) {
    return Column(
      children: merchantsWithDistance.map<Widget>((merchantWithDistance) {
        final merchant = merchantWithDistance.merchant;
        final distance = merchantWithDistance.distance;
        
        return MerchantWidget(
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
          // FIXED: Pass calculated distance to MerchantWidget
          showFavoriteButton: true, 
          distance: distance, // Now we have real calculated distance!
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

Widget homepageCarousel(WidgetRef ref) {
  final List<String> imgList = [
    'https://firebasestorage.googleapis.com/v0/b/project-database-63eea.appspot.com/o/banner%2FBannerTemuLapak1.png?alt=media&token=4b81f0dc-7ca2-4f90-91ec-c6bee743b622',
    'https://firebasestorage.googleapis.com/v0/b/project-database-63eea.appspot.com/o/banner%2FBannerTemuLapak2.png?alt=media&token=c72b4d9a-db9f-4b45-87d3-9fdcaa084e9b',
    'https://firebasestorage.googleapis.com/v0/b/project-database-63eea.appspot.com/o/banner%2FBannerTemuLapak3.png?alt=media&token=54b26ed2-b14f-42db-93a2-5ae573bbbc6b',
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

Widget _categoryItem({
  required Widget icon,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      // Remove fixed width dan height, biarkan Expanded yang mengatur
      constraints: BoxConstraints(
        minHeight: 72, // Minimum height untuk konsistensi
      ),
      decoration: BoxDecoration(
        color: MyColor.white,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Container untuk icon dengan ukuran tetap
            SizedBox(
              height: 32,
              child: icon,
            ),
            const SizedBox(height: 6),
            // Text yang responsive
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.w500
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}