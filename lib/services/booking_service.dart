// File: lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createBooking({
    required String userId,
    required String tourName,
    required DateTime date,
    required String timeSlot,
    required int guests,
    required bool includeTransportation,
    required bool includeGuide,
  }) async {
    final bookingId = const Uuid().v4();
    await _firestore.collection('bookings').doc(bookingId).set({
      'user_id': userId,
      'tour_name': tourName,
      'date': Timestamp.fromDate(date),
      'status': 'confirmed',
      'time_slot': timeSlot,
      'guests': guests,
      'include_transportation': includeTransportation,
      'include_guide': includeGuide,
      'created_at': Timestamp.now(),
    });
  }
}
