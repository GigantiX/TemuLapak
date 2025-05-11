import 'package:geolocator/geolocator.dart';
import 'package:temulapak_app/utils/logger.dart';

class LocationServices {
  static final LocationServices _instance = LocationServices._internal();
  static LocationServices get instance => _instance;

  factory LocationServices() => _instance;

  LocationServices._internal();

  Future<bool> checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Logger.log("Location services are disabled.");
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Logger.log("Location permissions are denied");
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Logger.log("Location permissions are permanently denied.");
      return false;
    }

    try {
      Logger.log("Testing precise location");
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5)
        )
      );

      //Calculate location accuracy
      double accuracy = position.accuracy;
      Logger.log("Location accuracy: $accuracy");

      if (accuracy > 100) {
        Logger.log("Location accuracy is not precise enough.");
        return false;
      }

      Logger.log("Precise location granted");
      return true;
    } catch (e) {
      Logger.log("Error getting location: $e");
      return false;
    }
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final permissionGranted = await checkPermission();

      if (!permissionGranted) {
        Logger.log("Permission not granted");
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      Logger.log("Error getting location: $e");
      return null;
    }
  }

  Future<bool> isPreciseLocAvailable() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      return position.accuracy <= 100;
    } catch (e) {
      Logger.log("Error checking precise location: $e");
      return false;
    }
  }
}
