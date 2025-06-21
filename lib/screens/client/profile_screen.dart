import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/providers/theme_provider.dart';
import 'package:zanzibar_tourism/providers/auth_provider.dart';
import 'package:zanzibar_tourism/services/auth_service.dart';
import 'package:zanzibar_tourism/screens/client/edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _UserInfoSection(),
          const SizedBox(height: 20),
          const _AccountManagementSection(),
          const SizedBox(height: 20),
          const _BookingHistorySection(),
          const SizedBox(height: 20),
          const _FavoritesSection(),
          const SizedBox(height: 20),
          const _SettingsAndLegalSection(),
        ],
      ),
    );
  }
}

class _UserInfoSection extends ConsumerWidget {
  const _UserInfoSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(authServiceProvider).currentUser;

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage:
              user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : const NetworkImage(
                    'https://images.unsplash.com/photo-1639526658732-ac7fdbfcf4db?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTl8fHBlcnNvbiUyMGhpamFifGVufDB8fDB8fHww',
                  ),
        ),
        const SizedBox(height: 10),
        Text(
          user?.displayName ?? 'User',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(user?.email ?? 'No email'),
        if (user?.emailVerified == false) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: const Text(
              'Email not verified',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AccountManagementSection extends ConsumerWidget {
  const _AccountManagementSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Edit Profile'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Change Password'),
          onTap: () {
            // Navigate to change password screen
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () {
            ref.read(authServiceProvider).signOut();
          },
        ),
      ],
    );
  }
}

class _BookingHistorySection extends StatelessWidget {
  const _BookingHistorySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Booking History',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        ListTile(
          title: const Text('Stone Town Guided Tour'),
          subtitle: const Text('Completed • Jan 10, 2025'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          title: const Text('Nungwi Beach Resort'),
          subtitle: const Text('Upcoming • May 15, 2025'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      ],
    );
  }
}

class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Favorites',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        ListTile(
          title: const Text('Old Fort Cultural Site'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          title: const Text('Jozani Forest Tour'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      ],
    );
  }
}

class _SettingsAndLegalSection extends ConsumerWidget {
  const _SettingsAndLegalSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings & Legal',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        SwitchListTile(
          value: theme == ThemeMode.dark,
          onChanged: (val) {
            // Handle dark mode toggle
            ref.read(themeProvider.notifier).toggleTheme();
          },
          title: const Text('Dark Mode'),
        ),
        ListTile(title: const Text('Privacy Policy'), onTap: () {}),
        ListTile(title: const Text('Terms & Conditions'), onTap: () {}),
        ListTile(title: const Text('Contact Support'), onTap: () {}),
      ],
    );
  }
}
