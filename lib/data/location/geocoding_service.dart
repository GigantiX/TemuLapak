import '../../utils/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GeocodingService {
  final String gate = 'AIzaSyBw404hlRiNV5MP-6ljiETugsAO3ScQj7c';

  Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$gate');

      Logger.log('Requesting address for coordinates: $latitude, $longitude');

      final response = await http.get(url);

      if (response.statusCode != 200) {
        Logger.error('Geocoding API error: ${response.statusCode}',
            error: response.body);
        return "Connection Error!";
      }

      final data = json.decode(response.body);

      // Check if the API returned an error
      if (data['status'] != 'OK') {
        final errorMessage = data['error_message'] ?? 'Unknown error';
        Logger.error('Geocoding API returned non-OK status: ${data['status']}',
            error: errorMessage);
        
        if (data['status'] == 'REQUEST_DENIED') {
        return "Request denied."; 
        }
        return "Unknown location";
      }

      // Get the first result (most accurate)
      if (data['results'].isEmpty) {
        Logger.error('No address found for coordinates',
            error: 'Empty results array');
        return "Unknown location";
      }

      final formattedAddress = data['results'][0]['formatted_address'];
      Logger.log('Address found: $formattedAddress');

      return formattedAddress;
    } catch (e) {
      Logger.error('Error in getAddressFromLatLng', error: e);
      return 'Failed to get address.';
    }
  }
}
