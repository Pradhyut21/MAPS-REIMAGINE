import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wayfinder/theme.dart';

/// A reusable glassmorphism container with blur, subtle border and tint.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? tint;

  const GlassContainer({super.key, required this.child, this.padding, this.borderRadius = AppRadius.md, this.tint});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final overlay = tint ?? Colors.white.withValues(alpha: 0.04);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [overlay, overlay.withValues(alpha: 0.02)],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Container(
            padding: padding ?? AppSpacing.paddingMd,
            foregroundDecoration: const BoxDecoration(gradient: AppGradients.glassStroke),
            child: DefaultTextStyle.merge(style: TextStyle(color: colorScheme.onSurface), child: child),
          ),
        ),
      ),
    );
  }
}
