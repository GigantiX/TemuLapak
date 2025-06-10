import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/utils/loading/loading.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/merchant_dashboard_page/live_tracking/live_tracking_dialog.dart';
import 'package:temulapak_app/view/merchant_dashboard_page/live_tracking/live_tracking_notifier.dart';
import 'package:temulapak_app/view/merchant_dashboard_page/merchant_dashboard_viewmodel.dart';
import 'package:temulapak_app/view/widget/map_picker/map_picker_dialog.dart';

class MerchantDashboardPage extends ConsumerStatefulWidget {
  const MerchantDashboardPage({super.key});

  @override
  ConsumerState<MerchantDashboardPage> createState() =>
      _MerchantDashboardPageState();
}

class _MerchantDashboardPageState extends ConsumerState<MerchantDashboardPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoadingAction = false;
  bool _isErrorHandled = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final liveTrackingState = ref.read(liveTrackingNotifierProvider);
      final actualServiceState =
          ref.read(liveTrackingNotifierProvider.notifier).isTracking;

      if (liveTrackingState.error != null ||
          (liveTrackingState.isEnabled && !actualServiceState)) {
        Logger.log("Fixing inconsistent tracking state on page init");
        ref.read(liveTrackingNotifierProvider.notifier).forceDisable();
        ref.read(liveTrackingNotifierProvider.notifier).clearError();
      } else {
        ref.read(liveTrackingNotifierProvider.notifier).syncWithService();
      }

      // Load merchant data
      ref.read(merchantDashboardViewmodelProvider.notifier).loadMerchantData();
    });
  }

  @override
  void dispose() {
    if (_isLoadingAction) {
      Loading.hide();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final merchantState = ref.watch(merchantDashboardViewmodelProvider);
    final liveTrackingState = ref.watch(liveTrackingNotifierProvider);

    // Handle loading states
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final shouldShowLoading =
          merchantState.isLoading || liveTrackingState.isInitializing;

      if (shouldShowLoading && !_isLoadingAction) {
        _isLoadingAction = true;
        Loading.show(context);
      } else if (!shouldShowLoading && _isLoadingAction) {
        _isLoadingAction = false;
        Loading.hide();
      }

      // Handle live tracking errors with improved safety
      if (liveTrackingState.error != null && mounted && !_isErrorHandled) {
        _isErrorHandled = true;

        // CRITICAL CHANGE: Force disable tracking when there's an error
        if (liveTrackingState.isEnabled) {
          Logger.log(
              "CRITICAL: Tracking service has error but UI shows enabled. Forcing disabled state.");
          // Force disable tracking without showing dialog
          await ref.read(liveTrackingNotifierProvider.notifier).forceDisable();
          // Stop refresh timer since tracking is now disabled
          ref
              .read(merchantDashboardViewmodelProvider.notifier)
              .stopLiveTrackingRefresh();
        }

        final errorMessage = liveTrackingState.error!;
        ref.read(liveTrackingNotifierProvider.notifier).clearError();

        Future.delayed(Duration(milliseconds: 500), () {
          if (!mounted) return;

          LiveTrackingDialog.showErrorDialog(context, errorMessage).then((_) {
            // IMPORTANT: Don't reset _isErrorHandled on a timer
            // Only reset when user navigates away or explicitly interacts
            _isErrorHandled = true; // Keep it true until page is disposed
          });
        });
      }

      // Update map marker when merchant data changes (for live tracking updates)
      if (merchantState.isSuccess && merchantState.data != null) {
        _updateMarker(merchantState.data!);
      }
    });

    return Scaffold(
      backgroundColor: MyColor.white,
      body: SafeArea(
        child: merchantState.when(
          idle: () => _buildLoadingWidget(),
          loading: () => _buildLoadingWidget(),
          success: (merchant) =>
              _buildSuccessWidget(merchant, liveTrackingState),
          error: (error, message) =>
              _buildErrorWidget(message ?? error.toString()),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Stack(
      children: [
        Column(
          children: [
            // Fixed Map placeholder while loading
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                color: MyColor.lightGrey,
              ),
              child: Center(
                child: Icon(
                  Icons.map,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
            ),

            // Scrollable loading content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(height: 100),
                    Text(
                      'Memuat data merchant...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Floating Back Button
        Positioned(
          top: 8,
          left: 16,
          child: GestureDetector(
            onTap: () => ref.read(merchantDashboardViewmodelProvider.notifier).navigateBack(context),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Stack(
      children: [
        Column(
          children: [
            // Fixed Map placeholder for error state
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                color: MyColor.lightGrey,
              ),
              child: Center(
                child: Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
            ),

            // Scrollable error content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 50),
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Error loading merchant data',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      errorMessage,
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(merchantDashboardViewmodelProvider.notifier)
                            .loadMerchantData();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: MyColor.orange),
                      child:
                          Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Floating Back Button
        Positioned(
          top: 8,
          left: 16,
          child: GestureDetector(
            onTap: () => ref.read(merchantDashboardViewmodelProvider.notifier).navigateBack(context),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessWidget(merchant, LiveTrackingState liveTrackingState) {
    return Stack(
      children: [
        Column(
          children: [
            // Fixed Map Section
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: BoxDecoration(
                color: MyColor.lightGrey,
              ),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    merchant.merchantLocLat ?? -6.2088,
                    merchant.merchantLocLong ?? 106.8456,
                  ),
                  zoom: 16,
                ),
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  _updateMarker(merchant);
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),

            // Scrollable Content Section
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Merchant Info Card
                    _buildMerchantInfoCard(merchant),

                    SizedBox(height: 20),

                    // Control Buttons
                    _buildControlButtons(merchant, liveTrackingState),

                    // Add some bottom padding for better scrolling experience
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Floating Back Button
        Positioned(
          top: 8,
          left: 16,
          child: GestureDetector(
            onTap: () => ref.read(merchantDashboardViewmodelProvider.notifier).navigateBack(context),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMerchantInfoCard(merchant) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Merchant Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: merchant.merchantImgUrl != null &&
                    merchant.merchantImgUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      merchant.merchantImgUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.store,
                            color: Colors.grey[400], size: 30);
                      },
                    ),
                  )
                : Icon(Icons.store, color: Colors.grey[400], size: 30),
          ),

          SizedBox(width: 16),

          // Merchant Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant.merchantName ?? 'Unknown Merchant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MyColor.blackPlain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Status Toko',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            merchant.merchantStatus ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        merchant.merchantStatus ? 'BUKA' : 'TUTUP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Toggle
          Switch(
            value: merchant.merchantStatus,
            onChanged: (value) async {
              Logger.log("Toggling merchant status to: $value");

              // Show loading for status update
              Loading.show(context);

              try {
                await ref
                    .read(merchantDashboardViewmodelProvider.notifier)
                    .updateMerchantStatus(value);

                Loading.hide();

                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value ? 'Toko dibuka' : 'Toko ditutup'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                Loading.hide();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengubah status toko'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            activeColor: MyColor.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(merchant, LiveTrackingState liveTrackingState) {
    return Column(
      children: [
        // Live Tracking Section
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    liveTrackingState.isEnabled
                        ? Icons.gps_fixed
                        : Icons.gps_off,
                    color: liveTrackingState.isEnabled
                        ? Colors.green
                        : MyColor.orange,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Live Tracking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MyColor.blackPlain,
                    ),
                  ),
                  SizedBox(width: 8),
                  if (liveTrackingState.isEnabled)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'AKTIF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Spacer(),
                  Switch(
                    value: liveTrackingState.isEnabled,
                    onChanged: liveTrackingState.isInitializing
                        ? null
                        : (value) => _handleLiveTrackingToggle(value),
                    activeColor: Colors.green,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                liveTrackingState.isEnabled
                    ? 'Lokasi toko Anda sedang diperbarui secara otomatis setiap 20 meter perpindahan. Fitur ini akan menggunakan GPS dan dapat menguras baterai.'
                    : 'Memperbarui lokasi lapak sesuai dengan lokasi penjual (Bila lokasi sering berpindah - pindah). Fitur ini lumayan memakan daya ponsel.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (liveTrackingState.isEnabled) ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.battery_alert, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Pastikan baterai mencukupi. Live tracking akan otomatis nonaktif jika aplikasi ditutup.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: 12),

        // Control Buttons
        _buildControlButton(
          icon: Icons.location_on,
          title: 'Update Lokasi',
          subtitle: 'Perbarui lokasi anda secara manual',
          color: MyColor.orange,
          onTap: () => _handleManualLocationUpdate(liveTrackingState, merchant),
        ),

        SizedBox(height: 12),

        _buildControlButton(
          icon: Icons.edit,
          title: 'Edit Profile Penjual',
          subtitle: 'Ubah nama, deskripsi, dan produk anda',
          color: MyColor.orange,
          onTap: () {
            Logger.log("Edit profile tapped");

            Loading.show(context);

            // Small delay to show loading animation
            Future.delayed(Duration(milliseconds: 500), () {
              Loading.hide();

              if (mounted) {
                ref.read(merchantDashboardViewmodelProvider.notifier).navigateToEditMerchant(
                      context
                    );
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: MyColor.blackPlain,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateMarker(merchant) {
    if (merchant.merchantLocLat != null && merchant.merchantLocLong != null) {
      setState(() {
        _markers = {
          Marker(
            markerId: MarkerId('merchant_location'),
            position:
                LatLng(merchant.merchantLocLat!, merchant.merchantLocLong!),
            infoWindow: InfoWindow(
              title: merchant.merchantName ?? 'My Store',
              snippet: merchant.merchantStatus ? 'BUKA' : 'TUTUP',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              merchant.merchantStatus
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueRed,
            ),
          ),
        };
      });
    }
  }

  /// Handle live tracking toggle with confirmation dialogs
  Future<void> _handleLiveTrackingToggle(bool value) async {
    try {
      if (value) {
        // Show confirmation dialog for enabling live tracking
        final confirmed = await LiveTrackingDialog.showEnableDialog(context);
        if (confirmed == true) {
          Logger.log("User confirmed to enable live tracking");

          final success = await ref
              .read(liveTrackingNotifierProvider.notifier)
              .startTracking();

          if (success && mounted) {
            // Start periodic refresh for live tracking updates
            ref
                .read(merchantDashboardViewmodelProvider.notifier)
                .startLiveTrackingRefresh();

            // Show success dialog
            LiveTrackingDialog.showSuccessEnableDialog(context);

            // Refresh merchant data to get updated location
            ref
                .read(merchantDashboardViewmodelProvider.notifier)
                .loadMerchantData();

            Logger.log("Live tracking enabled successfully with map refresh");
          }
        } else {
          Logger.log("User cancelled live tracking activation");
        }
      } else {
        // Show confirmation dialog for disabling live tracking
        final confirmed = await LiveTrackingDialog.showDisableDialog(context);
        if (confirmed == true) {
          Logger.log("User confirmed to disable live tracking");

          await ref.read(liveTrackingNotifierProvider.notifier).stopTracking();

          // Stop periodic refresh when live tracking is disabled
          ref
              .read(merchantDashboardViewmodelProvider.notifier)
              .stopLiveTrackingRefresh();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Live tracking dinonaktifkan'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }

          Logger.log(
              "Live tracking disabled successfully, map refresh stopped");
        } else {
          Logger.log("User cancelled live tracking deactivation");
        }
      }
    } catch (e) {
      Logger.error("Error handling live tracking toggle", error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat mengatur live tracking'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Handle manual location update
  Future<void> _handleManualLocationUpdate(
      LiveTrackingState liveTrackingState, merchant) async {
    try {
      Logger.log("Manual location update tapped");

      // Check if live tracking is enabled
      if (liveTrackingState.isEnabled) {
        Logger.log("Live tracking is enabled, showing warning message");

        // Show snackbar warning that live tracking must be turned off first
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Matikan Live Tracking terlebih dahulu untuk mengubah lokasi secara manual',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        return;
      }

      Logger.log(
          "Live tracking is disabled, proceeding with manual location update");

      // Get current merchant location for initial map position
      LatLng? initialLocation;
      if (merchant.merchantLocLat != null && merchant.merchantLocLong != null) {
        initialLocation =
            LatLng(merchant.merchantLocLat!, merchant.merchantLocLong!);
        Logger.log(
            "Using current merchant location as initial: $initialLocation");
      } else {
        Logger.log("No current merchant location, using default location");
        // Use default Jakarta location if no current location
        initialLocation = LatLng(-6.2088, 106.8456);
      }

      // Show loading briefly before opening map dialog
      Loading.show(context);

      await Future.delayed(Duration(milliseconds: 300));

      if (!mounted) {
        Loading.hide();
        return;
      }

      Loading.hide();

      // Show map picker dialog
      Logger.log(
          "Opening map picker dialog with initial location: $initialLocation");

      final selectedLocation = await showDialog<LatLng>(
        context: context,
        barrierDismissible: false, // Prevent dismissing by tapping outside
        builder: (context) => MapPickerDialog(
          initialLocation: initialLocation,
        ),
      );

      if (selectedLocation != null) {
        Logger.log("User selected new location: $selectedLocation");

        // Show loading while updating location
        Loading.show(context);

        try {
          // Update merchant location in Firebase
          await ref
              .read(merchantDashboardViewmodelProvider.notifier)
              .updateMerchantLocation(
                selectedLocation.latitude,
                selectedLocation.longitude,
              );

          Loading.hide();

          if (mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Lokasi toko berhasil diperbarui'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );

            // Update map marker to show new location
            _updateMarker(ref.read(merchantDashboardViewmodelProvider).data);
          }

          Logger.log("Location updated successfully");
        } catch (e) {
          Loading.hide();

          Logger.error("Failed to update merchant location", error: e);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child:
                          Text('Gagal memperbarui lokasi. Silakan coba lagi.'),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Coba Lagi',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    _handleManualLocationUpdate(liveTrackingState, merchant);
                  },
                ),
              ),
            );
          }
        }
      } else {
        Logger.log("User cancelled location selection");
        // User cancelled - no action needed, dialog already popped
      }
    } catch (e) {
      Loading.hide();
      Logger.error("Error in manual location update", error: e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Terjadi kesalahan saat memperbarui lokasi'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}