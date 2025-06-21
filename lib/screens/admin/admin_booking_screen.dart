import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/models/tour.dart';
import 'package:zanzibar_tourism/services/admin_service.dart';
import 'package:zanzibar_tourism/providers/admin_provider.dart';

class AdminBookingScreen extends ConsumerStatefulWidget {
  const AdminBookingScreen({super.key});

  @override
  ConsumerState<AdminBookingScreen> createState() => _AdminBookingScreenState();
}

class _AdminBookingScreenState extends ConsumerState<AdminBookingScreen> {
  late final AdminService _adminService;
  List<TourBooking> _bookings = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';
  final Map<String, String> _statusFilters = {
    'all': 'All Bookings',
    'pending': 'Pending',
    'confirmed': 'Confirmed',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  @override
  void initState() {
    super.initState();
    _adminService = ref.read(adminServiceProvider);
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      setState(() => _isLoading = true);
      _bookings = await _adminService.getBookings().first;
      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching bookings: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _adminService.updateBookingStatus(bookingId, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking status updated successfully')),
      );
      await _fetchBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating booking status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Management'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedStatus = value);
            },
            itemBuilder: (context) => _statusFilters.entries.map((entry) {
              return PopupMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchBookings,
              child: ListView.builder(
                itemCount: _bookings.length,
                itemBuilder: (context, index) {
                  final booking = _bookings[index];
                  if (_selectedStatus != 'all' &&
                      booking.status != _selectedStatus) {
                    return const SizedBox.shrink();
                  }
                  return _buildBookingCard(booking);
                },
              ),
            ),
    );
  }

  Widget _buildBookingCard(TourBooking booking) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to booking details
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.tour.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    label: Text(
                      booking.status,
                      style: TextStyle(
                        color: _getStatusColor(booking.status),
                      ),
                    ),
                    backgroundColor: _getStatusColor(booking.status).withOpacity(0.1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    booking.date.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Guests: ${booking.quantity}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TSH ${booking.tour.price * booking.quantity}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  DropdownButton<String>(
                    value: booking.status,
                    items: _statusFilters.entries
                        .map((entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null && value != booking.status) {
                        _updateBookingStatus(booking.id, value);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
