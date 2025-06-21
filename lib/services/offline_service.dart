import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final offlineServiceProvider = Provider<OfflineService>(
  (ref) => OfflineService(),
);

enum SyncStatus { pending, syncing, synced, failed }

class OfflineData {
  final String id;
  final String collection;
  final String documentId;
  final Map<String, dynamic> data;
  final String operation; // 'create', 'update', 'delete'
  final DateTime timestamp;
  final SyncStatus status;
  final String? error;

  OfflineData({
    required this.id,
    required this.collection,
    required this.documentId,
    required this.data,
    required this.operation,
    required this.timestamp,
    required this.status,
    this.error,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collection': collection,
      'documentId': documentId,
      'data': jsonEncode(data),
      'operation': operation,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
      'error': error,
    };
  }

  factory OfflineData.fromMap(Map<String, dynamic> map) {
    return OfflineData(
      id: map['id'],
      collection: map['collection'],
      documentId: map['documentId'],
      data: jsonDecode(map['data']),
      operation: map['operation'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      status: SyncStatus.values.firstWhere((e) => e.name == map['status']),
      error: map['error'],
    );
  }
}

class CachedData {
  final String id;
  final String collection;
  final String documentId;
  final Map<String, dynamic> data;
  final DateTime cachedAt;
  final DateTime? expiresAt;

  CachedData({
    required this.id,
    required this.collection,
    required this.documentId,
    required this.data,
    required this.cachedAt,
    this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collection': collection,
      'documentId': documentId,
      'data': jsonEncode(data),
      'cachedAt': cachedAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
    };
  }

  factory CachedData.fromMap(Map<String, dynamic> map) {
    return CachedData(
      id: map['id'],
      collection: map['collection'],
      documentId: map['documentId'],
      data: jsonDecode(map['data']),
      cachedAt: DateTime.fromMillisecondsSinceEpoch(map['cachedAt']),
      expiresAt:
          map['expiresAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'])
              : null,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

class OfflineService {
  static Database? _database;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  // Initialize offline database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'offline_data.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create offline operations table
        await db.execute('''
          CREATE TABLE offline_operations (
            id TEXT PRIMARY KEY,
            collection TEXT NOT NULL,
            documentId TEXT NOT NULL,
            data TEXT NOT NULL,
            operation TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            status TEXT NOT NULL,
            error TEXT
          )
        ''');

        // Create cached data table
        await db.execute('''
          CREATE TABLE cached_data (
            id TEXT PRIMARY KEY,
            collection TEXT NOT NULL,
            documentId TEXT NOT NULL,
            data TEXT NOT NULL,
            cachedAt INTEGER NOT NULL,
            expiresAt INTEGER
          )
        ''');

        // Create indexes
        await db.execute(
          'CREATE INDEX idx_collection ON cached_data(collection)',
        );
        await db.execute(
          'CREATE INDEX idx_status ON offline_operations(status)',
        );
      },
    );
  }

