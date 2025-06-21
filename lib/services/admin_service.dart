import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zanzibar_tourism/models/business.dart';
import 'package:zanzibar_tourism/models/tour.dart';
import '../models/cultural_site.dart';
import '../models/user.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Content Management
  Future<List<CulturalSite>> getCulturalSites() async {
    try {
      final snapshot = await _firestore.collection('cultural_sites').get();
      return snapshot.docs
          .map((doc) => CulturalSite.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch cultural sites: $e');
    }
  }

  Future<void> updateCulturalSite(CulturalSite site) async {
    try {
      await _firestore
          .collection('cultural_sites')
          .doc(site.id)
          .set(site.toMap());
    } catch (e) {
      throw Exception('Failed to update cultural site: $e');
    }
  }

  Future<void> deleteCulturalSite(String siteId) async {
    try {
      await _firestore.collection('cultural_sites').doc(siteId).delete();
    } catch (e) {
      throw Exception('Failed to delete cultural site: $e');
    }
  }

  Future<void> addCulturalSite({
    required String name,
    required String description,
    required String category,
    required double latitude,
    required double longitude,
    required double entryFee,
    required String openingHours,
  }) async {
    try {
      await _firestore.collection('cultural_sites').add({
        'name': name,
        'description': description,
        'category': category,
        'location': GeoPoint(latitude, longitude),
        'entryFee': entryFee,
        'openingHours': openingHours,
        'images': [],
        'rating': 0.0,
        'reviews': 0,
        'visitCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add cultural site: $e');
    }
  }

  // Booking Management
  Stream<List<TourBooking>> getBookings() {
    return _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => TourBooking.fromMap(doc.data()))
                  .toList(),
        );
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Business Management
  Stream<List<Business>> getBusinesses() {
    return _firestore
        .collection('businesses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Business.fromMap(doc.data())).toList(),
        );
  }

  Future<void> approveBusiness(String businessId) async {
    try {
      await _firestore.collection('businesses').doc(businessId).update({
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to approve business: $e');
    }
  }

  // User Management
  Stream<List<ZanzibarUser>> getUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => ZanzibarUser.fromFirebase(
                      _auth.currentUser!,
                      doc.data(),
                    ),
                  )
                  .toList(),
        );
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  // Analytics
  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      // Get total bookings and revenue
      final bookingsSnapshot = await _firestore.collection('bookings').get();
      final totalBookings = bookingsSnapshot.docs.length;

      final revenueSnapshot =
          await _firestore
              .collection('bookings')
              .where('status', isEqualTo: 'completed')
              .get();

      double totalRevenue = 0;
      Map<String, double> revenueByCategory = {};
      Map<String, int> bookingsByCategory = {};

      for (var doc in revenueSnapshot.docs) {
        final booking = TourBooking.fromMap(doc.data());
        final revenue = booking.tour.price * booking.quantity;
        totalRevenue += revenue;

        // Use the single category from the updated Tour model
        final category = booking.tour.category;
        revenueByCategory[category] =
            (revenueByCategory[category] ?? 0) + revenue;

        bookingsByCategory[category] = (bookingsByCategory[category] ?? 0) + 1;
      }

      // Get active businesses
      final businessesSnapshot =
          await _firestore
              .collection('businesses')
              .where('status', isEqualTo: 'approved')
              .get();
      final activeBusinesses = businessesSnapshot.docs.length;

      // Get user stats
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;
      final newUserCount = await _getNewUsersCount(
        DateTime.now().subtract(const Duration(days: 30)),
      );

      // Get popular sites
      final Map<String, int> siteVisits = await _getSiteVisitCounts();

      // Get user demographics
      final userDemographics = await _getUserDemographics();

      // Calculate conversion rates
      final totalBookingsSnapshot =
          await _firestore.collection('bookings').get();
      final totalBookingsCount = totalBookingsSnapshot.docs.length;
      final completedBookingsSnapshot =
          await _firestore
              .collection('bookings')
              .where('status', isEqualTo: 'completed')
              .get();
      final completedBookingsCount = completedBookingsSnapshot.docs.length;
      final conversionRate =
          totalBookingsCount > 0
              ? (completedBookingsCount / totalBookingsCount * 100)
                  .toStringAsFixed(1)
              : '0.0';

      return {
        'totalBookings': totalBookings,
        'totalRevenue': totalRevenue,
        'activeBusinesses': activeBusinesses,
        'totalUsers': totalUsers,
        'newUsers30Days': newUserCount,
        'revenueByCategory': revenueByCategory,
        'bookingsByCategory': bookingsByCategory,
        'popularSites': siteVisits,
        'userDemographics': userDemographics,
        'bookingsPerDay': await _getBookingsPerDay(),
        'conversionRate': conversionRate,
        'totalBookingsCount': totalBookingsCount,
        'completedBookingsCount': completedBookingsCount,
      };
    } catch (e) {
      throw Exception('Failed to fetch analytics: $e');
    }
  }

  Future<int> _getNewUsersCount(DateTime startDate) async {
    final snapshot =
        await _firestore
            .collection('users')
            .where('createdAt', isGreaterThanOrEqualTo: startDate)
            .get();
    return snapshot.docs.length;
  }

  Future<Map<String, int>> _getSiteVisitCounts() async {
    final snapshot = await _firestore.collection('cultural_sites').get();
    final Map<String, int> visitCounts = {};

    for (var doc in snapshot.docs) {
      final site = CulturalSite.fromMap(doc.data(), doc.id);
      visitCounts[site.name] = site.visitCount ?? 0;
    }

    return visitCounts;
  }

  Future<Map<String, dynamic>> _getUserDemographics() async {
    final snapshot = await _firestore.collection('users').get();
    final Map<String, int> ageGroups = {
      '18-25': 0,
      '26-35': 0,
      '36-45': 0,
      '46+': 0,
    };

    for (var doc in snapshot.docs) {
      final user = ZanzibarUser.fromFirebase(_auth.currentUser!, doc.data());
      if (user.age != null) {
        final int age = user.age!;
        if (age >= 18 && age <= 25)
          ageGroups['18-25'] = ageGroups['18-25']! + 1;
        else if (age >= 26 && age <= 35)
          ageGroups['26-35'] = ageGroups['26-35']! + 1;
        else if (age >= 36 && age <= 45)
          ageGroups['36-45'] = ageGroups['36-45']! + 1;
        else if (age >= 46)
          ageGroups['46+'] = ageGroups['46+']! + 1;
      }
    }

    return {'ageGroups': ageGroups, 'totalUsers': snapshot.docs.length};
  }

  Future<Map<String, int>> _getBookingsPerDay() async {
    final snapshot = await _firestore.collection('bookings').get();
    final Map<String, int> bookingsPerDay = {};

    for (var doc in snapshot.docs) {
      final booking = TourBooking.fromMap(doc.data());
      final date =
          (booking.createdAt as Timestamp).toDate().toLocal().toString().split(
            ' ',
          )[0];
      bookingsPerDay[date] = (bookingsPerDay[date] ?? 0) + 1;
    }

    return bookingsPerDay;
  }

  Future<Map<String, int>> getBookingsByStatus() async {
    try {
      final snapshot = await _firestore.collection('bookings').get();
      final bookings = snapshot.docs.map(
        (doc) => TourBooking.fromMap(doc.data()),
      );

      return bookings.fold<Map<String, int>>({}, (map, booking) {
        map[booking.status] = (map[booking.status] ?? 0) + 1;
        return map;
      });
    } catch (e) {
      throw Exception('Failed to fetch bookings by status: $e');
    }
  }
}
