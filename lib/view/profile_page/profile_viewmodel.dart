import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/data/network/login_service.dart';
import 'package:temulapak_app/data/network/notification_service.dart';
import 'package:temulapak_app/data/network/user_service.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/model/user/user_model.dart';
import 'package:temulapak_app/utils/custom_dialog.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/utils/loading/loading.dart';
import 'package:temulapak_app/utils/network_checker.dart';
import 'package:temulapak_app/view/help_centre_page/help_center_page.dart';
import 'package:temulapak_app/view/merchant_dashboard_page/merchant_dashboard_page.dart';
import 'package:temulapak_app/view/faq_page/faq_page.dart';
import 'package:temulapak_app/view/about_page/about_page.dart';
import 'package:temulapak_app/view/login_page/login_page.dart';
import 'package:temulapak_app/view/login_page/login_viewmodel.dart' as LoginVM;
import 'package:temulapak_app/view/register_merchant_page/register_merchant_page.dart';

final profileViewModelProvider =
    StateNotifierProvider<ProfileViewModel, AppState<UserModel, Exception>>(
        (ref) {
  final userService = UserService();
  final loginService = ref.read(loginServiceProvider);
  return ProfileViewModel(userService, loginService);
});

class ProfileViewModel extends StateNotifier<AppState<UserModel, Exception>> {
  final UserService _userService;
  final LoginService _loginService;
  final NotificationService _notificationService = NotificationService.instance;

  ProfileViewModel(this._userService, this._loginService)
      : super(AppState.idle());

  Future<void> getUser() async {
    Logger.log("PROFILEVM - Fetching user profile");
    state = AppState.loading();

    try {
      final user = await _userService.getCurrentUser();
      if (user != null) {
        Logger.log("PROFILEVM - User profile fetched successfully");
        state = AppState.success(user);
      } else {
        Logger.log("PROFILEVM - User profile not found");
        state = AppState.error(Exception('User profile not found'),
            message: 'Could not find your profile');
      }
    } catch (e) {
      Logger.error("PROFILEVM - Error fetching user profile", error: e);
      state = AppState.error(Exception(e.toString()),
          message: 'Failed to load profile');
    }
  }

  Future<void> navigateToFAQ(BuildContext context) async {
    Logger.log("PROFILEVM - Navigating to FAQ page");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FaqPage(),
      ),
    );
  }

  Future<void> navigateToBantuan(BuildContext context) async {
    Logger.log("PROFILEVM - Navigating to Help Center page");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpCenterPage(),
      ),
    );
  }

  Future<void> navigateToTentang(BuildContext context) async {
    Logger.log("PROFILEVM - Navigating to About page");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AboutPage(),
      ),
    );
  }

  Future<void> navigateToMerchant(BuildContext context) async {
    Logger.log("PROFILEVM - Tapped on Merchant Page");
    Loading.show(context);

    state.maybeWhen(
      success: (user) {
        if (user.isMerchant == true) {
          Logger.log("PROFILEVM - User is a merchant, navigating to MerchantDashboardPage");
          Future.delayed(Duration(milliseconds: 100), () {
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MerchantDashboardPage(),
              ),
            ).then((_) {
              Loading.hide();
            });
          });
        } else {
          Loading.hide();
          Logger.log("PROFILEVM - User is not a merchant, navigating to RegisterMerchantPage");
          Future.delayed(Duration(milliseconds: 100), () {
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegisterMerchantPage(),
              ),
            ).then((_) {});
          });
        }
      },
      orElse: () {
        Logger.error("PROFILEVM - User data not available");
        Future.delayed(Duration(milliseconds: 100), () {
          Loading.hide();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to access merchant page'),
              backgroundColor: Colors.red,
            ),
          );
        });
      },
    );
  }

  Future<void> signOut(BuildContext context) async {
    Logger.log("PROFILEVM - Initiating sign out process");
    
    final success = await NetworkChecker.instance.run(
      context: context,
      customOfflineMessage: "Can't connect to the internet",
      action: () async {
        Logger.log("PROFILEVM - Signing out user");
        
        try {
          await _notificationService.clearFCMTokenOnLogout();
          await _loginService.signOut();
          Logger.log("PROFILEVM - User signed out successfully");
          state = AppState.idle();
          return true;
        } catch (e) {
          Logger.error("PROFILEVM - Error signing out", error: e);
          state = AppState.error(Exception(e.toString()),
              message: 'Failed to sign out');
          return false;
        }
      },
    );

    if (success == true && context.mounted) {
      Logger.log("PROFILEVM - Navigating to login page after successful logout");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> refreshProfile() async {
    Logger.log("PROFILEVM - Refreshing user profile");
    await getUser();
  }

  // Show logout confirmation dialog
  Future<void> showLogoutDialog(BuildContext context, WidgetRef ref) async {
    Logger.log("PROFILEVM - Showing logout confirmation dialog");
    
    await showDialog(
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
            final success = await NetworkChecker.instance.run(
              context: context,
              customOfflineMessage: "Can't connect to the internet",
              action: () async {
                await signOut(context);
                return true;
              },
            );
            if (success == true && context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
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
  }
}