import 'dart:ui';
import 'package:flutter/material.dart';

class NavigationFinishButton extends StatelessWidget {
  final VoidCallback onTap;

  const NavigationFinishButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFFA33D23).withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('finish_button'),
              onTap: onTap,
              splashColor: Colors.white.withValues(alpha: 0.15),
              highlightColor: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFA33D23).withValues(alpha: 0.80),
                      const Color(0xFF8F321B).withValues(alpha: 0.62),
                      const Color(0xFFA33D23).withValues(alpha: 0.75),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Finish',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
