import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wayfinder/theme.dart';

/// Animated hero header cycling through images with a gentle Ken Burns effect.
class LiveImageHeader extends StatefulWidget {
  final List<String> images;
  final double height;
  final Duration switchInterval;

  const LiveImageHeader({super.key, required this.images, this.height = 220, this.switchInterval = const Duration(seconds: 6)});

  @override
  State<LiveImageHeader> createState() => _LiveImageHeaderState();
}

class _LiveImageHeaderState extends State<LiveImageHeader> with SingleTickerProviderStateMixin {
  int _index = 0;
  late Timer _timer;
  late AnimationController _zoom;

  @override
  void initState() {
    super.initState();
    _zoom = AnimationController(vsync: this, duration: widget.switchInterval)..forward();
    _timer = Timer.periodic(widget.switchInterval, (_) {
      setState(() => _index = (_index + 1) % widget.images.length);
      _zoom
        ..reset()
        ..forward();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.images[_index % widget.images.length];
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(children: [
          AnimatedBuilder(
            animation: _zoom,
            builder: (context, _) {
              final scale = 1.08 - (_zoom.value * 0.08); // zoom out subtly
              return Transform.scale(
                scale: scale,
                child: Image.asset(image, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              );
            },
          ),
          // Dark gradient for legibility
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Color(0xAA000000)],
                ),
              ),
            ),
          ),
          // Neon top border accent
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 2, decoration: const BoxDecoration(gradient: AppGradients.neon)),
          ),
        ]),
      ),
    );
  }
}
