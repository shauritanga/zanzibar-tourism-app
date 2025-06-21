import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

final aiRecommendationsServiceProvider = Provider<AIRecommendationsService>((ref) => AIRecommendationsService());

enum RecommendationType {
  products,
  culturalSites,
  tours,
  mixed,
}

class RecommendationItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double price;
  final double rating;
  final String category;
  final RecommendationType type;
  final double confidence;
  final String reason;
  final Map<String, dynamic> metadata;

  RecommendationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.category,
    required this.type,
    required this.confidence,
    required this.reason,
    required this.metadata,
  });

  factory RecommendationItem.fromProduct(Map<String, dynamic> data, String id, double confidence, String reason) {
    return RecommendationItem(
      id: id,
      title: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['image'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      type: RecommendationType.products,
      confidence: confidence,
      reason: reason,
      metadata: data,
    );
  }

  factory RecommendationItem.fromCulturalSite(Map<String, dynamic> data, String id, double confidence, String reason) {
    return RecommendationItem(
      id: id,
      title: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['images'] != null && (data['images'] as List).isNotEmpty 
          ? data['images'][0] 
          : '',
      price: (data['entryFee'] ?? 0.0).toDouble(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      type: RecommendationType.culturalSites,
      confidence: confidence,
      reason: reason,
      metadata: data,
    );
  }

  factory RecommendationItem.fromTour(Map<String, dynamic> data, String id, double confidence, String reason) {
    return RecommendationItem(
      id: id,
      title: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['image'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      type: RecommendationType.tours,
      confidence: confidence,
      reason: reason,
      metadata: data,
    );
  }
}

class UserPreferences {
  final String userId;
  final List<String> favoriteCategories;
  final Map<String, double> categoryScores;
  final double averageSpending;
  final double minRatingPreference;
  final List<String> visitedSites;
  final List<String> purchasedProducts;
  final List<String> bookedTours;
  final Map<String, int> interactionCounts;
  final DateTime lastUpdated;

  UserPreferences({
    required this.userId,
    required this.favoriteCategories,
    required this.categoryScores,
    required this.averageSpending,
    required this.minRatingPreference,
    required this.visitedSites,
    required this.purchasedProducts,
    required this.bookedTours,
    required this.interactionCounts,
    required this.lastUpdated,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map, String id) {
    return UserPreferences(
      userId: id,
      favoriteCategories: List<String>.from(map['favoriteCategories'] ?? []),
      categoryScores: Map<String, double>.from(map['categoryScores'] ?? {}),
      averageSpending: (map['averageSpending'] ?? 0.0).toDouble(),
      minRatingPreference: (map['minRatingPreference'] ?? 0.0).toDouble(),
      visitedSites: List<String>.from(map['visitedSites'] ?? []),
      purchasedProducts: List<String>.from(map['purchasedProducts'] ?? []),
      bookedTours: List<String>.from(map['bookedTours'] ?? []),
      interactionCounts: Map<String, int>.from(map['interactionCounts'] ?? {}),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'favoriteCategories': favoriteCategories,
      'categoryScores': categoryScores,
      'averageSpending': averageSpending,
      'minRatingPreference': minRatingPreference,
      'visitedSites': visitedSites,
      'purchasedProducts': purchasedProducts,
      'bookedTours': bookedTours,
      'interactionCounts': interactionCounts,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

class AIRecommendationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Get personalized recommendations
  Future<List<RecommendationItem>> getPersonalizedRecommendations({
    required String userId,
    RecommendationType type = RecommendationType.mixed,
    int limit = 10,
  }) async {
    try {
      final userPreferences = await _getUserPreferences(userId);
      final recommendations = <RecommendationItem>[];

      if (type == RecommendationType.mixed || type == RecommendationType.products) {
        final productRecs = await _getProductRecommendations(userPreferences, limit ~/ 3);
        recommendations.addAll(productRecs);
      }

      if (type == RecommendationType.mixed || type == RecommendationType.culturalSites) {
        final siteRecs = await _getCulturalSiteRecommendations(userPreferences, limit ~/ 3);
        recommendations.addAll(siteRecs);
      }

      if (type == RecommendationType.mixed || type == RecommendationType.tours) {
        final tourRecs = await _getTourRecommendations(userPreferences, limit ~/ 3);
        recommendations.addAll(tourRecs);
      }

      // Sort by confidence score
      recommendations.sort((a, b) => b.confidence.compareTo(a.confidence));

      return recommendations.take(limit).toList();
    } catch (e) {
      print('Error getting personalized recommendations: $e');
      return await _getFallbackRecommendations(type, limit);
    }
  }

  // Get trending recommendations
  Future<List<RecommendationItem>> getTrendingRecommendations({
    RecommendationType type = RecommendationType.mixed,
    int limit = 10,
  }) async {
    try {
      final recommendations = <RecommendationItem>[];
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      if (type == RecommendationType.mixed || type == RecommendationType.products) {
        final products = await _getTrendingProducts(thirtyDaysAgo, limit ~/ 3);
        recommendations.addAll(products);
      }

      if (type == RecommendationType.mixed || type == RecommendationType.culturalSites) {
        final sites = await _getTrendingSites(thirtyDaysAgo, limit ~/ 3);
        recommendations.addAll(sites);
      }

      if (type == RecommendationType.mixed || type == RecommendationType.tours) {
        final tours = await _getTrendingTours(thirtyDaysAgo, limit ~/ 3);
        recommendations.addAll(tours);
      }

      // Shuffle for variety
      recommendations.shuffle(_random);

      return recommendations.take(limit).toList();
    } catch (e) {
      print('Error getting trending recommendations: $e');
      return await _getFallbackRecommendations(type, limit);
    }
  }

  // Get similar items
  Future<List<RecommendationItem>> getSimilarItems({
    required String itemId,
    required RecommendationType itemType,
    int limit = 5,
  }) async {
    try {
      switch (itemType) {
        case RecommendationType.products:
          return await _getSimilarProducts(itemId, limit);
        case RecommendationType.culturalSites:
          return await _getSimilarSites(itemId, limit);
        case RecommendationType.tours:
          return await _getSimilarTours(itemId, limit);
        default:
          return [];
      }
    } catch (e) {
      print('Error getting similar items: $e');
      return [];
    }
  }

  // Update user preferences based on interactions
  Future<void> updateUserPreferences({
    required String userId,
    String? viewedItemId,
    String? viewedItemType,
    String? purchasedItemId,
    String? bookedTourId,
    String? favoriteItemId,
    String? category,
    double? spentAmount,
  }) async {
    try {
      final userPrefsRef = _firestore.collection('user_preferences').doc(userId);
      final doc = await userPrefsRef.get();

      UserPreferences preferences;
      if (doc.exists) {
        preferences = UserPreferences.fromMap(doc.data()!, doc.id);
      } else {
        preferences = UserPreferences(
          userId: userId,
          favoriteCategories: [],
          categoryScores: {},
          averageSpending: 0.0,
          minRatingPreference: 0.0,
          visitedSites: [],
          purchasedProducts: [],
          bookedTours: [],
          interactionCounts: {},
          lastUpdated: DateTime.now(),
        );
      }

      // Update based on interaction type
      final updatedPreferences = _updatePreferencesFromInteraction(
        preferences,
        viewedItemId: viewedItemId,
        viewedItemType: viewedItemType,
        purchasedItemId: purchasedItemId,
        bookedTourId: bookedTourId,
        favoriteItemId: favoriteItemId,
        category: category,
        spentAmount: spentAmount,
      );

      await userPrefsRef.set(updatedPreferences.toMap());
    } catch (e) {
      print('Error updating user preferences: $e');
    }
  }

  UserPreferences _updatePreferencesFromInteraction(
    UserPreferences preferences, {
    String? viewedItemId,
    String? viewedItemType,
    String? purchasedItemId,
    String? bookedTourId,
    String? favoriteItemId,
    String? category,
    double? spentAmount,
  }) {
    final newCategoryScores = Map<String, double>.from(preferences.categoryScores);
    final newInteractionCounts = Map<String, int>.from(preferences.interactionCounts);
    final newFavoriteCategories = List<String>.from(preferences.favoriteCategories);
    final newVisitedSites = List<String>.from(preferences.visitedSites);
    final newPurchasedProducts = List<String>.from(preferences.purchasedProducts);
    final newBookedTours = List<String>.from(preferences.bookedTours);

    // Update category scores
    if (category != null) {
      double currentScore = newCategoryScores[category] ?? 0.0;
      
      if (favoriteItemId != null) {
        currentScore += 5.0; // High weight for favorites
      } else if (purchasedItemId != null || bookedTourId != null) {
        currentScore += 3.0; // Medium weight for purchases/bookings
      } else if (viewedItemId != null) {
        currentScore += 1.0; // Low weight for views
      }
      
      newCategoryScores[category] = currentScore;
      
      // Update favorite categories
      if (!newFavoriteCategories.contains(category) && currentScore >= 10.0) {
        newFavoriteCategories.add(category);
      }
    }

    // Update interaction counts
    if (viewedItemType != null) {
      newInteractionCounts[viewedItemType] = (newInteractionCounts[viewedItemType] ?? 0) + 1;
    }

    // Update specific lists
    if (purchasedItemId != null && !newPurchasedProducts.contains(purchasedItemId)) {
      newPurchasedProducts.add(purchasedItemId);
    }
    
    if (bookedTourId != null && !newBookedTours.contains(bookedTourId)) {
      newBookedTours.add(bookedTourId);
    }

    // Calculate new average spending
    double newAverageSpending = preferences.averageSpending;
    if (spentAmount != null) {
      final totalPurchases = newPurchasedProducts.length + newBookedTours.length;
      if (totalPurchases > 0) {
        newAverageSpending = ((preferences.averageSpending * (totalPurchases - 1)) + spentAmount) / totalPurchases;
      } else {
        newAverageSpending = spentAmount;
      }
    }

    return UserPreferences(
      userId: preferences.userId,
      favoriteCategories: newFavoriteCategories,
      categoryScores: newCategoryScores,
      averageSpending: newAverageSpending,
      minRatingPreference: preferences.minRatingPreference,
      visitedSites: newVisitedSites,
      purchasedProducts: newPurchasedProducts,
      bookedTours: newBookedTours,
      interactionCounts: newInteractionCounts,
      lastUpdated: DateTime.now(),
    );
  }

  Future<UserPreferences> _getUserPreferences(String userId) async {
    try {
      final doc = await _firestore.collection('user_preferences').doc(userId).get();
      
      if (doc.exists) {
        return UserPreferences.fromMap(doc.data()!, doc.id);
      } else {
        // Create default preferences
        return UserPreferences(
          userId: userId,
          favoriteCategories: [],
          categoryScores: {},
          averageSpending: 50.0, // Default
          minRatingPreference: 3.0, // Default
          visitedSites: [],
          purchasedProducts: [],
          bookedTours: [],
          interactionCounts: {},
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      throw Exception('Failed to get user preferences: $e');
    }
  }

  Future<List<RecommendationItem>> _getProductRecommendations(UserPreferences preferences, int limit) async {
    final recommendations = <RecommendationItem>[];
    
    // Get products based on favorite categories
    for (final category in preferences.favoriteCategories.take(3)) {
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .where('rating', isGreaterThanOrEqualTo: preferences.minRatingPreference)
          .orderBy('rating', descending: true)
          .limit(limit ~/ 3)
          .get();

      for (final doc in snapshot.docs) {
        if (!preferences.purchasedProducts.contains(doc.id)) {
          final confidence = _calculateProductConfidence(doc.data(), preferences);
          final reason = 'Based on your interest in $category';
          
          recommendations.add(RecommendationItem.fromProduct(
            doc.data(),
            doc.id,
            confidence,
            reason,
          ));
        }
      }
    }

    return recommendations;
  }

  Future<List<RecommendationItem>> _getCulturalSiteRecommendations(UserPreferences preferences, int limit) async {
    final recommendations = <RecommendationItem>[];
    
    final snapshot = await _firestore
        .collection('cultural_sites')
        .where('rating', isGreaterThanOrEqualTo: preferences.minRatingPreference)
        .orderBy('rating', descending: true)
        .limit(limit)
        .get();

    for (final doc in snapshot.docs) {
      if (!preferences.visitedSites.contains(doc.id)) {
        final confidence = _calculateSiteConfidence(doc.data(), preferences);
        final reason = 'Highly rated cultural site';
        
        recommendations.add(RecommendationItem.fromCulturalSite(
          doc.data(),
          doc.id,
          confidence,
          reason,
        ));
      }
    }

    return recommendations;
  }

  Future<List<RecommendationItem>> _getTourRecommendations(UserPreferences preferences, int limit) async {
    final recommendations = <RecommendationItem>[];
    
    final snapshot = await _firestore
        .collection('tours')
        .where('rating', isGreaterThanOrEqualTo: preferences.minRatingPreference)
        .orderBy('rating', descending: true)
        .limit(limit)
        .get();

    for (final doc in snapshot.docs) {
      if (!preferences.bookedTours.contains(doc.id)) {
        final confidence = _calculateTourConfidence(doc.data(), preferences);
        final reason = 'Popular tour experience';
        
        recommendations.add(RecommendationItem.fromTour(
          doc.data(),
          doc.id,
          confidence,
          reason,
        ));
      }
    }

    return recommendations;
  }

  double _calculateProductConfidence(Map<String, dynamic> product, UserPreferences preferences) {
    double confidence = 0.5; // Base confidence
    
    final category = product['category'] as String?;
    final price = (product['price'] ?? 0.0).toDouble();
    final rating = (product['rating'] ?? 0.0).toDouble();
    
    // Category preference
    if (category != null && preferences.categoryScores.containsKey(category)) {
      confidence += (preferences.categoryScores[category]! / 20.0).clamp(0.0, 0.3);
    }
    
    // Price preference
    if (preferences.averageSpending > 0) {
      final priceRatio = price / preferences.averageSpending;
      if (priceRatio >= 0.5 && priceRatio <= 2.0) {
        confidence += 0.2;
      }
    }
    
    // Rating boost
    confidence += (rating / 5.0) * 0.3;
    
    return confidence.clamp(0.0, 1.0);
  }

  double _calculateSiteConfidence(Map<String, dynamic> site, UserPreferences preferences) {
    double confidence = 0.6; // Base confidence for sites
    
    final rating = (site['rating'] ?? 0.0).toDouble();
    final category = site['category'] as String?;
    
    // Category preference
    if (category != null && preferences.categoryScores.containsKey(category)) {
      confidence += (preferences.categoryScores[category]! / 20.0).clamp(0.0, 0.2);
    }
    
    // Rating boost
    confidence += (rating / 5.0) * 0.2;
    
    return confidence.clamp(0.0, 1.0);
  }

  double _calculateTourConfidence(Map<String, dynamic> tour, UserPreferences preferences) {
    double confidence = 0.5; // Base confidence
    
    final price = (tour['price'] ?? 0.0).toDouble();
    final rating = (tour['rating'] ?? 0.0).toDouble();
    
    // Price preference
    if (preferences.averageSpending > 0) {
      final priceRatio = price / preferences.averageSpending;
      if (priceRatio >= 0.5 && priceRatio <= 2.0) {
        confidence += 0.3;
      }
    }
    
    // Rating boost
    confidence += (rating / 5.0) * 0.2;
    
    return confidence.clamp(0.0, 1.0);
  }

  Future<List<RecommendationItem>> _getTrendingProducts(DateTime since, int limit) async {
    // Simplified trending logic - in production, you'd analyze view/purchase data
    final snapshot = await _firestore
        .collection('products')
        .orderBy('rating', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      return RecommendationItem.fromProduct(
        doc.data(),
        doc.id,
        0.8, // High confidence for trending
        'Trending now',
      );
    }).toList();
  }

  Future<List<RecommendationItem>> _getTrendingSites(DateTime since, int limit) async {
    final snapshot = await _firestore
        .collection('cultural_sites')
        .orderBy('rating', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      return RecommendationItem.fromCulturalSite(
        doc.data(),
        doc.id,
        0.8,
        'Popular destination',
      );
    }).toList();
  }

  Future<List<RecommendationItem>> _getTrendingTours(DateTime since, int limit) async {
    final snapshot = await _firestore
        .collection('tours')
        .orderBy('rating', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      return RecommendationItem.fromTour(
        doc.data(),
        doc.id,
        0.8,
        'Popular experience',
      );
    }).toList();
  }

  Future<List<RecommendationItem>> _getSimilarProducts(String productId, int limit) async {
    // Get the original product
    final productDoc = await _firestore.collection('products').doc(productId).get();
    if (!productDoc.exists) return [];

    final productData = productDoc.data()!;
    final category = productData['category'] as String?;

    if (category == null) return [];

    // Get similar products in the same category
    final snapshot = await _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .orderBy('rating', descending: true)
        .limit(limit + 1) // +1 to exclude the original
        .get();

    return snapshot.docs
        .where((doc) => doc.id != productId)
        .take(limit)
        .map((doc) {
      return RecommendationItem.fromProduct(
        doc.data(),
        doc.id,
        0.7,
        'Similar to your viewed item',
      );
    }).toList();
  }

  Future<List<RecommendationItem>> _getSimilarSites(String siteId, int limit) async {
    final siteDoc = await _firestore.collection('cultural_sites').doc(siteId).get();
    if (!siteDoc.exists) return [];

    final siteData = siteDoc.data()!;
    final category = siteData['category'] as String?;

    if (category == null) return [];

    final snapshot = await _firestore
        .collection('cultural_sites')
        .where('category', isEqualTo: category)
        .orderBy('rating', descending: true)
        .limit(limit + 1)
        .get();

    return snapshot.docs
        .where((doc) => doc.id != siteId)
        .take(limit)
        .map((doc) {
      return RecommendationItem.fromCulturalSite(
        doc.data(),
        doc.id,
        0.7,
        'Similar cultural site',
      );
    }).toList();
  }

  Future<List<RecommendationItem>> _getSimilarTours(String tourId, int limit) async {
    final tourDoc = await _firestore.collection('tours').doc(tourId).get();
    if (!tourDoc.exists) return [];

    final tourData = tourDoc.data()!;
    final category = tourData['category'] as String?;

    if (category == null) return [];

    final snapshot = await _firestore
        .collection('tours')
        .where('category', isEqualTo: category)
        .orderBy('rating', descending: true)
        .limit(limit + 1)
        .get();

    return snapshot.docs
        .where((doc) => doc.id != tourId)
        .take(limit)
        .map((doc) {
      return RecommendationItem.fromTour(
        doc.data(),
        doc.id,
        0.7,
        'Similar tour experience',
      );
    }).toList();
  }

  Future<List<RecommendationItem>> _getFallbackRecommendations(RecommendationType type, int limit) async {
    // Fallback to highest-rated items
    final recommendations = <RecommendationItem>[];

    try {
      if (type == RecommendationType.mixed || type == RecommendationType.products) {
        final snapshot = await _firestore
            .collection('products')
            .orderBy('rating', descending: true)
            .limit(limit ~/ 3)
            .get();

        recommendations.addAll(snapshot.docs.map((doc) {
          return RecommendationItem.fromProduct(
            doc.data(),
            doc.id,
            0.5,
            'Highly rated',
          );
        }));
      }

      if (type == RecommendationType.mixed || type == RecommendationType.culturalSites) {
        final snapshot = await _firestore
            .collection('cultural_sites')
            .orderBy('rating', descending: true)
            .limit(limit ~/ 3)
            .get();

        recommendations.addAll(snapshot.docs.map((doc) {
          return RecommendationItem.fromCulturalSite(
            doc.data(),
            doc.id,
            0.5,
            'Popular destination',
          );
        }));
      }

      if (type == RecommendationType.mixed || type == RecommendationType.tours) {
        final snapshot = await _firestore
            .collection('tours')
            .orderBy('rating', descending: true)
            .limit(limit ~/ 3)
            .get();

        recommendations.addAll(snapshot.docs.map((doc) {
          return RecommendationItem.fromTour(
            doc.data(),
            doc.id,
            0.5,
            'Popular experience',
          );
        }));
      }
    } catch (e) {
      print('Error in fallback recommendations: $e');
    }

    return recommendations.take(limit).toList();
  }
}
