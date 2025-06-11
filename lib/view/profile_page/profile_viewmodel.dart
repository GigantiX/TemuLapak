import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temulapak_app/data/network/login_service.dart';
import 'package:temulapak_app/data/network/notification_service.dart';
import 'package:temulapak_app/data/network/user_service.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/model/user/user_model.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/utils/loading/loading.dart';
import 'package:temulapak_app/view/help_centre_page/help_center_page.dart';
import 'package:temulapak_app/view/login_page/login_viewmodel.dart';
import 'package:temulapak_app/view/merchant_dashboard_page/merchant_dashboard_page.dart';
import 'package:temulapak_app/view/faq_page/faq_page.dart';
import 'package:temulapak_app/view/about_page/about_page.dart';
import 'package:temulapak_app/view/register_merchant_page/register_merchant_page.dart';

final profileViewModelProvider =
    StateNotifierProvider<ProfileViewModel, AppState<UserModel, Exception>>(
        (ref) {
  final userService = UserService();
  final loginService = ref.read(loginServiceProvider);

  return ProfileViewModel(userService, loginService, ref);
});

class ProfileViewModel extends StateNotifier<AppState<UserModel, Exception>> {
  final UserService _userService;
  final LoginService _loginService;
  final NotificationService _notificationService = NotificationService.instance;
  final Ref _ref;

  ProfileViewModel(this._userService, this._loginService, this._ref)
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
          Logger.log(
              "PROFILEVM - User is a merchant, navigating to MerchantDashboardPage");
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
          Logger.log(
              "PROFILEVM - User is not a merchant, navigating to RegisterMerchantPage");
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

  Future<bool> signOut() async {
    Logger.log("PROFILEVM - Initiating sign out process");
    state = AppState.loading();

    try {
      await _notificationService.clearFCMTokenOnLogout();
      await _loginService.signOut();

      _ref.invalidate(loginViewModelProvider);
      
      Logger.log("PROFILEVM - User signed out successfully");
      return true;
    } catch (e) {
      Logger.error("PROFILEVM - Error signing out", error: e);
      state = AppState.error(Exception(e.toString()),
          message: 'Failed to sign out');
      return false;
    }
  }


  Future<void> refreshProfile() async {
    Logger.log("PROFILEVM - Refreshing user profile");
    await getUser();
  }
}
