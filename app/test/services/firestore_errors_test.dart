import 'package:baskit/services/firestore_errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('list-not-found errors preserve the missing list id', () {
    final error = ListNotFoundException('missing-list');
    expect(error.listId, 'missing-list');
    expect(error.toString(), 'ListNotFoundException: missing-list');
  });

  test('list action errors preserve the user-facing message', () {
    const error = ListActionException('Could not add item');
    expect(error.message, 'Could not add item');
    expect(error.toString(), 'ListActionException: Could not add item');
  });
}
