// File: lib/providers/marketplace_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/models/product.dart';

final marketplaceProvider = StreamProvider<List<Product>>((ref) {
  return FirebaseFirestore.instance
      .collection('products')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => Product.fromMap(doc.data(), doc.id))
                .toList(),
      );
});
