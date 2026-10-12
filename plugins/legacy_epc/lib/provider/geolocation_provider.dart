import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class GeolocationProvider {

  final Geocoding _geocoding = Geocoding();

  Future<LocationPermission> reqPermission() async {
    return Geolocator.requestPermission();
  }

  Future<LocationPermission> getPermission() async {
    return Geolocator.checkPermission();
  }

  Future<Position> getCurrentLocation() async {
    return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.best));
  }

  Future<List<Placemark>> getAddressFromCoordinate(
    double latitude,
    double longitude,
  ) async {
    return _geocoding.placemarkFromCoordinates(latitude, longitude);
  }

  Future<List<Location>> getCoordinateFromAddress(String address) async {
    return _geocoding.locationFromAddress(address);
  }

}