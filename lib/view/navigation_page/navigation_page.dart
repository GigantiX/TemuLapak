import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/view/chat_page/chat_page.dart';
import 'package:temulapak_app/view/favorite_page/favorite_page.dart';
import 'package:temulapak_app/view/home_page/home_page.dart';
import 'package:temulapak_app/view/navigation_page/navigation_viewmodel.dart';
import 'package:temulapak_app/view/profile_page/profile_page.dart';

class NavigationPage extends ConsumerWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationViewModelProvider);
    final navViewModel = ref.read(navigationViewModelProvider.notifier);

    final pages = [
      const HomePage(),
      const FavoritePage(),
      const ChatPage(),
      const ProfilePage()
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 25),
        child: GNav(
          onTabChange: navViewModel.setIndex,
          gap: 8,
          iconSize: 28,
          duration: const Duration(milliseconds: 400),
          selectedIndex: currentIndex,
          color: MyColor.blackPlain,
          activeColor: MyColor.white,
          haptic: true,
          tabBackgroundColor: MyColor.orange,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          tabs: const [
            GButton(
              icon: Icons.home,
              text: 'Beranda',
            ),
            GButton(
              icon: Icons.favorite,
              text: 'Favorit',
            ),
            GButton(
              icon: Icons.chat,
              text: 'Pesan',
            ),
            GButton(
              icon: Icons.account_circle,
              text: 'Profil',
            ),
          ]
          ),
      ),
    );
  }
}