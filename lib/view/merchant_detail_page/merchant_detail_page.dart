import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:temulapak_app/utils/loading/loading.dart';
import 'package:temulapak_app/view/chat_page/chat_detail_page.dart';
import 'package:temulapak_app/view/chat_page/chat_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/product/product_model.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/merchant_detail_page/merchant_detail_viewmodel.dart';
import 'package:temulapak_app/view/widget/live_tracking_map.dart';
import 'package:temulapak_app/view/widget/location_update_indicator.dart';
import 'package:temulapak_app/view/widget/favorite_button.dart';
import 'package:temulapak_app/data/location/location_service.dart';
import 'package:flutter_svg/svg.dart';

class MerchantDetailPage extends ConsumerStatefulWidget {
  final MerchantModel merchant;

  const MerchantDetailPage({
    super.key,
    required this.merchant,
  });

  @override
  ConsumerState<MerchantDetailPage> createState() => _MerchantDetailPageState();
}

class _MerchantDetailPageState extends ConsumerState<MerchantDetailPage>
    with WidgetsBindingObserver {
  // ScrollController and map interaction state
  final ScrollController _scrollController = ScrollController();
  bool _isMapInteracting = false;

  // STEP 4: NEW - Distance state management
  double? _currentDistance;
  bool _isDistanceCalculating = false;

  // STEP 5: NEW - User location tracking
  Position? _currentUserLocation;
  StreamSubscription<Position>? _userLocationSubscription;
  Timer? _distanceRecalculationTimer;
  MerchantModel? _lastKnownMerchant;

  // STEP 6: NEW - Error handling & fallback state
  bool _hasLocationPermission = true;
  bool _isLocationServiceEnabled = true;
  int _distanceCalculationFailures = 0;
  Timer? _retryTimer;
  bool _isUsingFallbackDistance = false;

  // STEP 7: NEW - Performance optimization
  DateTime? _lastLocationUpdate;
  DateTime? _lastDistanceCalculation;
  Position? _cachedUserLocation;
  Timer? _locationCacheInvalidationTimer;
  bool _isAppInBackground = false;
  int _backgroundCalculationCount = 0;
  static const Duration _locationCacheTimeout = Duration(minutes: 2);
  static const Duration _minCalculationInterval = Duration(seconds: 3);
  static const int _maxBackgroundCalculations = 5;

  @override
  void initState() {
    super.initState();

    // STEP 4: Log initial state
    Logger.log(
        "DETAIL_PAGE - Step 4: Initializing with distance state management");

    // STEP 5: NEW - Initialize user location tracking
    Logger.log("DETAIL_PAGE - Step 5: Starting user location tracking");
    _initializeUserLocationTracking();

    // STEP 7: NEW - Initialize performance optimizations
    Logger.log("DETAIL_PAGE - Step 7: Enabling performance optimizations");
    _initializePerformanceOptimizations();

    // Initialize merchant detail
    Future.microtask(() {
      final notifier = ref.read(merchantDetailViewModelProvider.notifier);
      notifier.initializeMerchantDetail(widget.merchant);
    });
  }

  @override
  void dispose() {
    // STEP 5: NEW - Clean up user location tracking
    Logger.log("DETAIL_PAGE - Step 5: Disposing user location tracking");
    _userLocationSubscription?.cancel();
    _distanceRecalculationTimer?.cancel();

    // STEP 6: NEW - Clean up error handling timers
    _retryTimer?.cancel();

    // STEP 7: NEW - Clean up performance optimization timers
    _locationCacheInvalidationTimer?.cancel();

    // STEP 7: NEW - Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    _scrollController.dispose();
    super.dispose();
  }

  // STEP 7: NEW - Initialize performance optimizations
  void _initializePerformanceOptimizations() {
    // Start location cache invalidation timer
    _startLocationCacheInvalidation();

    // Initialize app lifecycle listener for background detection
    WidgetsBinding.instance.addObserver(this);

    Logger.log("DETAIL_PAGE - Step 7: Performance optimizations initialized");
  }

  // STEP 7: NEW - App lifecycle management for battery optimization
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
    _isAppInBackground = true;
    _backgroundCalculationCount = 0;
    Logger.log(
        "DETAIL_PAGE - Step 7: App backgrounded, reducing location activity");
  }

  void _handleAppForeground() {
    if (_isAppInBackground) {
      _isAppInBackground = false;
      Logger.log(
          "DETAIL_PAGE - Step 7: App foregrounded, resuming normal location activity");

      // Invalidate cache when returning to foreground for fresh data
      _invalidateLocationCache();
    }
  }

  // STEP 7: NEW - Start location cache invalidation timer
  void _startLocationCacheInvalidation() {
    _locationCacheInvalidationTimer?.cancel();
    _locationCacheInvalidationTimer =
        Timer.periodic(_locationCacheTimeout, (timer) {
      if (mounted) {
        _invalidateLocationCache();
      } else {
        timer.cancel();
      }
    });
  }

  // STEP 7: NEW - Invalidate location cache
  void _invalidateLocationCache() {
    if (_cachedUserLocation != null) {
      Logger.log(
          "DETAIL_PAGE - Step 7: Invalidating location cache after ${_locationCacheTimeout.inMinutes} minutes");
      _cachedUserLocation = null;
      _lastLocationUpdate = null;
    }
  }

  // STEP 7: NEW - Check if we should skip calculation for performance
  bool _shouldSkipCalculation() {
    // Skip if app is in background and we've done too many calculations
    if (_isAppInBackground) {
      _backgroundCalculationCount++;
      if (_backgroundCalculationCount > _maxBackgroundCalculations) {
        Logger.log(
            "DETAIL_PAGE - Step 7: Skipping calculation - too many background calculations");
        return true;
      }
    }

    // Skip if we calculated too recently
    if (_lastDistanceCalculation != null) {
      final timeSinceLastCalculation =
          DateTime.now().difference(_lastDistanceCalculation!);
      if (timeSinceLastCalculation < _minCalculationInterval) {
        Logger.log(
            "DETAIL_PAGE - Step 7: Skipping calculation - too recent (${timeSinceLastCalculation.inSeconds}s ago)");
        return true;
      }
    }

    return false;
  }

  // STEP 5: NEW - Initialize user location tracking
  Future<void> _initializeUserLocationTracking() async {
    try {
      Logger.log("DETAIL_PAGE - Step 5: Initializing user location tracking");

      // STEP 6: NEW - Check location permission and service status
      final permissionStatus = await _checkLocationStatus();
      if (!permissionStatus) {
        Logger.log(
            "DETAIL_PAGE - Step 6: Location not available, using fallback distance");
        _enableFallbackMode();
        return;
      }

      // STEP 7: NEW - Try to use cached location first for performance
      if (_cachedUserLocation != null && _lastLocationUpdate != null) {
        final cacheAge = DateTime.now().difference(_lastLocationUpdate!);
        if (cacheAge < _locationCacheTimeout) {
          Logger.log(
              "DETAIL_PAGE - Step 7: Using cached location (${cacheAge.inMinutes}m old)");
          _currentUserLocation = _cachedUserLocation;
          _startUserLocationStream();
          return;
        }
      }

      // Get initial user location
      final locationService = LocationService.instance;
      final initialPosition = await locationService.getCurrentLocation();

      if (initialPosition != null) {
        _currentUserLocation = initialPosition;

        // STEP 7: NEW - Cache the location
        _cachedUserLocation = initialPosition;
        _lastLocationUpdate = DateTime.now();

        Logger.log(
            "DETAIL_PAGE - Step 5: Initial user location: ${initialPosition.latitude}, ${initialPosition.longitude}");

        // Reset failure count on success
        _distanceCalculationFailures = 0;
        _isUsingFallbackDistance = false;

        // Start listening to location changes
        _startUserLocationStream();
      } else {
        Logger.log(
            "DETAIL_PAGE - Step 6: Could not get initial user location, enabling fallback");
        _enableFallbackMode();
      }
    } catch (e) {
      Logger.error(
          "DETAIL_PAGE - Step 6: Error initializing user location tracking",
          error: e);
      _handleLocationError(e);
    }
  }

  // STEP 6: NEW - Check location permission and service status
  Future<bool> _checkLocationStatus() async {
    try {
      // Check if location service is enabled
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_isLocationServiceEnabled) {
        Logger.log("DETAIL_PAGE - Step 6: Location service is disabled");
        return false;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      _hasLocationPermission = permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;

      if (!_hasLocationPermission) {
        Logger.log("DETAIL_PAGE - Step 6: Location permission denied");
        return false;
      }

      Logger.log("DETAIL_PAGE - Step 6: Location status check passed");
      return true;
    } catch (e) {
      Logger.error("DETAIL_PAGE - Step 6: Error checking location status",
          error: e);
      return false;
    }
  }

  // STEP 6: NEW - Enable fallback mode when location unavailable
  void _enableFallbackMode() {
    Logger.log("DETAIL_PAGE - Step 6: Enabling fallback distance mode");

    setState(() {
      _isUsingFallbackDistance = true;
      _isDistanceCalculating = false;
    });

    // Show user feedback about fallback mode
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Menggunakan perkiraan jarak (GPS tidak tersedia)"),
          backgroundColor: MyColor.orange,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // STEP 6: NEW - Handle location-related errors
  void _handleLocationError(Object error) {
    _distanceCalculationFailures++;
    Logger.error(
        "DETAIL_PAGE - Step 6: Location error #$_distanceCalculationFailures",
        error: error);

    // If too many failures, switch to fallback mode
    if (_distanceCalculationFailures >= 3) {
      Logger.log(
          "DETAIL_PAGE - Step 6: Too many location failures, switching to fallback mode");
      _enableFallbackMode();
      return;
    }

    // Try to recover after delay
    _scheduleLocationRetry();
  }

  // STEP 6: NEW - Schedule location retry with exponential backoff
  void _scheduleLocationRetry() {
    _retryTimer?.cancel();

    final retryDelay =
        Duration(seconds: 5 * _distanceCalculationFailures); // 5s, 10s, 15s
    Logger.log(
        "DETAIL_PAGE - Step 6: Scheduling location retry in ${retryDelay.inSeconds}s");

    _retryTimer = Timer(retryDelay, () {
      if (mounted && !_isUsingFallbackDistance) {
        Logger.log("DETAIL_PAGE - Step 6: Retrying location initialization");
        _initializeUserLocationTracking();
      }
    });
  }

  // STEP 5: NEW - Start user location stream
  void _startUserLocationStream() {
    try {
      Logger.log("DETAIL_PAGE - Step 5: Starting user location stream");

      // STEP 7: ENHANCED - Adaptive location settings based on app state
      final locationSettings = LocationSettings(
        accuracy: _isAppInBackground
            ? LocationAccuracy.medium
            : LocationAccuracy.high,
        distanceFilter:
            _isAppInBackground ? 20 : 10, // Less frequent updates in background
      );

      _userLocationSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          // STEP 7: NEW - Update cache on new location
          _cachedUserLocation = position;
          _lastLocationUpdate = DateTime.now();

          _handleUserLocationUpdate(position);
        },
        onError: (error) {
          Logger.error("DETAIL_PAGE - Step 6: User location stream error",
              error: error);
          _handleLocationError(error);
        },
      );

      Logger.log(
          "DETAIL_PAGE - Step 7: User location stream started with adaptive settings");
    } catch (e) {
      Logger.error("DETAIL_PAGE - Step 6: Error starting user location stream",
          error: e);
      _handleLocationError(e);
    }
  }

  // STEP 5: NEW - Handle user location updates
  void _handleUserLocationUpdate(Position newPosition) {
    Logger.log(
        "DETAIL_PAGE - Step 5: User location updated: ${newPosition.latitude}, ${newPosition.longitude}");

    // Calculate distance moved
    if (_currentUserLocation != null) {
      final distanceMoved = Geolocator.distanceBetween(
        _currentUserLocation!.latitude,
        _currentUserLocation!.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );

      Logger.log(
          "DETAIL_PAGE - Step 5: User moved ${distanceMoved.toStringAsFixed(2)} meters");

      // STEP 5: UPDATED - Use 20 meter threshold (consistent with LiveTrackingMap)
      if (distanceMoved > 20) {
        _currentUserLocation = newPosition;
        _scheduleDistanceRecalculation();
      } else {
        Logger.log(
            "DETAIL_PAGE - Step 5: Movement below 20m threshold, skipping recalculation");
      }
    } else {
      _currentUserLocation = newPosition;
      _scheduleDistanceRecalculation();
    }
  }

  // STEP 5: NEW - Schedule distance recalculation with debouncing
  void _scheduleDistanceRecalculation() {
    // STEP 7: NEW - Check if we should skip for performance
    if (_shouldSkipCalculation()) {
      return;
    }

    // Cancel previous timer if exists
    _distanceRecalculationTimer?.cancel();

    // STEP 7: ENHANCED - Adaptive debounce delay based on app state
    final debounceDelay = _isAppInBackground
        ? Duration(seconds: 10) // Longer delay in background
        : Duration(seconds: 2); // Normal delay in foreground

    Logger.log(
        "DETAIL_PAGE - Step 7: Scheduling distance recalculation in ${debounceDelay.inSeconds}s (background: $_isAppInBackground)");

    // Schedule recalculation with adaptive delay for debouncing
    _distanceRecalculationTimer = Timer(debounceDelay, () {
      if (mounted) {
        _recalculateDistanceFromUserMovement();
      }
    });
  }

  // STEP 5: NEW - Recalculate distance when user moves
  Future<void> _recalculateDistanceFromUserMovement() async {
    if (_currentUserLocation == null || _lastKnownMerchant == null) {
      Logger.log(
          "DETAIL_PAGE - Step 5: Cannot recalculate - missing user location or merchant data");
      return;
    }

    final merchant = _lastKnownMerchant!;
    if (merchant.merchantLocLat == null || merchant.merchantLocLong == null) {
      Logger.log(
          "DETAIL_PAGE - Step 5: Cannot recalculate - merchant has no location");
      return;
    }

    try {
      Logger.log(
          "DETAIL_PAGE - Step 5: Recalculating distance due to user movement");

      setState(() {
        _isDistanceCalculating = true;
      });

      // STEP 7: NEW - Record calculation time for performance tracking
      _lastDistanceCalculation = DateTime.now();

      // Calculate new distance
      final distance = Geolocator.distanceBetween(
            _currentUserLocation!.latitude,
            _currentUserLocation!.longitude,
            merchant.merchantLocLat!,
            merchant.merchantLocLong!,
          ) /
          1000; // Convert to kilometers

      Logger.log(
          "DETAIL_PAGE - Step 7: Distance calculated (background: $_isAppInBackground): ${distance.toStringAsFixed(4)} km");

      // Update state
      if (mounted) {
        setState(() {
          _currentDistance = distance;
          _isDistanceCalculating = false;

          // STEP 6: NEW - Reset error state on successful calculation
          _distanceCalculationFailures = 0;
          _isUsingFallbackDistance = false;
        });

        Logger.log(
            "DETAIL_PAGE - Step 5: Distance updated due to user movement");
      }
    } catch (e) {
      Logger.error(
          "DETAIL_PAGE - Step 6: Error recalculating distance from user movement",
          error: e);

      // STEP 6: NEW - Handle calculation error
      _handleLocationError(e);

      if (mounted) {
        setState(() {
          _isDistanceCalculating = false;
        });
      }
    }
  }

  String _getMerchantId(MerchantModel merchant) {
    return "MRCN_${merchant.uid}";
  }

  // STEP 4: NEW - Distance update callback handler
  void _handleDistanceUpdate(double? newDistance) {
    Logger.log(
        "DETAIL_PAGE - Step 4: Distance update received: ${newDistance?.toStringAsFixed(4)} km");

    if (mounted) {
      setState(() {
        _currentDistance = newDistance;
        _isDistanceCalculating = false;

        // STEP 6: NEW - Reset failure count on successful distance update
        if (newDistance != null) {
          _distanceCalculationFailures = 0;
          _isUsingFallbackDistance = false;
        }
      });

      Logger.log("DETAIL_PAGE - Step 4: Distance state updated successfully");
    } else {
      Logger.log(
          "DETAIL_PAGE - Step 4: Widget not mounted, skipping distance update");
    }
  }

  // STEP 4: NEW - Get display distance (prioritize live distance over static)
  double? _getDisplayDistance(Map<String, dynamic>? detailData) {
    // STEP 6: NEW - Show fallback indicator if using fallback distance
    if (_isUsingFallbackDistance && detailData != null) {
      final staticDistance = detailData['distance'] as double?;
      if (staticDistance != null) {
        Logger.log(
            "DETAIL_PAGE - Step 6: Using fallback static distance: ${staticDistance.toStringAsFixed(4)} km");
        return staticDistance;
      }
    }

    // Prioritize live calculated distance over initial static distance
    if (_currentDistance != null) {
      Logger.log(
          "DETAIL_PAGE - Step 4: Using live distance: ${_currentDistance!.toStringAsFixed(4)} km");
      return _currentDistance;
    }

    // Fallback to initial calculated distance from ViewModel
    final staticDistance = detailData?['distance'] as double?;
    if (staticDistance != null) {
      Logger.log(
          "DETAIL_PAGE - Step 4: Using static distance: ${staticDistance.toStringAsFixed(4)} km");
      return staticDistance;
    }

    Logger.log("DETAIL_PAGE - Step 4: No distance available");
    return null;
  }

  // Map interaction handlers
  void _disableParentScroll() {
    if (!_isMapInteracting) {
      setState(() {
        _isMapInteracting = true;
      });
      Logger.log("MAP_INTERACTION - Parent scroll disabled");
    }
  }

  void _enableParentScroll() {
    if (_isMapInteracting) {
      setState(() {
        _isMapInteracting = false;
      });
      Logger.log("MAP_INTERACTION - Parent scroll enabled");
    }
  }

  Future<void> _openInGoogleMaps(
      double latitude, double longitude, String? merchantName) async {
    try {
      Logger.log("Opening location in Google Maps: $latitude, $longitude");

      String url;
      if (Platform.isIOS) {
        url = "comgooglemaps://?center=$latitude,$longitude&zoom=16";

        if (!await canLaunchUrl(Uri.parse(url))) {
          url = "http://maps.apple.com/?q=$latitude,$longitude";
        }
      } else {
        url =
            "geo:$latitude,$longitude?q=$latitude,$longitude(${merchantName ?? 'Merchant'})";
      }

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Logger.log("Successfully opened Google Maps");
      } else {
        final webUrl =
            "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";
        await launchUrl(Uri.parse(webUrl),
            mode: LaunchMode.externalApplication);
        Logger.log("Opened web Google Maps as fallback");
      }
    } catch (e) {
      Logger.error("Error opening Google Maps", error: e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Tidak dapat membuka Google Maps"),
            backgroundColor: MyColor.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(merchantDetailViewModelProvider);

    return Scaffold(
      backgroundColor: MyColor.whitePlain,
      body: Stack(
        children: [
          // Main scrollable content - WITH SMART SCROLL PHYSICS
          detailState.when(
            idle: () => _buildLoadingState(),
            loading: () => _buildLoadingState(),
            success: (detailData) => _buildDetailContent(detailData),
            error: (error, message) => _buildErrorState(message),
          ),

          // Floating controls - Always on top
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Favorite Button
                FavoriteButton.floating(
                  merchant: widget.merchant,
                  showFeedback: true,
                  onToggle: () {
                    Logger.log(
                        "Favorite toggled for ${widget.merchant.merchantName}");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      // Floating Chat Button
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: MyColor.orange,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: MyColor.orange.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () {
            Logger.log(
                "Chat button clicked for ${widget.merchant.merchantName}");
            _handleChatButtonPressed();
          },
          icon: Icon(
            Icons.chat,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildDetailContent(Map<String, dynamic> detailData) {
    final merchant = detailData['merchant'] as MerchantModel;

    // STEP 5: NEW - Store current merchant for user location recalculation
    _lastKnownMerchant = merchant;

    // STEP 4: NEW - Use _getDisplayDistance instead of direct access
    final distance = _getDisplayDistance(detailData);

    final totalProducts = detailData['totalProducts'] as int;
    final hasLocation = detailData['hasLocation'] as bool;
    final priceRangeText = detailData['priceRangeText'] as String;

    return SingleChildScrollView(
      controller: _scrollController,
      // Smart scroll physics based on map interaction
      physics: _isMapInteracting
          ? NeverScrollableScrollPhysics()
          : AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Image - Scrollable
          SizedBox(
            height: 300,
            width: double.infinity,
            child: merchant.merchantImgUrl != null &&
                    merchant.merchantImgUrl!.isNotEmpty
                ? Image.network(
                    merchant.merchantImgUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderImage();
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildLoadingImage();
                    },
                  )
                : _buildPlaceholderImage(),
          ),

          // Content Container
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Merchant Name & Categories
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Merchant Name
                      Text(
                        merchant.merchantName ?? 'Merchant',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: MyColor.blackPlain,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Categories
                      if (merchant.merchantCategory != null &&
                          merchant.merchantCategory!.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: merchant.merchantCategory!.map((category) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: MyColor.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: MyColor.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: MyColor.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Status Badge with Location Update Indicator
                      Row(
                        children: [
                          // Merchant Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: merchant.merchantStatus
                                  ? Colors.green
                                  : Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              merchant.merchantStatus ? 'BUKA' : 'TUTUP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Location Update Indicator
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('merchant')
                                .doc(_getMerchantId(merchant))
                                .snapshots(),
                            builder: (context, snapshot) {
                              DateTime lastUpdate = DateTime.now();
                              ConnectionStatus status = ConnectionStatus.live;

                              if (snapshot.hasError) {
                                status = ConnectionStatus.offline;
                                lastUpdate = DateTime.now()
                                    .subtract(Duration(minutes: 10));
                              } else if (!snapshot.hasData ||
                                  !snapshot.data!.exists) {
                                status = ConnectionStatus.offline;
                                lastUpdate = DateTime.now()
                                    .subtract(Duration(minutes: 5));
                              } else if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                status = ConnectionStatus.recent;
                                lastUpdate = DateTime.now()
                                    .subtract(Duration(seconds: 30));
                              } else {
                                final data = snapshot.data!.data()
                                    as Map<String, dynamic>?;
                                if (data != null) {
                                  final lat = data['merchantLocLat'];
                                  final lng = data['merchantLocLong'];

                                  if (lat != null && lng != null) {
                                    status = ConnectionStatus.live;
                                    lastUpdate = DateTime.now();
                                  } else {
                                    status = ConnectionStatus.recent;
                                    lastUpdate = DateTime.now()
                                        .subtract(Duration(minutes: 1));
                                  }
                                }
                              }

                              return LocationUpdateIndicator(
                                lastUpdate: lastUpdate,
                                status: status,
                                compact: true,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // STEP 4: ENHANCED - Map Section with distance callback
                if (hasLocation) ...[
                  GestureDetector(
                    onPanDown: (_) {
                      _disableParentScroll();
                      // STEP 4: NEW - Set calculating state when user interacts
                      setState(() {
                        _isDistanceCalculating = true;
                      });
                    },
                    onPanEnd: (_) => _enableParentScroll(),
                    onPanCancel: () => _enableParentScroll(),
                    onTapDown: (_) => _disableParentScroll(),
                    onTapUp: (_) => _enableParentScroll(),
                    onTapCancel: () => _enableParentScroll(),
                    child: SizedBox(
                      height: 250,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LiveTrackingMap(
                          merchantId: _getMerchantId(merchant),
                          initialMerchant: merchant,
                          // STEP 4: NEW - Pass distance update callback
                          onDistanceUpdate: _handleDistanceUpdate,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // STEP 4: ENHANCED - Info Cards with live distance
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Combined Price Range & Distance Card
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: MyColor.orange),
                          ),
                          child: Row(
                            children: [
                              // Price Range
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      _formatPriceRange(priceRangeText),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: MyColor.blackPlain,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Kisaran harga",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: MyColor.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),

                              // Divider
                              Container(
                                height: 40,
                                width: 1,
                                color: MyColor.orange,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 12),
                              ),

                              // STEP 4: ENHANCED - Distance with live updates and loading state
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Distance value with loading indicator
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (_isDistanceCalculating) ...[
                                          SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      MyColor.orange),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(
                                          distance != null
                                              ? "${distance.toStringAsFixed(2)} km"
                                              : "- km",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: distance != null
                                                ? MyColor.blackPlain
                                                : Colors.grey[400],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Jarak",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: distance != null
                                                ? MyColor.orange
                                                : Colors.grey[400],
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        // STEP 6: ENHANCED - Show appropriate indicator based on mode
                                        if (distance != null &&
                                            !_isDistanceCalculating) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: _isUsingFallbackDistance
                                                  ? Colors
                                                      .orange // Fallback mode
                                                  : Colors.green, // Live mode
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                        // STEP 6: NEW - Show error indicator if location issues
                                        if (!_hasLocationPermission ||
                                            !_isLocationServiceEnabled) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.location_off,
                                            size: 10,
                                            color: Colors.red,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 5),

                      // Google Maps Button
                      if (hasLocation)
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () => _openInGoogleMaps(
                              merchant.merchantLocLat!,
                              merchant.merchantLocLong!,
                              merchant.merchantName,
                            ),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: MyColor.orange),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Buka di",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: MyColor.blackPlain,
                                          ),
                                        ),
                                        Text(
                                          "Google Maps",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: MyColor.orange,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: SvgPicture.asset(
                                        "lib/assets/icons/pin_icon.svg",
                                        width: 20,
                                        height: 20,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Description
                if (merchant.merchantDesc != null &&
                    merchant.merchantDesc!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Deskripsi",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: MyColor.blackPlain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          merchant.merchantDesc!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Products Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Produk ($totalProducts)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: MyColor.blackPlain,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Products List
                      if (merchant.products != null &&
                          merchant.products!.isNotEmpty)
                        ...merchant.products!
                            .map((product) => _buildProductItem(product))
                      else
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: MyColor.lightGrey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Belum ada produk tersedia",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 100), // Space for floating action button
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Format price range to use "k" for thousands
  String _formatPriceRange(String priceRangeText) {
    return priceRangeText.replaceAllMapped(RegExp(r'(\d+)\.000'), (match) {
      return '${match.group(1)}k';
    }).replaceAllMapped(RegExp(r'(\d+)\.(\d+)00'), (match) {
      String beforeDot = match.group(1)!;
      String afterDot = match.group(2)!;
      if (afterDot == '0') {
        return '${beforeDot}k';
      } else {
        return '$beforeDot.${afterDot}k';
      }
    });
  }

  Widget _buildProductItem(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: MyColor.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.fastfood,
              color: MyColor.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName ?? 'Produk',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MyColor.blackPlain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Rp ${product.productPrice ?? '0'}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: MyColor.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: _isMapInteracting
          ? NeverScrollableScrollPhysics()
          : AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 300,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 32,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 20,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? message) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Detail Merchant"),
        backgroundColor: MyColor.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: MyColor.red,
              ),
              const SizedBox(height: 24),
              Text(
                "Gagal Memuat Detail",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: MyColor.blackPlain,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message ?? "Terjadi kesalahan saat memuat detail merchant",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  final notifier =
                      ref.read(merchantDetailViewModelProvider.notifier);
                  notifier.refreshMerchantDetail(widget.merchant);
                },
                icon: Icon(Icons.refresh),
                label: Text("Coba Lagi"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColor.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[200],
      child: Icon(
        Icons.store,
        color: Colors.grey[400],
        size: 64,
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
      ),
    );
  }

  void _handleChatButtonPressed() async {
  try {
    Logger.log("MERCHANT_DETAIL - Starting chat with: ${widget.merchant.merchantName}");
    
    // Show loading indicator
    Loading.show(context);
    
    // Start chat using the chat actions viewmodel
    final conversationId = await ref.read(chatActionsViewModelProvider.notifier)
        .startChat(widget.merchant);
    
    Loading.hide();
    
    if (conversationId != null && mounted) {
      // Navigate to chat detail page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            conversationId: conversationId,
          ),
        ),
      );
      
      Logger.log("MERCHANT_DETAIL - Chat opened successfully: $conversationId");
      
      // Optional: Show success feedback
      _showChatSuccessMessage("Chat dengan ${widget.merchant.merchantName} dimulai");
      
    } else {
      _showChatErrorMessage("Gagal memulai chat dengan ${widget.merchant.merchantName}");
    }
    
  } catch (e) {
    Loading.hide();
    Logger.error("MERCHANT_DETAIL - Error starting chat", error: e);
    
    // Show user-friendly error message
    if (e.toString().contains('authenticated')) {
      _showChatErrorMessage("Silakan login terlebih dahulu untuk memulai chat");
    } else {
      _showChatErrorMessage("Gagal memulai chat. Silakan coba lagi.");
    }
  }
}

  void _showChatSuccessMessage(String message) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Show error message for chat
void _showChatErrorMessage(String message) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: MyColor.red,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Coba Lagi',
          textColor: Colors.white,
          onPressed: _handleChatButtonPressed,
        ),
      ),
    );
  }
}
}
