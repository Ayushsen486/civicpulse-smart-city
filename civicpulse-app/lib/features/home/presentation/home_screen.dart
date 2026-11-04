import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:civicpulse_app/features/issue/presentation/screens/feed_screen.dart';
import 'package:civicpulse_app/features/issue/presentation/screens/my_issues_screen.dart';
import 'package:civicpulse_app/features/map/presentation/complaints_map_screen.dart';
import 'package:civicpulse_app/features/profile/presentation/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const [
    FeedScreen(),
    ComplaintsMapScreen(),
    MyIssuesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        floatingActionButton: _currentIndex == 0 || _currentIndex == 2
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/report'),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Report Issue'),
                tooltip: 'Report a new civic issue with photo and GPS location',
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Explore',
              tooltip: 'Browse public civic feed',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Live Map',
              tooltip: 'Geospatial complaints command map',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'My Reports',
              tooltip: 'View your submitted issues',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
              tooltip: 'User profile and settings',
            ),
          ],
        ),
      ),
    );
  }
}
