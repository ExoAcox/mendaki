import 'package:flutter/material.dart';
import 'package:mendaki/core/config/app_config.dart';
import 'package:mendaki/core/services/gpx_storage_service.dart';
import 'package:mendaki/core/services/image_cache_manager.dart';
import 'package:mendaki/core/services/mountain_sort_service.dart';
import 'package:mendaki/core/services/navigation_session_service.dart';
import 'package:mendaki/core/services/network_service.dart';
import 'package:mendaki/core/services/offline_map_service.dart';
import 'package:mendaki/core/services/supabase_service.dart';
import 'package:mendaki/core/services/version_state_service.dart';
import 'package:mendaki/core/services/view_preference_service.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/app_version.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/screens/detail_screen.dart';
import 'package:mendaki/screens/library_screen.dart';
import 'package:mendaki/screens/navigation_screen.dart';
import 'package:mendaki/widgets/home/empty_mountain_view.dart';
import 'package:mendaki/widgets/home/feedback_modal.dart';
import 'package:mendaki/widgets/home/home_app_bar.dart';
import 'package:mendaki/widgets/home/home_error_view.dart';
import 'package:mendaki/widgets/home/home_filter_chips.dart';
import 'package:mendaki/widgets/home/home_search_bar.dart';
import 'package:mendaki/widgets/home/mountain_card.dart';
import 'package:mendaki/widgets/home/mountain_card_compact.dart';
import 'package:mendaki/widgets/home/mountain_category_button.dart';
import 'package:mendaki/widgets/home/mountain_section_header.dart';
import 'package:mendaki/widgets/home/responsive_mountain_sliver.dart';
import 'package:mendaki/widgets/home/version_update_dialog.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenLibrary;

  const HomeScreen({super.key, this.onOpenLibrary});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String selectedFilter = 'Semua';
  String? selectedCategory;
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
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
  int _totalCount = 0;
  String _viewMode = ViewPreferenceService.homeViewModeCached;
  MountainSortOption _sortOption = MountainSortService.homeSortCached;

  void refreshDownloadedCount() {
    _checkDownloadedCount();
  }

  void focusSearch() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    searchFocusNode.requestFocus();
  }

  final List<String> filters = [
    'Semua',
    'Jawa Tengah',
    'Jawa Barat',
    'Jawa Timur',
    'Luar Jawa',
  ];

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
    _loadSortPreference();
    MountainSortService.sortNotifier.addListener(_onSortNotifierChanged);
    _scrollController.addListener(_onScroll);
    _checkActiveNavigationSession();
    _checkDownloadedCount();
    _loadMountains();
    _checkAppVersion();
  }

  void _onSortNotifierChanged() {
    final newSort = MountainSortService.sortNotifier.value;
    if (_sortOption != newSort && mounted) {
      setState(() {
        _sortOption = newSort;
        if (mountains.isNotEmpty) {
          mountains = MountainSortService.sort(mountains, newSort);
        }
      });
      _loadMountains();
    }
  }

  Future<void> _loadViewPreference() async {
    final mode = await ViewPreferenceService.getHomeViewMode();
    if (mounted && _viewMode != mode) {
      setState(() {
        _viewMode = mode;
      });
    }
  }

  Future<void> _loadSortPreference() async {
    final sort = await MountainSortService.getSort();
    if (mounted && _sortOption != sort) {
      setState(() {
        _sortOption = sort;
        if (mountains.isNotEmpty) {
          mountains = MountainSortService.sort(mountains, sort);
        }
      });
    }
  }

  void _onSortChanged(MountainSortOption newSort) {
    if (_sortOption == newSort) return;
    MountainSortService.setSort(newSort);
  }

  @override
  void dispose() {
    MountainSortService.sortNotifier.removeListener(_onSortNotifierChanged);
    _scrollController.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkAppVersion() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final latestVersion = await SupabaseService.getLatestVersion();
        if (latestVersion == null || !mounted) return;

        // Cek apakah versi saat ini lebih rendah dari versi terbaru di database
        if (AppVersion.isVersionBelow(
          AppConfig.currentVersion,
          latestVersion.id,
        )) {
          // Cek apakah dialog masih dalam masa tunda 7 hari sejak ditutup oleh pengguna
          final shouldShow = await VersionStateService.shouldShowUpdateDialog(
            latestVersion.id,
            forceUpdate: latestVersion.forceUpdate,
          );
          if (!shouldShow) return;

          // Jangan tampilkan jika ada sesi navigasi aktif
          final session = await NavigationSessionService.getActiveSession();
          if (session != null) return;

          if (mounted) {
            VersionUpdateDialog.show(context, latestVersion);
          }
        }
      } catch (e) {
        debugPrint('Error saat pengecekan versi aplikasi: $e');
      }
    });
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
    final list = await GpxStorageService.getDownloadedMountains(
      onlyFullyReady: false,
    );
    for (final m in list) {
      GpxStorageService.setGpxDownloadedCache(m.id, m.isGpxReady);
      OfflineMapService.setOfflineMapDownloadedCache(m.id, m.isMapReady);
    }
    final count = list.where((m) => m.isGpxReady && m.isMapReady).length;
    if (mounted) {
      setState(() {
        _downloadedCount = count;
      });
    }
  }

  Future<void> _openLibrary() async {
    if (widget.onOpenLibrary != null) {
      widget.onOpenLibrary!();
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LibraryScreen()));
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
      final result = await SupabaseService.getMountainsResult(
        province: selectedFilter == 'Semua' ? null : selectedFilter,
        category: selectedCategory,
        search: searchController.text.trim().isEmpty
            ? null
            : searchController.text.trim(),
        page: 1,
        pageSize: _pageSize,
        sortOption: _sortOption,
      );

      if (mounted) {
        setState(() {
          mountains = MountainSortService.sort(result.mountains, _sortOption);
          _totalCount = result.totalCount;
          isLoading = false;
          _hasError = false;
          _isOffline = false;
          _hasMore = result.mountains.length >= _pageSize;
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
          _totalCount = 0;
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
      final result = await SupabaseService.getMountainsResult(
        province: selectedFilter == 'Semua' ? null : selectedFilter,
        category: selectedCategory,
        search: searchController.text.trim().isEmpty
            ? null
            : searchController.text.trim(),
        page: nextPage,
        pageSize: _pageSize,
        sortOption: _sortOption,
      );

      setState(() {
        _currentPage = nextPage;
        mountains.addAll(result.mountains);
        mountains = MountainSortService.sort(mountains, _sortOption);
        _totalCount = result.totalCount;
        _isLoadingMore = false;
        _hasMore = result.mountains.length >= _pageSize;
      });
    } catch (e) {
      debugPrint('Error loading more mountains: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await MountainImageCacheManager.resetStaleTime();
    await _loadMountains();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: const HomeAppBar(),
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.primary,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeSearchBar(
                        controller: searchController,
                        focusNode: searchFocusNode,
                        onSubmitted: (_) => _loadMountains(),
                        onClear: () {
                          searchController.clear();
                          _loadMountains();
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          MountainCategoryButton(
                            selectedCategory: selectedCategory,
                            onCategoryChanged: (category) {
                              setState(() {
                                selectedCategory = category;
                                if (category != null) {
                                  selectedFilter = 'Semua';
                                }
                              });
                              _loadMountains();
                            },
                          ),
                          if (selectedCategory == null || selectedCategory!.isEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: HomeFilterChips(
                                filters: filters,
                                selectedFilter: selectedFilter,
                                onSelected: (filter) {
                                  setState(() {
                                    selectedFilter = filter;
                                  });
                                  _loadMountains();
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              if (_hasError)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverToBoxAdapter(
                    child: HomeErrorView(
                      isOffline: _isOffline,
                      downloadedCount: _downloadedCount,
                      onOpenLibrary: _openLibrary,
                      onRetry: _loadMountains,
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MountainSectionHeader(
                          count: _totalCount > 0 ? _totalCount : mountains.length,
                          currentSort: _sortOption,
                          onSortChanged: _onSortChanged,
                          currentViewMode: _viewMode,
                          onViewModeChanged: (newMode) {
                            setState(() {
                              _viewMode = newMode;
                            });
                            ViewPreferenceService.setHomeViewMode(newMode);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                if (isLoading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  )
                else if (mountains.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const EmptyMountainView(),
                          const SizedBox(height: 16),
                          _buildFeedbackPrompt(),
                        ],
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: ResponsiveMountainSliver(
                      itemCount: mountains.length,
                      mainAxisSpacing:
                          _viewMode == ViewPreferenceService.viewModeCompact
                              ? 10
                              : 16,
                      crossAxisSpacing: 16,
                      itemBuilder: (context, index) {
                        final mountain = mountains[index];
                        if (_viewMode ==
                            ViewPreferenceService.viewModeCompact) {
                          return MountainCardCompact(
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
                          );
                        } else {
                          return MountainCard(
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
                          );
                        }
                      },
                    ),
                  ),
                  if (_isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
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
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _buildFeedbackPrompt(),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
              const SliverToBoxAdapter(
                child: SizedBox(height: 96),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackPrompt() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.outlineVariant.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Data gunung belum tersedia?',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () =>
                FeedbackModal.show(context, initialType: 'request'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: BorderSide(
                color: AppTheme.primary.withValues(alpha: 0.7),
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text(
              'Request di sini',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
