// File: lib/providers/cultural_site_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/models/cultural_site.dart';

final culturalSitesProvider = StreamProvider<List<CulturalSite>>((ref) {
  return FirebaseFirestore.instance
      .collection('cultural_sites')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => CulturalSite.fromMap(doc.data(), doc.id))
                .toList(),
      );
});

final culturalSitesFutureProvider = FutureProvider<List<CulturalSite>>((
  ref,
) async {
  final snapshot =
      await FirebaseFirestore.instance.collection('cultural_sites').get();

  return snapshot.docs
      .map((doc) => CulturalSite.fromMap(doc.data(), doc.id))
      .toList();
});
