import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/data/network/merchant_service.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/logger.dart';

part 'merchant_dashboard_viewmodel.g.dart';

@riverpod
class MerchantDashboardViewmodel extends _$MerchantDashboardViewmodel {
  final _merchantService = MerchantService();
  Timer? _refreshTimer;

  @override
  AppState<MerchantModel, Exception> build() {
    ref.onDispose(() {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    });
    
    return AppState.idle();
  }

  Future<void> loadMerchantData() async {
    try {
      state = AppState.loading();
      Logger.log("VM - Loading merchant data");
      
      final merchantData = await _merchantService.getUserMerchant();
      Logger.log("VM - Merchant data loaded successfully");
      
      state = AppState.success(merchantData);
    } catch (e) {
      state = AppState.error(e as Exception);
    }
  }

  Future<void> updateMerchantStatus(bool isOpen) async {
    try {
      Logger.log("VM - Updating merchant status to: $isOpen");
      
      await _merchantService.updateMerchantStatus(isOpen);
      
      final currentState = state;
      if (currentState.isSuccess && currentState.data != null) {
        final updatedMerchant = currentState.data!.copyWith(merchantStatus: isOpen);
        state = AppState.success(updatedMerchant);
        Logger.log("VM - Merchant status updated successfully");
      }
    } catch (e) {
      Logger.error("VM - Error updating merchant status", error: e);
      rethrow;
    }
  }

  Future<void> updateMerchantLocation(double lat, double lng) async {
    try {
      Logger.log("VM - Updating merchant location");
      
      await _merchantService.updateMerchantLocation(lat, lng);
      
      final currentState = state;
      if (currentState.isSuccess && currentState.data != null) {
        final updatedMerchant = currentState.data!.copyWith(
          merchantLocLat: lat,
          merchantLocLong: lng,
        );
        state = AppState.success(updatedMerchant);
        Logger.log("VM - Merchant location updated successfully");
      }
    } catch (e) {
      Logger.error("VM - Error updating merchant location", error: e);
      rethrow;
    }
  }

  void startLiveTrackingRefresh() {
    Logger.log("VM - Starting live tracking refresh timer");
    
    // Cancel existing timer if any
    _refreshTimer?.cancel();
    
    // Refresh merchant data every 30 seconds when live tracking is active
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      try {
        Logger.log("VM - Refreshing merchant data for live tracking");
        
        // Only refresh if current state is success (don't interfere with loading/error states)
        if (state.isSuccess) {
          final merchantData = await _merchantService.getUserMerchant();
          state = AppState.success(merchantData);
          Logger.log("VM - Live tracking refresh completed");
        }
      } catch (e) {
        Logger.error("VM - Error in live tracking refresh", error: e);
        // Don't change state to error during refresh, just log the error
      }
    });
  }

  void stopLiveTrackingRefresh() {
    Logger.log("VM - Stopping live tracking refresh timer");
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> refreshMerchantData() async {
    try {
      Logger.log("VM - Force refreshing merchant data");
      
      final merchantData = await _merchantService.getUserMerchant();
      state = AppState.success(merchantData);
      
      Logger.log("VM - Force refresh completed successfully");
    } catch (e) {
      Logger.error("VM - Error in force refresh", error: e);
      // Don't change to error state, just log the error
    }
  }
}
