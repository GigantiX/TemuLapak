// File: lib/view/widget/live_tracking_map.dart
// STEP 2: Add distance calculation functionality

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/merchant_detail_page/merchant_detail_viewmodel.dart';
import 'package:temulapak_app/view/widget/location_update_indicator.dart';

class LiveTrackingMap extends ConsumerStatefulWidget {
  final String merchantId;
  final MerchantModel initialMerchant;
  
  // STEP 1: NEW - Add callback for distance updates
  final Function(double?)? onDistanceUpdate;

  const LiveTrackingMap({
    super.key,
    required this.merchantId,
    required this.initialMerchant,
    this.onDistanceUpdate, // STEP 1: NEW parameter
  });

  @override
  ConsumerState<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends ConsumerState<LiveTrackingMap>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  DateTime _lastUpdateTime = DateTime.now();
  ConnectionStatus _connectionStatus = ConnectionStatus.live;

  // Animation Controllers
  late AnimationController _markerAnimationController;
  late Animation<double> _markerAnimation;
  
  // Current and target positions for smooth animation
  LatLng? _currentPosition;
  LatLng? _targetPosition;
  bool _isAnimating = false;

  // ✨ Debouncing variables
  Timer? _debounceTimer;
  MerchantModel? _pendingMerchantUpdate;
  
  // ✨ Distance tracking for optimization
  int _totalUpdates = 0;
  int _skippedUpdates = 0;
  
  // ✨ Background state management
  bool _isInBackground = false;
  StreamSubscription? _merchantStreamSubscription;
  
  // ✨ Memory leak prevention
  Timer? _connectionTimer;
  Timer? _memoryCheckTimer;
  Timer? _retryTimer;
  bool _isDisposed = false;
  final List<StreamSubscription> _subscriptions = [];
  
  // ✨ Connection recovery
  int _retryAttempts = 0;
  bool _isRetrying = false;
  
  // Configuration constants
  static const Duration _debounceDelay = Duration(milliseconds: 500);
  static const double _distanceThreshold = 0.02; // 20 meters in km
  static const Duration _memoryCheckInterval = Duration(minutes: 2);
  static const int _maxRetryAttempts = 5;
  static const Duration _baseRetryDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    
    // STEP 1: Log callback availability for debugging
    Logger.log("LIVE_MAP - Step 1: Distance callback ${widget.onDistanceUpdate != null ? 'provided' : 'not provided'}");
    
    // ✨ Add lifecycle observer for background/foreground detection
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize animation controller for marker movement
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _markerAnimation = CurvedAnimation(
      parent: _markerAnimationController,
      curve: Curves.easeInOut,
    );

    // Initialize with merchant's initial position
    if (widget.initialMerchant.merchantLocLat != null && 
        widget.initialMerchant.merchantLocLong != null) {
      _currentPosition = LatLng(
        widget.initialMerchant.merchantLocLat!, 
        widget.initialMerchant.merchantLocLong!
      );
      _targetPosition = _currentPosition;
    }

    _initializeMarkers(widget.initialMerchant);
    _markerAnimation.addListener(_updateMarkerPosition);
    
    // ✨ Start memory monitoring
    _startMemoryMonitoring();
    
