import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/analytics.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../utils.dart';

class DecisionPanel extends StatefulWidget {
  const DecisionPanel({super.key});
  @override
  State<DecisionPanel> createState() => _DecisionPanelState();
}

class _DecisionPanelState extends State<DecisionPanel> {
  late Future<
      (
        List<StockDecision>,
        List<Sale>,
        List<Product>,
        List<RecipeRow>,
        double
      )> data = _load();
  Future<
      (
        List<StockDecision>,
        List<Sale>,
        List<Product>,
        List<RecipeRow>,
        double
      )> _load() async {
    final now = DateTime.now();
    final results = await Future.wait<dynamic>([
      repo.reportSales(now.subtract(const Duration(days: 35)), now),
      repo.products(),
      repo.recipes(),
      repo.overdueAmount(now.subtract(const Duration(days: 30))),
    ]);
    final sales = results[0] as List<Sale>;
    final products = results[1] as List<Product>;
    final overdue = results[3] as double;
    return (
      stockDecisions(products, sales),
      sales,
      products,
      results[2] as List<RecipeRow>,
      overdue
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ListTile(
              title: const Text('Planning data unavailable'),
              subtitle: Text('${snapshot.error}'),
              trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => setState(() => data = _load())));
        }
        if (!snapshot.hasData) {
          return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()));
        }
        final (decisions, sales, products, recipes, overdue) = snapshot.data!;
        final now = DateTime.now();
        double revenueBetween(int from, int to) => sales.where((s) {
              final d = DateTime.tryParse(s.date)?.toLocal();
              return d != null &&
                  d.isAfter(now.subtract(Duration(days: from))) &&
                  d.isBefore(now.subtract(Duration(days: to)));
            }).fold<double>(0, (a, s) => a + s.total);
        final thisWeek = revenueBetween(7, 0), lastWeek = revenueBetween(14, 7);
        final change = lastWeek > 0 ? (thisWeek / lastWeek - 1) * 100 : null;
        Map<String, double> productWeek(int from, int to) {
          final totals = <String, double>{};
          for (final sale in sales) {
            final date = DateTime.tryParse(sale.date)?.toLocal();
            if (date == null ||
                !date.isAfter(now.subtract(Duration(days: from))) ||
                !date.isBefore(now.subtract(Duration(days: to)))) {
              continue;
            }
            for (final item in sale.items) {
              totals[item.name] = (totals[item.name] ?? 0) + item.quantity;
            }
          }
          return totals;
        }

        final recentProducts = productWeek(7, 0);
        final previousProducts = productWeek(14, 7);
        final movers = recentProducts.keys
            .where((name) =>
                (recentProducts[name] ?? 0) >= 2 &&
                (previousProducts[name] ?? 0) > 0)
            .toList()
          ..sort((a, b) =>
              ((recentProducts[b] ?? 0) - (previousProducts[b] ?? 0)).compareTo(
                  (recentProducts[a] ?? 0) - (previousProducts[a] ?? 0)));
        final rising = movers.isNotEmpty &&
                (recentProducts[movers.first] ?? 0) >
                    (previousProducts[movers.first] ?? 0)
            ? movers.first
            : null;
        final dropping = movers.isNotEmpty &&
                (recentProducts[movers.last] ?? 0) <
                    (previousProducts[movers.last] ?? 0)
            ? movers.last
            : null;
        final toReorder =
            decisions.where((d) => d.suggestedReorder > 0).take(6).toList();
        final flowers = decisions
            .where((d) =>
                d.product.category == Category.flower &&
                d.product.stock >= 3 &&
                d.product.sellingPrice > d.product.purchasePrice)
            .toList()
          ..sort((a, b) => b.dailyUse.compareTo(a.dailyUse));
        final a = flowers.isNotEmpty ? flowers.first.product : null;
        final b = flowers.length > 1 ? flowers[1].product : null;
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _card('Weekly insights', [
                Text(
                    'Sales ${change == null ? 'have no previous-week baseline' : '${change >= 0 ? 'rose' : 'fell'} ${change.abs().toStringAsFixed(0)}%'}: '
                    '${formatCurrency(thisWeek)} this week vs ${formatCurrency(lastWeek)} last week.'),
                Text(
                    'Payments more than 30 days old: ${formatCurrency(overdue)}.'),
                if (rising != null)
                  Text(
                      '$rising rose from ${previousProducts[rising]!.toStringAsFixed(0)} '
                      'to ${recentProducts[rising]!.toStringAsFixed(0)} units.'),
                if (dropping != null)
                  Text(
                      '$dropping fell from ${previousProducts[dropping]!.toStringAsFixed(0)} '
                      'to ${recentProducts[dropping]!.toStringAsFixed(0)} units.'),
                const Text(
                    'Based on non-voided invoices. Tap Sales or Credits for the underlying bills.'),
              ]),
              _card('Stock outlook and reorder proposals', [
                if (toReorder.isEmpty)
                  const Text('No reorder signal from the last 28 days.'),
                for (final d in toReorder)
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(displayName(d.product)),
                      subtitle: Text(
                          'Stock ${d.product.stock.toStringAsFixed(0)} · '
                          '${d.daysLeft.isFinite ? '${d.daysLeft.toStringAsFixed(1)} days left' : 'No recent use'}'),
                      trailing: Text(
                          'Plan +${d.suggestedReorder.toStringAsFixed(0)}')),
                const Text(
                    'Proposals only. Stock changes require a person to record receipt or adjustment.'),
              ]),
              _stockHistoryCard(products),
              _card('7-day demand forecast', [
                const Text(
                    'Simple 28-day sales rate; range reflects daily variation.'),
                for (final d in decisions.where((d) => d.dailyUse > 0).take(6))
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(displayName(d.product)),
                      subtitle: Text('Last 7 days: predicted '
                          '${d.backtestEstimate.toStringAsFixed(1)}, actual '
                          '${d.backtestActual.toStringAsFixed(1)}'),
                      trailing: Text(
                          '${d.lowEstimate.floor()}–${math.max(d.lowEstimate.ceil(), d.highEstimate.ceil())} ${d.product.unit}')),
                const Text(
                    'The next 7-day range is an estimate, not a guaranteed stock requirement.'),
              ]),
              if (a != null && b != null)
                _card('Bouquet idea', [
                  Text(
                      '${a.name} + ${b.name}: both have stock and positive unit margin.'),
                  Text(
                      'Current stock: ${a.stock.toStringAsFixed(0)} and ${b.stock.toStringAsFixed(0)}. '
                      'Candidate margin before wrapping and labour: '
                      '${formatCurrency((a.sellingPrice - a.purchasePrice) + (b.sellingPrice - b.purchasePrice))}.'),
                  const Text(
                      'Review the recipe and price before adding it to inventory.'),
                ]),
              if (recipes.isNotEmpty)
                _card('Bouquet recipes', [
                  Text(
                      '${recipes.map((r) => r.bouquetId).toSet().length} recorded recipes available for manual review.'),
                ]),
            ]);
      });

  Widget _stockHistoryCard(List<Product> products) => FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.allStockMovements(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final since = DateTime.now().subtract(const Duration(days: 28));
        final changes = <int, double>{};
        final wasted = <int, double>{};
        for (final entry in snapshot.data!) {
          final date = DateTime.tryParse('${entry['date']}');
          final id = (entry['product_id'] as num?)?.toInt();
          if (id == null || date == null || date.isBefore(since)) continue;
          final quantity = (entry['quantity'] as num?)?.toDouble() ?? 0;
          changes[id] = (changes[id] ?? 0) + quantity;
          if (entry['kind'] == 'waste') {
            wasted[id] = (wasted[id] ?? 0) - quantity;
          }
        }
        final rows = products.where((p) => changes.containsKey(p.id) || wasted.containsKey(p.id)).toList()
          ..sort((a, b) => a.stock.compareTo(b.stock));
        return _card('Stock movement · last 28 days', [
          if (rows.isEmpty) const Text('Movement trends will appear as stock is received, sold, or wasted.'),
          for (final p in rows.take(6)) ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(displayName(p)),
            subtitle: Text('Current ${p.stock.toStringAsFixed(0)} ${p.unit} · '
              'change ${(changes[p.id] ?? 0) >= 0 ? '+' : ''}${(changes[p.id] ?? 0).toStringAsFixed(0)}'),
            trailing: wasted[p.id] == null ? null : Text('Waste ${wasted[p.id]!.toStringAsFixed(0)}'),
          ),
        ]);
      });
  Widget _card(String title, List<Widget> children) => Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...children.map((w) =>
                Padding(padding: const EdgeInsets.only(bottom: 6), child: w))
          ])));
}
