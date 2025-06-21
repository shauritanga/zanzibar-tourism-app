// File: lib/providers/tours_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/models/tour.dart';

final toursProvider = StreamProvider<List<Tour>>((ref) {
  return FirebaseFirestore.instance
      .collection('tours')
      .where('isActive', isEqualTo: true)
      .orderBy('rating', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Tour.fromMap(doc.data(), doc.id))
            .toList(),
      );
});

final toursFutureProvider = FutureProvider<List<Tour>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('tours')
      .where('isActive', isEqualTo: true)
      .orderBy('rating', descending: true)
      .get();

  return snapshot.docs
      .map((doc) => Tour.fromMap(doc.data(), doc.id))
      .toList();
});

final tourByIdProvider = StreamProvider.family<Tour?, String>((ref, tourId) {
  return FirebaseFirestore.instance
      .collection('tours')
      .doc(tourId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return Tour.fromMap(doc.data()!, doc.id);
  });
});

final toursByCategoryProvider = StreamProvider.family<List<Tour>, String>((ref, category) {
  return FirebaseFirestore.instance
      .collection('tours')
      .where('isActive', isEqualTo: true)
      .where('category', isEqualTo: category)
      .orderBy('rating', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Tour.fromMap(doc.data(), doc.id))
            .toList(),
      );
});

final featuredToursProvider = StreamProvider<List<Tour>>((ref) {
  return FirebaseFirestore.instance
      .collection('tours')
      .where('isActive', isEqualTo: true)
      .where('rating', isGreaterThanOrEqualTo: 4.5)
      .orderBy('rating', descending: true)
      .limit(3)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Tour.fromMap(doc.data(), doc.id))
            .toList(),
      );
});