  // Check connectivity
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none) ||
          connectivityResult.isEmpty) {
        return false;
      }

      // Additional check by trying to reach a reliable server
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Cache data locally
  Future<void> cacheData({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    Duration? ttl,
  }) async {
    try {
      final db = await database;
      final id = '${collection}_$documentId';
      final expiresAt = ttl != null ? DateTime.now().add(ttl) : null;

      final cachedData = CachedData(
        id: id,
        collection: collection,
        documentId: documentId,
        data: data,
        cachedAt: DateTime.now(),
        expiresAt: expiresAt,
      );

      await db.insert(
        'cached_data',
        cachedData.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error caching data: $e');
    }
  }

  // Get cached data
  Future<Map<String, dynamic>?> getCachedData(
    String collection,
    String documentId,
  ) async {
    try {
      final db = await database;
      final id = '${collection}_$documentId';

      final List<Map<String, dynamic>> maps = await db.query(
        'cached_data',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;

      final cachedData = CachedData.fromMap(maps.first);

      // Check if data is expired
      if (cachedData.isExpired) {
        await deleteCachedData(collection, documentId);
        return null;
      }

      return cachedData.data;
    } catch (e) {
      print('Error getting cached data: $e');
      return null;
    }
  }

  // Get all cached data for a collection
  Future<List<Map<String, dynamic>>> getCachedCollection(
    String collection,
  ) async {
    try {
      final db = await database;

      final List<Map<String, dynamic>> maps = await db.query(
        'cached_data',
        where: 'collection = ?',
        whereArgs: [collection],
      );

      final List<Map<String, dynamic>> validData = [];

      for (final map in maps) {
        final cachedData = CachedData.fromMap(map);

        if (!cachedData.isExpired) {
          validData.add(cachedData.data);
        } else {
          // Remove expired data
          await db.delete(
            'cached_data',
            where: 'id = ?',
            whereArgs: [cachedData.id],
          );
        }
      }

      return validData;
    } catch (e) {
      print('Error getting cached collection: $e');
      return [];
    }
  }

  // Delete cached data
  Future<void> deleteCachedData(String collection, String documentId) async {
    try {
      final db = await database;
      final id = '${collection}_$documentId';

      await db.delete('cached_data', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error deleting cached data: $e');
    }
  }

  // Queue offline operation
  Future<void> queueOfflineOperation({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    required String operation,
  }) async {
    try {
      final db = await database;
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final offlineData = OfflineData(
        id: id,
        collection: collection,
        documentId: documentId,
        data: data,
        operation: operation,
        timestamp: DateTime.now(),
        status: SyncStatus.pending,
      );

      await db.insert('offline_operations', offlineData.toMap());
    } catch (e) {
      print('Error queuing offline operation: $e');
    }
  }

  // Get pending operations
  Future<List<OfflineData>> getPendingOperations() async {
    try {
      final db = await database;

      final List<Map<String, dynamic>> maps = await db.query(
        'offline_operations',
        where: 'status = ?',
        whereArgs: [SyncStatus.pending.name],
        orderBy: 'timestamp ASC',
      );

      return maps.map((map) => OfflineData.fromMap(map)).toList();
    } catch (e) {
      print('Error getting pending operations: $e');
      return [];
    }
  }

  // Sync offline operations
  Future<void> syncOfflineOperations() async {
    try {
      if (!await isOnline()) {
        print('Device is offline, skipping sync');
        return;
      }

      final pendingOperations = await getPendingOperations();

      for (final operation in pendingOperations) {
        await _syncOperation(operation);
      }
    } catch (e) {
      print('Error syncing offline operations: $e');
    }
  }

  Future<void> _syncOperation(OfflineData operation) async {
    try {
      final db = await database;

      // Update status to syncing
      await db.update(
        'offline_operations',
        {'status': SyncStatus.syncing.name},
        where: 'id = ?',
        whereArgs: [operation.id],
      );

      // Perform the operation
      final docRef = _firestore
          .collection(operation.collection)
          .doc(operation.documentId);

      switch (operation.operation) {
        case 'create':
          await docRef.set(operation.data);
          break;
        case 'update':
          await docRef.update(operation.data);
          break;
        case 'delete':
          await docRef.delete();
          break;
      }

      // Mark as synced
      await db.update(
        'offline_operations',
        {'status': SyncStatus.synced.name},
        where: 'id = ?',
        whereArgs: [operation.id],
      );

      // Remove synced operation after a delay
      Future.delayed(const Duration(hours: 1), () async {
        await db.delete(
          'offline_operations',
          where: 'id = ? AND status = ?',
          whereArgs: [operation.id, SyncStatus.synced.name],
        );
      });
    } catch (e) {
      // Mark as failed
      final db = await database;
      await db.update(
        'offline_operations',
        {'status': SyncStatus.failed.name, 'error': e.toString()},
        where: 'id = ?',
        whereArgs: [operation.id],
      );
      print('Error syncing operation ${operation.id}: $e');
    }
  }

  // Clear expired cache
  Future<void> clearExpiredCache() async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.delete(
        'cached_data',
        where: 'expiresAt IS NOT NULL AND expiresAt < ?',
        whereArgs: [now],
      );
    } catch (e) {
      print('Error clearing expired cache: $e');
    }
  }

  // Get cache statistics
  Future<Map<String, int>> getCacheStatistics() async {
    try {
      final db = await database;

      final cacheCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM cached_data'),
          ) ??
          0;

      final pendingOpsCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM offline_operations WHERE status = ?',
              [SyncStatus.pending.name],
            ),
          ) ??
          0;

      final failedOpsCount =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM offline_operations WHERE status = ?',
              [SyncStatus.failed.name],
            ),
          ) ??
          0;

      return {
        'cachedItems': cacheCount,
        'pendingOperations': pendingOpsCount,
        'failedOperations': failedOpsCount,
      };
    } catch (e) {
      return {};
    }
  }

  // Clear all offline data
  Future<void> clearAllOfflineData() async {
    try {
      final db = await database;
      await db.delete('cached_data');
      await db.delete('offline_operations');
    } catch (e) {
      print('Error clearing offline data: $e');
    }
  }

  // Auto-sync when connectivity is restored
  void startAutoSync() {
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        // Delay to ensure connection is stable
        Future.delayed(const Duration(seconds: 2), () {
          syncOfflineOperations();
        });
      }
    });
  }

  // Preload essential data for offline use
  Future<void> preloadEssentialData() async {
    try {
      if (!await isOnline()) return;

      // Preload cultural sites
      final sitesSnapshot =
          await _firestore.collection('cultural_sites').limit(50).get();
      for (final doc in sitesSnapshot.docs) {
        await cacheData(
          collection: 'cultural_sites',
          documentId: doc.id,
          data: doc.data(),
          ttl: const Duration(days: 7),
        );
      }

      // Preload popular products
      final productsSnapshot =
          await _firestore
              .collection('products')
              .orderBy('rating', descending: true)
              .limit(100)
              .get();
      for (final doc in productsSnapshot.docs) {
        await cacheData(
          collection: 'products',
          documentId: doc.id,
          data: doc.data(),
          ttl: const Duration(days: 3),
        );
      }

      print('Essential data preloaded for offline use');
    } catch (e) {
      print('Error preloading essential data: $e');
    }
  }
}
