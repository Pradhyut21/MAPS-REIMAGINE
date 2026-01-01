import 'package:flutter/material.dart';
import 'package:wayfinder/theme.dart';

/// Global background: single 3D night city image with a soft overlay.
class AppGradientBackground extends StatefulWidget {
  final Widget child;
  const AppGradientBackground({super.key, required this.child});

  @override
  State<AppGradientBackground> createState() => _AppGradientBackgroundState();
}

class _AppGradientBackgroundState extends State<AppGradientBackground> {
  // Single fixed background (side view with plenty of dark night skyscrapers)
  static const String _bgAsset = 'assets/images/side_view_night_city_skyline_skyscrapers_moody_black_1767260400421.jpg';

  @override
  void initState() {
    super.initState();
    // Precache the single image for instant display
    WidgetsBinding.instance.addPostFrameCallback((_) => precacheImage(const AssetImage(_bgAsset), context));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Background image
      Positioned.fill(
        child: Image.asset(
          _bgAsset,
          fit: BoxFit.cover,
          // Side-view framing works better slightly to the right to showcase towers
          alignment: Alignment.centerRight,
          errorBuilder: (_, __, ___) => const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A0A0A), Color(0xFF121212)],
              ),
            ),
          ),
        ),
      ),
      // Subtle dark gradient overlay for readability (keep image visible)
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.14),
                Colors.black.withValues(alpha: 0.32),
              ],
            ),
          ),
        ),
      ),
      // Soft neon top line to match brand
      Positioned(top: 0, left: 0, right: 0, child: Container(height: 2, decoration: const BoxDecoration(gradient: AppGradients.neon))),
      SafeArea(child: widget.child),
    ]);
  }
}
