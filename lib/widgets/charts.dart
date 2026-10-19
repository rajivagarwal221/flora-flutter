import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models.dart';
import '../theme.dart';
import '../utils.dart';

/// Studio chart card panel with signature colored top border accent.
class StudioChartPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final Color accentColor;
  final int delay;

  const StudioChartPanel({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.accentColor = AppColors.primary,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            color: Color(0x0E000000),
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Signature top accent border
          Container(height: 4, color: accentColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.fraunces(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.foreground,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 18, 16),
            child: SizedBox(
              height: 220,
              child: child,
            ),
          ),
        ],
      ),
    ).animate(delay: delay.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
  }
}

/// Area Chart for continuous trajectory (Revenue, Net Profit)
/// Matches Recharts AreaChart with linearGradient #D93B68 from Sidhi-Florals
class StudioAreaChart extends StatelessWidget {
  final List<DailyRow> rows;
  final double Function(DailyRow) metric;
  final String metricName;
  final bool isCurrency;

  const StudioAreaChart({
    super.key,
    required this.rows,
    required this.metric,
    required this.metricName,
    this.isCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'No sales yet — your first bill will show up here.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      );
    }

    final values = rows.map(metric).toList();
    final rawMax = values.isEmpty ? 0.0 : values.reduce(math.max);
    final maxY = rawMax <= 0 ? 100.0 : rawMax * 1.2;
    final yInterval = (maxY / 4) > 0 ? (maxY / 4) : 25.0;

    final step = (rows.length / 5).ceil().clamp(1, 10);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (rows.length - 1).toDouble().clamp(0, double.infinity),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppColors.border,
            strokeWidth: 1,
            dashArray: [3, 3],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: yInterval,
              getTitlesWidget: (val, meta) {
                if (val == 0) return const SizedBox();
                final text = isCurrency ? formatCompactCurrency(val) : formatNumber(val.round());
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: step.toDouble(),
              getTitlesWidget: (val, meta) {
                final idx = val.round();
                if (idx < 0 || idx >= rows.length) return const SizedBox();
                final dateStr = rows[idx].date;
                final formatted = dateStr.length > 5 ? dateStr.substring(5) : dateStr;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      formatted,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, indicators) {
            return indicators.map((index) {
              return TouchedSpotIndicatorData(
                const FlLine(
                  color: AppColors.primaryBorder,
                  strokeWidth: 1.5,
                  dashArray: [3, 3],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, idx) => FlDotCirclePainter(
                    radius: 6,
                    color: AppColors.primary,
                    strokeColor: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipBorder: const BorderSide(color: AppColors.primaryBorder, width: 1),
            tooltipRoundedRadius: 14,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.round();
                final dateStr = (idx >= 0 && idx < rows.length) ? formatDate(rows[idx].date) : '';
                final val = isCurrency ? formatCurrency(spot.y) : formatNumber(spot.y.round());
                return LineTooltipItem(
                  dateStr.isNotEmpty ? '$dateStr\n' : '',
                  GoogleFonts.inter(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: '$metricName: ',
                      style: GoogleFonts.inter(
                        color: AppColors.foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: val,
                      style: GoogleFonts.fraunces(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < rows.length; i++)
                FlSpot(i.toDouble(), metric(rows[i])),
            ],
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.primary,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.4),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Line Chart with explicit dots on points (Daily Units Sold)
/// Matches Recharts LineChart from Sidhi-Florals
class StudioLineChart extends StatelessWidget {
  final List<DailyRow> rows;
  final double Function(DailyRow) metric;
  final String metricName;

  const StudioLineChart({
    super.key,
    required this.rows,
    required this.metric,
    required this.metricName,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'No data available yet.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      );
    }

    final values = rows.map(metric).toList();
    final rawMax = values.isEmpty ? 0.0 : values.reduce(math.max);
    final maxY = rawMax <= 0 ? 10.0 : rawMax * 1.25;
    final yInterval = (maxY / 4) > 0 ? (maxY / 4) : 2.0;
    final step = (rows.length / 5).ceil().clamp(1, 10);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (rows.length - 1).toDouble().clamp(0, double.infinity),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppColors.border,
            strokeWidth: 1,
            dashArray: [3, 3],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: yInterval,
              getTitlesWidget: (val, meta) {
                if (val == 0) return const SizedBox();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    val.round().toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: step.toDouble(),
              getTitlesWidget: (val, meta) {
                final idx = val.round();
                if (idx < 0 || idx >= rows.length) return const SizedBox();
                final dateStr = rows[idx].date;
                final formatted = dateStr.length > 5 ? dateStr.substring(5) : dateStr;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      formatted,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, indicators) {
            return indicators.map((index) {
              return TouchedSpotIndicatorData(
                const FlLine(
                  color: AppColors.primaryBorder,
                  strokeWidth: 1.5,
                  dashArray: [3, 3],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, idx) => FlDotCirclePainter(
                    radius: 7,
                    color: AppColors.primary,
                    strokeColor: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipBorder: const BorderSide(color: AppColors.primaryBorder, width: 1),
            tooltipRoundedRadius: 14,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.round();
                final dateStr = (idx >= 0 && idx < rows.length) ? formatDate(rows[idx].date) : '';
                return LineTooltipItem(
                  dateStr.isNotEmpty ? '$dateStr\n' : '',
                  GoogleFonts.inter(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: '${spot.y.round()} ',
                      style: GoogleFonts.fraunces(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: metricName,
                      style: GoogleFonts.inter(
                        color: AppColors.foreground,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < rows.length; i++)
                FlSpot(i.toDouble(), metric(rows[i])),
            ],
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.primary,
            barWidth: 3.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, idx) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.primary,
                strokeColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Monthly Bar Chart with highlighted latest month
/// Matches Recharts BarChart from Sidhi-Florals
class StudioBarChart extends StatelessWidget {
  final List<MonthlyRow> rows;
  final double Function(MonthlyRow) metric;
  final String metricName;

  const StudioBarChart({
    super.key,
    required this.rows,
    required this.metric,
    required this.metricName,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'No data available yet.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      );
    }

    final values = rows.map(metric).toList();
    final rawMax = values.isEmpty ? 0.0 : values.reduce(math.max);
    final maxY = rawMax <= 0 ? 1000.0 : rawMax * 1.2;
    final yInterval = (maxY / 4) > 0 ? (maxY / 4) : 250.0;

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppColors.border,
            strokeWidth: 1,
            dashArray: [3, 3],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: yInterval,
              getTitlesWidget: (val, meta) {
                if (val == 0) return const SizedBox();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    formatCompactCurrency(val),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= rows.length) return const SizedBox();
                final m = rows[idx].month;
                final label = formatChartMonth(m);
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipBorder: const BorderSide(color: AppColors.primaryBorder, width: 1),
            tooltipRoundedRadius: 14,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final idx = group.x.toInt();
              final monthStr = (idx >= 0 && idx < rows.length) ? rows[idx].month : '';
              return BarTooltipItem(
                monthStr.isNotEmpty ? '$monthStr\n' : '',
                GoogleFonts.inter(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: '$metricName: ',
                    style: GoogleFonts.inter(
                      color: AppColors.foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: formatCurrency(rod.toY),
                    style: GoogleFonts.fraunces(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (int i = 0; i < rows.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: metric(rows[i]),
                  color: i == rows.length - 1 ? AppColors.primary : AppColors.secondary,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Horizontal Bar Chart for Top Products (By Quantity Sold)
/// Directly faithfully replicates the Recharts horizontal bar chart from Sidhi-Florals
class TopProductsHorizontalChart extends StatelessWidget {
  final List<TopProduct> items;

  const TopProductsHorizontalChart({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No sales recorded yet.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      );
    }

    final topRows = items.take(6).toList();
    final maxQty = topRows.map((e) => e.quantitySold).reduce(math.max);

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: topRows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final p = topRows[i];
        final ratio = maxQty > 0 ? (p.quantitySold / maxQty).clamp(0.05, 1.0) : 0.05;
        final barColor = i == 0
            ? AppColors.primary
            : i % 2 == 0
                ? AppColors.secondary
                : const Color(0xFF6E6475);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayName(p),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.foreground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${formatNumber(p.quantitySold.round())} sold',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatCurrency(p.revenue),
                  style: GoogleFonts.fraunces(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            LayoutBuilder(
              builder: (ctx, constraints) {
                final barWidth = constraints.maxWidth * ratio;
                return Stack(
                  children: [
                    Container(
                      height: 18,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.secondarySoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      height: 18,
                      width: barWidth,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(8), left: Radius.circular(4)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ).animate(delay: (i * 40).ms).fadeIn(duration: 250.ms).slideX(begin: 0.05, end: 0);
      },
    );
  }
}
