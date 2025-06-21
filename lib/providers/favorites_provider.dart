import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/services/favorites_service.dart';
import 'package:zanzibar_tourism/services/auth_service.dart';

// Provider for favorites service
final favoritesProvider = StreamProvider.family<List<FavoriteItem>, String>((ref, userId) {
  final favoritesService = ref.read(favoritesServiceProvider);
  return favoritesService.getUserFavorites(userId);
});

// Provider for favorites by type
final favoritesByTypeProvider = StreamProvider.family<List<FavoriteItem>, FavoritesByTypeParams>((ref, params) {
  final favoritesService = ref.read(favoritesServiceProvider);
  return favoritesService.getFavoritesByType(params.userId, params.type);
});

class FavoritesByTypeParams {
  final String userId;
  final FavoriteType type;

  FavoritesByTypeParams({required this.userId, required this.type});
}

// Provider for checking if an item is favorite
final isFavoriteProvider = FutureProvider.family<bool, FavoriteCheckParams>((ref, params) {
  final favoritesService = ref.read(favoritesServiceProvider);
  return favoritesService.isFavorite(
    userId: params.userId,
    itemId: params.itemId,
    type: params.type,
  );
});

class FavoriteCheckParams {
  final String userId;
  final String itemId;
  final FavoriteType type;

  FavoriteCheckParams({
    required this.userId,
    required this.itemId,
    required this.type,
  });
}

// Provider for favorites count
final favoritesCountProvider = FutureProvider.family<int, String>((ref, userId) {
  final favoritesService = ref.read(favoritesServiceProvider);
  return favoritesService.getFavoritesCount(userId);
});

// Notifier for managing favorite actions
class FavoritesNotifier extends StateNotifier<AsyncValue<bool?>> {
  FavoritesNotifier(this._favoritesService) : super(const AsyncValue.data(null));

  final FavoritesService _favoritesService;

  Future<void> toggleFavorite({
    required String userId,
    required String itemId,
    required FavoriteType type,
    required String title,
    required String description,
    required String imageUrl,
    double? price,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final result = await _favoritesService.toggleFavorite(
        userId: userId,
        itemId: itemId,
        type: type,
        title: title,
        description: description,
        imageUrl: imageUrl,
        price: price,
      );
      
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addToFavorites({
    required String userId,
    required String itemId,
    required FavoriteType type,
    required String title,
    required String description,
    required String imageUrl,
    double? price,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _favoritesService.addToFavorites(
        userId: userId,
        itemId: itemId,
        type: type,
        title: title,
        description: description,
        imageUrl: imageUrl,
        price: price,
      );
      
      state = const AsyncValue.data(true);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeFromFavorites({
    required String userId,
    required String itemId,
    required FavoriteType type,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _favoritesService.removeFromFavorites(
        userId: userId,
        itemId: itemId,
        type: type,
      );
      
      state = const AsyncValue.data(false);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> clearAllFavorites(String userId) async {
    state = const AsyncValue.loading();
    
    try {
      await _favoritesService.clearAllFavorites(userId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearState() {
    state = const AsyncValue.data(null);
  }
}

final favoritesNotifierProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<bool?>>((ref) {
  final favoritesService = ref.read(favoritesServiceProvider);
  return FavoritesNotifier(favoritesService);
});

// Helper provider to get current user's favorites
final currentUserFavoritesProvider = StreamProvider<List<FavoriteItem>>((ref) {
  final user = ref.read(authServiceProvider).currentUser;
  if (user == null) {
    return Stream.value([]);
  }
  
  final favoritesService = ref.read(favoritesServiceProvider);
  return favoritesService.getUserFavorites(user.uid);
});

// Helper provider to get current user's product favorites
final currentUserProductFavoritesProvider = StreamProvider<List<FavoriteItem>>((ref) {
  final user = ref.read(authServiceProvider).currentUser;
  if (user == null) {
    return Stream.value([]);
  }
  
  final favoritesService = ref.read(favoritesServiceProvider);
  return favoritesService.getFavoritesByType(user.uid, FavoriteType.product);
});

// Helper provider to get current user's cultural site favorites
final currentUserSiteFavoritesProvider = StreamProvider<List<FavoriteItem>>((ref) {
  final user = ref.read(authServiceProvider).currentUser;
  if (user == null) {
    return Stream.value([]);
  }
  
  final favoritesService = ref.read(favoritesServiceProvider);
  return favoritesService.getFavoritesByType(user.uid, FavoriteType.culturalSite);
});

// Helper provider to get current user's favorites count
final currentUserFavoritesCountProvider = FutureProvider<int>((ref) {
  final user = ref.read(authServiceProvider).currentUser;
  if (user == null) {
    return Future.value(0);
  }
  
  final favoritesService = ref.read(favoritesServiceProvider);
  return favoritesService.getFavoritesCount(user.uid);
});
