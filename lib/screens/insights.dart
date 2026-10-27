import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../services/insights.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/async_view.dart';
import '../widgets/insight_card.dart';
import '../widgets/product_image.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 4, vsync: this);
  @override void dispose() { _tab.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(children: [
        const PageHeader(title: 'AI Insights', subtitle: 'Decisions, not just numbers.'),
        Material(color: Colors.white, child: TabBar(controller: _tab, isScrollable: true, tabs: const [
          Tab(icon: Icon(Icons.auto_awesome, size: 18), text: 'Highlights'),
          Tab(icon: Icon(Icons.show_chart, size: 18), text: 'Forecast'),
          Tab(icon: Icon(Icons.inventory, size: 18), text: 'Reorder'),
          Tab(icon: Icon(Icons.diversity_3, size: 18), text: 'Customers'),
        ])),
        Expanded(child: AsyncView<_Payload>(
          load: _load,
          builder: (ctx, data, refresh) {
            return TabBarView(controller: _tab, children: [
              _HighlightsTab(result: data.result, designer: data.designer),
              _ForecastTab(result: data.result),
              _ReorderTab(result: data.result, products: data.products),
              _CustomersTab(result: data.result),
            ]);
          },
        )),
      ]),
    );
  }

  Future<_Payload> _load() async {
    final results = await Future.wait([
      repo.sales(limit: 500),
      repo.products(),
      repo.customers(),
      repo.dailySales(),
      repo.profitMargins(),
    ]);
    final sales = results[0] as List<Sale>;
    final products = results[1] as List<Product>;
    final customers = results[2] as List<Customer>;
    final daily = results[3] as List<DailyRow>;
    final margins = results[4] as List<MarginRow>;
    final engine = InsightsEngine(sales: sales, products: products, customers: customers,
      daily: daily, margins: margins);
    final designer = BouquetDesigner(products: products, margins: margins);
    return _Payload(result: engine.run(), designer: designer, products: products);
  }
}

class _Payload {
  final AnalyticsResult result;
  final BouquetDesigner designer;
  final List<Product> products;
  _Payload({required this.result, required this.designer, required this.products});
}

// ---------------- Highlights ----------------
class _HighlightsTab extends StatelessWidget {
  final AnalyticsResult result;
  final BouquetDesigner designer;
  const _HighlightsTab({required this.result, required this.designer});

  @override Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        _MetricsStrip(result: result),
        const SizedBox(height: 14),
        Text('What the data says', style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (result.insights.isEmpty)
          const EmptyState(icon: Icons.insights, message: 'Not enough data yet', hint: 'Record a few sales to see insights.'),
        for (int i = 0; i < result.insights.length; i++)
          InsightTile(insight: result.insights[i])
            .animate(delay: (i * 60).ms).fadeIn(duration: 220.ms).slideY(begin: 0.08, end: 0),
        const SizedBox(height: 12),
        _BouquetDesignerCard(designer: designer),
      ],
    );
  }
}

class _MetricsStrip extends StatelessWidget {
  final AnalyticsResult result;
  const _MetricsStrip({required this.result});
  @override Widget build(BuildContext context) {
    final up = result.revenueWowDelta >= 0;
    final pct = (result.revenueWowDelta * 100).abs().toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(blurRadius: 20, color: AppColors.roseShadow, offset: Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.auto_awesome, size: 12, color: Colors.white),
              SizedBox(width: 4),
              Text('AI SNAPSHOT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ])),
          const Spacer(),
          Icon(up ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 20),
        ]),
        const SizedBox(height: 10),
        Text('Last 7 days', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(formatCurrency(result.trailing7dRevenue), style: GoogleFonts.fraunces(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('${up ? "▲" : "▼"} $pct% vs prior week · projected ${formatCurrency(result.projected7dRevenue)} next 7',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
      ]),
    );
  }
}

class _BouquetDesignerCard extends StatefulWidget {
  final BouquetDesigner designer;
  const _BouquetDesignerCard({required this.designer});
  @override State<_BouquetDesignerCard> createState() => _BouquetDesignerCardState();
}

class _BouquetDesignerCardState extends State<_BouquetDesignerCard> {
  double _budget = 500;
  String _theme = '';
  List<BouquetSuggestion> _suggestions = const [];
  @override void initState() { super.initState(); _run(); }
  void _run() { setState(() => _suggestions = widget.designer.suggest(budget: _budget, theme: _theme.trim())); }

  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.workspaces, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('AI Bouquet Designer', style: GoogleFonts.fraunces(fontSize: 17, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Budget: ${formatCurrency(_budget)}', style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
            Slider(
              min: 200, max: 3000, divisions: 28, value: _budget,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _budget = v),
              onChangeEnd: (_) => _run(),
            ),
          ])),
        ]),
        TextField(
          decoration: const InputDecoration(hintText: 'Optional theme (e.g. rose, pink, lily)', prefixIcon: Icon(Icons.palette_outlined)),
          onSubmitted: (v) { _theme = v; _run(); },
        ),
        const SizedBox(height: 12),
        if (_suggestions.isEmpty)
          const Text('No stock currently matches that theme — try another.', style: TextStyle(color: AppColors.muted)),
        for (final s in _suggestions) _suggestionTile(s),
      ]),
    );
  }

  Widget _suggestionTile(BouquetSuggestion s) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${s.lines.length}-flower design', style: const TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(999)),
            child: Text('${s.margin.toStringAsFixed(0)}% margin',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 8),
        for (final l in s.lines) Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            ProductImage(product: l.product, size: 34, radius: 8),
            const SizedBox(width: 10),
            Expanded(child: Text('${l.quantity} × ${l.product.name}${l.product.variety.isEmpty ? "" : " · ${l.product.variety}"}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
            Text(formatCurrency(l.quantity * l.product.sellingPrice),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
        ),
        const Divider(),
        Row(children: [
          const Text('Suggested price', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const Spacer(),
          Text(formatCurrency(s.total), style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
        ]),
      ]),
    );
  }
}

