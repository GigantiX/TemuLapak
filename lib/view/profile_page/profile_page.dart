import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/utils/custom_dialog.dart';
import 'package:temulapak_app/utils/loading/loading.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/utils/network_checker.dart';
import 'package:temulapak_app/view/help_centre_page/help_center_page.dart';
import 'package:temulapak_app/view/merchant_dashboard_page/merchant_dashboard_page.dart';
import 'package:temulapak_app/view/profile_page/profile_viewmodel.dart';
import 'package:temulapak_app/view/faq_page/faq_page.dart';
import 'package:temulapak_app/view/about_page/about_page.dart';
import 'package:temulapak_app/view/login_page/login_page.dart';
import 'package:temulapak_app/view/login_page/login_viewmodel.dart';
import 'package:temulapak_app/view/register_merchant_page/register_merchant_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(profileViewModelProvider.notifier).getUser());
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(profileViewModelProvider);
    final loginVM = ref.watch(loginViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: MyColor.orange,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: MyColor.orange,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundImage: userState.maybeWhen(
                        success: (user) => user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : const AssetImage(
                                    "lib/assets/images/thumbnail.jpeg")
                                as ImageProvider,
                        orElse: () => const AssetImage(
                            "lib/assets/images/thumbnail.jpeg"),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userState.maybeWhen(
                      success: (user) => user.displayName ?? "User Name",
                      orElse: () => "User Name",
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      userState.maybeWhen(
                        success: (user) => user.email ?? "user@email.com",
                        orElse: () => "user@email.com",
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  userState.maybeWhen(
                    success: (user) => user.isMerchant == true
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.storefront,
                                  size: 16,
                                  color: MyColor.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Penjual Aktif",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: MyColor.orange,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  SizedBox(height: 5),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 60,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: MyColor.orange,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: MyColor.orange.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: () {
                              Logger.log("Tapped on Merchant Page");
                              Loading.show(context);

                              userState.maybeWhen(
                                success: (user) {
                                  if (user.isMerchant == true) {
                                    Logger.log(
                                        "User is a merchant, navigating to MerchantDashboardPage");
                                    Future.delayed(Duration(milliseconds: 100),
                                        () {
                                      if (!context.mounted) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MerchantDashboardPage(),
                                        ),
                                      ).then((_) {
                                        Loading.hide();
                                      });
                                    });
                                  } else {
                                    Logger.log(
                                        "User is not a merchant, navigating to RegisterMerchantPage");
                                    Future.delayed(Duration(milliseconds: 100),
                                        () {
                                      if (!context.mounted) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RegisterMerchantPage(),
                                        ),
                                      ).then((_) {
                                        Loading.hide();
                                      });
                                    });
                                  }
                                },
                                orElse: () {
                                  // Handle case when user data isn't available yet
                                  Logger.error("User data not available");
                                  Future.delayed(Duration(milliseconds: 100),
                                      () {
                                    Loading.hide();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Unable to access merchant page'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  });
                                },
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.storefront,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Halaman Penjual",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Spacer(),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: "FAQ",
                        subtitle: "Pertanyaan yang sering ditanyakan",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FaqPage(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.support_agent,
                        title: "Bantuan & Dukungan",
                        subtitle: "Hubungi tim support kami",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpCenterPage(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        title: "Tentang Aplikasi",
                        subtitle: "Informasi aplikasi",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutPage(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.logout,
                        title: "Keluar",
                        subtitle: "Keluar dari akun",
                        textColor: MyColor.red,
                        iconColor: MyColor.red,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return CustomAlertDialog(
                                title: "Logout",
                                content: "Do you really want to logout?",
                                confirmText: "Yes",
                                cancelText: "No",
                                icon: Icons.logout,
                                iconColor: Colors.white,
                                dialogColor: MyColor.red,
                                onConfirm: () async {
                                  Navigator.pop(context);
                                  final success =
                                      await NetworkChecker.instance.run(
                                    context: context,
                                    customOfflineMessage:
                                        "Can't connect to the internet",
                                    action: () async {
                                      await loginVM.signOut();
                                      return true;
                                    },
                                  );
                                  if (success == true && context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginPage()),
                                      (route) => false,
                                    );
                                  }
                                },
                                onCancel: () {
                                  Navigator.pop(context);
                                },
                              );
                            },
                          );
                        },
                      ),
                      Text(
                        "TemuLapak v1.0.0",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? MyColor.orange).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? MyColor.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor ?? MyColor.blackPlain,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
