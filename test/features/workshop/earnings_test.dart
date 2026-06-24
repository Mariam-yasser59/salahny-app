import 'package:flutter_test/flutter_test.dart';

double calculateTotal(List<double> list) {
  return list.fold(0, (a, b) => a + b);
}

void main() {
  test('calculate earnings', () {
    expect(calculateTotal([200, 300]), 500);
  });

  test('empty earnings', () {
    expect(calculateTotal([]), 0);
  });
}