import 'package:flutter/material.dart';
import 'package:mendaki/core/services/gpx_storage_service.dart';
import 'package:mendaki/core/services/offline_map_service.dart';
import 'package:mendaki/core/services/view_preference_service.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/screens/detail_screen.dart';
import 'package:mendaki/widgets/home/empty_mountain_view.dart';
import 'package:mendaki/widgets/home/home_app_bar.dart';
import 'package:mendaki/widgets/home/home_search_bar.dart';
import 'package:mendaki/widgets/home/mountain_card.dart';
import 'package:mendaki/widgets/home/mountain_card_compact.dart';
import 'package:mendaki/widgets/home/offline_storage_bar.dart';

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
  String _viewMode = ViewPreferenceService.libraryViewModeCached;

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
    _loadDownloadedMountains();
  }

  Future<void> _loadViewPreference() async {
    final mode = await ViewPreferenceService.getLibraryViewMode();
    if (mounted && _viewMode != mode) {
      setState(() {
        _viewMode = mode;
      });
    }
  }

  @override
  void dispose() {
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
      final gpxBytes = await GpxStorageService.getTotalGpxSizeBytes();
      final mapBytes = await OfflineMapService.getTotalOfflineMapsSizeBytes();

      if (mounted) {
        setState(() {
          // Hanya menampilkan gunung yang kedua-duanya (isGpxReady dan isMapReady) ada
          _downloadedMountains = list
              .where((m) => m.isGpxReady && m.isMapReady)
              .toList();
          _gpxBytes = gpxBytes;
          _mapBytes = mapBytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading downloaded mountains: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Mountain> get _filteredMountains {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _downloadedMountains;

    return _downloadedMountains.where((m) {
      return m.name.toLowerCase().contains(query) ||
          m.location.toLowerCase().contains(query) ||
          m.province.toLowerCase().contains(query) ||
          m.cities.any((c) => c.toLowerCase().contains(query));
    }).toList();
  }

  Future<void> _showDeleteModal(Mountain mountain) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.error,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hapus ${mountain.name}?',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Data jalur GPX dan peta offline yang tersimpan di perangkat akan dihapus dari library.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: AppTheme.outlineVariant.withValues(
                              alpha: 0.8,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: AppTheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Hapus',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMountains;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: HomeAppBar(showBackButton: widget.showBackButton),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadDownloadedMountains,
          color: AppTheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
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

                // 2.1 Indikator ukuran penyimpanan offline (GPX & Map)
                OfflineStorageBar(gpxBytes: _gpxBytes, mapBytes: _mapBytes),
                const SizedBox(height: 16),

                // 3. Mountain card seperti home
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  )
                else if (_downloadedMountains.isEmpty)
                  EmptyMountainView(
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
                  )
                else if (filtered.isEmpty)
                  EmptyMountainView(
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
                  )
                else ...[
                  _buildSectionHeader(filtered.length),
                  const SizedBox(height: 12),
                  for (final mountain in filtered) ...[
                    if (_viewMode == ViewPreferenceService.viewModeCompact)
                      MountainCardCompact(
                        mountain: mountain,
                        onDetailTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(mountain: mountain),
                            ),
                          );
                          _loadDownloadedMountains();
                        },
                        onDownloaded: _loadDownloadedMountains,
                        onDeleteTap: () => _showDeleteModal(mountain),
                      )
                    else
                      MountainCard(
                        mountain: mountain,
                        onDetailTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(mountain: mountain),
                            ),
                          );
                          _loadDownloadedMountains();
                        },
                        onDownloaded: _loadDownloadedMountains,
                        onDeleteTap: () => _showDeleteModal(mountain),
                      ),
                    SizedBox(
                      height: _viewMode == ViewPreferenceService.viewModeCompact
                          ? 10
                          : 16,
                    ),
                  ],
                ],
                const SizedBox(height: 96),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$count Gunung Tersedia',
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),
        Container(
          height: 34,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildViewModeToggleItem(
                label: 'Detail',
                icon: Icons.web,
                isSelected: _viewMode == ViewPreferenceService.viewModeDetail,
                onTap: () {
                  if (_viewMode != ViewPreferenceService.viewModeDetail) {
                    setState(() {
                      _viewMode = ViewPreferenceService.viewModeDetail;
                    });
                    ViewPreferenceService.setLibraryViewMode(
                      ViewPreferenceService.viewModeDetail,
                    );
                  }
                },
              ),
              _buildViewModeToggleItem(
                label: 'Simple',
                icon: Icons.format_list_bulleted,
                isSelected: _viewMode == ViewPreferenceService.viewModeCompact,
                onTap: () {
                  if (_viewMode != ViewPreferenceService.viewModeCompact) {
                    setState(() {
                      _viewMode = ViewPreferenceService.viewModeCompact;
                    });
                    ViewPreferenceService.setLibraryViewMode(
                      ViewPreferenceService.viewModeCompact,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewModeToggleItem({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: Key('toggle_mode_${label.toLowerCase()}'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        width: 32,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? AppTheme.primary : AppTheme.outline,
        ),
      ),
    );
  }
}
