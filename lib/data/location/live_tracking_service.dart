import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:temulapak_app/data/location/location_service.dart';
import 'package:temulapak_app/data/network/merchant_service.dart';
import 'package:temulapak_app/utils/logger.dart';

class LiveTrackingService {
  static final LiveTrackingService _instance = LiveTrackingService._internal();
  static LiveTrackingService get instance => _instance;

  factory LiveTrackingService() => _instance;
  LiveTrackingService._internal();

  // Service state
  bool _isTracking = false;
  Position? _lastKnownPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _batteryOptimizationTimer;
  
  // Dependencies
  final MerchantService _merchantService = MerchantService();
  final LocationService _locationService = LocationService();
  
  // Configuration
  static const double _minimumDistanceThreshold = 20.0; // 20 meters
  static const int _updateIntervalSeconds = 30; // Check every 30 seconds for battery optimization
  static const LocationAccuracy _trackingAccuracy = LocationAccuracy.medium; // Balanced accuracy for battery optimization

  // Getters
  bool get isTracking => _isTracking;
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Start live tracking with battery optimization
  Future<bool> startTracking() async {
    try {
      Logger.log("LiveTracking - Starting live tracking service");

      // Check permissions first
      if (!await _locationService.checkPermission()) {
        Logger.error("LiveTracking - Location permissions not granted");
        return false;
      }

      if (_isTracking) {
        Logger.log("LiveTracking - Already tracking, ignoring start request");
        return true;
      }

      // Get initial position
      _lastKnownPosition = await _getCurrentPosition();
      if (_lastKnownPosition == null) {
        Logger.error("LiveTracking - Failed to get initial position");
        return false;
      }

      // Update initial merchant location
      await _updateMerchantLocation(_lastKnownPosition!);

      _isTracking = true;

      // Start position stream with battery-optimized settings
      _startPositionStream();

      // Start battery optimization timer
      _startBatteryOptimizationTimer();

      Logger.log("LiveTracking - Live tracking started successfully");
      return true;

    } catch (e) {
      Logger.error("LiveTracking - Error starting tracking", error: e);
      return false;
    }
  }

  /// Stop live tracking
  Future<void> stopTracking() async {
    try {
      Logger.log("LiveTracking - Stopping live tracking service");

      _isTracking = false;

      // Cancel position stream
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;

      // Cancel battery optimization timer
      _batteryOptimizationTimer?.cancel();
      _batteryOptimizationTimer = null;

      Logger.log("LiveTracking - Live tracking stopped successfully");

    } catch (e) {
      Logger.error("LiveTracking - Error stopping tracking", error: e);
    }
  }

  /// Start position stream with battery optimization
  void _startPositionStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: _trackingAccuracy,
      distanceFilter: 10, // Only get updates when moved 10+ meters
      timeLimit: Duration(seconds: 10), // Timeout after 10 seconds
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onPositionUpdate,
      onError: _onPositionError,
      cancelOnError: false,
    );
  }

  /// Battery optimization timer - checks position periodically instead of continuous tracking
  void _startBatteryOptimizationTimer() {
    _batteryOptimizationTimer = Timer.periodic(
      Duration(seconds: _updateIntervalSeconds),
      (_) async {
        if (!_isTracking) return;

        try {
          final currentPosition = await _getCurrentPosition();
          if (currentPosition != null) {
            await _onPositionUpdate(currentPosition);
          }
        } catch (e) {
          Logger.error("LiveTracking - Error in battery optimization timer", error: e);
        }
      },
    );
  }

  /// Handle position updates with distance threshold
  Future<void> _onPositionUpdate(Position position) async {
    try {
      if (!_isTracking) return;

      // Calculate distance from last known position
      if (_lastKnownPosition != null) {
        final distance = _calculateDistance(
          _lastKnownPosition!.latitude,
          _lastKnownPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        Logger.log("LiveTracking - Distance moved: ${distance.toStringAsFixed(2)} meters");

        // Only update if moved more than threshold
        if (distance < _minimumDistanceThreshold) {
          Logger.log("LiveTracking - Distance below threshold, skipping update");
          return;
        }
      }

      // Update last known position
      _lastKnownPosition = position;

      // Update merchant location in Firebase
      await _updateMerchantLocation(position);

      Logger.log("LiveTracking - Location updated successfully");

    } catch (e) {
      Logger.error("LiveTracking - Error updating position", error: e);
    }
  }

  /// Handle position stream errors
  void _onPositionError(dynamic error) {
    Logger.error("LiveTracking - Position stream error", error: error);
    
    // Try to restart tracking after a delay
    Future.delayed(Duration(seconds: 5), () {
      if (_isTracking) {
        Logger.log("LiveTracking - Attempting to restart position stream");
        _startPositionStream();
      }
    });
  }

  /// Update merchant location in Firebase
  Future<void> _updateMerchantLocation(Position position) async {
    try {
      await _merchantService.updateMerchantLocation(
        position.latitude,
        position.longitude,
      );
      
      Logger.log("LiveTracking - Merchant location updated: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      Logger.error("LiveTracking - Failed to update merchant location", error: e);
      rethrow;
    }
  }

  /// Get current position with error handling
  Future<Position?> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: _trackingAccuracy,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      Logger.error("LiveTracking - Error getting current position", error: e);
      return null;
    }
  }

  

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Cleanup resources
  Future<void> dispose() async {
    await stopTracking();
    _lastKnownPosition = null;
  }
}