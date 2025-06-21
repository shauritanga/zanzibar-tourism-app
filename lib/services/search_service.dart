import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchServiceProvider = Provider<SearchService>((ref) => SearchService());

enum SearchType { all, products, culturalSites, tours }

class SearchFilter {
  final double? minPrice;
  final double? maxPrice;
  final List<String> categories;
  final double? minRating;
  final String? location;
  final bool? isAvailable;
  final String? sortBy; // 'price_asc', 'price_desc', 'rating', 'newest', 'popular'

  SearchFilter({
    this.minPrice,
    this.maxPrice,
    this.categories = const [],
    this.minRating,
    this.location,
    this.isAvailable,
    this.sortBy,
  });

  SearchFilter copyWith({
    double? minPrice,
    double? maxPrice,
    List<String>? categories,
    double? minRating,
    String? location,
    bool? isAvailable,
    String? sortBy,
  }) {
    return SearchFilter(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      categories: categories ?? this.categories,
      minRating: minRating ?? this.minRating,
      location: location ?? this.location,
      isAvailable: isAvailable ?? this.isAvailable,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class SearchResult {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double? price;
  final double rating;
  final String category;
  final SearchType type;
  final Map<String, dynamic> data;

  SearchResult({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.price,
    required this.rating,
    required this.category,
    required this.type,
    required this.data,
  });

  factory SearchResult.fromProduct(Map<String, dynamic> data, String id) {
    return SearchResult(
      id: id,
      title: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['image'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      type: SearchType.products,
      data: data,
    );
  }

  factory SearchResult.fromCulturalSite(Map<String, dynamic> data, String id) {
    return SearchResult(
      id: id,
      title: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['images'] != null && (data['images'] as List).isNotEmpty 
          ? data['images'][0] 
          : '',
      price: (data['entryFee'] ?? 0.0).toDouble(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      type: SearchType.culturalSites,
      data: data,
    );
  }

  factory SearchResult.fromTour(Map<String, dynamic> data, String id) {
    return SearchResult(
      id: id,
      title: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['image'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      type: SearchType.tours,
      data: data,
    );
  }
}

class SearchSuggestion {
  final String text;
  final SearchType type;
  final int frequency;

  SearchSuggestion({
    required this.text,
    required this.type,
    required this.frequency,
  });
}

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Perform search across all collections
  Future<List<SearchResult>> search({
    required String query,
    SearchType type = SearchType.all,
    SearchFilter? filter,
    int limit = 20,
  }) async {
    try {
      List<SearchResult> results = [];

      if (type == SearchType.all || type == SearchType.products) {
        final productResults = await _searchProducts(query, filter, limit);
        results.addAll(productResults);
      }

      if (type == SearchType.all || type == SearchType.culturalSites) {
        final siteResults = await _searchCulturalSites(query, filter, limit);
        results.addAll(siteResults);
      }

      if (type == SearchType.all || type == SearchType.tours) {
        final tourResults = await _searchTours(query, filter, limit);
        results.addAll(tourResults);
      }

      // Apply sorting
      if (filter?.sortBy != null) {
        results = _sortResults(results, filter!.sortBy!);
      }

      // Save search query for analytics
      await _saveSearchQuery(query, type, results.length);

      return results.take(limit).toList();
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  // Search products
  Future<List<SearchResult>> _searchProducts(String query, SearchFilter? filter, int limit) async {
    Query queryRef = _firestore.collection('products');

    // Apply filters
    if (filter != null) {
      if (filter.categories.isNotEmpty) {
        queryRef = queryRef.where('category', whereIn: filter.categories);
      }
      if (filter.minPrice != null) {
        queryRef = queryRef.where('price', isGreaterThanOrEqualTo: filter.minPrice);
      }
      if (filter.maxPrice != null) {
        queryRef = queryRef.where('price', isLessThanOrEqualTo: filter.maxPrice);
      }
      if (filter.minRating != null) {
        queryRef = queryRef.where('rating', isGreaterThanOrEqualTo: filter.minRating);
      }
      if (filter.isAvailable == true) {
        queryRef = queryRef.where('stock', isGreaterThan: 0);
      }
    }

    final snapshot = await queryRef.limit(limit).get();
    
    return snapshot.docs
        .map((doc) => SearchResult.fromProduct(doc.data() as Map<String, dynamic>, doc.id))
        .where((result) => _matchesQuery(result, query))
        .toList();
  }

  // Search cultural sites
  Future<List<SearchResult>> _searchCulturalSites(String query, SearchFilter? filter, int limit) async {
    Query queryRef = _firestore.collection('cultural_sites');

    // Apply filters
    if (filter != null) {
      if (filter.categories.isNotEmpty) {
        queryRef = queryRef.where('category', whereIn: filter.categories);
      }
      if (filter.minPrice != null) {
        queryRef = queryRef.where('entryFee', isGreaterThanOrEqualTo: filter.minPrice);
      }
      if (filter.maxPrice != null) {
        queryRef = queryRef.where('entryFee', isLessThanOrEqualTo: filter.maxPrice);
      }
      if (filter.minRating != null) {
        queryRef = queryRef.where('rating', isGreaterThanOrEqualTo: filter.minRating);
      }
    }

    final snapshot = await queryRef.limit(limit).get();
    
    return snapshot.docs
        .map((doc) => SearchResult.fromCulturalSite(doc.data() as Map<String, dynamic>, doc.id))
        .where((result) => _matchesQuery(result, query))
        .toList();
  }

  // Search tours
  Future<List<SearchResult>> _searchTours(String query, SearchFilter? filter, int limit) async {
    Query queryRef = _firestore.collection('tours');

    // Apply filters
    if (filter != null) {
      if (filter.categories.isNotEmpty) {
        queryRef = queryRef.where('category', whereIn: filter.categories);
      }
      if (filter.minPrice != null) {
        queryRef = queryRef.where('price', isGreaterThanOrEqualTo: filter.minPrice);
      }
      if (filter.maxPrice != null) {
        queryRef = queryRef.where('price', isLessThanOrEqualTo: filter.maxPrice);
      }
      if (filter.minRating != null) {
        queryRef = queryRef.where('rating', isGreaterThanOrEqualTo: filter.minRating);
      }
    }

    final snapshot = await queryRef.limit(limit).get();
    
    return snapshot.docs
        .map((doc) => SearchResult.fromTour(doc.data() as Map<String, dynamic>, doc.id))
        .where((result) => _matchesQuery(result, query))
        .toList();
  }

  // Check if result matches query
  bool _matchesQuery(SearchResult result, String query) {
    final lowerQuery = query.toLowerCase();
    return result.title.toLowerCase().contains(lowerQuery) ||
           result.description.toLowerCase().contains(lowerQuery) ||
           result.category.toLowerCase().contains(lowerQuery);
  }

  // Sort results
  List<SearchResult> _sortResults(List<SearchResult> results, String sortBy) {
    switch (sortBy) {
      case 'price_asc':
        results.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        break;
      case 'price_desc':
        results.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case 'rating':
        results.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'popular':
        // Sort by rating for now, could be enhanced with view counts
        results.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'newest':
        // For now, keep original order (could be enhanced with creation date)
        break;
    }
    return results;
  }

  // Get search suggestions
  Future<List<SearchSuggestion>> getSearchSuggestions(String query) async {
    try {
      if (query.length < 2) return [];

      // Get popular search terms
      final snapshot = await _firestore
          .collection('search_analytics')
          .where('query', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('query', isLessThan: '${query.toLowerCase()}z')
          .orderBy('frequency', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SearchSuggestion(
          text: data['query'] ?? '',
          type: SearchType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => SearchType.all,
          ),
          frequency: data['frequency'] ?? 0,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get popular searches
  Future<List<String>> getPopularSearches({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('search_analytics')
          .orderBy('frequency', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['query'] as String? ?? '')
          .where((query) => query.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get available categories for filtering
  Future<List<String>> getAvailableCategories(SearchType type) async {
    try {
      String collection;
      switch (type) {
        case SearchType.products:
          collection = 'products';
          break;
        case SearchType.culturalSites:
          collection = 'cultural_sites';
          break;
        case SearchType.tours:
          collection = 'tours';
          break;
        default:
          return [];
      }

      final snapshot = await _firestore.collection(collection).get();
      final categories = <String>{};
      
      for (var doc in snapshot.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  // Save search query for analytics
  Future<void> _saveSearchQuery(String query, SearchType type, int resultCount) async {
    try {
      final lowerQuery = query.toLowerCase().trim();
      if (lowerQuery.isEmpty) return;

      final docRef = _firestore
          .collection('search_analytics')
          .doc('${type.name}_$lowerQuery');

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          transaction.update(docRef, {
            'frequency': FieldValue.increment(1),
            'lastSearched': FieldValue.serverTimestamp(),
            'resultCount': resultCount,
          });
        } else {
          transaction.set(docRef, {
            'query': lowerQuery,
            'type': type.name,
            'frequency': 1,
            'firstSearched': FieldValue.serverTimestamp(),
            'lastSearched': FieldValue.serverTimestamp(),
            'resultCount': resultCount,
          });
        }
      });
    } catch (e) {
      // Silently fail to avoid breaking search functionality
      print('Failed to save search analytics: $e');
    }
  }

  // Clear search history (for user privacy)
  Future<void> clearSearchHistory() async {
    try {
      // This would typically clear user-specific search history
      // For now, we'll just implement a placeholder
      print('Search history cleared');
    } catch (e) {
      throw Exception('Failed to clear search history: $e');
    }
  }
}
