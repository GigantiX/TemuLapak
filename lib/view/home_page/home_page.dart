import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/utils/custom_dialog.dart';
import 'package:temulapak_app/utils/network_checker.dart';
import 'package:temulapak_app/view/home_page/home_viewmodel.dart';
import 'package:temulapak_app/view/login_page/login_page.dart';
import 'package:temulapak_app/view/login_page/login_viewmodel.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            homepageAppBar(),
            homepageCarousel(ref),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Upcoming Events",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget homepageAppBar() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage('https://picsum.photos/200/300'),
        ),
        SizedBox(width: 10),
        Expanded(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Lokasi saya"),
            Row(children: [
            Icon(Icons.location_on, color: MyColor.orange, size: 20,),
              Text(
              'Jakarta, Indonesia',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            )
            ],),
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
            child: Image.network(imgList[index],
                fit: BoxFit.cover,
                width: 280,
                height: 160, loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;

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
            }),
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
