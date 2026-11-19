import 'package:flutter/material.dart';
import 'package:mendaki/core/services/gpx_storage_service.dart';
import 'package:mendaki/core/services/offline_map_service.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/screens/detail_screen.dart';
import 'package:mendaki/widgets/home/empty_mountain_view.dart';
import 'package:mendaki/widgets/home/home_app_bar.dart';
import 'package:mendaki/widgets/home/home_search_bar.dart';
import 'package:mendaki/widgets/home/mountain_card.dart';
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

  void refreshDownloadedMountains() {
    _loadDownloadedMountains();
  }

  void focusSearch() {
    _searchFocusNode.requestFocus();
  }

  @override
  void initState() {
    super.initState();
    _loadDownloadedMountains();
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
                  for (final mountain in filtered) ...[
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
                    const SizedBox(height: 16),
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
}
