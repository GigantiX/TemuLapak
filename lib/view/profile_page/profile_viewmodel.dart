import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temulapak_app/data/network/login_service.dart';
import 'package:temulapak_app/data/network/notification_service.dart';
import 'package:temulapak_app/data/network/user_service.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/model/user/user_model.dart';
import 'package:temulapak_app/utils/logger.dart';

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

  Future<void> signOut() async {
    Logger.log("PROFILEVM - Signing out user");
    state = AppState.loading();

    try {
      final userId = _userService.getCurrentUID();
      Logger.log("PROFILEVM - Current UID before logout: $userId");
      
      if (userId != null) {
        await _notificationService.clearFCMTokenWithUID(userId);
      } else {
        Logger.log("PROFILEVM - No UID found, skipping FCM token cleanup");
      }
      
      await _loginService.signOut();
      Logger.log("PROFILEVM - User signed out successfully");
      state = AppState.idle();
    } catch (e) {
      Logger.error("PROFILEVM - Error signing out", error: e);
      state = AppState.error(Exception(e.toString()),
          message: 'Failed to sign out');
    }
  }

  Future<void> refreshProfile() async {
    await getUser();
  }
}
