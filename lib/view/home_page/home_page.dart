import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/home_page/home_viewmodel.dart';
import 'package:temulapak_app/view/listmerchant_page/listmerchant_page.dart';
import 'package:temulapak_app/view/listmerchant_page/listmerchant_viewmodel.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(homeViewmodelProvider);
    final addressState = ref.watch(addressViewModelProvider);

    return Scaffold(
      backgroundColor: MyColor.whitePlain,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            homepageAppBar(userState, addressState),
            homepageCarousel(ref),
            _homepageCategory(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Rekomendasi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homepageCategory() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _categoryItem(
            icon: Icon(Icons.share_location, color: MyColor.orange, size: 30,), label: "Terdekat", onTap: () {
              Logger.log("Clicked on Terdekat");
              Navigator.push(
              context, 
                MaterialPageRoute(
                  builder: (context) => ListMerchantPage(
                    category: MerchantCategory.nearest,
                  ),
                ),
              );
            }), 
        _categoryItem(
            icon: FaIcon(FontAwesomeIcons.whiskeyGlass, color: MyColor.orange, size: 25,), label: "Minuman", onTap: () {
              Logger.log("Clicked on Minuman");
              Navigator.push(
              context, 
                MaterialPageRoute(
                  builder: (context) => ListMerchantPage(
                    category: MerchantCategory.drinks,
                  ),
                ),
              );
            }),
        _categoryItem(
            icon: FaIcon(FontAwesomeIcons.bowlFood, color: MyColor.orange, size: 25,), label: "Makanan", onTap: () {
              Logger.log("Clicked on Makanan");
              Navigator.push(
              context, 
                MaterialPageRoute(
                  builder: (context) => ListMerchantPage(
                    category: MerchantCategory.food,
                  ),
                ),
              );
            }),
        _categoryItem(
            icon: FaIcon(FontAwesomeIcons.cookieBite, color: MyColor.orange, size: 25,), label: "Cemilan", onTap: () {
              Logger.log("Clicked on Cemilan");
              Navigator.push(
              context, 
                MaterialPageRoute(
                  builder: (context) => ListMerchantPage(
                    category: MerchantCategory.snacks,
                  ),
                ),
              );
            }),
      ],
    ),
  );
}
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
          onPressed: () {},
          icon: const Icon(Icons.notifications_none),
          color: MyColor.blackPlain,
          iconSize: 33,
        ),
      ],
    ),
  );
}

Widget homepageCarousel(WidgetRef ref) {
  final List<String> imgList = [
    'https://picsum.photos/id/868/1280/720',
    'https://picsum.photos/id/869/1280/720',
    'https://picsum.photos/id/866/1280/720',
    'https://picsum.photos/id/862/1280/720',
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
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: MyColor.white,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Column(
          children: [
            icon,
            SizedBox(height: 7),
            Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    ),
  );
}
