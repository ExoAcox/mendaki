import 'dart:ui';
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

  Future<void> _showDeleteDialog(Mountain mountain) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.88),
                        Colors.white.withValues(alpha: 0.60),
                        Colors.white.withValues(alpha: 0.78),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.20),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Hapus ${mountain.name}?',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Data jalur GPX dan peta offline yang tersimpan di perangkat akan dihapus dari library.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.35,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Batal',
                                  style: TextStyle(
                                    color: AppTheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFDC2626).withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.of(ctx).pop(true),
                                    splashColor: Colors.white.withValues(
                                      alpha: 0.2,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            const Color(0xFFEF4444).withValues(
                                              alpha: 0.90,
                                            ),
                                            const Color(0xFFDC2626).withValues(
                                              alpha: 0.85,
                                            ),
                                            const Color(0xFFB91C1C).withValues(
                                              alpha: 0.90,
                                            ),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.35,
                                          ),
                                          width: 1.2,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'Hapus',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
                        onDeleteTap: () => _showDeleteDialog(mountain),
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
                        onDeleteTap: () => _showDeleteDialog(mountain),
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
