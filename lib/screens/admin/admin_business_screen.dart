import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/models/business.dart';
import 'package:zanzibar_tourism/providers/admin_provider.dart';
import 'package:zanzibar_tourism/services/admin_service.dart';

class AdminBusinessScreen extends ConsumerStatefulWidget {
  const AdminBusinessScreen({super.key});

  @override
  ConsumerState<AdminBusinessScreen> createState() =>
      _AdminBusinessScreenState();
}

class _AdminBusinessScreenState extends ConsumerState<AdminBusinessScreen> {
  late final AdminService _adminService;
  List<Business> _businesses = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';
  final Map<String, String> _statusFilters = {
    'all': 'All Businesses',
    'pending': 'Pending Review',
    'approved': 'Approved',
    'rejected': 'Rejected',
  };

  @override
  void initState() {
    super.initState();
    _adminService = ref.read(adminServiceProvider);
    _fetchBusinesses();
  }

  Future<void> _fetchBusinesses() async {
    try {
      setState(() => _isLoading = true);
      _businesses = await _adminService.getBusinesses().first;
      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching businesses: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveBusiness(String businessId) async {
    try {
      await _adminService.approveBusiness(businessId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business approved successfully')),
      );
      await _fetchBusinesses();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving business: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Management'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedStatus = value);
            },
            itemBuilder:
                (context) =>
                    _statusFilters.entries.map((entry) {
                      return PopupMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchBusinesses,
                child: ListView.builder(
                  itemCount: _businesses.length,
                  itemBuilder: (context, index) {
                    final business = _businesses[index];
                    if (_selectedStatus != 'all' &&
                        business.status != _selectedStatus) {
                      return const SizedBox.shrink();
                    }
                    return _buildBusinessCard(business);
                  },
                ),
              ),
    );
  }

  Widget _buildBusinessCard(Business business) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to business details
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
                      business.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    label: Text(
                      business.status,
                      style: TextStyle(color: _getStatusColor(business.status)),
                    ),
                    backgroundColor: _getStatusColor(
                      business.status,
                    ).withOpacity(0.1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    business.category,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      business.address,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Contact: ${business.contact}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (business.status == 'pending')
                    ElevatedButton.icon(
                      onPressed: () => _approveBusiness(business.id),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
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
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
