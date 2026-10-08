import 'package:gasione_core_starter/src/services/permission_service.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart' as geolocator;

enum AppLocationAccuracy { lowest, low, medium, high, best, navigation }

enum LocationAccessStatus {
  granted,
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  permissionRestricted,
}

final class GeoCoordinates {
  const GeoCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) {
    return other is GeoCoordinates &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

final class DeviceLocation {
  const DeviceLocation({
    required this.coordinates,
    required this.capturedAt,
    required this.accuracy,
    required this.altitude,
    required this.heading,
    required this.speed,
    required this.isMocked,
    required this.hasAccuracy,
  });

  final GeoCoordinates coordinates;
  final DateTime capturedAt;
  final double accuracy;
  final double altitude;
  final double heading;
  final double speed;
  final bool isMocked;
  final bool hasAccuracy;
}

final class LocationAddress {
  const LocationAddress({
    this.name,
    this.street,
    this.subLocality,
    this.locality,
    this.subAdministrativeArea,
    this.administrativeArea,
    this.postalCode,
    this.country,
    this.isoCountryCode,
  });

  final String? name;
  final String? street;
  final String? subLocality;
  final String? locality;
  final String? subAdministrativeArea;
  final String? administrativeArea;
  final String? postalCode;
  final String? country;
  final String? isoCountryCode;
}

final class LocationAccessException implements Exception {
  const LocationAccessException(this.status);

  final LocationAccessStatus status;

  @override
  String toString() => 'LocationAccessException: ${status.name}';
}

abstract interface class LocationService {
  Future<bool> isServiceEnabled();

  Future<LocationAccessStatus> checkAccess();

  Future<LocationAccessStatus> requestAccess();

  Future<DeviceLocation?> getLastKnownLocation();

  Future<DeviceLocation> getCurrentLocation({
    AppLocationAccuracy accuracy = AppLocationAccuracy.high,
    Duration timeout = const Duration(seconds: 15),
  });

  Stream<DeviceLocation> watchLocation({
    AppLocationAccuracy accuracy = AppLocationAccuracy.high,
    int distanceFilter = 10,
  });

  Future<List<LocationAddress>> reverseGeocode(GeoCoordinates coordinates);

  Future<List<GeoCoordinates>> geocode(String address);

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}

final class DeviceLocationService implements LocationService {
  DeviceLocationService(
    this._permissionService, {
    geocoding.Geocoding? geocoder,
  }) : _geocoder = geocoder ?? geocoding.Geocoding();

  final PermissionService _permissionService;
  final geocoding.Geocoding _geocoder;

  @override
  Future<bool> isServiceEnabled() {
    return geolocator.Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<LocationAccessStatus> checkAccess() async {
    if (!await isServiceEnabled()) {
      return LocationAccessStatus.serviceDisabled;
    }

    final status = await _permissionService.check(
      AppPermission.locationWhenInUse,
    );
    return _toAccessStatus(status);
  }

  @override
  Future<LocationAccessStatus> requestAccess() async {
    if (!await isServiceEnabled()) {
      return LocationAccessStatus.serviceDisabled;
    }

    final current = await _permissionService.check(
      AppPermission.locationWhenInUse,
    );
    if (current != AppPermissionStatus.denied) {
      return _toAccessStatus(current);
    }

    final requested = await _permissionService.request(
      AppPermission.locationWhenInUse,
    );
    return _toAccessStatus(requested);
  }

  @override
  Future<DeviceLocation?> getLastKnownLocation() async {
    await _requireAccess();
    final position = await geolocator.Geolocator.getLastKnownPosition();
    return position == null ? null : _fromPosition(position);
  }

  @override
  Future<DeviceLocation> getCurrentLocation({
    AppLocationAccuracy accuracy = AppLocationAccuracy.high,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    await _requireAccess();
    final position = await geolocator.Geolocator.getCurrentPosition(
      locationSettings: geolocator.LocationSettings(
        accuracy: _toPluginAccuracy(accuracy),
        timeLimit: timeout,
      ),
    );
    return _fromPosition(position);
  }

  @override
  Stream<DeviceLocation> watchLocation({
    AppLocationAccuracy accuracy = AppLocationAccuracy.high,
    int distanceFilter = 10,
  }) async* {
    assert(distanceFilter >= 0, 'distanceFilter must not be negative.');
    await _requireAccess();

    final positions = geolocator.Geolocator.getPositionStream(
      locationSettings: geolocator.LocationSettings(
        accuracy: _toPluginAccuracy(accuracy),
        distanceFilter: distanceFilter,
      ),
    );
    await for (final position in positions) {
      yield _fromPosition(position);
    }
  }

  @override
  Future<List<LocationAddress>> reverseGeocode(
    GeoCoordinates coordinates,
  ) async {
    final placemarks = await _geocoder.placemarkFromCoordinates(
      coordinates.latitude,
      coordinates.longitude,
    );
    return placemarks.map(_fromPlacemark).toList(growable: false);
  }

  @override
  Future<List<GeoCoordinates>> geocode(String address) async {
    final locations = await _geocoder.locationFromAddress(address);
    return locations
        .map(
          (location) => GeoCoordinates(
            latitude: location.latitude,
            longitude: location.longitude,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<bool> openAppSettings() => _permissionService.openSettings();

  @override
  Future<bool> openLocationSettings() {
    return geolocator.Geolocator.openLocationSettings();
  }

  Future<void> _requireAccess() async {
    final status = await checkAccess();
    if (status != LocationAccessStatus.granted) {
      throw LocationAccessException(status);
    }
  }

  LocationAccessStatus _toAccessStatus(AppPermissionStatus status) {
    return switch (status) {
      AppPermissionStatus.granted => LocationAccessStatus.granted,
      AppPermissionStatus.denied => LocationAccessStatus.permissionDenied,
      AppPermissionStatus.permanentlyDenied =>
        LocationAccessStatus.permissionPermanentlyDenied,
      AppPermissionStatus.restricted =>
        LocationAccessStatus.permissionRestricted,
    };
  }

  geolocator.LocationAccuracy _toPluginAccuracy(AppLocationAccuracy accuracy) {
    return switch (accuracy) {
      AppLocationAccuracy.lowest => geolocator.LocationAccuracy.lowest,
      AppLocationAccuracy.low => geolocator.LocationAccuracy.low,
      AppLocationAccuracy.medium => geolocator.LocationAccuracy.medium,
      AppLocationAccuracy.high => geolocator.LocationAccuracy.high,
      AppLocationAccuracy.best => geolocator.LocationAccuracy.best,
      AppLocationAccuracy.navigation =>
        geolocator.LocationAccuracy.bestForNavigation,
    };
  }

  DeviceLocation _fromPosition(geolocator.Position position) {
    return DeviceLocation(
      coordinates: GeoCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
      capturedAt: position.timestamp,
      accuracy: position.accuracy,
      altitude: position.altitude,
      heading: position.heading,
      speed: position.speed,
      isMocked: position.isMocked,
      hasAccuracy: position.hasAccuracy,
    );
  }

  LocationAddress _fromPlacemark(geocoding.Placemark placemark) {
    return LocationAddress(
      name: placemark.name,
      street: placemark.street,
      subLocality: placemark.subLocality,
      locality: placemark.locality,
      subAdministrativeArea: placemark.subAdministrativeArea,
      administrativeArea: placemark.administrativeArea,
      postalCode: placemark.postalCode,
      country: placemark.country,
      isoCountryCode: placemark.isoCountryCode,
    );
  }
}
