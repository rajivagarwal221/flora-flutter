import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/insights.dart';
import '../theme.dart';

class InsightTile extends StatelessWidget {
  final Insight insight;
  const InsightTile({super.key, required this.insight});

  (Color, Color, IconData) get _style => switch (insight.tone) {
    InsightTone.positive => (const Color(0xFFE8F6EF), const Color(0xFF1C7A4A), Icons.trending_up),
    InsightTone.negative => (const Color(0xFFFDECEE), const Color(0xFFB42334), Icons.trending_down),
    InsightTone.warning => (const Color(0xFFFFF5E5), const Color(0xFFB87414), Icons.warning_amber),
    InsightTone.action => (AppColors.primarySoft, AppColors.primary, Icons.auto_awesome),
    InsightTone.neutral => (AppColors.secondarySoft, AppColors.foreground, Icons.insights),
  };

  @override Widget build(BuildContext context) {
    final (bg, fg, icon) = _style;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x0A000000), offset: Offset(0, 4))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: fg, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(insight.title, style: GoogleFonts.fraunces(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.foreground)),
          const SizedBox(height: 4),
          Text(insight.body, style: const TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.4)),
        ])),
      ]),
    );
  }
}
