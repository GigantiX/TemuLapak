import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temulapak_app/data/location/geocoding_service.dart';
import 'package:temulapak_app/data/location/location_services.dart';
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
LocationServices locationServices(Ref ref) {
  return LocationServices.instance;
}

@riverpod
GeocodingService geocodingService(Ref ref) {
  return GeocodingService();
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
        state = AppState.error(Exception('User profile not found'),
            message: 'Could not find your profile');
        return;
      }
    } catch (e) {
      Logger.error("Error fetching user profile", error: e);
      state = AppState.error(Exception(e.toString()));
      rethrow;
    }
  }
}

@riverpod
class AddressViewModel extends _$AddressViewModel {
  @override
  AppState<String, Exception> build() {
    return AppState.idle(); 
  }

  Future<void> getAddress() async {
    state = AppState.loading();
    try {
      Logger.log("Address VM - Getting current location");
      final locationService = ref.read(locationServicesProvider);
      final position = await locationService.getCurrentLocation();
      
      if (position == null) {
        Logger.error("Failed to get current location");
        state = AppState.success("No location");
        return;
      }
      
      Logger.log("Address VM - Location obtained: ${position.latitude}, ${position.longitude}");
      
      final geocodingService = ref.read(geocodingServiceProvider);
      try {
        final address = await geocodingService.getAddressFromLatLng(
          position.latitude, 
          position.longitude
        );
        
        Logger.log("Address VM - Address obtained: $address");
        state = AppState.success(address);
      } catch (geocodingError) {
        Logger.error("Error in geocoding", error: geocodingError);
        state = AppState.success("Error fetching address");
      }
    } catch (e) {
      Logger.error("Error fetching address", error: e);
      state = AppState.success("No location");
    }
  }
}
