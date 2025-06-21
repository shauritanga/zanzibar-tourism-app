import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/services/admin_service.dart';
import 'package:zanzibar_tourism/providers/admin_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  late final AdminService _adminService;
  Map<String, dynamic>? _analyticsData;
  Map<String, int>? _bookingsByStatus;
  bool _isLoading = true;
  final List<String> _timePeriods = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
  ];
  String _selectedTimePeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    _adminService = ref.read(adminServiceProvider);
    _fetchAnalyticsData();
    _fetchBookingsByStatus();
  }

  Future<void> _fetchAnalyticsData() async {
    try {
      setState(() => _isLoading = true);

      // Get analytics data for the selected time period
      _analyticsData = await _adminService.getAnalytics();

      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching analytics: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBookingsByStatus() async {
    try {
      setState(() => _isLoading = true);
      _bookingsByStatus = await _adminService.getBookingsByStatus();
      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching bookings by status: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedTimePeriod = value;
                _fetchAnalyticsData();
              });
            },
            itemBuilder:
                (context) =>
                    _timePeriods.map((period) {
                      return PopupMenuItem(value: period, child: Text(period));
                    }).toList(),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () async {
                  await _fetchAnalyticsData();
                  await _fetchBookingsByStatus();
                },
                child: ListView(
                  children: [
                    _buildMetricsRow(),
                    const SizedBox(height: 16),
                    _buildBookingsChart(),
                    const SizedBox(height: 16),
                    _buildStatusPieChart(),
                  ],
                ),
              ),
    );
  }

  Widget _buildMetricsRow() {
    if (_analyticsData == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMetricCard(
            title: 'Total Bookings',
            value: _analyticsData!['totalBookings'].toString(),
            color: Colors.blue,
          ),
          _buildMetricCard(
            title: 'Total Revenue',
            value: NumberFormat.currency(
              symbol: 'TSh ',
            ).format(_analyticsData!['totalRevenue']),
            color: Colors.green,
          ),
          _buildMetricCard(
            title: 'Active Businesses',
            value: _analyticsData!['activeBusinesses'].toString(),
            color: Colors.orange,
          ),
          _buildMetricCard(
            title: 'Total Users',
            value: _analyticsData!['totalUsers'].toString(),
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 80,
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsChart() {
    if (_analyticsData == null ||
        !_analyticsData!.containsKey('bookingsPerDay')) {
      return const SizedBox.shrink();
    }

    final bookingsPerDay =
        _analyticsData!['bookingsPerDay'] as Map<String, int>;
    final data =
        bookingsPerDay.entries.map((entry) {
          final index = bookingsPerDay.entries.toList().indexOf(entry);
          return FlSpot(index.toDouble(), entry.value.toDouble());
        }).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bookings Trend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: data,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.blue.withOpacity(0.5)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.3),
                            Colors.blue.withOpacity(0),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= bookingsPerDay.length)
                            return const SizedBox.shrink();
                          final date = bookingsPerDay.keys.toList()[index];
                          return Text(
                            date.split('-').last,
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1,
                    verticalInterval: 1,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPieChart() {
    if (_bookingsByStatus == null) return const SizedBox.shrink();

    final total = _bookingsByStatus!.values.reduce((a, b) => a + b);
    final sections =
        _bookingsByStatus!.entries.map((entry) {
          final percentage = (entry.value / total * 100).toStringAsFixed(1);
          return PieChartSectionData(
            value: entry.value.toDouble(),
            title: '$percentage%',
            color: _getColor(entry.key),
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Status Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(sections: sections, centerSpaceRadius: 40),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: ListView(
                      shrinkWrap: true,
                      children:
                          _bookingsByStatus!.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _getColor(entry.key),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${entry.key}: ${entry.value}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _getColor(String status) {
  switch (status) {
    case 'Pending':
      return Colors.orange;
    case 'Confirmed':
      return Colors.blue;
    case 'Completed':
      return Colors.green;
    case 'Cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
