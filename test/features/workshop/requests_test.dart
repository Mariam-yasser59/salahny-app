import 'package:flutter_test/flutter_test.dart';

String handleRequest(bool accept) {
  return accept ? 'Accepted' : 'Rejected';
}

void main() {
  test('accept request', () {
    expect(handleRequest(true), 'Accepted');
  });

  test('reject request', () {
    expect(handleRequest(false), 'Rejected');
  });
}