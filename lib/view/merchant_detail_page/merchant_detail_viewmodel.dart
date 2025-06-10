import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:temulapak_app/data/location/location_service.dart';
import 'package:temulapak_app/model/merchant/merchant_model.dart';
import 'package:temulapak_app/model/state/app_state.dart';
import 'package:temulapak_app/view/chat_page/chat_detail_page.dart';
import 'package:temulapak_app/view/chat_page/chat_viewmodel.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'dart:math';

part 'merchant_detail_viewmodel.g.dart';

@riverpod
LocationService locationServicesDetail(Ref ref) {
  return LocationService.instance;
}

@riverpod
Stream<MerchantModel?> merchantLiveStream(Ref ref, String merchantId) {
  return FirebaseFirestore.instance
      .collection('merchant')
      .doc(merchantId)
      .snapshots()
      .map((documentSnapshot) {
    
    if (!documentSnapshot.exists) {
      return null;
    }
    
    try {
      final data = documentSnapshot.data() as Map<String, dynamic>;
      final merchant = MerchantModel.fromMap(data);
      return merchant;
      
    } catch (e) {
      Logger.error("STREAM - Error parsing merchant data", error: e);
      return null;
    }
  }).handleError((error) {
    Logger.error("STREAM - Firebase stream error", error: error);
    throw Exception("Failed to load merchant data: $error");
  });
}

class EnhancedMerchantDetailState {
  final Map<String, dynamic>? detailData;
  final double? currentDistance;
  final bool isDistanceCalculating;
  final Position? currentUserLocation;
  final MerchantModel? lastKnownMerchant;
  final bool hasLocationPermission;
  final bool isLocationServiceEnabled;
  final int distanceCalculationFailures;
  final bool isUsingFallbackDistance;
  final DateTime? lastLocationUpdate;
  final DateTime? lastDistanceCalculation;
  final Position? cachedUserLocation;
  final bool isAppInBackground;
  final int backgroundCalculationCount;
  final ViewModelCommand? command;

  const EnhancedMerchantDetailState({
    this.detailData,
    this.currentDistance,
    this.isDistanceCalculating = false,
    this.currentUserLocation,
    this.lastKnownMerchant,
    this.hasLocationPermission = true,
    this.isLocationServiceEnabled = true,
    this.distanceCalculationFailures = 0,
    this.isUsingFallbackDistance = false,
    this.lastLocationUpdate,
    this.lastDistanceCalculation,
    this.cachedUserLocation,
    this.isAppInBackground = false,
    this.backgroundCalculationCount = 0,
    this.command,
  });

  EnhancedMerchantDetailState copyWith({
    Map<String, dynamic>? detailData,
    double? currentDistance,
    bool? isDistanceCalculating,
    Position? currentUserLocation,
    MerchantModel? lastKnownMerchant,
    bool? hasLocationPermission,
    bool? isLocationServiceEnabled,
    int? distanceCalculationFailures,
    bool? isUsingFallbackDistance,
    DateTime? lastLocationUpdate,
    DateTime? lastDistanceCalculation,
    Position? cachedUserLocation,
    bool? isAppInBackground,
    int? backgroundCalculationCount,
    ViewModelCommand? command,
  }) {
    return EnhancedMerchantDetailState(
      detailData: detailData ?? this.detailData,
      currentDistance: currentDistance ?? this.currentDistance,
      isDistanceCalculating: isDistanceCalculating ?? this.isDistanceCalculating,
      currentUserLocation: currentUserLocation ?? this.currentUserLocation,
      lastKnownMerchant: lastKnownMerchant ?? this.lastKnownMerchant,
      hasLocationPermission: hasLocationPermission ?? this.hasLocationPermission,
      isLocationServiceEnabled: isLocationServiceEnabled ?? this.isLocationServiceEnabled,
      distanceCalculationFailures: distanceCalculationFailures ?? this.distanceCalculationFailures,
      isUsingFallbackDistance: isUsingFallbackDistance ?? this.isUsingFallbackDistance,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      lastDistanceCalculation: lastDistanceCalculation ?? this.lastDistanceCalculation,
      cachedUserLocation: cachedUserLocation ?? this.cachedUserLocation,
      isAppInBackground: isAppInBackground ?? this.isAppInBackground,
      backgroundCalculationCount: backgroundCalculationCount ?? this.backgroundCalculationCount,
      command: command ?? this.command,
    );
  }
}

