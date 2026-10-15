import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/async_view.dart';
import '../widgets/count_up.dart';
import '../widgets/petal_field.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AsyncView<(List<DailyRow>, List<MonthlyRow>, List<TopProduct>)>(
        load: () async => (await repo.dailySales(), await repo.monthlySales(), await repo.topProducts()),
        builder: (ctx, d, refresh) {
          final daily = d.$1; final monthly = d.$2; final top = d.$3;
          final revenue30 = daily.fold<double>(0, (a, r) => a + r.revenue);
          final profit30 = daily.fold<double>(0, (a, r) => a + r.profit);
          final units30 = daily.fold<double>(0, (a, r) => a + r.quantitySold);
          return ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              const PageHeader(title: 'Analytics', subtitle: 'Revenue, margins, top sellers.'),
              _Hero(revenue: revenue30, profit: profit30, units: units30),
              const SizedBox(height: 14),
              _ChartCard(title: 'Monthly revenue · 12 mo', delay: 100, child: monthly.isEmpty
                  ? const EmptyState(icon: Icons.bar_chart, message: 'No data yet')
                  : _MonthlyBars(rows: monthly, metric: (r) => r.revenue)),
              _ChartCard(title: 'Daily units sold · 30 d', delay: 150, child: daily.isEmpty
                  ? const EmptyState(icon: Icons.show_chart, message: 'No data yet')
                  : _DailyLine(rows: daily, metric: (r) => r.quantitySold)),
              _ChartCard(title: 'Daily net profit · 30 d', delay: 200, child: daily.isEmpty
                  ? const EmptyState(icon: Icons.show_chart, message: 'No data yet')
                  : _DailyLine(rows: daily, metric: (r) => r.profit)),
              _ChartCard(title: 'Monthly net profit · 12 mo', delay: 250, child: monthly.isEmpty
                  ? const EmptyState(icon: Icons.bar_chart, message: 'No data yet')
                  : _MonthlyBars(rows: monthly, metric: (r) => r.profit)),
              _TopProductsCard(items: top),
            ],
          );
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final double revenue, profit, units;
  const _Hero({required this.revenue, required this.profit, required this.units});
  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      height: 170,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(blurRadius: 24, color: AppColors.roseShadow, offset: Offset(0, 10))],
      ),
      child: Stack(children: [
        Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(22), child: const PetalField(count: 14, height: 170))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('LAST 30 DAYS', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            CountUp(value: revenue, format: formatCurrency, style: GoogleFonts.fraunces(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
            const Text('Revenue', style: TextStyle(color: Colors.white70)),
            const Spacer(),
            Row(children: [
              Expanded(child: _mini('Net profit', formatCurrency(profit))),
              const SizedBox(width: 8),
              Expanded(child: _mini('Units sold', formatNumber(units.round()))),
            ]),
          ]),
        ),
      ]),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }
  Widget _mini(String label, String value) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
      const SizedBox(height: 2),
      Text(value, style: GoogleFonts.fraunces(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _ChartCard extends StatelessWidget {
  final String title; final Widget child; final int delay;
  const _ChartCard({required this.title, required this.child, this.delay = 0});
  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(blurRadius: 14, color: Color(0x0C000000), offset: Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.fraunces(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 12),
        SizedBox(height: 180, child: child),
      ]),
    ).animate(delay: delay.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }
}

class _MonthlyBars extends StatelessWidget {
  final List<MonthlyRow> rows; final double Function(MonthlyRow) metric;
  const _MonthlyBars({required this.rows, required this.metric});
  @override Widget build(BuildContext context) {
    final values = rows.map(metric).toList();
    final maxV = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    return BarChart(BarChartData(
      barGroups: [for (int i = 0; i < rows.length; i++) BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: metric(rows[i]),
          gradient: i == rows.length - 1 ? AppColors.primaryGradient : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.secondary, Color(0xFF4A4350)]),
          width: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ])],
      maxY: maxV * 1.1,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 26, getTitlesWidget: (v, m) {
          final i = v.toInt(); if (i < 0 || i >= rows.length) return const SizedBox();
          final s = rows[i].month; final short = s.length >= 2 ? s.substring(s.length - 2) : s;
          return Padding(padding: const EdgeInsets.only(top: 4), child: Text(short, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600)));
        })),
      ),
      borderData: FlBorderData(show: false),
    ));
  }
}

class _DailyLine extends StatelessWidget {
  final List<DailyRow> rows; final double Function(DailyRow) metric;
  const _DailyLine({required this.rows, required this.metric});
  @override Widget build(BuildContext context) {
    return LineChart(LineChartData(
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: [for (int i = 0; i < rows.length; i++) FlSpot(i.toDouble(), metric(rows[i]))],
          isCurved: true, color: AppColors.primary, barWidth: 3.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [AppColors.primary.withValues(alpha: 0.35), AppColors.primary.withValues(alpha: 0)],
          )),
        ),
      ],
    ));
  }
}

class _TopProductsCard extends StatelessWidget {
  final List<TopProduct> items;
  const _TopProductsCard({required this.items});
  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(blurRadius: 14, color: Color(0x0C000000), offset: Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.star, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Top products', style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),
        if (items.isEmpty) const EmptyState(icon: Icons.local_florist, message: 'No sales yet')
        else for (int i = 0; i < items.length; i++) Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: i == 0 ? AppColors.primaryGradient : LinearGradient(colors: [AppColors.secondary.withValues(alpha: 0.85), AppColors.secondary]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: i == 0 ? const [BoxShadow(blurRadius: 10, color: AppColors.roseShadow, offset: Offset(0, 3))] : null,
              ),
              child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(displayName(items[i]), style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('${items[i].quantitySold.toStringAsFixed(0)} sold', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ])),
            Text(formatCurrency(items[i].revenue), style: GoogleFonts.fraunces(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary)),
          ]).animate(delay: (i * 40).ms).fadeIn(duration: 220.ms).slideX(begin: 0.05, end: 0),
        ),
      ]),
    ).animate(delay: 300.ms).fadeIn(duration: 300.ms);
  }
}
