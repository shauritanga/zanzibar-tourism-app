// File: lib/providers/booking_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/services/booking_service.dart';

final bookingProvider = Provider((ref) => FirestoreService());
