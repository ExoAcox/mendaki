import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int downloadedCount;
  final VoidCallback? onLibraryTap;
  final VoidCallback? onDownloadedTap;
  final bool isShowingDownloaded;

  const HomeAppBar({
    super.key,
    this.downloadedCount = 0,
    this.onLibraryTap,
    this.onDownloadedTap,
    this.isShowingDownloaded = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = onLibraryTap ?? onDownloadedTap;

    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.landscape_rounded,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mendaki',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: AppTheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Tracking & Peta Offline',
                style: TextStyle(
                  color: AppTheme.outline,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Tooltip(
            message: 'Library Offline',
            child: InkWell(
              onTap: effectiveOnTap,
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isShowingDownloaded
                      ? const Color(0xFF0F5238)
                      : AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isShowingDownloaded
                        ? const Color(0xFF89EDBA)
                        : downloadedCount > 0
                            ? AppTheme.primary.withValues(alpha: 0.25)
                            : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isShowingDownloaded || downloadedCount > 0
                          ? Icons.offline_pin_rounded
                          : Icons.download_done_rounded,
                      color: isShowingDownloaded
                          ? const Color(0xFF89EDBA)
                          : AppTheme.primary,
                      size: 20,
                    ),
                    if (downloadedCount > 0) ...[
                      const SizedBox(width: 5),
                      Text(
                        '$downloadedCount',
                        style: TextStyle(
                          color: isShowingDownloaded
                              ? const Color(0xFF89EDBA)
                              : AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