abstract class ViewModelCommand {
  const ViewModelCommand();
}

class NavigateCommand extends ViewModelCommand {
  final Widget page;
  const NavigateCommand(this.page);
}

class ShowSnackbarCommand extends ViewModelCommand {
  final String message;
  final Color backgroundColor;
  final int durationSeconds;
  const ShowSnackbarCommand(this.message, this.backgroundColor, this.durationSeconds);
}

class OpenUrlCommand extends ViewModelCommand {
  final String url;
  const OpenUrlCommand(this.url);
}

class MerchantDetailConstants {
  static const Duration locationCacheTimeout = Duration(minutes: 2);
  static const Duration minCalculationInterval = Duration(seconds: 3);
  static const int maxBackgroundCalculations = 5;
  static const double movementThreshold = 20.0; 
}

@riverpod
class EnhancedMerchantDetailStateNotifier extends _$EnhancedMerchantDetailStateNotifier {
  @override
  EnhancedMerchantDetailState build() {
    ref.onDispose(() {
      _cleanup();
    });
    
    return const EnhancedMerchantDetailState();
  }

  StreamSubscription<Position>? _userLocationSubscription;
  Timer? _distanceRecalculationTimer;
  Timer? _retryTimer;
  Timer? _locationCacheInvalidationTimer;

  void _cleanup() {
    Logger.log("ENHANCED_VM - Disposing resources");
    _userLocationSubscription?.cancel();
    _distanceRecalculationTimer?.cancel();
    _retryTimer?.cancel();
    _locationCacheInvalidationTimer?.cancel();
  }

  void setDetailData(Map<String, dynamic> data) {
    state = state.copyWith(detailData: data);
    if (data['merchant'] != null) {
      state = state.copyWith(lastKnownMerchant: data['merchant'] as MerchantModel);
    }
  }

  void handleDistanceUpdate(double? newDistance) {
    state = state.copyWith(
      currentDistance: newDistance,
      isDistanceCalculating: false,
    );
    
    if (newDistance != null) {
      state = state.copyWith(
        distanceCalculationFailures: 0,
        isUsingFallbackDistance: false,
      );
    }
  }

  double? getDisplayDistance() {
    if (state.isUsingFallbackDistance && state.detailData != null) {
      final staticDistance = state.detailData!['distance'] as double?;
      if (staticDistance != null) {
        return staticDistance;
      }
    }
    
    if (state.currentDistance != null) {
      return state.currentDistance;
    }
    
    final staticDistance = state.detailData?['distance'] as double?;
    if (staticDistance != null) {
      return staticDistance;
    }
    
    return null;
  }

  Future<void> initializeUserLocationTracking() async {
    try {
      Logger.log("ENHANCED_VM - Initializing user location tracking");
      
      final permissionStatus = await checkLocationStatus();
      if (!permissionStatus) {
        Logger.log("ENHANCED_VM - Location not available, using fallback distance");
        enableFallbackMode();
        return;
      }
      
      if (state.cachedUserLocation != null && state.lastLocationUpdate != null) {
        final cacheAge = DateTime.now().difference(state.lastLocationUpdate!);
        if (cacheAge < MerchantDetailConstants.locationCacheTimeout) {
          state = state.copyWith(currentUserLocation: state.cachedUserLocation);
          startUserLocationStream();
          return;
        }
      }
      
      final locationService = LocationService.instance;
      final initialPosition = await locationService.getCurrentLocation();
      
      if (initialPosition != null) {
        state = state.copyWith(
          currentUserLocation: initialPosition,
          cachedUserLocation: initialPosition,
          lastLocationUpdate: DateTime.now(),
          distanceCalculationFailures: 0,
          isUsingFallbackDistance: false,
        );
        
        startUserLocationStream();
      } else {
        Logger.log("ENHANCED_VM - Could not get initial user location, enabling fallback");
        enableFallbackMode();
      }
    } catch (e) {
      Logger.error("ENHANCED_VM - Error initializing user location tracking", error: e);
      handleLocationError(e);
    }
  }

