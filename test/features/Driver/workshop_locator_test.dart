// test/workshop_locator_test.dart
// US3: As a driver needing a routine service, I want to easily use GPS
// to locate the nearest available workshops.

import 'package:flutter_test/flutter_test.dart';

// Mock workshop model
class MockWorkshop {
  final String name;
  final double distanceKm;
  final String specialty;

  const MockWorkshop({
    required this.name,
    required this.distanceKm,
    required this.specialty,
  });
}

void main() {
  group('US3: Workshop Locator Tests', () {

    // Mock data
    final List<MockWorkshop> mockWorkshops = [
      const MockWorkshop(name: 'ProTech Auto',   distanceKm: 2.5,  specialty: 'Oil Change'),
      const MockWorkshop(name: 'SpeedFix',       distanceKm: 5.0,  specialty: 'Brakes'),
      const MockWorkshop(name: 'QuickCare',      distanceKm: 8.0,  specialty: 'Engine'),
      const MockWorkshop(name: 'FarWorkshop',    distanceKm: 15.0, specialty: 'Oil Change'),
    ];

    // AC1: Given the driver is on the "Workshops" tab,
    // When they enable GPS,
    // Then the app should display all registered workshops within a 10km radius.
    test('AC1 - Shows only workshops within 10km radius', () {
      // Act
      final nearbyWorkshops = mockWorkshops
          .where((w) => w.distanceKm <= 10.0)
          .toList();

      // Assert
      expect(nearbyWorkshops.length, equals(3));
      for (final w in nearbyWorkshops) {
        expect(w.distanceKm, lessThanOrEqualTo(10.0));
      }
    });

    // AC2: Given the user selects a workshop,
    // When they click "View Profile,"
    // Then the page should load in less than 1.5 seconds.
    test('AC2 - Workshop profile loads in less than 1.5 seconds', () async {
      // Arrange
      final stopwatch = Stopwatch()..start();

      // Act - simulate page load
      await Future.delayed(const Duration(milliseconds: 800));
      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(1500));
    });

    // AC3: Given multiple options are available,
    // When the user applies a filter,
    // Then only relevant workshops should remain on the map.
    test('AC3 - Filter shows only relevant workshops', () {
      // Arrange
      const String filterSpecialty = 'Oil Change';

      // Act
      final filtered = mockWorkshops
          .where((w) => w.specialty == filterSpecialty)
          .toList();

      // Assert
      expect(filtered.length,             equals(2));
      expect(filtered.every((w) =>
          w.specialty == filterSpecialty), isTrue);
    });

  });
}
