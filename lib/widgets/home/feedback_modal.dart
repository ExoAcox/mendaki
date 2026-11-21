import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mendaki/core/services/supabase_service.dart';
import 'package:mendaki/core/theme/app_theme.dart';

class FeedbackModal extends StatefulWidget {
  final String initialType;

  const FeedbackModal({super.key, this.initialType = 'request'});

  /// Menampilkan modal feedback sebagai modal bottom sheet
  static Future<void> show(
    BuildContext context, {
    String initialType = 'request',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => FeedbackModal(initialType: initialType),
    );
  }

  @override
  State<FeedbackModal> createState() => _FeedbackModalState();
}

class _FeedbackModalState extends State<FeedbackModal> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedType;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();
  bool _isSubmitting = false;

  int _num1 = 0;
  int _num2 = 0;

  void _generateCaptcha() {
    setState(() {
      _num1 = Random().nextInt(9) + 1;
      _num2 = Random().nextInt(9) + 1;
      _captchaController.clear();
    });
  }

  final List<Map<String, String>> _types = [
    {
      'value': 'request',
      'label': 'Request Gunung / Rute',
      'placeholder':
          'Tuliskan nama gunung, jalur pendakian, atau koordinat yang ingin ditambahkan...',
    },
    {
      'value': 'feature',
      'label': 'Request Fitur Baru',
      'placeholder':
          'Jelaskan ide atau fitur baru yang ingin ada di aplikasi...',
    },
    {
      'value': 'bug',
      'label': 'Lapor Bug',
      'placeholder': 'Jelaskan kendala, bug, atau error yang Anda alami...',
    },
  ];

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
    _selectedType = widget.initialType;
    if (!_types.any((t) => t['value'] == _selectedType)) {
      _selectedType = 'request';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _commentController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  String get _currentPlaceholder {
    final match = _types.firstWhere(
      (t) => t['value'] == _selectedType,
      orElse: () => _types.first,
    );
    return match['placeholder'] ?? 'Tuliskan masukan atau permintaan Anda...';
  }

  InputDecoration _buildGlassInputDecoration({
    String? hintText,
    Widget? prefixIcon,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 12,
    ),
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 14,
        color: AppTheme.outline.withValues(alpha: 0.6),
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.55),
      contentPadding: contentPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppTheme.primary.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.error, width: 1),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await SupabaseService.submitFeedback(
        type: _selectedType,
        comment: _commentController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Terima kasih! Masukan Anda telah berhasil dikirim.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text('Gagal mengirim masukan: $e')),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.92),
                  Colors.white.withValues(alpha: 0.72),
                  Colors.white.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
                width: 1.2,
              ),
            ),
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 42,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: AppTheme.onSurfaceVariant.withValues(
                              alpha: 0.25,
                            ),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.feedback_outlined,
                                color: AppTheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Kirim Masukan & Request',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          // Container(
                          //   decoration: BoxDecoration(
                          //     color: Colors.black.withValues(alpha: 0.05),
                          //     shape: BoxShape.circle,
                          //   ),
                          //   child: IconButton(
                          //     icon: const Icon(Icons.close_rounded, size: 20),
                          //     color: AppTheme.onSurfaceVariant,
                          //     onPressed: () => Navigator.of(context).pop(),
                          //     visualDensity: VisualDensity.compact,
                          //   ),
                          // ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bantu kami mengembangkan data jalur dan aplikasi Mendaki.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.onSurfaceVariant.withValues(
                            alpha: 0.85,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Dropdown Tipe
                      const Text(
                        'Tipe Masukan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        dropdownColor: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(14),
                        decoration: _buildGlassInputDecoration(),
                        items: _types.map((type) {
                          return DropdownMenuItem<String>(
                            value: type['value'],
                            child: Text(
                              type['label']!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: _isSubmitting
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedType = val;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 16),

                      // Email Input (Optional)
                      const Text(
                        'Email (Opsional)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 14),
                        decoration: _buildGlassInputDecoration(
                          hintText: 'nama@email.com',
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Textarea / Comment
                      const Text(
                        'Pesan / Keterangan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _commentController,
                        enabled: !_isSubmitting,
                        minLines: 3,
                        maxLines: 5,
                        style: const TextStyle(fontSize: 14),
                        decoration: _buildGlassInputDecoration(
                          hintText: _currentPlaceholder,
                          contentPadding: const EdgeInsets.all(14),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Pesan tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Simple Math Captcha
                      const Text(
                        'Verifikasi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.9),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              '$_num1 + $_num2 =',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                letterSpacing: 1.2,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: TextFormField(
                              controller: _captchaController,
                              enabled: !_isSubmitting,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                              decoration: _buildGlassInputDecoration(
                                hintText: 'Hasil',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Isi jawaban';
                                }
                                final parsed = int.tryParse(value.trim());
                                if (parsed == null ||
                                    parsed != (_num1 + _num2)) {
                                  return 'Jawaban salah';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.8),
                                width: 1,
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              tooltip: 'Ganti Pertanyaan',
                              color: AppTheme.onSurfaceVariant,
                              onPressed: _isSubmitting
                                  ? null
                                  : _generateCaptcha,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.onPrimary,
                                  ),
                                )
                              : const Text(
                                  'Kirim',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
