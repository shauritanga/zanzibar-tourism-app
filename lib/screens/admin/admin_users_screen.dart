import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/models/user.dart';
import 'package:zanzibar_tourism/services/admin_service.dart';
import 'package:zanzibar_tourism/providers/admin_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  late final AdminService _adminService;
  List<ZanzibarUser> _users = [];
  bool _isLoading = true;
  String _selectedRole = 'all';
  final Map<String, String> _roleFilters = {
    'all': 'All Users',
    'user': 'Regular Users',
    'admin': 'Administrators',
  };

  @override
  void initState() {
    super.initState();
    _adminService = ref.read(adminServiceProvider);
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      setState(() => _isLoading = true);
      _users = await _adminService.getUsers().first;
      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await _adminService.updateUserRole(userId, newRole);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User role updated successfully')),
      );
      await _fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user role: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedRole = value);
            },
            itemBuilder: (context) => _roleFilters.entries.map((entry) {
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
              onRefresh: _fetchUsers,
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  if (_selectedRole != 'all' && user.role != _selectedRole) {
                    return const SizedBox.shrink();
                  }
                  return _buildUserCard(user);
                },
              ),
            ),
    );
  }

  Widget _buildUserCard(ZanzibarUser user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to user details
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
                      user.email,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    label: Text(
                      user.role,
                      style: TextStyle(
                        color: _getRoleColor(user.role),
                      ),
                    ),
                    backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (user.name.isNotEmpty)
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Joined: ${user.createdAt?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (user.role != 'admin')
                    DropdownButton<String>(
                      value: user.role,
                      items: _roleFilters.entries
                          .where((entry) => entry.key != 'admin')
                          .map((entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null && value != user.role) {
                          _updateUserRole(user.id, value);
                        }
                      },
                    ),
                  Text(
                    'Last Login: ${user.lastSignInTime?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'user':
        return Colors.blue;
      case 'admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
