import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';

class HomeErrorView extends StatelessWidget {
  final bool isOffline;
  final int downloadedCount;
  final VoidCallback onOpenLibrary;
  final VoidCallback onRetry;
  final String? customMessage;

  const HomeErrorView({
    super.key,
    required this.isOffline,
    required this.downloadedCount,
    required this.onOpenLibrary,
    required this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final title = isOffline ? 'Tidak Ada Sinyal' : 'Gagal Memuat Data';

    final message =
        customMessage ??
        (isOffline
            ? 'Perangkat Anda sedang tidak terhubung ke sinyal atau internet. Anda tetap dapat mengakses peta dan rute yang telah diunduh di Library.'
            : 'Terjadi kendala saat mengambil data dari server. Silakan coba lagi atau buka data gunung yang telah tersimpan di Library offline.');

    final icon = isOffline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ambient icon badge
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 44, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: AppTheme.outline,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Button to Library (Primary)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('home_error_library_button'),
                onPressed: onOpenLibrary,
                icon: const Icon(Icons.folder_special_rounded, size: 20),
                label: Text(
                  downloadedCount > 0
                      ? 'Buka Library Offline ($downloadedCount)'
                      : 'Buka Library Offline',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Button to Retry (Secondary)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('home_error_retry_button'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text(
                  'Coba Muat Ulang',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
