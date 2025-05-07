import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/utils/custom_dialog.dart';
import 'package:temulapak_app/utils/network_checker.dart';
import 'package:temulapak_app/view/login_page/login_page.dart';
import 'package:temulapak_app/view/login_page/login_viewmodel.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginVM = ref.watch(loginViewModelProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Column(
        children: [
          Center(
            child: const Text('Profile Page'),
          ),
          ElevatedButton(onPressed: (){
            showDialog(
                    context: context,
                    builder: (context) {
                      return CustomAlertDialog(
                          title: "Logout",
                          content: "Do you really want to logout?",
                          confirmText: "Yes",
                          cancelText: "No",
                          icon: Icons.logout,
                          iconColor: Colors.black,
                          dialogColor: MyColor.red,
                          onConfirm: () async {
                            NetworkChecker.instance.execute(context, () async {
                              await loginVM.signOut();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => LoginPage()),
                                    (route) => false);
                              }
                            });
                          },
                          onCancel: () {
                            Navigator.pop(context);
                          });
                    });
          }, child: Text("Logout")),
        ],
      ),
    );
  }
}