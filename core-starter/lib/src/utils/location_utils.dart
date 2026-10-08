import 'package:gasione_core_starter/src/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

abstract final class LocationUtils {
  static double distanceInMeters(GeoCoordinates start, GeoCoordinates end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  static double bearingInDegrees(GeoCoordinates start, GeoCoordinates end) {
    return Geolocator.bearingBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  static bool isWithinRadius(
    GeoCoordinates point,
    GeoCoordinates center, {
    required double radiusInMeters,
  }) {
    if (radiusInMeters < 0) {
      return false;
    }
    return distanceInMeters(point, center) <= radiusInMeters;
  }

  static bool isValidCoordinates(GeoCoordinates coordinates) {
    return coordinates.latitude >= -90 &&
        coordinates.latitude <= 90 &&
        coordinates.longitude >= -180 &&
        coordinates.longitude <= 180;
  }

  static String formatAddress(
    LocationAddress address, {
    String separator = ', ',
  }) {
    final values = <String>[];
    final candidates = [
      address.street,
      address.subLocality,
      address.locality,
      address.subAdministrativeArea,
      address.administrativeArea,
      address.postalCode,
      address.country,
    ];

    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty && !values.contains(value)) {
        values.add(value);
      }
    }

    return values.join(separator);
  }
}