// ---------------- Forecast ----------------
class _ForecastTab extends StatelessWidget {
  final AnalyticsResult result;
  const _ForecastTab({required this.result});
  @override Widget build(BuildContext context) {
    if (result.forecast.isEmpty) {
      return const EmptyState(icon: Icons.show_chart, message: 'No sales yet', hint: 'Record a few sales to generate a forecast.');
    }
    final actual = result.forecast.where((p) => !p.isForecast).toList();
    final forecast = result.forecast.where((p) => p.isForecast).toList();
    final allPoints = result.forecast;
    final maxY = (allPoints.map((e) => e.value).fold<double>(0, math.max) * 1.15).clamp(10, double.infinity).toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: [
        _MetricsStrip(result: result),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Revenue forecast', style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              const StatusChip(label: 'EMA + weekday', bg: AppColors.primarySoft, fg: AppColors.primary, icon: Icons.auto_awesome),
            ]),
            const SizedBox(height: 4),
            const Text('Solid line: observed. Dashed: predicted 14-day outlook.',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: LineChart(LineChartData(
                minY: 0, maxY: maxY,
                gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (int i = 0; i < actual.length; i++) FlSpot(i.toDouble(), actual[i].value)],
                    isCurved: true, color: AppColors.primary, barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [AppColors.primary.withValues(alpha: 0.3), AppColors.primary.withValues(alpha: 0)],
                    )),
                  ),
                  LineChartBarData(
                    spots: [
                      if (actual.isNotEmpty) FlSpot((actual.length - 1).toDouble(), actual.last.value),
                      for (int i = 0; i < forecast.length; i++) FlSpot((actual.length + i).toDouble(), forecast[i].value),
                    ],
                    isCurved: true,
                    color: AppColors.secondary,
                    barWidth: 2.5,
                    dashArray: const [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              )),
            ),
          ]),
        ),
      ],
    );
  }
}

// ---------------- Reorder ----------------
class _ReorderTab extends StatelessWidget {
  final AnalyticsResult result;
  final List<Product> products;
  const _ReorderTab({required this.result, required this.products});
  @override Widget build(BuildContext context) {
    if (result.reorders.isEmpty) {
      return const EmptyState(icon: Icons.check_circle_outline, message: 'All stocked up', hint: 'Nothing critical to reorder right now.');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: result.reorders.length,
      itemBuilder: (c, i) {
        final r = result.reorders[i];
        final urgent = r.daysLeft <= 5;
        final product = products.firstWhere((p) => p.id == r.productId,
          orElse: () => Product(id: r.productId, name: r.name, variety: r.variety, unit: r.unit,
            category: Category.flower, purchasePrice: 0, sellingPrice: 0, stock: r.stock, supplier: '', createdAt: ''));
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: urgent ? AppColors.primaryBorder : AppColors.border),
          ),
          child: Row(children: [
            ProductImage(product: product, size: 54),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${r.name}${r.variety.isEmpty ? "" : " · ${r.variety}"}', style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Stock ${r.stock.toStringAsFixed(0)} · ${r.perDay.toStringAsFixed(1)}/day · '
                '${r.daysLeft.isFinite ? "~${r.daysLeft.toStringAsFixed(0)} days left" : "slow mover"}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: urgent ? AppColors.primaryGradient : null,
                color: urgent ? null : AppColors.secondarySoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('Order ${r.suggestOrder.toStringAsFixed(0)}',
                style: TextStyle(color: urgent ? Colors.white : AppColors.foreground, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ]),
        ).animate(delay: (i.clamp(0, 10) * 25).ms).fadeIn(duration: 220.ms).slideY(begin: 0.08, end: 0);
      },
    );
  }
}

// ---------------- Customers (RFM) ----------------
class _CustomersTab extends StatelessWidget {
  final AnalyticsResult result;
  const _CustomersTab({required this.result});

  Color _segmentColor(RfmSegment s) => switch (s) {
    RfmSegment.champion => const Color(0xFF1C7A4A),
    RfmSegment.loyal => AppColors.primary,
    RfmSegment.potential => const Color(0xFF4A61C7),
    RfmSegment.newCustomer => const Color(0xFF2CA6BD),
    RfmSegment.atRisk => const Color(0xFFB87414),
    RfmSegment.lost => AppColors.muted,
    RfmSegment.oneTime => const Color(0xFF8A6EC9),
  };

  @override Widget build(BuildContext context) {
    if (result.customerSegments.isEmpty) {
      return const EmptyState(icon: Icons.people_outline, message: 'No customers yet', hint: 'Add customers to see segments.');
    }
    final counts = result.segmentCounts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Segment mix', style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in counts) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _segmentColor(e.key).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _segmentColor(e.key).withValues(alpha: 0.3)),
                ),
                child: Text('${e.key.label} · ${e.value}',
                  style: TextStyle(color: _segmentColor(e.key), fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < result.customerSegments.length; i++) _row(result.customerSegments[i], i),
      ],
    );
  }

  Widget _row(RfmScore r, int i) {
    final color = _segmentColor(r.segment);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(r.name.isEmpty ? '·' : r.name[0].toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.w800)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(r.recencyDays >= 9999
            ? 'No orders'
            : '${r.frequency} order${r.frequency == 1 ? "" : "s"} · last ${r.recencyDays}d ago · ${formatCurrency(r.monetary)}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
          child: Text(r.segment.label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11))),
      ]),
    ).animate(delay: (i.clamp(0, 10) * 20).ms).fadeIn(duration: 200.ms);
  }
}

