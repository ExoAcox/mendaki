import 'package:flutter/material.dart';
import 'package:mendaki/core/theme/app_theme.dart';
import 'package:mendaki/widgets/home/feedback_modal.dart';

class FeedbackPrompt extends StatelessWidget {
  final String title;
  final String buttonLabel;
  final String initialType;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const FeedbackPrompt({
    super.key,
    this.title = 'Gunung belum tersedia?',
    this.buttonLabel = 'Request di sini',
    this.initialType = 'request',
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.only(top: 8.0),
      padding: padding ?? const EdgeInsets.only(top: 20.0, bottom: 8.0),
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
            title,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () =>
                FeedbackModal.show(context, initialType: initialType),
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
            label: Text(
              buttonLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
