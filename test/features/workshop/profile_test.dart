import 'package:flutter_test/flutter_test.dart';

bool isValidProfile(String location, List<double> prices) {
  return location.isNotEmpty && prices.every((p) => p > 0);
}

void main() {
  test('valid profile', () {
    expect(isValidProfile('Cairo', [100]), true);
  });

  test('invalid profile', () {
    expect(isValidProfile('', [0]), false);
  });
}