import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/screens/home_screen.dart';
import 'package:mendaki/screens/library_screen.dart';
import 'package:mendaki/screens/more_screen.dart';
import 'package:mendaki/widgets/home/floating_nav_bar.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<LibraryScreenState> _libraryKey =
      GlobalKey<LibraryScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;

    if (index == 0) {
      _homeKey.currentState?.refreshDownloadedCount();
    } else if (index == 1) {
      _libraryKey.currentState?.refreshDownloadedMountains();
    }

    setState(() {
      _currentIndex = index;
    });
  }

  void _onSearchTap() {
    if (_currentIndex == 0) {
      _homeKey.currentState?.focusSearch();
    } else if (_currentIndex == 1) {
      _libraryKey.currentState?.focusSearch();
    } else {
      _onTabSelected(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _homeKey.currentState?.focusSearch();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(key: _homeKey, onOpenLibrary: () => _onTabSelected(1)),
              LibraryScreen(
                key: _libraryKey,
                showBackButton: false,
                onExploreTap: () => _onTabSelected(0),
              ),
              const MoreScreen(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavBar(
              currentIndex: _currentIndex,
              onTap: _onTabSelected,
              onSearchTap: _onSearchTap,
            ),
          ),
        ],
      ),
    );
  }
}
