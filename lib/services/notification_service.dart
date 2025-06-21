import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

enum NotificationType {
  bookingConfirmed,
  bookingCancelled,
  paymentReceived,
  newReview,
  promotionalOffer,
  systemUpdate,
  reminderBooking,
  orderShipped,
  orderDelivered,
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final bool isRead;
  final String? imageUrl;
  final String? actionUrl;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.createdAt,
    required this.isRead,
    this.imageUrl,
    this.actionUrl,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.systemUpdate,
      ),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      imageUrl: map['imageUrl'],
      actionUrl: map['actionUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    String? imageUrl,
    String? actionUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'zanzibar_tourism_channel',
    'Zanzibar Tourism Notifications',
    description: 'Notifications for Zanzibar Tourism App',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    // Request permission for notifications
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Setup FCM
    await _setupFCM();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _setupFCM() async {
    // Get FCM token
    final token = await _messaging.getToken();
    print('FCM Token: $token');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(message);
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    // Handle navigation based on notification data
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'zanzibar_tourism_channel',
      'Zanzibar Tourism Notifications',
      channelDescription: 'Notifications for Zanzibar Tourism App',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Zanzibar Tourism',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  // Send notification to user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic> data = const {},
    String? imageUrl,
    String? actionUrl,
  }) async {
    try {
      // Save to Firestore
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'data': data,
        'imageUrl': imageUrl,
        'actionUrl': actionUrl,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send push notification via FCM
      // This would typically be done from a server
      // For demo purposes, we'll just save to database
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }

  // Get user notifications
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return AppNotification.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Get unread count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Send booking confirmation notification
  Future<void> sendBookingConfirmation({
    required String userId,
    required String bookingId,
    required String tourName,
    required DateTime bookingDate,
  }) async {
    await sendNotification(
      userId: userId,
      title: 'Booking Confirmed! 🎉',
      body:
          'Your booking for $tourName has been confirmed for ${bookingDate.day}/${bookingDate.month}/${bookingDate.year}',
      type: NotificationType.bookingConfirmed,
      data: {
        'bookingId': bookingId,
        'tourName': tourName,
        'bookingDate': bookingDate.toIso8601String(),
      },
      actionUrl: '/bookings/$bookingId',
    );
  }

  // Send payment confirmation notification
  Future<void> sendPaymentConfirmation({
    required String userId,
    required String orderId,
    required double amount,
    required String itemName,
  }) async {
    await sendNotification(
      userId: userId,
      title: 'Payment Received 💳',
      body:
          'Payment of \$${amount.toStringAsFixed(2)} for $itemName has been processed successfully',
      type: NotificationType.paymentReceived,
      data: {'orderId': orderId, 'amount': amount, 'itemName': itemName},
      actionUrl: '/orders/$orderId',
    );
  }

  // Send new review notification
  Future<void> sendNewReviewNotification({
    required String userId,
    required String itemName,
    required double rating,
    required String reviewerName,
  }) async {
    await sendNotification(
      userId: userId,
      title: 'New Review ⭐',
      body:
          '$reviewerName left a ${rating.toStringAsFixed(1)}-star review for $itemName',
      type: NotificationType.newReview,
      data: {
        'itemName': itemName,
        'rating': rating,
        'reviewerName': reviewerName,
      },
    );
  }

  // Send promotional offer notification
  Future<void> sendPromotionalOffer({
    required String userId,
    required String title,
    required String description,
    required String offerCode,
    String? imageUrl,
  }) async {
    await sendNotification(
      userId: userId,
      title: title,
      body: description,
      type: NotificationType.promotionalOffer,
      data: {'offerCode': offerCode},
      imageUrl: imageUrl,
      actionUrl: '/marketplace',
    );
  }

  // Send booking reminder
  Future<void> sendBookingReminder({
    required String userId,
    required String bookingId,
    required String tourName,
    required DateTime bookingDate,
  }) async {
    await sendNotification(
      userId: userId,
      title: 'Booking Reminder 📅',
      body:
          'Don\'t forget! Your $tourName experience is tomorrow at ${bookingDate.hour}:${bookingDate.minute.toString().padLeft(2, '0')}',
      type: NotificationType.reminderBooking,
      data: {
        'bookingId': bookingId,
        'tourName': tourName,
        'bookingDate': bookingDate.toIso8601String(),
      },
      actionUrl: '/bookings/$bookingId',
    );
  }
}
