import 'package:flutter_test/flutter_test.dart';

bool canView(bool exists) {
  return exists;
}

void main() {
  test('can view details', () {
    expect(canView(true), true);
  });

  test('cannot view details', () {
    expect(canView(false), false);
  });
}