// File: lib/providers/promotions_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/models/promotion.dart';

final promotionsProvider = StreamProvider<List<Promotion>>((ref) {
  return FirebaseFirestore.instance
      .collection('promotions')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Promotion.fromMap(doc.data(), doc.id))
            .where((promotion) => promotion.isValid)
            .toList(),
      );
});

final activePromotionsProvider = StreamProvider<List<Promotion>>((ref) {
  final now = DateTime.now();
  return FirebaseFirestore.instance
      .collection('promotions')
      .where('isActive', isEqualTo: true)
      .where('validFrom', isLessThanOrEqualTo: Timestamp.fromDate(now))
      .where('validUntil', isGreaterThan: Timestamp.fromDate(now))
      .orderBy('validUntil')
      .orderBy('discountPercentage', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Promotion.fromMap(doc.data(), doc.id))
            .where((promotion) => promotion.isValid)
            .toList(),
      );
});

final featuredPromotionProvider = StreamProvider<Promotion?>((ref) {
  final now = DateTime.now();
  return FirebaseFirestore.instance
      .collection('promotions')
      .where('isActive', isEqualTo: true)
      .where('validFrom', isLessThanOrEqualTo: Timestamp.fromDate(now))
      .where('validUntil', isGreaterThan: Timestamp.fromDate(now))
      .orderBy('validUntil')
      .orderBy('discountPercentage', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) return null;
    final promotion = Promotion.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    return promotion.isValid ? promotion : null;
  });
});

final promotionByIdProvider = StreamProvider.family<Promotion?, String>((ref, promotionId) {
  return FirebaseFirestore.instance
      .collection('promotions')
      .doc(promotionId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return Promotion.fromMap(doc.data()!, doc.id);
  });
});

final promotionsByCategoryProvider = StreamProvider.family<List<Promotion>, String>((ref, category) {
  final now = DateTime.now();
  return FirebaseFirestore.instance
      .collection('promotions')
      .where('isActive', isEqualTo: true)
      .where('category', isEqualTo: category)
      .where('validFrom', isLessThanOrEqualTo: Timestamp.fromDate(now))
      .where('validUntil', isGreaterThan: Timestamp.fromDate(now))
      .orderBy('validUntil')
      .orderBy('discountPercentage', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Promotion.fromMap(doc.data(), doc.id))
            .where((promotion) => promotion.isValid)
            .toList(),
      );
});

final promotionByCodeProvider = FutureProvider.family<Promotion?, String>((ref, code) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('promotions')
      .where('discountCode', isEqualTo: code)
      .where('isActive', isEqualTo: true)
      .limit(1)
      .get();

  if (snapshot.docs.isEmpty) return null;
  final promotion = Promotion.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
  return promotion.isValid ? promotion : null;
});
