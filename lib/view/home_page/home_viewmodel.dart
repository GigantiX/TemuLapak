import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temulapak_app/data/network/user_service.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/model/user/user_model.dart';
import 'package:temulapak_app/utils/logger.dart';

part 'home_viewmodel.g.dart';

final carouselIndexProvider = StateProvider<int>((ref) => 0);

@riverpod
UserService userService(Ref ref) {
  return UserService();
}

@riverpod
class HomeViewmodel extends _$HomeViewmodel {
  @override
  AppState<UserModel, Exception> build() {
    return AppState.idle();
  }

  Future<void> getUser() async {
    Logger.log("HOMEVM - Fetching user profile");
    state = AppState.loading();
    try {
      final userService = ref.read(userServiceProvider);
      final user = await userService.getCurrentUser();
      if (user != null) {
        Logger.log("User profile fetched successfully");
        state = AppState.success(user);
      } else {
        state = AppState.error(
          Exception('User profile not found'),
          message: 'Could not find your profile'
        );
        return;
      }
    } catch (e) {
      Logger.error("Error fetching user profile", error: e);
      state = AppState.error(Exception(e.toString()));
      rethrow;
    }
  }
}
