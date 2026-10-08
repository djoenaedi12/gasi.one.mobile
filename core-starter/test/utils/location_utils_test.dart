import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';

void main() {
  const origin = GeoCoordinates(latitude: -6.2, longitude: 106.816666);

  test('calculates zero distance for the same coordinates', () {
    expect(LocationUtils.distanceInMeters(origin, origin), closeTo(0, 0.001));
  });

  test('checks whether coordinates are within a radius', () {
    const nearby = GeoCoordinates(latitude: -6.2001, longitude: 106.816666);

    expect(
      LocationUtils.isWithinRadius(nearby, origin, radiusInMeters: 20),
      isTrue,
    );
    expect(
      LocationUtils.isWithinRadius(nearby, origin, radiusInMeters: 5),
      isFalse,
    );
    expect(
      LocationUtils.isWithinRadius(origin, origin, radiusInMeters: -1),
      isFalse,
    );
  });

  test('validates latitude and longitude boundaries', () {
    expect(LocationUtils.isValidCoordinates(origin), isTrue);
    expect(
      LocationUtils.isValidCoordinates(
        const GeoCoordinates(latitude: 91, longitude: 0),
      ),
      isFalse,
    );
    expect(
      LocationUtils.isValidCoordinates(
        const GeoCoordinates(latitude: 0, longitude: -181),
      ),
      isFalse,
    );
  });

  test('formats an address and removes empty or duplicate values', () {
    const address = LocationAddress(
      street: 'Jl. Sudirman',
      subLocality: 'Karet',
      locality: 'Jakarta',
      administrativeArea: 'Jakarta',
      postalCode: '10220',
      country: 'Indonesia',
    );

    expect(
      LocationUtils.formatAddress(address),
      'Jl. Sudirman, Karet, Jakarta, 10220, Indonesia',
    );
  });
}
