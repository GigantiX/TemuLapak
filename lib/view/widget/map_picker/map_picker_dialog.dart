import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/utils/loading/loading.dart';
import 'package:temulapak_app/utils/logger.dart';
import 'package:temulapak_app/view/register_merchant_page/register_merchant_viewmodel.dart';

class MapPickerDialog extends ConsumerStatefulWidget {
  final LatLng? initialLocation;

  const MapPickerDialog({
    Key? key,
    this.initialLocation,
  }) : super(key: key);

  @override
  ConsumerState<MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends ConsumerState<MapPickerDialog> {
  GoogleMapController? _mapController;
  LatLng _centerLocation = LocationPickerViewModel.defaultLocation;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _centerLocation = widget.initialLocation!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Pilih lokasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _centerLocation,
                      zoom: 16,
                    ),
                    onMapCreated: (controller) {
                      Logger.log("Map created");
                      _mapController = controller;

                      Loading.show(context);

                      Future.delayed(Duration(milliseconds: 500), () {
                        Loading.hide();
                      });
                    },
                    onCameraIdle: () {
                      if (_mapController != null) {
                        _mapController!.getVisibleRegion().then((bounds) {
                          setState(() {
                            _centerLocation = LatLng(
                                (bounds.northeast.latitude +
                                        bounds.southwest.latitude) /
                                    2,
                                (bounds.northeast.longitude +
                                        bounds.southwest.longitude) /
                                    2);
                          });
                        });
                      }
                    },
                    onCameraMove: (position) {
                      setState(() {
                        _centerLocation = position.target;
                      });
                    },
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    compassEnabled: true,
                    mapToolbarEnabled: false,
                    zoomControlsEnabled: false,
                    onTap: (_) {},
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 35,
                        width: 35,
                        decoration: BoxDecoration(
                          color: MyColor.orange.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: MyColor.white,
                          size: 20,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MyColor.orange,
                        side: BorderSide(color: MyColor.orange),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("Batal"),
                )),
                SizedBox(width: 8),
                Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(locationPickerViewModelProvider.notifier)
                            .setLocation(_centerLocation);
                        Navigator.of(context).pop(_centerLocation);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyColor.orange,
                        foregroundColor: MyColor.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("Pilih lokasi"),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
