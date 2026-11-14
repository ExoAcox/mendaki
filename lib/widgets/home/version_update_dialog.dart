import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mendaki/core/services/version_state_service.dart';
import 'package:mendaki/models/app_version.dart';

class VersionUpdateDialog extends StatelessWidget {
  final AppVersion version;

  const VersionUpdateDialog({super.key, required this.version});

  /// Menampilkan dialog update secara modal
  static Future<void> show(BuildContext context, AppVersion version) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          PopScope(canPop: false, child: VersionUpdateDialog(version: version)),
    );
  }

  Future<void> _handleDismiss(BuildContext context) async {
    await VersionStateService.saveDismissState(version.id);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleUpdateTap(BuildContext context) async {
    final link = version.updateLink;
    if (link != null && link.trim().isNotEmpty) {
      final uri = Uri.tryParse(link.trim());
      if (uri != null) {
        try {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return;
        } catch (e) {
          debugPrint('Error launching update URL: $e');
        }
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan pembaruan belum tersedia saat ini.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F5238);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon & Version Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          version.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.4,
                          ),
                        ),
                        // const SizedBox(height: 4),
                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 8,
                        //     vertical: 2,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     color: const Color(0xFFE2E8F0),
                        //     borderRadius: BorderRadius.circular(6),
                        //   ),
                        //   child: Text(
                        //     'Versi ${version.id}',
                        //     style: const TextStyle(
                        //       fontSize: 11,
                        //       fontWeight: FontWeight.w700,
                        //       color: Color(0xFF334155),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              // Content / Changelog (Scrollable)
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: version.desc.trim().isNotEmpty
                      ? _HtmlContentView(htmlContent: version.desc)
                      : const Text(
                          'Pembaruan aplikasi telah tersedia. Silakan perbarui aplikasi untuk menikmati fitur dan stabilitas terbaru.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  if (!version.forceUpdate) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleDismiss(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Nanti Saja',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleUpdateTap(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        version.forceUpdate ? 'Update Sekarang' : 'Update',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
    );
  }
}

/// Widget parser ringan khusus konten HTML changelog/update
class _HtmlContentView extends StatelessWidget {
  final String htmlContent;

  const _HtmlContentView({required this.htmlContent});

  @override
  Widget build(BuildContext context) {
    final widgets = _parseHtmlToWidgets(htmlContent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  static List<Widget> _parseHtmlToWidgets(String rawHtml) {
    final widgets = <Widget>[];

    String clean = rawHtml.trim();
    if (clean.toLowerCase().startsWith('<p>')) {
      clean = clean.substring(3);
    }
    if (clean.toLowerCase().endsWith('</p>')) {
      clean = clean.substring(0, clean.length - 4);
    }
    clean = clean.trim();

    final ulRegex = RegExp(
      r'<ul>(.*?)</ul>',
      dotAll: true,
      caseSensitive: false,
    );
    int lastIndex = 0;

    for (final match in ulRegex.allMatches(clean)) {
      if (match.start > lastIndex) {
        final before = clean.substring(lastIndex, match.start).trim();
        _addTextBlocks(widgets, before);
      }

      final ulContent = match.group(1) ?? '';
      // Memecah elemen <li> baik yang memiliki penutup </li> maupun yang tidak
      final rawItems = ulContent.split(
        RegExp(r'<li[^>]*>', caseSensitive: false),
      );
      final liItems = rawItems.skip(1);

      for (final rawLi in liItems) {
        final liText = rawLi
            .replaceAll(RegExp(r'</li>', caseSensitive: false), '')
            .trim();
        if (liText.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 7.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F5238),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: _parseInlineSpans(
                          liText,
                          const TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: Color(0xFF334155),
                          ),
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

      lastIndex = match.end;
    }

    if (lastIndex < clean.length) {
      final after = clean.substring(lastIndex).trim();
      _addTextBlocks(widgets, after);
    }

    if (widgets.isEmpty && clean.isNotEmpty) {
      _addTextBlocks(widgets, clean);
    }

    return widgets;
  }

  static void _addTextBlocks(List<Widget> widgets, String rawText) {
    // Pecah berdasarkan <br> untuk mempertahankan jarak baris vertikal (line break)
    final segments = rawText.split(RegExp(r'<br\s*/?>', caseSensitive: false));

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i].trim();

      if (segment.isNotEmpty) {
        final isHeader = RegExp(
          r'^<(strong|b|span)>.*?</(strong|b|span)>$',
          caseSensitive: false,
        ).hasMatch(segment);
        final cleanText = segment.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (cleanText.isNotEmpty) {
          if (isHeader) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
                child: Text(
                  cleanText,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F5238),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            );
          } else {
            widgets.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text.rich(
                  TextSpan(
                    children: _parseInlineSpans(
                      segment,
                      const TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        }
      }

      // Jika ada tag <br>, tambahkan jarak vertikal antar baris/seksi
      if (i < segments.length - 1) {
        widgets.add(const SizedBox(height: 12.0));
      }
    }
  }

  static List<InlineSpan> _parseInlineSpans(String text, TextStyle baseStyle) {
    final unescaped = text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    final spans = <InlineSpan>[];
    final tagRegex = RegExp(
      r'<(strong|b|code|span)>(.*?)</\1>',
      dotAll: true,
      caseSensitive: false,
    );
    int lastIndex = 0;

    for (final match in tagRegex.allMatches(unescaped)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: unescaped.substring(lastIndex, match.start),
            style: baseStyle,
          ),
        );
      }

      final tag = match.group(1)?.toLowerCase();
      final content = match.group(2) ?? '';

      if (tag == 'strong' || tag == 'b') {
        spans.add(
          TextSpan(
            text: content,
            style: baseStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        );
      } else if (tag == 'code') {
        spans.add(
          TextSpan(
            text: ' $content ',
            style: baseStyle.copyWith(
              fontFamily: 'monospace',
              fontSize: (baseStyle.fontSize ?? 12.5) * 0.92,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F5238),
              backgroundColor: const Color(0xFFF1F5F9),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: content, style: baseStyle));
      }

      lastIndex = match.end;
    }

    if (lastIndex < unescaped.length) {
      spans.add(
        TextSpan(text: unescaped.substring(lastIndex), style: baseStyle),
      );
    }

    return spans;
  }
}
