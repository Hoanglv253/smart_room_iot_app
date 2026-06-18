import 'package:flutter_test/flutter_test.dart';
import 'package:apart_hub/core/services/app_firestore_service.dart';

void main() {
  test('UserRole labels are mapped', () {
    expect(UserRole.label(UserRole.admin), 'Quan tri vien');
    expect(UserRole.label(UserRole.manager), 'Quan ly');
    expect(UserRole.label(UserRole.user), 'Nguoi dung');
  });
}
