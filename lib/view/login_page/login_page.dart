import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/model/login/login_state.dart';
import 'package:temulapak_app/utils/custom_dialog.dart';
import 'package:temulapak_app/utils/loading/loading.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/utils/network_checker.dart';
import 'package:temulapak_app/view/login_page/login_viewmodel.dart';
import 'package:temulapak_app/view/navigation_page/navigation_page.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<LoginState>(loginViewModelProvider, (previous, current) {
      switch (current) {
        case LoginState(isLoading: true):
          Loading.show(context);

        case LoginState(error: String error?):
          Loading.hide();
          Logger.log("Error: $error");
          CustomAlertDialog(
              title: "Error Login",
              content: error,
              icon: Icons.error,
              dialogColor: MyColor.red,
              onConfirm: () {
                Navigator.pop(context);
              });

        case LoginState(user: User? user) when user != null:
          Loading.hide();
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => NavigationPage()),
              (route) => false);

        default:
          break;
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(25),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(
                        image: const AssetImage(
                          "lib/assets/icons/logoappTemuLapak.png",
                        ),
                        width: 28,
                        height: 28),
                    const SizedBox(width: 5),
                    Text(
                      "TemuLapak",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          color: MyColor.orange),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 70, 0, 50),
              child: SvgPicture.asset(
                'lib/assets/images/temulapak_login_draw.svg',
              ),
            ),
            Center(
                child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  SizedBox(
                    width: 180,
                    child: Text(
                      "Jelajahi, Temukan Dan Nikmati Penjual Terdekat!",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    width: 250,
                    child: Text(
                      "Live Tracking mempermudah anda menemukan pedagang favoritmu.",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: MyColor.blackPlain),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )),
            Expanded(child: SizedBox()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
              child: SizedBox(
                height: 47,
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () async {
                      Logger.log("Login Pressed");
                      NetworkChecker.instance.execute(context, () async {
                        await ref
                            .read(loginViewModelProvider.notifier)
                            .googleSignIn();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: MyColor.orange, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          "lib/assets/icons/google_icon.svg",
                          width: 22,
                          height: 22,
                        ),
                        SizedBox(width: 10),
                        Text("Masuk dengan Google",
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                color: MyColor.blackPlain)),
                      ],
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