  Future<bool> checkLocationStatus() async {
    try {
      final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      state = state.copyWith(isLocationServiceEnabled: isLocationServiceEnabled);
      
      if (!isLocationServiceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final hasLocationPermission = permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;
      
      state = state.copyWith(hasLocationPermission: hasLocationPermission);

      if (!hasLocationPermission) {
        return false;
      }

      return true;
    } catch (e) {
      Logger.error("ENHANCED_VM - Error checking location status", error: e);
      return false;
    }
  }

  void enableFallbackMode() {
    Logger.log("ENHANCED_VM - Enabling fallback distance mode");

    state = state.copyWith(
      isUsingFallbackDistance: true,
      isDistanceCalculating: false,
    );

    _emitCommand(ShowSnackbarCommand(
      "Menggunakan perkiraan jarak (GPS tidak tersedia)",
      MyColor.orange,
      3,
    ));
  }

  void handleLocationError(Object error) {
    final newFailureCount = state.distanceCalculationFailures + 1;
    state = state.copyWith(distanceCalculationFailures: newFailureCount);
    
    Logger.error("ENHANCED_VM - Location error #$newFailureCount", error: error);

    if (newFailureCount >= 3) {
      Logger.log("ENHANCED_VM - Too many location failures, switching to fallback mode");
      enableFallbackMode();
      return;
    }

    scheduleLocationRetry();
  }

  void scheduleLocationRetry() {
    _retryTimer?.cancel();

    final retryDelay = Duration(seconds: 5 * state.distanceCalculationFailures);

    _retryTimer = Timer(retryDelay, () {
      if (_isMounted && !state.isUsingFallbackDistance) {
        initializeUserLocationTracking();
      }
    });
  }

  void startUserLocationStream() {
    try {
      final locationSettings = LocationSettings(
        accuracy: state.isAppInBackground
            ? LocationAccuracy.medium
            : LocationAccuracy.high,
        distanceFilter: state.isAppInBackground ? 20 : 10,
      );

      _userLocationSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          state = state.copyWith(
            cachedUserLocation: position,
            lastLocationUpdate: DateTime.now(),
          );

          handleUserLocationUpdate(position);
        },
        onError: (error) {
          Logger.error("ENHANCED_VM - User location stream error", error: error);
          handleLocationError(error);
        },
      );

    } catch (e) {
      Logger.error("ENHANCED_VM - Error starting user location stream", error: e);
      handleLocationError(e);
    }
  }

  void handleUserLocationUpdate(Position newPosition) {
    if (state.currentUserLocation != null) {
      final distanceMoved = Geolocator.distanceBetween(
        state.currentUserLocation!.latitude,
        state.currentUserLocation!.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );

      if (distanceMoved > MerchantDetailConstants.movementThreshold) {
        state = state.copyWith(currentUserLocation: newPosition);
        scheduleDistanceRecalculation();
      }
    } else {
      state = state.copyWith(currentUserLocation: newPosition);
      scheduleDistanceRecalculation();
    }
  }

  void initializePerformanceOptimizations() {
    startLocationCacheInvalidation();
  }

  void handleAppLifecycleChange(AppLifecycleState lifecycleState) {
    switch (lifecycleState) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        handleAppBackground();
        break;
      case AppLifecycleState.resumed:
        handleAppForeground();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void handleAppBackground() {
    state = state.copyWith(
      isAppInBackground: true,
      backgroundCalculationCount: 0,
    );
  }

  void handleAppForeground() {
    if (state.isAppInBackground) {
      state = state.copyWith(isAppInBackground: false);
      invalidateLocationCache();
    }
  }

  void startLocationCacheInvalidation() {
    _locationCacheInvalidationTimer?.cancel();
    _locationCacheInvalidationTimer = Timer.periodic(
      MerchantDetailConstants.locationCacheTimeout, 
      (timer) {
        if (_isMounted) {
          invalidateLocationCache();
        } else {
          timer.cancel();
        }
      }
    );
  }

  void invalidateLocationCache() {
    if (state.cachedUserLocation != null) {
      state = state.copyWith(
        cachedUserLocation: null,
        lastLocationUpdate: null,
      );
    }
  }

  bool shouldSkipCalculation() {
    if (state.isAppInBackground) {
      final newCount = state.backgroundCalculationCount + 1;
      state = state.copyWith(backgroundCalculationCount: newCount);
      
      if (newCount > MerchantDetailConstants.maxBackgroundCalculations) {
        return true;
      }
    }

    if (state.lastDistanceCalculation != null) {
      final timeSinceLastCalculation = DateTime.now().difference(state.lastDistanceCalculation!);
      if (timeSinceLastCalculation < MerchantDetailConstants.minCalculationInterval) {
        return true;
      }
    }

    return false;
  }

  void scheduleDistanceRecalculation() {
    if (shouldSkipCalculation()) {
      return;
    }

    _distanceRecalculationTimer?.cancel();

    final debounceDelay = state.isAppInBackground
        ? Duration(seconds: 10)
        : Duration(seconds: 2);

    _distanceRecalculationTimer = Timer(debounceDelay, () {
      if (_isMounted) {
        recalculateDistanceFromUserMovement();
      }
    });
  }

  Future<void> recalculateDistanceFromUserMovement() async {
    if (state.currentUserLocation == null || state.lastKnownMerchant == null) {
      return;
    }

    final merchant = state.lastKnownMerchant!;
    if (merchant.merchantLocLat == null || merchant.merchantLocLong == null) {
      return;
    }

    try {
      state = state.copyWith(isDistanceCalculating: true);
      state = state.copyWith(lastDistanceCalculation: DateTime.now());

      final distance = Geolocator.distanceBetween(
            state.currentUserLocation!.latitude,
            state.currentUserLocation!.longitude,
            merchant.merchantLocLat!,
            merchant.merchantLocLong!,
          ) /
          1000;

      state = state.copyWith(
        currentDistance: distance,
        isDistanceCalculating: false,
        distanceCalculationFailures: 0,
        isUsingFallbackDistance: false,
      );
      
    } catch (e) {
      Logger.error("ENHANCED_VM - Error recalculating distance from user movement", error: e);
      handleLocationError(e);
      state = state.copyWith(isDistanceCalculating: false);
    }
  }

  Future<void> navigateToChatDetail() async {
    if (state.lastKnownMerchant == null) return;
    
    try {
      Logger.log("ENHANCED_VM - Starting chat with: ${state.lastKnownMerchant!.merchantName}");
      
      final conversationId = await ref.read(chatActionsViewModelProvider.notifier)
          .startChat(state.lastKnownMerchant!);
      
      if (conversationId != null) {
        _emitCommand(NavigateCommand(ChatDetailPage(conversationId: conversationId)));
        
        Logger.log("ENHANCED_VM - Chat opened successfully: $conversationId");
        
        _emitCommand(ShowSnackbarCommand(
          "Chat dengan ${state.lastKnownMerchant!.merchantName} dimulai", 
          Colors.green,
          2,
        ));
      } else {
        _emitCommand(ShowSnackbarCommand(
          "Gagal memulai chat dengan ${state.lastKnownMerchant!.merchantName}", 
          Colors.red,
          3,
        ));
      }
      
    } catch (e) {
      Logger.error("ENHANCED_VM - Error starting chat", error: e);
      
      if (e.toString().contains('authenticated')) {
        _emitCommand(ShowSnackbarCommand(
          "Silakan login terlebih dahulu untuk memulai chat", 
          Colors.red,
          3,
        ));
      } else {
        _emitCommand(ShowSnackbarCommand(
          "Gagal memulai chat. Silakan coba lagi.", 
          Colors.red,
          3,
        ));
      }
    }
  }

  Future<void> openInGoogleMaps(double latitude, double longitude, String? merchantName) async {
    try {
      Logger.log("ENHANCED_VM - Opening location in Google Maps: $latitude, $longitude");
      
      String url;
      if (Platform.isIOS) {
        url = "comgooglemaps://?center=$latitude,$longitude&zoom=16";
        
        if (!await canLaunchUrl(Uri.parse(url))) {
          url = "http://maps.apple.com/?q=$latitude,$longitude";
        }
      } else {
        url = "geo:$latitude,$longitude?q=$latitude,$longitude(${merchantName ?? 'Merchant'})";
      }
      
      _emitCommand(OpenUrlCommand(url));
      
      Logger.log("ENHANCED_VM - Google Maps URL prepared: $url");
      
    } catch (e) {
      Logger.error("ENHANCED_VM - Error preparing Google Maps URL", error: e);
      
      _emitCommand(ShowSnackbarCommand(
        "Tidak dapat membuka Google Maps", 
        Colors.red,
        3,
      ));
    }
  }

  String getMerchantId(MerchantModel merchant) {
    return "MRCN_${merchant.uid}";
  }

  String formatPriceRange(String priceRangeText) {
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

  void pauseLocationUpdates() {
    // Map interaction handling
  }
  
  void resumeLocationUpdates() {
    // Map interaction handling
  }

  void _emitCommand(ViewModelCommand command) {
    state = state.copyWith(command: command);
    Future.microtask(() {
      if (_isMounted) {
        state = state.copyWith(command: null);
      }
    });
  }

  bool get _isMounted {
    try {
      ref.exists;
      return true;
    } catch (e) {
      return false;
    }
  }
}

@riverpod
class MerchantDetailViewModel extends _$MerchantDetailViewModel {
  @override
  AppState<Map<String, dynamic>, Exception> build() {
    return AppState.idle();
  }

  Future<void> initializeMerchantDetail(MerchantModel merchant) async {
    _updateState(AppState.loading());
    
    try {
      Logger.log("DETAILVM - Initializing merchant detail: ${merchant.merchantName}");
      
      double? distance;
      try {
        distance = await _calculateDistanceFromUser(merchant);
      } catch (e) {
        Logger.error("DETAILVM - Error calculating distance", error: e);
        distance = null;
      }
      
      Map<String, dynamic> priceRange = _calculatePriceRange(merchant.products);
      
      Map<String, dynamic> detailData = {
        'merchant': merchant,
        'distance': distance,
        'totalProducts': merchant.products?.length ?? 0,
        'hasLocation': merchant.merchantLocLat != null && merchant.merchantLocLong != null,
        'minPrice': priceRange['minPrice'],
        'maxPrice': priceRange['maxPrice'],
        'priceRangeText': priceRange['priceRangeText'],
      };
      
      Logger.log("DETAILVM - Merchant detail initialized successfully");
      
      _updateState(AppState.success(detailData));
      
      try {
        ref.read(enhancedMerchantDetailStateNotifierProvider.notifier)
            .setDetailData(detailData);
      } catch (e) {
        Logger.error("DETAILVM - Error syncing with enhanced state", error: e);
      }
      
    } catch (e) {
      Logger.error("DETAILVM - Error initializing merchant detail", error: e);
      _updateState(AppState.error(
        Exception(e.toString()),
        message: 'Failed to load merchant details'
      ));
    }
  }

  Map<String, dynamic> _calculatePriceRange(List<dynamic>? products) {
    if (products == null || products.isEmpty) {
      return {
        'minPrice': null,
        'maxPrice': null,
        'priceRangeText': 'Harga tidak tersedia',
      };
    }
    
    List<int> prices = [];
    
    for (var product in products) {
      try {
        String? priceString = product.productPrice?.toString();
        if (priceString != null && priceString.isNotEmpty) {
          String cleanPrice = priceString.replaceAll(RegExp(r'[^\d]'), '');
          if (cleanPrice.isNotEmpty) {
            int price = int.parse(cleanPrice);
            prices.add(price);
          }
        }
      } catch (e) {
        Logger.error("Error parsing price: ${product.productPrice}", error: e);
        continue;
      }
    }
    
    if (prices.isEmpty) {
      return {
        'minPrice': null,
        'maxPrice': null,
        'priceRangeText': 'Harga tidak tersedia',
      };
    }
    
    prices.sort();
    int minPrice = prices.first;
    int maxPrice = prices.last;
    
    String priceRangeText;
    if (minPrice == maxPrice) {
      priceRangeText = "Rp ${_formatPrice(minPrice)}";
    } else {
      priceRangeText = "Rp ${_formatPrice(minPrice)} - ${_formatPrice(maxPrice)}";
    }
    
    return {
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'priceRangeText': priceRangeText,
    };
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Future<double?> _calculateDistanceFromUser(MerchantModel merchant) async {
    if (merchant.merchantLocLat == null || merchant.merchantLocLong == null) {
      return null;
    }
    
    final locationService = ref.read(locationServicesDetailProvider);
    final position = await locationService.getCurrentLocation();
    
    if (position == null) {
      throw Exception('Unable to get current location');
    }
    
    return _calculateDistance(
      position.latitude,
      position.longitude,
      merchant.merchantLocLat!,
      merchant.merchantLocLong!,
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  Future<void> refreshMerchantDetail(MerchantModel merchant) async {
    Logger.log("DETAILVM - Refreshing merchant detail");
    await initializeMerchantDetail(merchant);
  }

  void _updateState(AppState<Map<String, dynamic>, Exception> newState) {
    state = newState;
  }
}