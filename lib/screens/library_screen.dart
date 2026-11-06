import 'package:flutter/material.dart';
import 'package:mendaki/core/services/gpx_storage_service.dart';
import 'package:mendaki/core/services/offline_map_service.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/models/mountain.dart';
import 'package:mendaki/screens/detail_screen.dart';
import 'package:mendaki/widgets/home/empty_mountain_view.dart';
import 'package:mendaki/widgets/home/home_search_bar.dart';
import 'package:mendaki/widgets/home/mountain_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Mountain> _downloadedMountains = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedMountains();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          _downloadedMountains =
              list.where((m) => m.isGpxReady && m.isMapReady).toList();
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
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Library',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: AppTheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
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
                // 1. Search Bar (tanpa filter provinsi)
                HomeSearchBar(
                  controller: _searchController,
                  hintText: 'Cari gunung di library...',
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => setState(() {}),
                  onClear: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),

                // 2. Keterangan teks kalau data yang ada di sini offline
                Row(
                  children: [
                    const Icon(
                      Icons.offline_pin_rounded,
                      color: AppTheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Data dan peta gunung di halaman ini tersimpan offline di perangkat Anda.',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant.withValues(
                            alpha: 0.9,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
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
                      onPressed: () => Navigator.of(context).pop(),
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
                    message:
                        'Tidak ada gunung di library offline yang cocok dengan "${_searchController.text.trim()}".',
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
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
