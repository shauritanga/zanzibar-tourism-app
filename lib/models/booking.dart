import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String tourName;
  final DateTime date;
  final String timeSlot;
  final int guests;
  final bool includeTransportation;
  final bool includeGuide;
  final String status;

  Booking({
    required this.id,
    required this.userId,
    required this.tourName,
    required this.date,
    required this.timeSlot,
    required this.guests,
    required this.includeTransportation,
    required this.includeGuide,
    required this.status,
  });

  factory Booking.fromMap(Map<String, dynamic> data, String id) {
    return Booking(
      id: id,
      timeSlot: data['time_slot'] ?? '',
      guests: data['guests'] ?? 0,
      includeTransportation: data['include_transportation'] ?? false,
      includeGuide: data['include_guide'] ?? false,
      userId: data['user_id'] ?? '',
      tourName: data['tour_name'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      status: data['status'] ?? '',
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'time_slot': timeSlot,
      'guests': guests,
      'include_transportation': includeTransportation,
      'include_guide': includeGuide,
      'tour_name': tourName,
      'date': Timestamp.fromDate(date),
      'status': status,
    };
  }
}
