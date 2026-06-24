import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salahny_fixed/features/driver/profile/profile_screen.dart';
import 'package:salahny_fixed/shared/models/models.dart';
import 'package:salahny_fixed/shared/services/app_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppCache.setCurrentUser(
      UserModel(
        id: 'driver-1',
        name: 'Mariam',
        phone: '01000000000',
        email: 'mariam@example.com',
        role: 'driver',
        activeSubscription: ActiveSubscription(
          packageName: 'Premium Care',
          startsAt: DateTime(2026, 5, 1),
          endsAt: DateTime(2026, 6, 1),
          remainingDays: 15,
        ),
      ),
    );
  });

  testWidgets('profile shows active subscription details', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Active Subscription'), findsOneWidget);
    expect(find.text('Premium Care'), findsWidgets);
    expect(find.text('15 days'), findsOneWidget);
    expect(find.text('2026-06-01'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
