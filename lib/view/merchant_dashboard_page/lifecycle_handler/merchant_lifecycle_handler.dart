import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temulapak_app/data/location/live_tracking_service.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/merchant_dashboard_page/live_tracking/live_tracking_notifier.dart';

class MerchantLifecycleHandler extends ConsumerStatefulWidget {
  final Widget child;

  const MerchantLifecycleHandler({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MerchantLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends ConsumerState<MerchantLifecycleHandler>
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Logger.log("AppLifecycleHandler - Lifecycle observer added");
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Logger.log("AppLifecycleHandler - Lifecycle observer removed");
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    Logger.log("AppLifecycleHandler - App lifecycle state changed: $state");
    
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  /// Handle app resumed (foreground)
  void _handleAppResumed() {
    Logger.log("AppLifecycleHandler - App resumed (foreground)");
    
    // App is back in foreground
    // Sync live tracking state with actual service status
    final liveTrackingNotifier = ref.read(liveTrackingNotifierProvider.notifier);
    liveTrackingNotifier.syncWithService();
    
    final liveTrackingState = ref.read(liveTrackingNotifierProvider);
    
    if (liveTrackingState.isEnabled) {
      Logger.log("AppLifecycleHandler - Live tracking should be active, checking service status");
      
      // Check if service is still running, restart if needed
      final isServiceRunning = LiveTrackingService.instance.isTracking;
      if (!isServiceRunning) {
        Logger.log("AppLifecycleHandler - Live tracking service stopped, restarting...");
        // Restart tracking service
        Future.delayed(Duration(milliseconds: 500), () {
          liveTrackingNotifier.startTracking();
        });
      } else {
        Logger.log("AppLifecycleHandler - Live tracking service is running correctly");
      }
    }
  }

  /// Handle app paused (background)
  void _handleAppPaused() {
    Logger.log("AppLifecycleHandler - App paused (background)");
    
    // App moved to background
    // Live tracking continues in background until app is killed
    final liveTrackingState = ref.read(liveTrackingNotifierProvider);
    
    if (liveTrackingState.isEnabled) {
      Logger.log("AppLifecycleHandler - App in background, live tracking continues");
    }
  }

  /// Handle app detached (killed/terminated)
  void _handleAppDetached() {
    Logger.log("AppLifecycleHandler - App detached (being killed)");
    
    // App is being killed/terminated
    // Automatically stop live tracking
    final liveTrackingState = ref.read(liveTrackingNotifierProvider);
    
    if (liveTrackingState.isEnabled) {
      Logger.log("AppLifecycleHandler - App being killed, stopping live tracking");
      
      // Stop live tracking without showing dialog (auto-deactivate)
      ref.read(liveTrackingNotifierProvider.notifier).stopTracking();
      
      // Cleanup tracking service
      LiveTrackingService.instance.dispose();
    }
  }

  /// Handle app inactive (temporary interruption)
  void _handleAppInactive() {
    Logger.log("AppLifecycleHandler - App inactive (temporary interruption)");
    // App is temporarily inactive (e.g., incoming call, notification panel)
    // No action needed, live tracking continues
  }

  /// Handle app hidden (iOS specific)
  void _handleAppHidden() {
    Logger.log("AppLifecycleHandler - App hidden");
    // App is hidden but not necessarily killed
    // Live tracking continues
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}