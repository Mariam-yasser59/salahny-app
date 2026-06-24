import 'package:flutter_test/flutter_test.dart';
import 'package:salahny_fixed/shared/models/admin_models.dart';
import 'package:salahny_fixed/shared/services/app_cache.dart';

void main() {
  group('Admin hidden access demo', () {
    test('pass: hidden admin credentials are accepted', () {
      expect(
        AppCache.validateAdminCredentials('admin@salahny.com', 'admin123'),
        isTrue,
      );
    });

    test('fail: non-admin credentials are rejected', () {
      expect(
        AppCache.validateAdminCredentials('driver@salahny.com', 'admin123'),
        isFalse,
      );
      expect(
        AppCache.validateAdminCredentials('admin@salahny.com', 'wrong-pass'),
        isFalse,
      );
    });
  });

  group('Admin package demo', () {
    test('package model keeps admin package details stable', () {
      const package = ManagedPackage(
        id: 'pkg-demo',
        name: 'Gold Plan',
        tagline: 'Best for busy drivers',
        duration: '3 months',
        price: 149,
        originalPrice: 189,
        features: ['Priority booking', 'Special discounts'],
        isPopular: true,
      );

      final model = package.toPackageModel();

      expect(model.name, 'Gold Plan');
      expect(model.duration, '3 months');
      expect(model.features, contains('Priority booking'));
      expect(model.isPopular, isTrue);
    });
  });
}