    Logger.log("LIVE_MAP - Initialized with distance callback support");
  }

  // ... [Rest of the existing methods remain unchanged] ...
  // App lifecycle management for battery optimization
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _handleAppBackground();
        break;
      case AppLifecycleState.resumed:
        _handleAppForeground();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _handleAppBackground() {
    if (!_isInBackground) {
      _isInBackground = true;
      Logger.log("LIVE_MAP - App moved to background, pausing live tracking for battery optimization");
      _debounceTimer?.cancel();
    }
  }

  void _handleAppForeground() {
    if (_isInBackground) {
      _isInBackground = false;
      Logger.log("LIVE_MAP - App moved to foreground, resuming live tracking");
      if (_pendingMerchantUpdate != null) {
        Logger.log("LIVE_MAP - Processing pending update from background");
        _processPendingUpdate();
      }
    }
  }

  void _startMemoryMonitoring() {
    _memoryCheckTimer?.cancel();
    _memoryCheckTimer = Timer.periodic(_memoryCheckInterval, (timer) {
      if (!_isDisposed && mounted) {
        _performMemoryCheck();
      } else {
        timer.cancel();
      }
    });
  }

  void _performMemoryCheck() {
    final hasActiveTimers = _debounceTimer?.isActive == true || 
                           _connectionTimer?.isActive == true ||
                           _memoryCheckTimer?.isActive == true;
    
    final hasActiveSubscriptions = _subscriptions.any((sub) => !sub.isPaused);
    final hasActiveAnimations = _markerAnimationController.isAnimating;
    
    Logger.log("LIVE_MAP - Memory check: Timers: $hasActiveTimers, Subscriptions: $hasActiveSubscriptions, Animations: $hasActiveAnimations");
    
    if (_subscriptions.length > 5) {
      Logger.log("LIVE_MAP - WARNING: High subscription count: ${_subscriptions.length}");
    }
  }

  Timer? _safeStartTimer(Duration duration, VoidCallback callback) {
    if (!_isDisposed && mounted) {
      return Timer(duration, callback);
    }
    return null;
  }

  void _cancelAllSubscriptions() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    Logger.log("LIVE_MAP - All subscriptions cancelled: ${_subscriptions.length} items");
  }

  void _handleConnectionError(Object error) {
    Logger.error("LIVE_MAP - Connection error", error: error);
    
    setState(() {
      _connectionStatus = ConnectionStatus.offline;
    });

    if (_retryAttempts < _maxRetryAttempts && !_isInBackground && !_isRetrying) {
      _startRetrySequence();
    } else if (_retryAttempts >= _maxRetryAttempts) {
      Logger.log("LIVE_MAP - Max retry attempts reached ($_maxRetryAttempts), stopping recovery");
    } else if (_isInBackground) {
      Logger.log("LIVE_MAP - Skipping retry, app in background");
    }
  }

  void _startRetrySequence() {
    _isRetrying = true;
    _retryAttempts++;
    
    final delay = Duration(seconds: min(pow(2, _retryAttempts).toInt() * _baseRetryDelay.inSeconds, 30));
    
    Logger.log("LIVE_MAP - Starting retry attempt $_retryAttempts/$_maxRetryAttempts in ${delay.inSeconds}s");
    
    setState(() {
      _connectionStatus = ConnectionStatus.offline;
    });
    
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (!_isDisposed && mounted && !_isInBackground) {
        _attemptConnectionRecovery();
      } else {
        _isRetrying = false;
      }
    });
  }

  void _attemptConnectionRecovery() {
    Logger.log("LIVE_MAP - Attempting connection recovery (attempt $_retryAttempts)");
    
    setState(() {
      _connectionStatus = ConnectionStatus.recent;
    });
    
    Timer(Duration(seconds: 3), () {
      if (!_isDisposed && mounted) {
        _checkRecoverySuccess();
      }
    });
  }

  void _checkRecoverySuccess() {
    final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime);
    
    if (timeSinceLastUpdate.inSeconds < 10) {
      _onConnectionRecovered();
    } else {
      _onConnectionRecoveryFailed();
    }
  }

  void _onConnectionRecovered() {
    Logger.log("LIVE_MAP - Connection recovery successful! (attempt $_retryAttempts)");
    
    _retryAttempts = 0;
    _isRetrying = false;
    
    setState(() {
      _connectionStatus = ConnectionStatus.live;
    });
  }

  void _onConnectionRecoveryFailed() {
    Logger.log("LIVE_MAP - Connection recovery failed (attempt $_retryAttempts)");
    _isRetrying = false;
    
    if (_retryAttempts < _maxRetryAttempts && !_isInBackground) {
      _startRetrySequence();
    } else {
      setState(() {
        _connectionStatus = ConnectionStatus.offline;
      });
    }
  }

  void _onSuccessfulUpdate() {
    if (_retryAttempts > 0) {
      Logger.log("LIVE_MAP - Resetting retry attempts after successful update");
      _retryAttempts = 0;
      _isRetrying = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    
    if (_totalUpdates > 0) {
      final efficiency = (_skippedUpdates / _totalUpdates * 100).toStringAsFixed(1);
      Logger.log("LIVE_MAP - Final stats: $_totalUpdates updates, $_skippedUpdates skipped ($efficiency% efficiency)");
    }
    
    _debounceTimer?.cancel();
    _connectionTimer?.cancel();
    _memoryCheckTimer?.cancel();
    _retryTimer?.cancel();
    
    _cancelAllSubscriptions();
    _merchantStreamSubscription?.cancel();
    
    if (_markerAnimationController.isAnimating) {
      _markerAnimationController.stop();
    }
    _markerAnimationController.dispose();
    
    _mapController?.dispose();
    
    _markers.clear();
    _pendingMerchantUpdate = null;
    
    Logger.log("LIVE_MAP - Step 1: All resources disposed safely with distance callback support");
    super.dispose();
  }

  void _initializeMarkers(MerchantModel merchant) {
    if (merchant.merchantLocLat == null || merchant.merchantLocLong == null) {
      return;
    }

    final position = _currentPosition ?? LatLng(merchant.merchantLocLat!, merchant.merchantLocLong!);

    _markers = {
      Marker(
        markerId: MarkerId(widget.merchantId),
        position: position,
        infoWindow: InfoWindow(
          title: merchant.merchantName ?? 'Merchant',
          snippet: merchant.merchantStatus ? 'BUKA' : 'TUTUP',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          merchant.merchantStatus ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
      )
    };
    
    Logger.log("LIVE_MAP - Markers initialized for ${merchant.merchantName} at $position");
  }

  void _updateMarkerPosition() {
    if (_currentPosition == null || _targetPosition == null || !mounted || _isDisposed) return;

    final lat = _currentPosition!.latitude + 
        (_targetPosition!.latitude - _currentPosition!.latitude) * _markerAnimation.value;
    final lng = _currentPosition!.longitude + 
        (_targetPosition!.longitude - _currentPosition!.longitude) * _markerAnimation.value;

    final interpolatedPosition = LatLng(lat, lng);

    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId(widget.merchantId),
          position: interpolatedPosition,
          infoWindow: InfoWindow(
            title: widget.initialMerchant.merchantName ?? 'Merchant',
            snippet: widget.initialMerchant.merchantStatus ? 'BUKA' : 'TUTUP',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            widget.initialMerchant.merchantStatus ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
        )
      };
    });
  }

  void _handleMerchantLocationUpdate(MerchantModel merchant) {
    if (merchant.merchantLocLat == null || merchant.merchantLocLong == null) {
      Logger.log("LIVE_MAP - Cannot update: coordinates are null");
      return;
    }

    if (_isInBackground) {
      Logger.log("LIVE_MAP - Skipping update, app in background (battery optimization)");
      return;
    }

    final newPosition = LatLng(merchant.merchantLocLat!, merchant.merchantLocLong!);
    _totalUpdates++;

    if (_currentPosition != null) {
      final distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude, 
        newPosition.latitude,
        newPosition.longitude,
      );
      
      if (distance < _distanceThreshold) {
        _skippedUpdates++;
        final skipPercentage = (_skippedUpdates / _totalUpdates * 100).toStringAsFixed(1);
        Logger.log("LIVE_MAP - Skipping update, distance below threshold: ${distance.toStringAsFixed(4)} km ($skipPercentage% efficiency)");
        return;
      } else {
        Logger.log("LIVE_MAP - Distance above threshold: ${distance.toStringAsFixed(4)} km - proceeding with update");
      }
    }

    _pendingMerchantUpdate = merchant;
    _debounceTimer?.cancel();
    
    Logger.log("LIVE_MAP - Scheduling debounced update in ${_debounceDelay.inMilliseconds}ms");
    
    _debounceTimer = _safeStartTimer(_debounceDelay, () {
      if (!_isDisposed && mounted) {
        _processPendingUpdate();
      }
    });
  }

  void _processPendingUpdate() {
    if (_pendingMerchantUpdate == null || _isDisposed || !mounted) return;
    
    final merchant = _pendingMerchantUpdate!;
    _pendingMerchantUpdate = null;
    
    Logger.log("LIVE_MAP - Processing debounced update for ${merchant.merchantName}");
    
    _animateMarkerToNewPosition(merchant);
  }

  void _animateMarkerToNewPosition(MerchantModel merchant) {
    if (merchant.merchantLocLat == null || merchant.merchantLocLong == null) {
      Logger.log("LIVE_MAP - Cannot animate marker: coordinates are null");
      return;
    }

    final newPosition = LatLng(merchant.merchantLocLat!, merchant.merchantLocLong!);

    if (_currentPosition != null) {
      final distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude, 
        newPosition.latitude,
        newPosition.longitude,
      );
      
      Logger.log("LIVE_MAP - Animating to new position, distance: ${distance.toStringAsFixed(4)} km");
    }

    _currentPosition = _currentPosition ?? newPosition;
    _targetPosition = newPosition;
    _isAnimating = true;

    Logger.log("LIVE_MAP - Starting smooth animation from $_currentPosition to $_targetPosition");

    _markerAnimationController.reset();
    _markerAnimationController.forward().then((_) {
      _currentPosition = _targetPosition;
      _isAnimating = false;
      Logger.log("LIVE_MAP - Animation completed at $_currentPosition");
      
      // STEP 2: NEW - Calculate and notify distance after animation completes
      Logger.log("LIVE_MAP - Step 2: About to call _calculateAndNotifyDistance");
      _calculateAndNotifyDistance(merchant);
    });

    setState(() {
      _lastUpdateTime = DateTime.now();
      _connectionStatus = ConnectionStatus.live;
    });

    _onSuccessfulUpdate();

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(newPosition),
    );
  }

  // STEP 2: NEW - Calculate distance to user and notify via callback
  Future<void> _calculateAndNotifyDistance(MerchantModel merchant) async {
    // Skip if no callback provided
    if (widget.onDistanceUpdate == null) {
      Logger.log("LIVE_MAP - Step 2: No distance callback, skipping calculation");
      return;
    }

    // Skip if merchant has no location
    if (merchant.merchantLocLat == null || merchant.merchantLocLong == null) {
      Logger.log("LIVE_MAP - Step 2: Merchant location null, cannot calculate distance");
      widget.onDistanceUpdate!(null);
      return;
    }

    try {
      Logger.log("LIVE_MAP - Step 2: Starting distance calculation");
      
      // Import LocationServices
      final locationService = ref.read(locationServicesDetailProvider);
      final userPosition = await locationService.getCurrentLocation();
      
      if (userPosition == null) {
        Logger.log("LIVE_MAP - Step 2: User location not available");
        widget.onDistanceUpdate!(null);
        return;
      }

      Logger.log("LIVE_MAP - Step 2: User position: ${userPosition.latitude}, ${userPosition.longitude}");
      Logger.log("LIVE_MAP - Step 2: Merchant position: ${merchant.merchantLocLat}, ${merchant.merchantLocLong}");
      
      // Calculate distance using existing method
      final distance = _calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        merchant.merchantLocLat!,
        merchant.merchantLocLong!,
      );
      
      Logger.log("LIVE_MAP - Step 2: Calculated distance: ${distance.toStringAsFixed(4)} km");
      
      // Notify parent via callback
      widget.onDistanceUpdate!(distance);
      
    } catch (e) {
      Logger.error("LIVE_MAP - Step 2: Error calculating distance", error: e);
      widget.onDistanceUpdate!(null);
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    
    double dLat = (lat2 - lat1) * (3.14159 / 180);
    double dLon = (lon2 - lon1) * (3.14159 / 180);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * 3.14159 / 180) * cos(lat2 * 3.14159 / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  void _updateConnectionStatus() {
    final now = DateTime.now();
    final timeDifference = now.difference(_lastUpdateTime);

    ConnectionStatus newStatus;
    if (timeDifference.inSeconds < 60) {
      newStatus = ConnectionStatus.live;
    } else if (timeDifference.inMinutes < 5) {
      newStatus = ConnectionStatus.recent;
    } else {
      newStatus = ConnectionStatus.offline;
    }

    if (newStatus != _connectionStatus) {
      setState(() {
        _connectionStatus = newStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchantStream = ref.watch(merchantLiveStreamProvider(widget.merchantId));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateConnectionStatus();
    });

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: merchantStream.when(
          data: (merchant) {
            if (merchant == null) {
              setState(() {
                _connectionStatus = ConnectionStatus.offline;
              });
              return _buildErrorMap("Merchant tidak ditemukan");
            }

            if (merchant.merchantLocLat == null || merchant.merchantLocLong == null) {
              return _buildNoLocationMap();
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isAnimating) {
                _handleMerchantLocationUpdate(merchant);
              }
            });

            return _buildGoogleMap(merchant);
          },
          loading: () => _buildLoadingMap(),
          error: (error, stack) {
            Logger.error("LIVE_MAP - Stream error", error: error);
            _handleConnectionError(error);
            return _buildErrorMap("Gagal memuat lokasi");
          },
        ),
      ),
    );
  }

  Widget _buildGoogleMap(MerchantModel merchant) {
    final initialPosition = _currentPosition ?? 
        LatLng(merchant.merchantLocLat!, merchant.merchantLocLong!);

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 16,
      ),
      markers: _markers,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        Logger.log("LIVE_MAP - Google Map created successfully");
      },
      onCameraIdle: () {
        Logger.log("LIVE_MAP - Camera movement stopped");
      },
      onTap: (LatLng position) {
        Logger.log("LIVE_MAP - Map tapped at: $position");
      },
      myLocationButtonEnabled: false,    
      myLocationEnabled: false,        
      compassEnabled: false,             
      mapToolbarEnabled: false,        
      zoomControlsEnabled: false,       
      rotateGesturesEnabled: false,      
      scrollGesturesEnabled: false,      
      tiltGesturesEnabled: false,     
      zoomGesturesEnabled: false,      
    );
  }

  Widget _buildLoadingMap() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: MyColor.orange, strokeWidth: 2),
            const SizedBox(height: 12),
            Text("Memuat peta...", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLocationMap() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text("Lokasi tidak tersedia", style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text("Merchant belum mengatur lokasi", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMap(String message) {
    return Container(
      color: MyColor.red.withValues(alpha: 0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: MyColor.red),
            const SizedBox(height: 12),
            Text("Error", style: TextStyle(color: MyColor.red, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(message, style: TextStyle(color: MyColor.red, fontSize: 12), textAlign: TextAlign.center),
            
            if (_connectionStatus == ConnectionStatus.offline) ...[
              const SizedBox(height: 8),
              if (_isRetrying) ...[
                Text(
                  "Mencoba koneksi ulang... ($_retryAttempts/$_maxRetryAttempts)",
                  style: TextStyle(color: MyColor.orange, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(MyColor.orange),
                  ),
                ),
              ] else if (_retryAttempts < _maxRetryAttempts) ...[
                TextButton(
                  onPressed: () {
                    _retryAttempts = 0;
                    _handleConnectionError(Exception("Manual retry"));
                  },
                  child: Text(
                    "Coba Lagi",
                    style: TextStyle(color: MyColor.orange, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ] else ...[
                Text(
                  "Koneksi gagal setelah $_maxRetryAttempts percobaan",
                  style: TextStyle(color: MyColor.red, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}