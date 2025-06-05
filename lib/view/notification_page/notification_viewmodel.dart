import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/data/network/notification_service.dart';
import 'package:temulapak_app/model/notification/notification_model.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/utils/logger.dart';

part 'notification_viewmodel.g.dart';

@riverpod
NotificationService notificationService(Ref ref) {
  return NotificationService.instance;
}

/// Stream provider for notification history
@riverpod
Stream<List<NotificationModel>> notificationHistory(Ref ref) {
  Logger.log("NOTIFICATION_VM - Starting notification history stream");
  final notificationService = ref.read(notificationServiceProvider);
  return notificationService.getNotificationHistory();
}

/// Notification actions viewmodel
@riverpod
class NotificationActionsViewModel extends _$NotificationActionsViewModel {
  @override
  AppState<String, Exception> build() {
    return AppState.idle();
  }

  /// Initialize notification service
  Future<void> initializeNotifications() async {
    try {
      state = AppState.loading();
      Logger.log("NOTIFICATION_ACTIONS_VM - Initializing notifications");
      
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();
      
      Logger.log("NOTIFICATION_ACTIONS_VM - Notifications initialized successfully");
      state = AppState.success("Notifications initialized");
      
    } catch (e) {
      Logger.error("NOTIFICATION_ACTIONS_VM - Error initializing notifications", error: e);
      state = AppState.error(
        Exception(e.toString()),
        message: 'Failed to initialize notifications: ${e.toString()}'
      );
    }
  }

  /// Update FCM token on login
  Future<void> updateTokenOnLogin() async {
    try {
      Logger.log("NOTIFICATION_ACTIONS_VM - Updating FCM token on login");
      
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.updateFCMTokenOnLogin();
      
      Logger.log("NOTIFICATION_ACTIONS_VM - FCM token updated successfully");
      
    } catch (e) {
      Logger.error("NOTIFICATION_ACTIONS_VM - Error updating FCM token", error: e);
    }
  }

  /// Clear FCM token on logout
  Future<void> clearTokenOnLogout() async {
    try {
      Logger.log("NOTIFICATION_ACTIONS_VM - Clearing FCM token on logout");
      
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.clearFCMTokenOnLogout();
      
      Logger.log("NOTIFICATION_ACTIONS_VM - FCM token cleared successfully");
      
    } catch (e) {
      Logger.error("NOTIFICATION_ACTIONS_VM - Error clearing FCM token", error: e);
    }
  }

  /// Clear state
  void clearState() {
    state = AppState.idle();
  }
}