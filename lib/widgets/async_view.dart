import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class AsyncView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext, T, VoidCallback refresh) builder;
  const AsyncView({super.key, required this.load, required this.builder});
  @override State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _f;
  @override void initState() { super.initState(); _f = widget.load(); }
  void _refresh() { setState(() { _f = widget.load(); }); }
  @override Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async { _refresh(); try { await _f; } catch (_) {} },
      child: FutureBuilder<T>(
        future: _f,
        builder: (c, s) {
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.primary)));
          }
          if (s.hasError) {
            return ListView(children: [
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.cloud_off, size: 56, color: AppColors.muted),
                  const SizedBox(height: 10),
                  Text('${s.error}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                ]),
              ),
            ]);
          }
          return widget.builder(c, s.data as T, _refresh).animate().fadeIn(duration: 220.ms);
        },
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title; final String? subtitle; final List<Widget>? actions; final Widget? background;
  const PageHeader({super.key, required this.title, this.subtitle, this.actions, this.background});
  @override Widget build(BuildContext context) {
    return Stack(children: [
      if (background != null) Positioned.fill(child: background!),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: GoogleFonts.fraunces(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.foreground, letterSpacing: -0.5))),
            if (actions != null) ...actions!,
          ]),
          if (subtitle != null) Padding(
            padding: const EdgeInsets.only(top: 4, right: 20),
            child: Text(subtitle!, style: const TextStyle(color: AppColors.muted, fontSize: 13.5, height: 1.3)),
          ),
        ]),
      ),
    ]);
  }
}

/// A soft stat tile with gradient halo and animated value.
class StatCard extends StatelessWidget {
  final IconData icon; final String label; final Widget value; final bool primary;
  const StatCard({super.key, required this.icon, required this.label, required this.value, this.primary = false});
  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(blurRadius: 18, color: Color(0x11000000), offset: Offset(0, 6))],
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: primary ? AppColors.primaryGradient : null,
            color: primary ? null : AppColors.secondary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: primary ? const [BoxShadow(blurRadius: 14, offset: Offset(0, 5), color: AppColors.roseShadow)] : null,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(label.toUpperCase(), style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
          const SizedBox(height: 4),
          value,
        ])),
      ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon; final String message; final String? hint;
  const EmptyState({super.key, required this.icon, required this.message, this.hint});
  @override Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: Icon(icon, size: 42, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w700)),
          if (hint != null) Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(hint!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ),
        ]),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label; final Color bg; final Color fg; final IconData? icon;
  const StatusChip({super.key, required this.label, required this.bg, required this.fg, this.icon});
  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
        Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 11)),
      ]),
    );
  }
}

/// Gradient primary button for the headline CTAs.
class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed; final Widget child; final bool loading;
  const GradientButton({super.key, this.onPressed, required this.child, this.loading = false});
  @override Widget build(BuildContext context) {
    return Opacity(opacity: onPressed == null ? 0.5 : 1, child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: loading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(blurRadius: 16, offset: Offset(0, 6), color: AppColors.roseShadow)],
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          child: IconTheme(data: const IconThemeData(color: Colors.white, size: 18),
            child: loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : child),
        ),
      ),
    ));
  }
}
