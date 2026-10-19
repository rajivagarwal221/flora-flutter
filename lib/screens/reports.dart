import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/async_view.dart';
import '../widgets/charts.dart';
import '../widgets/count_up.dart';
import '../widgets/petal_field.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AsyncView<(List<DailyRow>, List<MonthlyRow>, List<TopProduct>)>(
        load: () async => (
          await repo.dailySales(),
          await repo.monthlySales(),
          await repo.topProducts()
        ),
        builder: (ctx, d, refresh) {
          final daily = d.$1;
          final monthly = d.$2;
          final top = d.$3;
          final revenue30 = daily.fold<double>(0, (a, r) => a + r.revenue);
          final profit30 = daily.fold<double>(0, (a, r) => a + r.profit);
          final units30 = daily.fold<double>(0, (a, r) => a + r.quantitySold);

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const PageHeader(
                title: 'Studio Analytics & Reports',
                subtitle: 'Performance metrics, margins, and top flower volume.',
              ),
              _Hero(revenue: revenue30, profit: profit30, units: units30),
              const SizedBox(height: 16),

              // Monthly Revenue (12 Months)
              StudioChartPanel(
                title: 'Monthly Revenue (12 Months)',
                subtitle: 'Continuous monthly sales turnover',
                accentColor: AppColors.primary,
                delay: 100,
                child: StudioBarChart(
                  rows: monthly,
                  metric: (r) => r.revenue,
                  metricName: 'Revenue',
                ),
              ),

              // Top Products (By Quantity Sold)
              StudioChartPanel(
                title: 'Top Products (By Quantity Sold)',
                subtitle: 'Volume leaderboards & revenue contributions',
                accentColor: AppColors.secondary,
                delay: 150,
                child: TopProductsHorizontalChart(items: top),
              ),

              // Daily Units Sold (Last 30 Days)
              StudioChartPanel(
                title: 'Daily Units Sold (Last 30 Days)',
                subtitle: 'Stems and arrangements sold daily',
                accentColor: AppColors.primary,
                delay: 200,
                child: StudioLineChart(
                  rows: daily,
                  metric: (r) => r.quantitySold,
                  metricName: 'Units',
                ),
              ),

              // Section: Net Studio Profit
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Studio Profit',
                      style: GoogleFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.foreground,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Revenue calculated minus raw inventory purchase cost (including custom recipes).',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Daily Net Profit (30 Days)
              StudioChartPanel(
                title: 'Daily Net Profit (30 Days)',
                subtitle: 'Profit trajectory calculated per recipe',
                accentColor: AppColors.primary,
                delay: 250,
                child: StudioAreaChart(
                  rows: daily,
                  metric: (r) => r.profit,
                  metricName: 'Net Profit',
                  isCurrency: true,
                ),
              ),

              // Monthly Net Profit (12 Months)
              StudioChartPanel(
                title: 'Monthly Net Profit (12 Months)',
                subtitle: 'Net studio margin across preceding 12 billing periods',
                accentColor: AppColors.secondary,
                delay: 300,
                child: StudioBarChart(
                  rows: monthly,
                  metric: (r) => r.profit,
                  metricName: 'Profit',
                ),
              ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      height: 170,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            color: AppColors.roseShadow,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: const PetalField(count: 14, height: 170),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LAST 30 DAYS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                CountUp(
                  value: revenue,
                  format: formatCurrency,
                  style: GoogleFonts.fraunces(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Total Revenue',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(child: _mini('Net profit', formatCurrency(profit))),
                    const SizedBox(width: 8),
                    Expanded(child: _mini('Units sold', formatNumber(units.round()))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _mini(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white24,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.fraunces(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}
