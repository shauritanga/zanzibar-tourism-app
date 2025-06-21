import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/services/admin_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});
