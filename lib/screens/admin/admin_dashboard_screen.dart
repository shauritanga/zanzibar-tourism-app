import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      // Fetch all required data in parallel
      final results = await Future.wait([
        _getTotalBookings(),
        _getTotalRevenue(),
        _getTotalUsers(),
        _getTotalBusinesses(),
        _getRecentBookings(),
        _getMonthlyRevenue(),
        _getBookingsByStatus(),
        _getTopProducts(),
      ]);

      setState(() {
        _dashboardData = {
          'totalBookings': results[0],
          'totalRevenue': results[1],
          'totalUsers': results[2],
          'totalBusinesses': results[3],
          'recentBookings': results[4],
          'monthlyRevenue': results[5],
          'bookingsByStatus': results[6],
          'topProducts': results[7],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading dashboard: $e')));
      }
    }
  }

  Future<int> _getTotalBookings() async {
    final snapshot = await _firestore.collection('bookings').get();
    return snapshot.docs.length;
  }

  Future<double> _getTotalRevenue() async {
    final snapshot =
        await _firestore
            .collection('payments')
            .where('status', isEqualTo: 'completed')
            .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['amount'] ?? 0).toDouble();
    }
    return total;
  }

  Future<int> _getTotalUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.length;
  }

  Future<int> _getTotalBusinesses() async {
    final snapshot = await _firestore.collection('businesses').get();
    return snapshot.docs.length;
  }

  Future<List<Map<String, dynamic>>> _getRecentBookings() async {
    final snapshot =
        await _firestore
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getMonthlyRevenue() async {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);

    final snapshot =
        await _firestore
            .collection('payments')
            .where('status', isEqualTo: 'completed')
            .where('createdAt', isGreaterThan: sixMonthsAgo)
            .get();

    Map<String, double> monthlyData = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = data['createdAt'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        final monthKey = DateFormat('MMM yyyy').format(date);
        monthlyData[monthKey] =
            (monthlyData[monthKey] ?? 0) + (data['amount'] ?? 0).toDouble();
      }
    }

    return monthlyData.entries
        .map((e) => {'month': e.key, 'revenue': e.value})
        .toList();
  }

  Future<Map<String, int>> _getBookingsByStatus() async {
    final snapshot = await _firestore.collection('bookings').get();

    Map<String, int> statusCount = {
      'pending': 0,
      'confirmed': 0,
      'completed': 0,
      'cancelled': 0,
    };

    for (var doc in snapshot.docs) {
      final status = doc.data()['status'] ?? 'pending';
      statusCount[status] = (statusCount[status] ?? 0) + 1;
    }

    return statusCount;
  }

  Future<List<Map<String, dynamic>>> _getTopProducts() async {
    final snapshot =
        await _firestore
            .collection('products')
            .orderBy('rating', descending: true)
            .limit(5)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.dashboard,
                                size: 40,
                                color: Colors.indigo,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Welcome to Admin Dashboard',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Last updated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Key Metrics Cards
                      const Text(
                        'Key Metrics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMetricsGrid(),
                      const SizedBox(height: 24),

                      // Charts Section
                      const Text(
                        'Analytics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildChartsSection(),
                      const SizedBox(height: 24),

                      // Recent Activity
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRecentActivity(),
                      const SizedBox(height: 24),

                      // Quick Actions
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQuickActions(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMetricCard(
          'Total Bookings',
          '${_dashboardData['totalBookings'] ?? 0}',
          Icons.book_online,
          Colors.blue,
        ),
        _buildMetricCard(
          'Total Revenue',
          '\$${(_dashboardData['totalRevenue'] ?? 0.0).toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.green,
        ),
        _buildMetricCard(
          'Total Users',
          '${_dashboardData['totalUsers'] ?? 0}',
          Icons.people,
          Colors.orange,
        ),
        _buildMetricCard(
          'Businesses',
          '${_dashboardData['totalBusinesses'] ?? 0}',
          Icons.business,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    final bookingsByStatus =
        _dashboardData['bookingsByStatus'] as Map<String, int>? ?? {};

    return Row(
      children: [
        // Booking Status Pie Chart
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Bookings by Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(bookingsByStatus),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLegend(bookingsByStatus),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, int> data) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red];
    final statuses = data.keys.toList();

    return statuses.asMap().entries.map((entry) {
      final index = entry.key;
      final status = entry.value;
      final count = data[status] ?? 0;
      final total = data.values.fold(0, (total, value) => total + value);
      final percentage = total > 0 ? (count / total * 100) : 0;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: count.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(Map<String, int> data) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red];
    final statuses = data.keys.toList();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children:
          statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final count = data[status] ?? 0;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${status.toUpperCase()} ($count)',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildRecentActivity() {
    final recentBookings =
        _dashboardData['recentBookings'] as List<Map<String, dynamic>>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Bookings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (recentBookings.isEmpty)
              const Center(
                child: Text(
                  'No recent bookings',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...recentBookings.map((booking) => _buildBookingItem(booking)),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingItem(Map<String, dynamic> booking) {
    final tourName = booking['tourName'] ?? 'Unknown Tour';
    final status = booking['status'] ?? 'pending';
    final timestamp = booking['createdAt'] as Timestamp?;
    final dateStr =
        timestamp != null
            ? DateFormat('MMM dd, HH:mm').format(timestamp.toDate())
            : 'Unknown date';

    Color statusColor;
    switch (status) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tourName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildActionCard(
          'Manage Bookings',
          Icons.book_online,
          Colors.blue,
          () => context.go('/admin/bookings'),
        ),
        _buildActionCard(
          'Manage Users',
          Icons.people,
          Colors.green,
          () => context.go('/admin/users'),
        ),
        _buildActionCard(
          'Manage Content',
          Icons.article,
          Colors.orange,
          () => context.go('/admin/content'),
        ),
        _buildActionCard(
          'View Analytics',
          Icons.analytics,
          Colors.purple,
          () => context.go('/admin/analytics'),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
