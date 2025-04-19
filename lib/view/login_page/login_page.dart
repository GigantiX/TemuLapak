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
import 'package:temulapak_app/view/home_page/home_page.dart';
import 'package:temulapak_app/view/login_page/login_viewmodel.dart';

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
              MaterialPageRoute(builder: (context) => HomePage()),
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
                child: Text(
                  "TemuLapak",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
              child: SvgPicture.asset(
                'lib/assets/images/login_image.svg',
              ),
            ),
            Expanded(child: SizedBox()),
            Center(
                child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Text(
                    "Welcome",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 32),
                  ),
                  Text(
                    "Please sign in or sign up to continue",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w300,
                        fontSize: 14,
                        color: MyColor.blackPlain),
                  ),
                ],
              ),
            )),
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
                      side: const BorderSide(color: MyColor.darkBlue, width: 2),
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
                        Text("Sign in with Google",
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