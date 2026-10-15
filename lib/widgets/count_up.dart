import 'package:flutter/material.dart';

/// Animates a number from 0 → [value] over 900ms when the widget is first built
/// or [value] changes. Formatter controls display.
class CountUp extends StatefulWidget {
  final double value;
  final String Function(double) format;
  final TextStyle? style;
  final Duration duration;
  const CountUp({super.key, required this.value, required this.format, this.style, this.duration = const Duration(milliseconds: 900)});
  @override State<CountUp> createState() => _CountUpState();
}
class _CountUpState extends State<CountUp> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _anim;
  double _from = 0;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(begin: 0, end: widget.value).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }
  @override void didUpdateWidget(covariant CountUp old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = _anim.value;
      _anim = Tween<double>(begin: _from, end: widget.value).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
      _c..reset()..forward();
    }
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _anim, builder: (_, __) => Text(widget.format(_anim.value), style: widget.style, maxLines: 1, overflow: TextOverflow.ellipsis));
  }
}
