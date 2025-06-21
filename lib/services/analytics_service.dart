import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(),
);

enum EventType {
  pageView,
  userAction,
  purchase,
  booking,
  search,
  engagement,
  error,
  performance,
}

class AnalyticsEvent {
  final String id;
  final String userId;
  final EventType type;
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final String? sessionId;
  final String? deviceInfo;

  AnalyticsEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.parameters,
    required this.timestamp,
    this.sessionId,
    this.deviceInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'name': name,
      'parameters': parameters,
      'timestamp': Timestamp.fromDate(timestamp),
      'sessionId': sessionId,
      'deviceInfo': deviceInfo,
    };
  }

  factory AnalyticsEvent.fromMap(Map<String, dynamic> map, String id) {
    return AnalyticsEvent(
      id: id,
      userId: map['userId'] ?? '',
      type: EventType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => EventType.userAction,
      ),
      name: map['name'] ?? '',
      parameters: Map<String, dynamic>.from(map['parameters'] ?? {}),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sessionId: map['sessionId'],
      deviceInfo: map['deviceInfo'],
    );
  }
}

class UserBehavior {
  final String userId;
  final int totalSessions;
  final Duration totalTimeSpent;
  final int pageViews;
  final int purchases;
  final int bookings;
  final List<String> favoriteCategories;
  final double averageSessionDuration;
  final DateTime lastActive;
  final Map<String, int> activityCounts;

  UserBehavior({
    required this.userId,
    required this.totalSessions,
    required this.totalTimeSpent,
    required this.pageViews,
    required this.purchases,
    required this.bookings,
    required this.favoriteCategories,
    required this.averageSessionDuration,
    required this.lastActive,
    required this.activityCounts,
  });
}

class AppMetrics {
  final int totalUsers;
  final int activeUsers;
  final int totalBookings;
  final int totalPurchases;
  final double totalRevenue;
  final Map<String, int> popularPages;
  final Map<String, int> deviceTypes;
  final Map<String, double> conversionRates;
  final DateTime generatedAt;

