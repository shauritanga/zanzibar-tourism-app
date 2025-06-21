import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final favoritesServiceProvider = Provider<FavoritesService>((ref) => FavoritesService());

enum FavoriteType { product, culturalSite, tour }

class FavoriteItem {
  final String id;
  final String itemId;
  final String userId;
  final FavoriteType type;
  final String title;
  final String description;
  final String imageUrl;
  final double? price;
  final DateTime createdAt;

  FavoriteItem({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.price,
    required this.createdAt,
  });

  factory FavoriteItem.fromMap(Map<String, dynamic> map, String id) {
    return FavoriteItem(
      id: id,
      itemId: map['itemId'] ?? '',
      userId: map['userId'] ?? '',
      type: FavoriteType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FavoriteType.product,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: map['price']?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'userId': userId,
      'type': type.name,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add item to favorites
  Future<void> addToFavorites({
    required String userId,
    required String itemId,
    required FavoriteType type,
    required String title,
    required String description,
    required String imageUrl,
    double? price,
  }) async {
    try {
      // Check if already in favorites
      final existing = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('itemId', isEqualTo: itemId)
          .where('type', isEqualTo: type.name)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Item already in favorites');
      }

      await _firestore.collection('favorites').add({
        'userId': userId,
        'itemId': itemId,
        'type': type.name,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'price': price,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  // Remove item from favorites
  Future<void> removeFromFavorites({
    required String userId,
    required String itemId,
    required FavoriteType type,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('itemId', isEqualTo: itemId)
          .where('type', isEqualTo: type.name)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  // Check if item is in favorites
  Future<bool> isFavorite({
    required String userId,
    required String itemId,
    required FavoriteType type,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('itemId', isEqualTo: itemId)
          .where('type', isEqualTo: type.name)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get user's favorites
  Stream<List<FavoriteItem>> getUserFavorites(String userId) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FavoriteItem.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get favorites by type
  Stream<List<FavoriteItem>> getFavoritesByType(String userId, FavoriteType type) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FavoriteItem.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get favorites count for user
  Future<int> getFavoritesCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite({
    required String userId,
    required String itemId,
    required FavoriteType type,
    required String title,
    required String description,
    required String imageUrl,
    double? price,
  }) async {
    try {
      final isFav = await isFavorite(
        userId: userId,
        itemId: itemId,
        type: type,
      );

      if (isFav) {
        await removeFromFavorites(
          userId: userId,
          itemId: itemId,
          type: type,
        );
        return false;
      } else {
        await addToFavorites(
          userId: userId,
          itemId: itemId,
          type: type,
          title: title,
          description: description,
          imageUrl: imageUrl,
          price: price,
        );
        return true;
      }
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  // Clear all favorites for user
  Future<void> clearAllFavorites(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear favorites: $e');
    }
  }
}
