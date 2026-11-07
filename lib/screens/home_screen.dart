import 'package:flutter/material.dart';
import 'package:mendaki/core/services/gpx_storage_service.dart';
import 'package:mendaki/core/services/navigation_session_service.dart';
import 'package:mendaki/core/services/network_service.dart';
import 'package:mendaki/core/services/supabase_service.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/screens/detail_screen.dart';
import 'package:mendaki/screens/library_screen.dart';
import 'package:mendaki/screens/navigation_screen.dart';
import 'package:mendaki/widgets/home/empty_mountain_view.dart';
import 'package:mendaki/widgets/home/home_app_bar.dart';
import 'package:mendaki/widgets/home/home_error_view.dart';
import 'package:mendaki/widgets/home/home_filter_chips.dart';
import 'package:mendaki/widgets/home/home_search_bar.dart';
import 'package:mendaki/widgets/home/mountain_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = 'Semua';
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Mountain> mountains = [];
  bool isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _hasError = false;
  bool _isOffline = false;
  int _currentPage = 1;
  static const int _pageSize = 10;
  int _downloadedCount = 0;

  final List<String> filters = [
    'Semua',
    'Jawa Tengah',
    'Jawa Timur',
    'Jawa Barat',
    'Luar Jawa',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkActiveNavigationSession();
    _checkDownloadedCount();
    _loadMountains();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _checkActiveNavigationSession() async {
    final session = await NavigationSessionService.getActiveSession();
    if (session != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NavigationScreen(
                mountain: session.mountain,
                selectedRoute: session.selectedRoute,
                initialStartTime: session.startTime,
                initialTraveledPath: session.traveledPath,
              ),
            ),
          );
        }
      });
    }
  }

  Future<void> _checkDownloadedCount() async {
    final count = await GpxStorageService.getDownloadedMountainsCount();
    if (mounted) {
      setState(() {
        _downloadedCount = count;
      });
    }
  }

  Future<void> _openLibrary() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LibraryScreen(),
      ),
    );
    _checkDownloadedCount();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreMountains();
    }
  }

  Future<void> _loadMountains() async {
    setState(() {
      isLoading = true;
      _currentPage = 1;
      _hasMore = true;
      _hasError = false;
      _isOffline = false;
    });

    // 1. Pengecekan device offline: jika tidak ada sinyal/internet, langsung tampilkan global error
    final isOnline = await NetworkService.isOnline();
    if (!isOnline) {
      if (mounted) {
        setState(() {
          isLoading = false;
          _hasError = true;
          _isOffline = true;
          mountains = [];
        });
      }
      _checkDownloadedCount();
      return;
    }

    await _checkDownloadedCount();

    // 2. Jika online, ambil daftar gunung dari server
    try {
      final data = await SupabaseService.getMountains(
        province: selectedFilter == 'Semua' ? null : selectedFilter,
        search: searchController.text.trim().isEmpty
            ? null
            : searchController.text.trim(),
        page: 1,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          mountains = data;
          isLoading = false;
          _hasError = false;
          _isOffline = false;
          _hasMore = data.length >= _pageSize;
        });
      }
    } catch (e) {
      debugPrint('Error loading mountains from Supabase: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          _hasError = true;
          _isOffline = false;
          mountains = [];
        });
      }
    }
  }

  Future<void> _loadMoreMountains() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final data = await SupabaseService.getMountains(
        province: selectedFilter == 'Semua' ? null : selectedFilter,
        search: searchController.text.trim().isEmpty
            ? null
            : searchController.text.trim(),
        page: nextPage,
        pageSize: _pageSize,
      );

      setState(() {
        _currentPage = nextPage;
        mountains.addAll(data);
        _isLoadingMore = false;
        _hasMore = data.length >= _pageSize;
      });
    } catch (e) {
      debugPrint('Error loading more mountains: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: HomeAppBar(
        downloadedCount: _downloadedCount,
        onLibraryTap: _openLibrary,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadMountains,
          color: AppTheme.primary,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeSearchBar(
                  controller: searchController,
                  onSubmitted: (_) => _loadMountains(),
                  onClear: () {
                    searchController.clear();
                    _loadMountains();
                  },
                ),
                const SizedBox(height: 14),
                HomeFilterChips(
                  filters: filters,
                  selectedFilter: selectedFilter,
                  onSelected: (filter) {
                    setState(() {
                      selectedFilter = filter;
                    });
                    _loadMountains();
                  },
                ),
                const SizedBox(height: 20),
                if (_hasError)
                  HomeErrorView(
                    isOffline: _isOffline,
                    downloadedCount: _downloadedCount,
                    onOpenLibrary: _openLibrary,
                    onRetry: _loadMountains,
                  )
                else ...[
                  _buildSectionHeader(),
                  const SizedBox(height: 12),
                  if (isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  else if (mountains.isEmpty)
                    const EmptyMountainView()
                  else ...[
                    for (final mountain in mountains) ...[
                      MountainCard(
                        mountain: mountain,
                        onDetailTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailScreen(mountain: mountain),
                            ),
                          );
                          _checkDownloadedCount();
                        },
                        onDownloaded: _checkDownloadedCount,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Daftar Gunung',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        Text(
          '${mountains.length} Gunung',
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
