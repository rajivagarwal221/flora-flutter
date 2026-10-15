import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

/// Softly drifting petals, used as decorative hero backgrounds.
class PetalField extends StatefulWidget {
  final int count; final double height;
  const PetalField({super.key, this.count = 10, this.height = 180});
  @override State<PetalField> createState() => _PetalFieldState();
}
class _PetalFieldState extends State<PetalField> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  late final List<_Petal> _petals = List.generate(widget.count, (i) => _Petal.random(i));
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return IgnorePointer(child: SizedBox(
      height: widget.height,
      child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: _PetalPainter(_petals, _c.value), size: Size.infinite)),
    ));
  }
}

class _Petal {
  final double x, size, speed, drift, phase; final Color color;
  _Petal(this.x, this.size, this.speed, this.drift, this.phase, this.color);
  factory _Petal.random(int i) {
    final r = Random(i * 11 + 3);
    final tints = [AppColors.primary, AppColors.primaryBorder, const Color(0xFFFBD1DD), const Color(0xFFEE91AC)];
    return _Petal(r.nextDouble(), 8 + r.nextDouble() * 14, 0.3 + r.nextDouble() * 0.6, r.nextDouble() * 20 - 10, r.nextDouble(), tints[r.nextInt(tints.length)]);
  }
}
class _PetalPainter extends CustomPainter {
  final List<_Petal> petals; final double t;
  _PetalPainter(this.petals, this.t);
  @override void paint(Canvas canvas, Size size) {
    for (final p in petals) {
      final progress = (t + p.phase) % 1;
      final y = progress * (size.height + 40) - 20;
      final x = p.x * size.width + sin((progress + p.phase) * 2 * pi) * p.drift;
      final paint = Paint()..color = p.color.withValues(alpha: 0.55);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 2 * pi);
      final r = p.size;
      final path = Path()
        ..moveTo(0, -r)
        ..quadraticBezierTo(r, -r * 0.3, 0, r)
        ..quadraticBezierTo(-r, -r * 0.3, 0, -r);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }
  @override bool shouldRepaint(_PetalPainter o) => o.t != t;
}
