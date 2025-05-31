// File: lib/screens/booking_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zanzibar_tourism/providers/booking_provider.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _tourNameController = TextEditingController();
  final _guestsController = TextEditingController(text: '2');
  DateTime? _selectedDate;
  String _selectedTimeSlot = 'Morning (9:00 AM)';
  bool _includeTransportation = false;
  bool _includeGuide = true;
  bool _isLoading = false;

  final List<String> _timeSlots = [
    'Morning (9:00 AM)',
    'Afternoon (1:00 PM)',
    'Evening (4:00 PM)',
  ];

  final List<Map<String, dynamic>> _popularTours = [
    {
      'name': 'Spice Farm Tour',
      'image':
          'https://www.zanzibar-tours.co.tz/wp-content/uploads/2024/12/146-2.jpg',
      'price': 45,
    },
    {
      'name': 'Prison Island Excursion',
      'image':
          'https://www.zanzibar-tours.co.tz/wp-content/uploads/2024/11/tour_gallery_23-800x450.jpg',
      'price': 65,
    },
    {
      'name': 'Jozani Forest Adventure',
      'image':
          'https://www.zanzibar-tours.co.tz/wp-content/uploads/2024/12/P12-16-720x450.jpg',
      'price': 35,
    },
  ];

  @override
  void dispose() {
    _tourNameController.dispose();
    _guestsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _selectTour(String tourName) {
    setState(() {
      _tourNameController.text = tourName;
    });
  }

  Future<void> _submitBooking() async {
    if (_tourNameController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please log in to book')));
        setState(() => _isLoading = false);
        return;
      }

      // Add additional booking details
      final int guests = int.tryParse(_guestsController.text) ?? 2;

      await ref
          .read(bookingProvider)
          .createBooking(
            userId: user.uid,
            tourName: _tourNameController.text.trim(),
            date: _selectedDate!,
            timeSlot: _selectedTimeSlot,
            guests: guests,
            includeTransportation: _includeTransportation,
            includeGuide: _includeGuide,
          );

      if (mounted) {
        // Show success dialog instead of snackbar
        showDialog(
          context: context,
          builder:
              (context) => _BookingConfirmationDialog(
                tourName: _tourNameController.text,
                date: _selectedDate!,
                timeSlot: _selectedTimeSlot,
              ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate estimated price
    int basePrice = 0;
    for (var tour in _popularTours) {
      if (tour['name'] == _tourNameController.text) {
        basePrice = tour['price'];
        break;
      }
    }

    final int guests = int.tryParse(_guestsController.text) ?? 2;
    final int transportationFee = _includeTransportation ? 15 : 0;
    final int guideFee = _includeGuide ? 25 : 0;
    final int totalPrice = (basePrice * guests) + transportationFee + guideFee;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom app bar with image
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Book Your Experience',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black54,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://www.zanzibar-tours.co.tz/wp-content/uploads/2024/12/146-2.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Popular tours section
                  const _SectionHeader(title: 'Popular Tours'),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _popularTours.length,
                      itemBuilder: (context, index) {
                        final tour = _popularTours[index];
                        final bool isSelected =
                            tour['name'] == _tourNameController.text;

                        return GestureDetector(
                          onTap: () => _selectTour(tour['name']),
                          child: Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.teal
                                        : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    tour['image'],
                                    height: 140,
                                    width: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Container(
                                  height: 140,
                                  width: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  right: 12,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tour['name'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '\$${tour['price']} per person',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.teal,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tour details section
                  const _SectionHeader(title: 'Tour Details'),

                  // Custom tour name field
                  if (_tourNameController.text.isEmpty)
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: TextField(
                          controller: _tourNameController,
                          decoration: const InputDecoration(
                            labelText: 'Tour Name',
                            border: InputBorder.none,
                            icon: Icon(Icons.tour, color: Colors.teal),
                          ),
                        ),
                      ),
                    ),

                  // Date and time selection
                  Row(
                    children: [
                      // Date picker
                      Expanded(
                        child: Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 16, right: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.teal,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedDate == null
                                              ? 'Select a date'
                                              : DateFormat.yMMMMd().format(
                                                _selectedDate!,
                                              ),
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Number of guests
                      Expanded(
                        child: Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 16, left: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Icon(Icons.people, color: Colors.teal),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Guests',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: _guestsController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          isDense: true,
                                        ),
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Time slot dropdown
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.teal),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time Slot',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                DropdownButton<String>(
                                  value: _selectedTimeSlot,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedTimeSlot = newValue;
                                      });
                                    }
                                  },
                                  items:
                                      _timeSlots.map<DropdownMenuItem<String>>((
                                        String value,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Additional options
                  const _SectionHeader(title: 'Additional Options'),

                  // Transportation option
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car, color: Colors.teal),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Include Transportation'),
                                Text(
                                  'Hotel pickup and drop-off service',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+\$15',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _includeTransportation,
                            activeColor: Colors.teal,
                            onChanged: (value) {
                              setState(() {
                                _includeTransportation = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Guide option
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.teal),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Private Guide'),
                                Text(
                                  'Personal guide with local knowledge',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+\$25',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _includeGuide,
                            activeColor: Colors.teal,
                            onChanged: (value) {
                              setState(() {
                                _includeGuide = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Price summary
                  if (basePrice > 0)
                    Card(
                      elevation: 0,
                      color: Colors.teal.shade50,
                      margin: const EdgeInsets.only(bottom: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.teal.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Price Summary',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                Text(
                                  'Total: \$$totalPrice',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.teal),
                            const SizedBox(height: 8),
                            _PriceSummaryItem(
                              label: 'Tour Price',
                              value: '\$$basePrice × $guests guests',
                              amount: basePrice * guests,
                            ),
                            if (_includeTransportation)
                              const _PriceSummaryItem(
                                label: 'Transportation',
                                value: 'Hotel pickup & drop-off',
                                amount: 15,
                              ),
                            if (_includeGuide)
                              const _PriceSummaryItem(
                                label: 'Private Guide',
                                value: 'Personal guide service',
                                amount: 25,
                              ),
                          ],
                        ),
                      ),
                    ),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Confirm Booking',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Cancellation policy
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'Cancellation Policy',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please note that cancellations made within 48 hours of the tour date are subject to a 50% cancellation fee. Cancellations made more than 48 hours in advance are free of charge.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.teal[700],
        ),
      ),
    );
  }
}

class _PriceSummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final int amount;

  const _PriceSummaryItem({
    required this.label,
    required this.value,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          '\$$amount',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }
}

class _BookingConfirmationDialog extends StatelessWidget {
  final String tourName;
  final DateTime date;
  final String timeSlot;

  const _BookingConfirmationDialog({
    required this.tourName,
    required this.date,
    required this.timeSlot,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Booking Confirmation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have successfully booked the following tour:',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Tour: $tourName',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            'Date: ${DateFormat.yMMMMd().format(date)}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            'Time Slot: $timeSlot',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
