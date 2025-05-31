// File: lib/providers/education_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/models/educational_content.dart';

final educationContentProvider = StreamProvider<List<EducationalContent>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection('educational_content')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => EducationalContent.fromMap(doc.data(), doc.id))
                .toList(),
      );
});
