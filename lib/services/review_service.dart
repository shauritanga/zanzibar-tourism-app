import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());

enum ReviewType { product, culturalSite, tour }

class Review {
  final String id;
  final String itemId;
  final String userId;
  final String userName;
  final String userAvatar;
  final ReviewType type;
  final double rating;
  final String comment;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int helpfulCount;
  final bool isVerifiedPurchase;

  Review({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.type,
    required this.rating,
    required this.comment,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    required this.helpfulCount,
    required this.isVerifiedPurchase,
  });

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      itemId: map['itemId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userAvatar: map['userAvatar'] ?? '',
      type: ReviewType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReviewType.product,
      ),
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      helpfulCount: map['helpfulCount'] ?? 0,
      isVerifiedPurchase: map['isVerifiedPurchase'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'type': type.name,
      'rating': rating,
      'comment': comment,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'helpfulCount': helpfulCount,
      'isVerifiedPurchase': isVerifiedPurchase,
    };
  }
}

class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });
}

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a review
  Future<void> addReview({
    required String itemId,
    required String userId,
    required String userName,
    required String userAvatar,
    required ReviewType type,
    required double rating,
    required String comment,
    List<String> images = const [],
    bool isVerifiedPurchase = false,
  }) async {
    try {
      // Check if user already reviewed this item
      final existing = await _firestore
          .collection('reviews')
          .where('itemId', isEqualTo: itemId)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.name)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('You have already reviewed this item');
      }

      // Add the review
      await _firestore.collection('reviews').add({
        'itemId': itemId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'type': type.name,
        'rating': rating,
        'comment': comment,
        'images': images,
        'helpfulCount': 0,
        'isVerifiedPurchase': isVerifiedPurchase,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update item's average rating
      await _updateItemRating(itemId, type);
    } catch (e) {
      throw Exception('Failed to add review: $e');
    }
  }

  // Update a review
  Future<void> updateReview({
    required String reviewId,
    required double rating,
    required String comment,
    List<String> images = const [],
  }) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'rating': rating,
        'comment': comment,
        'images': images,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get the review to update item rating
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (reviewDoc.exists) {
        final review = Review.fromMap(reviewDoc.data()!, reviewDoc.id);
        await _updateItemRating(review.itemId, review.type);
      }
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      // Get the review first to update item rating
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (reviewDoc.exists) {
        final review = Review.fromMap(reviewDoc.data()!, reviewDoc.id);
        
        await _firestore.collection('reviews').doc(reviewId).delete();
        await _updateItemRating(review.itemId, review.type);
      }
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }

  // Get reviews for an item
  Stream<List<Review>> getItemReviews(String itemId, ReviewType type) {
    return _firestore
        .collection('reviews')
        .where('itemId', isEqualTo: itemId)
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Review.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get user's reviews
  Stream<List<Review>> getUserReviews(String userId) {
    return _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Review.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get review statistics for an item
  Future<ReviewStats> getReviewStats(String itemId, ReviewType type) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('itemId', isEqualTo: itemId)
          .where('type', isEqualTo: type.name)
          .get();

      if (snapshot.docs.isEmpty) {
        return ReviewStats(
          averageRating: 0.0,
          totalReviews: 0,
          ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        );
      }

      double totalRating = 0;
      Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var doc in snapshot.docs) {
        final rating = (doc.data()['rating'] ?? 0.0).toDouble();
        totalRating += rating;
        final ratingInt = rating.round();
        distribution[ratingInt] = (distribution[ratingInt] ?? 0) + 1;
      }

      return ReviewStats(
        averageRating: totalRating / snapshot.docs.length,
        totalReviews: snapshot.docs.length,
        ratingDistribution: distribution,
      );
    } catch (e) {
      throw Exception('Failed to get review stats: $e');
    }
  }

  // Mark review as helpful
  Future<void> markReviewHelpful(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'helpfulCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to mark review as helpful: $e');
    }
  }

  // Check if user can review (has purchased/visited)
  Future<bool> canUserReview(String userId, String itemId, ReviewType type) async {
    try {
      // Check if user already reviewed
      final existingReview = await _firestore
          .collection('reviews')
          .where('itemId', isEqualTo: itemId)
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.name)
          .get();

      if (existingReview.docs.isNotEmpty) {
        return false; // Already reviewed
      }

      // Check if user has purchased/booked the item
      String collectionName;
      switch (type) {
        case ReviewType.product:
          collectionName = 'orders';
          break;
        case ReviewType.culturalSite:
        case ReviewType.tour:
          collectionName = 'bookings';
          break;
      }

      final purchaseSnapshot = await _firestore
          .collection(collectionName)
          .where('userId', isEqualTo: userId)
          .where('itemId', isEqualTo: itemId)
          .get();

      return purchaseSnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Update item's average rating
  Future<void> _updateItemRating(String itemId, ReviewType type) async {
    try {
      final stats = await getReviewStats(itemId, type);
      
      String collectionName;
      switch (type) {
        case ReviewType.product:
          collectionName = 'products';
          break;
        case ReviewType.culturalSite:
          collectionName = 'cultural_sites';
          break;
        case ReviewType.tour:
          collectionName = 'tours';
          break;
      }

      await _firestore.collection(collectionName).doc(itemId).update({
        'rating': stats.averageRating,
        'reviewCount': stats.totalReviews,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail to avoid breaking the review process
      print('Failed to update item rating: $e');
    }
  }
}
