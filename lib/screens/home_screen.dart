import 'package:flutter/material.dart';
import 'package:mendaki/core/services/gpx_storage_service.dart';
import 'package:mendaki/core/services/supabase_service.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/widgets/home/empty_mountain_view.dart';
import 'package:mendaki/widgets/home/home_app_bar.dart';
import 'package:mendaki/widgets/home/home_filter_chips.dart';
import 'package:mendaki/widgets/home/home_search_bar.dart';
import 'package:mendaki/widgets/home/mountain_card.dart';
import 'package:mendaki/screens/detail_screen.dart';

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
  int _currentPage = 1;
  static const int _pageSize = 10;

  bool _showOnlyDownloaded = false;
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
    _checkDownloadedCount();
    _loadMountains();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _checkDownloadedCount() async {
    final count = await GpxStorageService.getDownloadedMountainsCount();
    if (mounted) {
      setState(() {
        _downloadedCount = count;
      });
    }
  }

  void _toggleDownloadedFilter() {
    setState(() {
      _showOnlyDownloaded = !_showOnlyDownloaded;
    });
    _loadMountains();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoading &&
        !_isLoadingMore &&
        !_showOnlyDownloaded &&
        _hasMore) {
      _loadMoreMountains();
    }
  }

  Future<void> _loadMountains() async {
    setState(() {
      isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    });

    await _checkDownloadedCount();

    // 1. Jika mode filter Gunung Tersimpan (Offline) aktif
    if (_showOnlyDownloaded) {
      final allDownloaded = await GpxStorageService.getDownloadedMountains();
      final query = searchController.text.trim().toLowerCase();

      final filtered = allDownloaded.where((m) {
        final matchSearch =
            query.isEmpty ||
            m.name.toLowerCase().contains(query) ||
            m.cities.any((c) => c.toLowerCase().contains(query));

        final matchFilter =
            selectedFilter == 'Semua' ||
            (selectedFilter == 'Luar Jawa'
                ? ![
                    'Jawa Tengah',
                    'Jawa Barat',
                    'Jawa Timur',
                  ].contains(m.province)
                : m.province == selectedFilter);

        return matchSearch && matchFilter;
      }).toList();

      if (mounted) {
        setState(() {
          mountains = filtered;
          isLoading = false;
          _hasMore = false;
        });
      }
      return;
    }

    // 2. Mode Normal (Fetch dari Supabase, dengan fallback offline otomatis jika no internet)
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
          _hasMore = data.length >= _pageSize;
        });
      }
    } catch (e) {
      debugPrint(
        'Error loading mountains from Supabase, fallback to offline: $e',
      );
      final offline = await GpxStorageService.getDownloadedMountains();
      if (mounted) {
        setState(() {
          mountains = offline;
          isLoading = false;
          _hasMore = false;
        });
      }
    }
  }

  Future<void> _loadMoreMountains() async {
    if (_showOnlyDownloaded) return;

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
        isShowingDownloaded: _showOnlyDownloaded,
        downloadedCount: _downloadedCount,
        onDownloadedTap: _toggleDownloadedFilter,
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
                _buildSectionHeader(),
                const SizedBox(height: 12),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  )
                else if (mountains.isEmpty)
                  if (_showOnlyDownloaded)
                    EmptyMountainView(
                      icon: Icons.offline_pin_rounded,
                      title: 'Belum Ada Gunung Tersimpan',
                      message:
                          'Unduh berkas GPX pada kartu gunung untuk mengakses rute, peta, dan navigasi secara offline.',
                      action: ElevatedButton.icon(
                        onPressed: _toggleDownloadedFilter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.explore_rounded, size: 18),
                        label: const Text('Jelajahi Semua Gunung'),
                      ),
                    )
                  else
                    const EmptyMountainView()
                else ...[
                  for (final mountain in mountains) ...[
                    MountainCard(
                      mountain: mountain,
                      onDetailTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(mountain: mountain),
                          ),
                        );
                        _checkDownloadedCount();
                        if (_showOnlyDownloaded) {
                          _loadMountains();
                        }
                      },
                      onDownloaded: () {
                        _checkDownloadedCount();
                        if (_showOnlyDownloaded) {
                          _loadMountains();
                        }
                      },
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
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    if (_showOnlyDownloaded) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'Downloaded',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: _toggleDownloadedFilter,
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Semua Gunung'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

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