  AppMetrics({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalBookings,
    required this.totalPurchases,
    required this.totalRevenue,
    required this.popularPages,
    required this.deviceTypes,
    required this.conversionRates,
    required this.generatedAt,
  });
}

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  String? _currentSessionId;
  DateTime? _sessionStartTime;

  // Initialize analytics
  Future<void> initialize() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
    _startNewSession();
  }

  // Start new session
  void _startNewSession() {
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _sessionStartTime = DateTime.now();
  }

  // Track event
  Future<void> trackEvent({
    required String userId,
    required EventType type,
    required String name,
    Map<String, dynamic> parameters = const {},
  }) async {
    try {
      // Track with Firebase Analytics
      await _analytics.logEvent(
        name: name,
        parameters: {'user_id': userId, 'event_type': type.name, ...parameters},
      );

      // Store in Firestore for detailed analysis
      final event = AnalyticsEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: type,
        name: name,
        parameters: parameters,
        timestamp: DateTime.now(),
        sessionId: _currentSessionId,
      );

      await _firestore.collection('analytics_events').add(event.toMap());
    } catch (e) {
      print('Error tracking event: $e');
    }
  }

  // Track page view
  Future<void> trackPageView({
    required String userId,
    required String pageName,
    Map<String, dynamic> parameters = const {},
  }) async {
    await trackEvent(
      userId: userId,
      type: EventType.pageView,
      name: 'page_view',
      parameters: {'page_name': pageName, ...parameters},
    );

    await _analytics.logScreenView(screenName: pageName);
  }

  // Track user action
  Future<void> trackUserAction({
    required String userId,
    required String action,
    Map<String, dynamic> parameters = const {},
  }) async {
    await trackEvent(
      userId: userId,
      type: EventType.userAction,
      name: action,
      parameters: parameters,
    );
  }

  // Track purchase
  Future<void> trackPurchase({
    required String userId,
    required String itemId,
    required String itemName,
    required double value,
    required String currency,
    Map<String, dynamic> parameters = const {},
  }) async {
    await trackEvent(
      userId: userId,
      type: EventType.purchase,
      name: 'purchase',
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
        'value': value,
        'currency': currency,
        ...parameters,
      },
    );

    await _analytics.logPurchase(
      currency: currency,
      value: value,
      items: [
        AnalyticsEventItem(itemId: itemId, itemName: itemName, price: value),
      ],
    );
  }

  // Track booking
  Future<void> trackBooking({
    required String userId,
    required String tourId,
    required String tourName,
    required double value,
    required DateTime bookingDate,
    Map<String, dynamic> parameters = const {},
  }) async {
    await trackEvent(
      userId: userId,
      type: EventType.booking,
      name: 'booking_created',
      parameters: {
        'tour_id': tourId,
        'tour_name': tourName,
        'value': value,
        'booking_date': bookingDate.toIso8601String(),
        ...parameters,
      },
    );
  }

  // Track search
  Future<void> trackSearch({
    required String userId,
    required String searchTerm,
    required int resultCount,
    Map<String, dynamic> parameters = const {},
  }) async {
    await trackEvent(
      userId: userId,
      type: EventType.search,
      name: 'search',
      parameters: {
        'search_term': searchTerm,
        'result_count': resultCount,
        ...parameters,
      },
    );

    await _analytics.logSearch(searchTerm: searchTerm);
  }

  // Track engagement
  Future<void> trackEngagement({
    required String userId,
    required String engagementType,
    required String itemId,
    Map<String, dynamic> parameters = const {},
  }) async {
    await trackEvent(
      userId: userId,
      type: EventType.engagement,
      name: engagementType,
      parameters: {'item_id': itemId, ...parameters},
    );
  }

  // Track error
  Future<void> trackError({
    required String userId,
    required String errorType,
    required String errorMessage,
    Map<String, dynamic> parameters = const {},
  }) async {
    await trackEvent(
      userId: userId,
      type: EventType.error,
      name: 'error_occurred',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        ...parameters,
      },
    );
  }

  // Get user behavior analytics
  Future<UserBehavior?> getUserBehavior(String userId) async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final eventsSnapshot =
          await _firestore
              .collection('analytics_events')
              .where('userId', isEqualTo: userId)
              .where(
                'timestamp',
                isGreaterThan: Timestamp.fromDate(thirtyDaysAgo),
              )
              .get();

      if (eventsSnapshot.docs.isEmpty) return null;

      final events =
          eventsSnapshot.docs
              .map((doc) => AnalyticsEvent.fromMap(doc.data(), doc.id))
              .toList();

      // Calculate metrics
      final sessions = <String>{};
      final pageViews =
          events.where((e) => e.type == EventType.pageView).length;
      final purchases =
          events.where((e) => e.type == EventType.purchase).length;
      final bookings = events.where((e) => e.type == EventType.booking).length;

      final activityCounts = <String, int>{};
      final categories = <String>[];

      for (final event in events) {
        if (event.sessionId != null) {
          sessions.add(event.sessionId!);
        }

        activityCounts[event.name] = (activityCounts[event.name] ?? 0) + 1;

        if (event.parameters.containsKey('category')) {
          categories.add(event.parameters['category']);
        }
      }

      // Calculate favorite categories
      final categoryCount = <String, int>{};
      for (final category in categories) {
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }

      final favoriteCategories =
          categoryCount.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      return UserBehavior(
        userId: userId,
        totalSessions: sessions.length,
        totalTimeSpent: Duration(hours: sessions.length * 2), // Estimated
        pageViews: pageViews,
        purchases: purchases,
        bookings: bookings,
        favoriteCategories:
            favoriteCategories.take(5).map((e) => e.key).toList(),
        averageSessionDuration:
            sessions.isNotEmpty ? 120.0 : 0.0, // Estimated in minutes
        lastActive: events.isNotEmpty ? events.last.timestamp : DateTime.now(),
        activityCounts: activityCounts,
      );
    } catch (e) {
      print('Error getting user behavior: $e');
      return null;
    }
  }

  // Get app metrics
  Future<AppMetrics> getAppMetrics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Get events in date range
      final eventsSnapshot =
          await _firestore
              .collection('analytics_events')
              .where('timestamp', isGreaterThan: Timestamp.fromDate(start))
              .where('timestamp', isLessThan: Timestamp.fromDate(end))
              .get();

      final events =
          eventsSnapshot.docs
              .map((doc) => AnalyticsEvent.fromMap(doc.data(), doc.id))
              .toList();

      // Calculate metrics
      final uniqueUsers = <String>{};
      final popularPages = <String, int>{};
      final deviceTypes = <String, int>{};

      int totalBookings = 0;
      int totalPurchases = 0;
      double totalRevenue = 0.0;

      for (final event in events) {
        uniqueUsers.add(event.userId);

        if (event.type == EventType.pageView) {
          final pageName = event.parameters['page_name'] ?? 'unknown';
          popularPages[pageName] = (popularPages[pageName] ?? 0) + 1;
        }

        if (event.type == EventType.booking) {
          totalBookings++;
          totalRevenue += (event.parameters['value'] ?? 0.0).toDouble();
        }

        if (event.type == EventType.purchase) {
          totalPurchases++;
          totalRevenue += (event.parameters['value'] ?? 0.0).toDouble();
        }

        if (event.deviceInfo != null) {
          deviceTypes[event.deviceInfo!] =
              (deviceTypes[event.deviceInfo!] ?? 0) + 1;
        }
      }

      // Calculate conversion rates
      final pageViewCount =
          events.where((e) => e.type == EventType.pageView).length;
      final conversionRates = <String, double>{
        'booking_conversion':
            pageViewCount > 0 ? (totalBookings / pageViewCount) * 100 : 0.0,
        'purchase_conversion':
            pageViewCount > 0 ? (totalPurchases / pageViewCount) * 100 : 0.0,
      };

      return AppMetrics(
        totalUsers: uniqueUsers.length,
        activeUsers: uniqueUsers.length, // Simplified for this period
        totalBookings: totalBookings,
        totalPurchases: totalPurchases,
        totalRevenue: totalRevenue,
        popularPages: popularPages,
        deviceTypes: deviceTypes,
        conversionRates: conversionRates,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error getting app metrics: $e');
      return AppMetrics(
        totalUsers: 0,
        activeUsers: 0,
        totalBookings: 0,
        totalPurchases: 0,
        totalRevenue: 0.0,
        popularPages: {},
        deviceTypes: {},
        conversionRates: {},
        generatedAt: DateTime.now(),
      );
    }
  }

  // Get popular content
  Future<List<Map<String, dynamic>>> getPopularContent({
    required String contentType,
    int limit = 10,
  }) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final eventsSnapshot =
          await _firestore
              .collection('analytics_events')
              .where('name', isEqualTo: 'page_view')
              .where(
                'timestamp',
                isGreaterThan: Timestamp.fromDate(thirtyDaysAgo),
              )
              .get();

      final contentViews = <String, int>{};

      for (final doc in eventsSnapshot.docs) {
        final event = AnalyticsEvent.fromMap(doc.data(), doc.id);
        final itemId = event.parameters['item_id'];
        final pageType = event.parameters['content_type'];

        if (itemId != null && pageType == contentType) {
          contentViews[itemId] = (contentViews[itemId] ?? 0) + 1;
        }
      }

      final sortedContent =
          contentViews.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      return sortedContent
          .take(limit)
          .map((entry) => {'id': entry.key, 'views': entry.value})
          .toList();
    } catch (e) {
      print('Error getting popular content: $e');
      return [];
    }
  }

  // Set user properties
  Future<void> setUserProperties({
    required String userId,
    required Map<String, dynamic> properties,
  }) async {
    try {
      for (final entry in properties.entries) {
        await _analytics.setUserProperty(
          name: entry.key,
          value: entry.value.toString(),
        );
      }

      // Store in Firestore
      await _firestore.collection('user_properties').doc(userId).set({
        ...properties,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error setting user properties: $e');
    }
  }

  // Track session duration
  Future<void> endSession(String userId) async {
    if (_sessionStartTime != null && _currentSessionId != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);

      await trackEvent(
        userId: userId,
        type: EventType.engagement,
        name: 'session_end',
        parameters: {
          'session_duration': sessionDuration.inMinutes,
          'session_id': _currentSessionId,
        },
      );
    }

    _startNewSession();
  }

  // Get real-time metrics
  Stream<Map<String, dynamic>> getRealTimeMetrics() {
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

    return _firestore
        .collection('analytics_events')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
        .snapshots()
        .map((snapshot) {
          final events =
              snapshot.docs
                  .map((doc) => AnalyticsEvent.fromMap(doc.data(), doc.id))
                  .toList();

          final activeUsers = <String>{};
          final pageViews = <String, int>{};

          for (final event in events) {
            activeUsers.add(event.userId);

            if (event.type == EventType.pageView) {
              final pageName = event.parameters['page_name'] ?? 'unknown';
              pageViews[pageName] = (pageViews[pageName] ?? 0) + 1;
            }
          }

          return {
            'active_users': activeUsers.length,
            'total_events': events.length,
            'page_views': pageViews,
            'timestamp': DateTime.now().toIso8601String(),
          };
        });
  }
}
