import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:temulapak_app/data/location/live_tracking_service.dart';
import 'package:temulapak_app/utils/logger.dart';

part 'live_tracking_notifier.g.dart';

@Riverpod(keepAlive: true)
class LiveTrackingNotifier extends _$LiveTrackingNotifier{
  final LiveTrackingService _trackingService = LiveTrackingService.instance;

  @override
  LiveTrackingState build() {
    final isServiceRunning = _trackingService.isTracking;
    
    Logger.log("LiveTrackingProvider - Initializing with service status: $isServiceRunning");
    return LiveTrackingState(
      isEnabled: isServiceRunning,
      isInitializing: false,
      error: null,
    );
  }

  /// Start live tracking with user confirmation
  Future<bool> startTracking() async {
    try {
      Logger.log("LiveTrackingProvider - Starting live tracking");
      
      state = state.copyWith(isInitializing: true, error: null);

      final success = await _trackingService.startTracking();
      
      if (success) {
        state = state.copyWith(
          isEnabled: true,
          isInitializing: false,
          error: null,
        );
        Logger.log("LiveTrackingProvider - Live tracking started successfully");
        return true;
      } else {
        state = state.copyWith(
          isEnabled: false,
          isInitializing: false,
          error: "Failed to start live tracking. Please check location permissions.",
        );
        Logger.error("LiveTrackingProvider - Failed to start live tracking");
        return false;
      }
    } catch (e) {
      Logger.error("LiveTrackingProvider - Error starting live tracking", error: e);
      state = state.copyWith(
        isEnabled: false,
        isInitializing: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Stop live tracking
  Future<void> stopTracking() async {
    try {
      Logger.log("LiveTrackingProvider - Stopping live tracking");
      
      state = state.copyWith(isInitializing: true, error: null);

      await _trackingService.stopTracking();
      
      state = state.copyWith(
        isEnabled: false,
        isInitializing: false,
        error: null,
      );
      
      Logger.log("LiveTrackingProvider - Live tracking stopped successfully");
    } catch (e) {
      Logger.error("LiveTrackingProvider - Error stopping live tracking", error: e);
      state = state.copyWith(
        isEnabled: false,
        isInitializing: false,
        error: e.toString(),
      );
    }
  }

  /// Toggle live tracking state
  Future<bool> toggleTracking() async {
    if (state.isEnabled) {
      await stopTracking();
      return false;
    } else {
      return await startTracking();
    }
  }

  void syncWithService() {
    final serviceStatus = _trackingService.isTracking;
    
    Logger.log("LiveTrackingProvider - Syncing state with service: $serviceStatus");
    
    if (state.isEnabled != serviceStatus) {
      Logger.log("LiveTrackingProvider - State mismatch detected, updating state to: $serviceStatus");
      state = state.copyWith(
        isEnabled: serviceStatus,
        isInitializing: false,
        error: null,
      );
    }
  }

  bool get isTracking => _trackingService.isTracking;

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// State class for live tracking
class LiveTrackingState {
  final bool isEnabled;
  final bool isInitializing;
  final String? error;

  const LiveTrackingState({
    required this.isEnabled,
    required this.isInitializing,
    this.error,
  });

  LiveTrackingState copyWith({
    bool? isEnabled,
    bool? isInitializing,
    String? error,
  }) {
    return LiveTrackingState(
      isEnabled: isEnabled ?? this.isEnabled,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'LiveTrackingState(isEnabled: $isEnabled, isInitializing: $isInitializing, error: $error)';
  }
}