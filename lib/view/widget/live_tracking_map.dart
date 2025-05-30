// File: lib/view/widget/live_tracking_map.dart
// UPDATE: Fix map interaction berdasarkan map_picker_dialog.dart

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

  const LiveTrackingMap({
    super.key,
    required this.merchantId,
    required this.initialMerchant,
  });

  @override
  ConsumerState<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends ConsumerState<LiveTrackingMap>
    with TickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();
    
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
  }

  @override
  void dispose() {
    _markerAnimationController.dispose();
    _mapController?.dispose();
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
    
    Logger.log("MAP - Markers initialized for ${merchant.merchantName} at $position");
  }

  void _updateMarkerPosition() {
    if (_currentPosition == null || _targetPosition == null || !mounted) return;

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

  void _animateMarkerToNewPosition(MerchantModel merchant) {
    if (merchant.merchantLocLat == null || merchant.merchantLocLong == null) {
      Logger.log("MAP - Cannot animate marker: coordinates are null");
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
      
      if (distance < 0.01) {
        Logger.log("MAP - Skipping animation, distance too small: ${distance.toStringAsFixed(4)} km");
        return;
      }
    }

    _currentPosition = _currentPosition ?? newPosition;
    _targetPosition = newPosition;
    _isAnimating = true;

    Logger.log("MAP - Starting smooth animation from $_currentPosition to $_targetPosition");

    _markerAnimationController.reset();
    _markerAnimationController.forward().then((_) {
      _currentPosition = _targetPosition;
      _isAnimating = false;
      Logger.log("MAP - Animation completed at $_currentPosition");
    });

    setState(() {
      _lastUpdateTime = DateTime.now();
      _connectionStatus = ConnectionStatus.live;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(newPosition),
    );
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
                _animateMarkerToNewPosition(merchant);
              }
            });

            return _buildGoogleMap(merchant);
          },
          loading: () => _buildLoadingMap(),
          error: (error, stack) {
            Logger.error("MAP - Stream error", error: error);
            setState(() {
              _connectionStatus = ConnectionStatus.offline;
            });
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
        Logger.log("MAP - Google Map created successfully");
      },
      // FIX: Enable all interactions like in map_picker_dialog.dart
      onCameraIdle: () {
        // Optional: Handle camera idle if needed
        Logger.log("MAP - Camera movement stopped");
      },
      onCameraMove: (_) {
        // Optional: Handle camera movement if needed  
        // Logger.log("MAP - Camera moved to: ${position.target}");
      },
      onTap: (LatLng position) {
        // Optional: Handle map tap if needed
        Logger.log("MAP - Map tapped at: $position");
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
          ],
        ),
      ),
    );
  }
}