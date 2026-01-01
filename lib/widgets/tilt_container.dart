import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Adds subtle 3D tilt and scale on hover/press.
class TiltContainer extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final double pressScale;
  final Duration duration;

  const TiltContainer({super.key, required this.child, this.maxTilt = 8, this.pressScale = 0.98, this.duration = const Duration(milliseconds: 200)});

  @override
  State<TiltContainer> createState() => _TiltContainerState();
}

class _TiltContainerState extends State<TiltContainer> {
  double _tiltX = 0;
  double _tiltY = 0;
  double _scale = 1;

  void _reset() => setState(() { _tiltX = 0; _tiltY = 0; _scale = 1; });

  void _updateFromLocalPosition(Offset local, Size size) {
    final dx = (local.dx - size.width / 2) / (size.width / 2);
    final dy = (local.dy - size.height / 2) / (size.height / 2);
    setState(() {
      _tiltY = dx * widget.maxTilt * 0.0174533; // to radians
      _tiltX = -dy * widget.maxTilt * 0.0174533;
    });
  }

  @override
  Widget build(BuildContext context) {
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(_tiltX)
      ..rotateY(_tiltY)
      ..scale(_scale);

    final child = AnimatedContainer(
      duration: widget.duration,
      curve: Curves.easeOut,
      transform: transform,
      child: widget.child,
    );

    return Listener(
      onPointerMove: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) _updateFromLocalPosition(box.globalToLocal(e.position), box.size);
      },
      onPointerUp: (_) => _reset(),
      onPointerCancel: (_) => _reset(),
      child: MouseRegion(
        onExit: (_) => _reset(),
        onHover: (e) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) _updateFromLocalPosition(box.globalToLocal(e.position), box.size);
        },
        child: GestureDetector(
          onTapDown: (_) => setState(() => _scale = widget.pressScale),
          onTapUp: (_) => _reset(),
          onTapCancel: _reset,
          child: child,
        ),
      ),
    );
  }
}
