import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/providers/theme_provider.dart';
import 'package:zanzibar_tourism/services/auth_service.dart';

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

class _UserInfoSection extends StatelessWidget {
  const _UserInfoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundImage: NetworkImage(
            'https://images.unsplash.com/photo-1639526658732-ac7fdbfcf4db?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTl8fHBlcnNvbiUyMGhpamFifGVufDB8fDB8fHww',
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Rahma Yusuf',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Text('rahmayusuf@gmail.com'),
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
            // Navigate to edit profile screen
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
