import 'package:geolocator/geolocator.dart';
import 'permission_service.dart';

class LocationService {
  final PermissionService _permissions = PermissionService();

  Future<Position?> getCurrentPosition() async {
    if (!await _permissions.requestLocation()) return null;
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  Future<bool> isServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }
}
