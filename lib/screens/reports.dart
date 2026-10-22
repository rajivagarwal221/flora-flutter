import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/analytics.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/charts.dart';
import '../widgets/async_view.dart';
import 'decision_panel.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTimeRange range = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 29)),
      end: DateTime.now());
  late Future<ReportData> report = _load();
  Future<ReportData> _load() async {
    final results = await Future.wait<dynamic>([
      repo.reportSales(range.start, range.end),
      repo.allProducts(),
    ]);
    return ReportData.build(results[0] as List<Sale>,
        results[1] as List<Product>, range.start, range.end);
  }

  Future<void> _pick() async {
    final next = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        initialDateRange: range);
    if (next != null) {
      setState(() {
        range = next;
        report = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      bottom: false,
      child: FutureBuilder<ReportData>(
          future: report,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${snapshot.error}'),
                TextButton(
                    onPressed: () => setState(() => report = _load()),
                    child: const Text('Retry'))
              ]));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final d = snapshot.data!;
            final label =
                '${DateFormat.yMMMd().format(range.start)} – ${DateFormat.yMMMd().format(range.end)}';
            return RefreshIndicator(
                onRefresh: () async {
                  setState(() => report = _load());
                  await report;
                },
                child: ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      const PageHeader(
                          title: 'Reports',
                          subtitle: 'Sales, mix and margins for one period.'),
                      Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: OutlinedButton.icon(
                              onPressed: _pick,
                              icon: const Icon(Icons.date_range),
                              label: Text(label))),
                      Card(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Revenue',
                                        style:
                                            TextStyle(color: AppColors.muted)),
                                    Text(formatCurrency(d.revenue),
                                        style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                        'Profit ${formatCurrency(d.profit)}  ·  ${formatNumber(d.units.round())} units',
                                        style: const TextStyle(
                                            color: AppColors.muted))
                                  ]))),
                      StudioChartPanel(
                          title: 'Revenue by category',
                          subtitle:
                              'Tap a slice to see products. Custom bouquets are separate.',
                          child: _CategoryPie(d)),
                      StudioChartPanel(
                          title: 'Revenue by month',
                          child: StudioBarChart(
                              rows: d.monthly,
                              metric: (r) => r.revenue,
                              metricName: 'Revenue')),
                      StudioChartPanel(
                          title: 'Top products',
                          child: TopProductsHorizontalChart(items: d.top)),
                      StudioChartPanel(
                          title: 'Units sold by day',
                          child: StudioLineChart(
                              rows: d.daily,
                              metric: (r) => r.quantitySold,
                              metricName: 'Units')),
                      StudioChartPanel(
                          title: 'Profit by day',
                          child: StudioAreaChart(
                              rows: d.daily,
                              metric: (r) => r.profit,
                              metricName: 'Profit',
                              isCurrency: true)),
                      StudioChartPanel(
                          title: 'Profit by month',
                          child: StudioBarChart(
                              rows: d.monthly,
                              metric: (r) => r.profit,
                              metricName: 'Profit')),
                      const DecisionPanel(),
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                              'Voided invoices are excluded. Invoice discounts are allocated across items. '
                              'Quick bills without items appear as Unallocated bills. Profit excludes those bills because their costs are unknown.',
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 12))),
                    ]));
          }));
}

class _CategoryPie extends StatelessWidget {
  final ReportData data;
  const _CategoryPie(this.data);
  static const colors = [
    Color(0xffbc496e),
    Color(0xff6f9a73),
    Color(0xffe8a653),
    Color(0xff8276b5),
    Color(0xff6aa6b5)
  ];
  @override
  Widget build(BuildContext context) {
    final entries = data.categoryRevenue.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final pieTotal = entries.fold<double>(0, (sum, e) => sum + e.value);
    if (entries.isEmpty) {
      return const Center(child: Text('No sales in this period'));
    }
    return Row(children: [
      Expanded(
          child: PieChart(PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 32,
        sections: [
          for (var i = 0; i < entries.length; i++)
            PieChartSectionData(
                value: entries[i].value,
                color: colors[i % colors.length],
                radius: 68,
                title: '${(entries[i].value / pieTotal * 100).round()}%',
                titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11))
        ],
        pieTouchData: PieTouchData(touchCallback: (event, response) {
          if (!event.isInterestedForInteractions ||
              response?.touchedSection == null) {
            return;
          }
          final index = response!.touchedSection!.touchedSectionIndex;
          if (index >= 0 && index < entries.length) {
            _showProducts(context, entries[index].key);
          }
        }),
      ))),
      SizedBox(
          width: 126,
          child: ListView(shrinkWrap: true, children: [
            for (var i = 0; i < entries.length; i++)
              InkWell(
                  onTap: () => _showProducts(context, entries[i].key),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        CircleAvatar(
                            radius: 5,
                            backgroundColor: colors[i % colors.length]),
                        const SizedBox(width: 5),
                        Expanded(
                            child: Text(
                                '${entries[i].key}\n${formatCurrency(entries[i].value)}',
                                style: const TextStyle(fontSize: 10),
                                maxLines: 2))
                      ]))),
          ]))
    ]);
  }

  void _showProducts(BuildContext context, String category) {
    final rows = data.categoryProducts[category] ?? [];
    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
                child: ListView(shrinkWrap: true, children: [
              ListTile(
                  title: Text(category),
                  subtitle: Text(
                      formatCurrency(data.categoryRevenue[category] ?? 0))),
              if (rows.isEmpty)
                const ListTile(title: Text('No item detail for these bills')),
              for (final p in rows)
                ListTile(
                    title: Text(p.name),
                    subtitle:
                        Text('${formatNumber(p.quantitySold.round())} sold'),
                    trailing: Text(formatCurrency(p.revenue))),
            ])));
  }
}
