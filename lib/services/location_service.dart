import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Request permission
    var status = await Permission.location.request();
    if (!status.isGranted) {
      return null;
    }

    // Get current position
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  static Future<bool> checkPermission() async {
    var status = await Permission.location.status;
    return status.isGranted;
  }

  static Future<bool> requestPermission() async {
    var status = await Permission.location.request();
    return status.isGranted;
  }
}
