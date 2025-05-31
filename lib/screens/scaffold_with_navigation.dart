import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:zanzibar_tourism/providers/theme_provider.dart';

class ScaffoldWithNestedNavigation extends StatelessWidget {
  const ScaffoldWithNestedNavigation({Key? key, required this.navigationShell})
    : super(key: key ?? const ValueKey('ScaffoldWithNestedNavigation'));
  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavigationBar(
      body: navigationShell,
      currentIndex: navigationShell.currentIndex,
      onDestinationSelected: _goBranch,
    );
  }
}

class ScaffoldWithNavigationBar extends ConsumerWidget {
  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  ScaffoldWithNavigationBar({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final List<String> _titles = [
    'Home',
    'Showcase',
    'Booking',
    'Marketplace',
    'Profile',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar:
          _titles[currentIndex] == 'Booking'
              ? null
              : _titles[currentIndex] == 'Marketplace'
              ? null
              : AppBar(
                title: Text(_titles[currentIndex]),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      // Handle search action
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      // Handle notifications action
                    },
                  ),
                ],
              ),
      drawer: NavigationDrawer(
        children: [
          // Drawer header with background image and profile info
          DrawerHeader(
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1577315734214-4b3dec92d9ad?w=900&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTB8fFphbnppYmFyfGVufDB8fDB8fHww',
                ),
                fit: BoxFit.cover,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            child: Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 36, color: Colors.teal),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Zanzibar Explorer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Discover the beauty of Zanzibar',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider with padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Colors.grey.withOpacity(0.3)),
          ),

          // Main navigation section
          const Padding(
            padding: EdgeInsets.only(left: 28, top: 16, bottom: 10),
            child: Text(
              'EXPLORE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          // Education destination
          ListTile(
            leading: const Icon(HugeIcons.strokeRoundedBookOpen02),
            title: const Text('Education'),
            onTap: () {
              context.go('/education');
              Navigator.pop(context); // Close drawer
            },
          ),

          // Maps destination
          ListTile(
            leading: const Icon(HugeIcons.strokeRoundedMaps),
            title: const Text('Navigation'),
            onTap: () {
              context.go('/navigation');
              Navigator.pop(context); // Close drawer
            },
          ),

          // Divider with padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(color: Colors.grey.withOpacity(0.3)),
          ),

          // Additional section
          const Padding(
            padding: EdgeInsets.only(left: 28, top: 8, bottom: 10),
            child: Text(
              'INFORMATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          // About destination
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Zanzibar'),
            onTap: () {
              // Navigate to about page
              Navigator.pop(context); // Close drawer
            },
          ),

          // Help destination
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () {
              // Navigate to help page
              Navigator.pop(context); // Close drawer
            },
          ),

          // Settings destination
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              // Navigate to settings page
              Navigator.pop(context); // Close drawer
            },
          ),

          // Bottom section with theme toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Divider(color: Colors.grey.withOpacity(0.3)),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dark Mode',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final themeNotifier = ref.watch(themeProvider.notifier);
                    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

                    return Switch(
                      value: isDark,
                      activeColor: Colors.teal,
                      onChanged: (_) {
                        themeNotifier.toggleTheme();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: body,
      ),
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(
            icon: const Icon(HugeIcons.strokeRoundedDashboardSquare01),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(HugeIcons.strokeRoundedBuilding03),
            label: 'places',
          ),
          NavigationDestination(
            icon: const Icon(HugeIcons.strokeRoundedAppointment02),
            label: 'Booking',
          ),
          NavigationDestination(
            icon: const Icon(HugeIcons.strokeRoundedShoppingBasket01),
            label: 'marketplace',
          ),
          NavigationDestination(
            icon: const Icon(HugeIcons.strokeRoundedUserAccount),
            label: 'Profile',
          ),
        ],
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
    );
  }
}
