import 'package:flutter/material.dart';
import 'package:mendaki/core/services/gpx_storage_service.dart';
import 'package:mendaki/core/services/mountain_sort_service.dart';
import 'package:mendaki/core/services/offline_map_service.dart';
import 'package:mendaki/core/services/storage_info_service.dart';
import 'package:mendaki/core/services/view_preference_service.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/screens/detail_screen.dart';
import 'package:mendaki/widgets/home/empty_mountain_view.dart';
import 'package:mendaki/widgets/home/home_app_bar.dart';
import 'package:mendaki/widgets/home/home_search_bar.dart';
import 'package:mendaki/widgets/home/mountain_card.dart';
import 'package:mendaki/widgets/home/mountain_card_compact.dart';
import 'package:mendaki/widgets/home/mountain_section_header.dart';
import 'package:mendaki/widgets/library/delete_mountain_dialog.dart';
import 'package:mendaki/widgets/library/delete_storage_dialog.dart';
import 'package:mendaki/widgets/library/offline_storage_bar.dart';

class LibraryScreen extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onExploreTap;

  const LibraryScreen({
    super.key,
    this.showBackButton = true,
    this.onExploreTap,
  });

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Mountain> _downloadedMountains = [];
  bool _isLoading = true;
  int _gpxBytes = 0;
  int _mapBytes = 0;
  int _imageBytes = 0;
  int? _availableBytes;
  String _viewMode = ViewPreferenceService.libraryViewModeCached;
  MountainSortOption _sortOption = MountainSortService.librarySortCached;

  void refreshDownloadedMountains() {
    _loadDownloadedMountains();
  }

  void focusSearch() {
    _searchFocusNode.requestFocus();
  }

  @override
  void initState() {
    super.initState();
    _loadViewPreference();
    _loadSortPreference();
    MountainSortService.sortNotifier.addListener(_onSortNotifierChanged);
    _loadDownloadedMountains();
  }

  void _onSortNotifierChanged() {
    final newSort = MountainSortService.sortNotifier.value;
    if (_sortOption != newSort && mounted) {
      setState(() {
        _sortOption = newSort;
      });
    }
  }

  Future<void> _loadViewPreference() async {
    final mode = await ViewPreferenceService.getLibraryViewMode();
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
      });
    }
  }

  @override
  void dispose() {
    MountainSortService.sortNotifier.removeListener(_onSortNotifierChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadDownloadedMountains() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final list = await GpxStorageService.getDownloadedMountains(
        onlyFullyReady: true,
      );

      if (mounted) {
        setState(() {
          // Hanya menampilkan gunung yang kedua-duanya (isGpxReady dan isMapReady) ada
          _downloadedMountains = list
              .where((m) => m.isGpxReady && m.isMapReady)
              .toList();
          _isLoading = false;
        });
      }

      // Ambil metrik penyimpanan secara paralel di latar belakang tanpa menahan daftar gunung
      _loadStorageMetrics();
    } catch (e) {
      debugPrint('Error loading downloaded mountains: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStorageMetrics() async {
    try {
      final gpxFuture = GpxStorageService.getTotalGpxSizeBytes();
      final mapFuture = OfflineMapService.getTotalOfflineMapsSizeBytes();
      final imageFuture = GpxStorageService.getTotalImagesSizeBytes();
      final diskFuture = StorageInfoService.getAvailableDiskSpaceBytes();

      final gpxBytes = await gpxFuture;
      final mapBytes = await mapFuture;
      final imageBytes = await imageFuture;
      final availableBytes = await diskFuture;

      if (mounted) {
        setState(() {
          _gpxBytes = gpxBytes;
          _mapBytes = mapBytes;
          _imageBytes = imageBytes;
          _availableBytes = availableBytes;
        });
      }
    } catch (e) {
      debugPrint('Error loading storage metrics: $e');
    }
  }

  List<Mountain> get _filteredMountains {
    final query = _searchController.text.trim().toLowerCase();
    List<Mountain> result = _downloadedMountains;
    if (query.isNotEmpty) {
      result = _downloadedMountains.where((m) {
        return m.name.toLowerCase().contains(query) ||
            m.location.toLowerCase().contains(query) ||
            m.province.toLowerCase().contains(query) ||
            m.cities.any((c) => c.toLowerCase().contains(query));
      }).toList();
    }
    return MountainSortService.sort(result, _sortOption);
  }

  Future<void> _handleDeleteMountain(Mountain mountain) async {
    final confirmed = await DeleteMountainDialog.show(context, mountain);

    if (confirmed == true) {
      await GpxStorageService.deleteDownloadedMountain(mountain.id);
      await OfflineMapService.deleteOfflineMap(mountain.id);
      _loadDownloadedMountains();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${mountain.name} berhasil dihapus dari library'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteStorage() async {
    final result = await DeleteStorageFlow.show(
      context,
      gpxBytes: _gpxBytes,
      mapBytes: _mapBytes,
      imageBytes: _imageBytes,
    );

    if (result != null) {
      if (result.gpx) {
        await GpxStorageService.deleteAllGpxFiles();
      }
      if (result.maps) {
        await OfflineMapService.deleteAllOfflineMaps();
      }
      if (result.images) {
        await GpxStorageService.deleteAllImages();
      }

      await _loadDownloadedMountains();
      await _loadStorageMetrics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data offline terpilih berhasil dihapus'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMountains;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: HomeAppBar(showBackButton: widget.showBackButton),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadDownloadedMountains();
            await _loadStorageMetrics();
          },
          color: AppTheme.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const OfflineStorageNotice(),
                      const SizedBox(height: 12),
                      // 1. Search Bar (tanpa filter provinsi)
                      HomeSearchBar(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        hintText: 'Cari gunung di library...',
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => setState(() {}),
                        onClear: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 12),

                      // 2. Indikator ukuran penyimpanan offline (GPX, Map & Images)
                      OfflineStorageBar(
                        gpxBytes: _gpxBytes,
                        mapBytes: _mapBytes,
                        imageBytes: _imageBytes,
                        availableBytes: _availableBytes,
                        onDeletePressed: _handleDeleteStorage,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // 3. Mountain card list atau empty state
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  ),
                )
              else if (_downloadedMountains.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverToBoxAdapter(
                    child: EmptyMountainView(
                      icon: Icons.folder_open_rounded,
                      title: 'Belum Ada Gunung Tersimpan',
                      message:
                          'Data offline gunung yang telah Anda unduh akan muncul di sini untuk diakses tanpa koneksi internet.',
                      action: ElevatedButton.icon(
                        onPressed: () {
                          if (widget.onExploreTap != null) {
                            widget.onExploreTap!();
                          } else if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.explore_rounded, size: 18),
                        label: const Text('Jelajahi Gunung'),
                      ),
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverToBoxAdapter(
                    child: EmptyMountainView(
                      title: 'Gunung Tidak Ditemukan',
                      message: 'Tidak ada gunung di library offline.',
                      action: ElevatedButton.icon(
                        onPressed: () {
                          if (widget.onExploreTap != null) {
                            widget.onExploreTap!();
                          } else if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.explore_rounded, size: 18),
                        label: const Text('Jelajahi Gunung'),
                      ),
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
                          count: filtered.length,
                          currentSort: _sortOption,
                          onSortChanged: (newSort) {
                            MountainSortService.setSort(newSort);
                          },
                          currentViewMode: _viewMode,
                          onViewModeChanged: (newMode) {
                            setState(() {
                              _viewMode = newMode;
                            });
                            ViewPreferenceService.setLibraryViewMode(newMode);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final mountain = filtered[index];
                      if (_viewMode == ViewPreferenceService.viewModeCompact) {
                        return MountainCardCompact(
                          mountain: mountain,
                          onDetailTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetailScreen(mountain: mountain),
                              ),
                            );
                            _loadDownloadedMountains();
                          },
                          onDownloaded: _loadDownloadedMountains,
                          onDeleteTap: () => _handleDeleteMountain(mountain),
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
                            _loadDownloadedMountains();
                          },
                          onDownloaded: _loadDownloadedMountains,
                          onDeleteTap: () => _handleDeleteMountain(mountain),
                        );
                      }
                    },
                    separatorBuilder: (context, index) => SizedBox(
                      height: _viewMode == ViewPreferenceService.viewModeCompact
                          ? 10
                          : 16,
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
    );
  }
}
