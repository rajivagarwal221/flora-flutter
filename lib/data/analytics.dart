import 'dart:math' as math;
import 'models.dart';

/// All report figures come from active invoices in one selected interval.
/// The same allocation rules can be reused by the web client.
class ReportData {
  final List<DailyRow> daily;
  final List<MonthlyRow> monthly;
  final List<TopProduct> top;
  final Map<String, double> categoryRevenue;
  final Map<String, List<TopProduct>> categoryProducts;
  final double revenue, profit, units;
  ReportData(this.daily, this.monthly, this.top, this.categoryRevenue,
      this.categoryProducts, this.revenue, this.profit, this.units);

  factory ReportData.build(
      List<Sale> sales, List<Product> products, DateTime start, DateTime end) {
    final productById = {for (final p in products) p.id: p};
    final days = <String, List<double>>{};
    final months = <String, List<double>>{};
    final categories = <String, double>{};
    final productTotals = <String, List<double>>{};
    final productCategories = <String, String>{};
    double revenue = 0, profit = 0, units = 0;
    for (final sale in sales.where((s) => !s.isVoided)) {
      final date = DateTime.tryParse(sale.date)?.toLocal();
      if (date == null ||
          date.isBefore(start) ||
          date.isAfter(
              DateTime(end.year, end.month, end.day, 23, 59, 59, 999))) {
        continue;
      }
      final day =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final month = day.substring(0, 7);
      final itemGross = sale.items.fold<double>(0, (a, i) => a + i.total);
      final cost =
          sale.items.fold<double>(0, (a, i) => a + i.unitCost * i.quantity);
      final quantity = sale.items.fold<double>(0, (a, i) => a + i.quantity);
      // Quick bills have no item costs, so their profit is unknown.
      final saleProfit = sale.items.isEmpty ? 0.0 : sale.total - cost;
      revenue += sale.total;
      profit += saleProfit;
      units += quantity;
      for (final bucket in [
        days.putIfAbsent(day, () => [0, 0, 0]),
        months.putIfAbsent(month, () => [0, 0, 0])
      ]) {
        bucket[0] += sale.total;
        bucket[1] += quantity;
        bucket[2] += saleProfit;
      }
      for (final item in sale.items) {
        final category = item.kind == ItemKind.customBouquet
            ? 'Custom bouquets'
            : (productById[item.productId]?.category.name ?? 'Uncategorised');
        final amount =
            itemGross > 0 ? sale.total * item.total / itemGross : 0.0;
        categories[category] = (categories[category] ?? 0) + amount;
        final key = item.kind == ItemKind.customBouquet
            ? 'custom:${item.name}'
            : '${item.productId ?? 0}:${item.name}';
        final totals = productTotals.putIfAbsent(key, () => [0, 0]);
        totals[0] += item.quantity;
        totals[1] += amount;
        productCategories[key] = category;
      }
      if (sale.items.isEmpty || itemGross <= 0) {
        categories['Unallocated bills'] =
            (categories['Unallocated bills'] ?? 0) + sale.total;
      }
    }
    for (var date = DateTime(start.year, start.month, start.day);
        !date.isAfter(DateTime(end.year, end.month, end.day));
        date = DateTime(date.year, date.month, date.day + 1)) {
      final key = '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      days.putIfAbsent(key, () => [0, 0, 0]);
    }
    for (var month = DateTime(start.year, start.month);
        !month.isAfter(DateTime(end.year, end.month));
        month = DateTime(month.year, month.month + 1)) {
      final key = '${month.year.toString().padLeft(4, '0')}-'
          '${month.month.toString().padLeft(2, '0')}';
      months.putIfAbsent(key, () => [0, 0, 0]);
    }
    final top = <TopProduct>[];
    final drill = <String, List<TopProduct>>{};
    for (final entry in productTotals.entries) {
      final key = entry.key;
      final name = key.substring(key.indexOf(':') + 1);
      final category = productCategories[key]!;
      final row = TopProduct(
          id: int.tryParse(key.split(':').first) ?? 0,
          name: name,
          variety: '',
          category: Category.parse(category),
          quantitySold: entry.value[0],
          revenue: entry.value[1]);
      top.add(row);
      drill.putIfAbsent(category, () => []).add(row);
    }
    top.sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
    for (final rows in drill.values) {
      rows.sort((a, b) => b.revenue.compareTo(a.revenue));
    }
    final daily = days.entries
        .map((e) => DailyRow(
            date: e.key,
            revenue: e.value[0],
            quantitySold: e.value[1],
            profit: e.value[2]))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final monthly = months.entries
        .map((e) => MonthlyRow(
            month: e.key,
            revenue: e.value[0],
            quantitySold: e.value[1],
            profit: e.value[2]))
        .toList()
      ..sort((a, b) => a.month.compareTo(b.month));
    return ReportData(
        daily, monthly, top, categories, drill, revenue, profit, units);
  }
}

class StockDecision {
  final Product product;
  final double dailyUse, daysLeft, suggestedReorder, lowEstimate, highEstimate;
  final double backtestEstimate, backtestActual;
  StockDecision(
      this.product,
      this.dailyUse,
      this.daysLeft,
      this.suggestedReorder,
      this.lowEstimate,
      this.highEstimate,
      this.backtestEstimate,
      this.backtestActual);
}

List<StockDecision> stockDecisions(List<Product> products, List<Sale> sales,
    {int historyDays = 28, int horizonDays = 7}) {
  final used = <int, double>{};
  final recentUsed = <int, double>{};
  final daily = <int, Map<String, double>>{};
  final now = DateTime.now();
  final since = now.subtract(Duration(days: historyDays));
  for (final sale in sales.where((s) => !s.isVoided)) {
    final date = DateTime.tryParse(sale.date)?.toLocal();
    if (date == null || date.isBefore(since)) continue;
    final key = '${date.year}-${date.month}-${date.day}';
    void add(int? id, double qty) {
      if (id == null) return;
      used[id] = (used[id] ?? 0) + qty;
      if (date.isAfter(now.subtract(const Duration(days: 7)))) {
        recentUsed[id] = (recentUsed[id] ?? 0) + qty;
      }
      final byDay = daily.putIfAbsent(id, () => {});
      byDay[key] = (byDay[key] ?? 0) + qty;
    }

    for (final item in sale.items) {
      if (item.components.isNotEmpty) {
        for (final c in item.components) {
          add(c.productId, c.quantity * item.quantity);
        }
      } else if (item.kind == ItemKind.product) {
        add(item.productId, item.quantity);
      }
    }
  }
  return products.where((p) => p.category != Category.bouquet).map((p) {
    final avg = (used[p.id] ?? 0) / historyDays;
    final values = daily[p.id]?.values.toList() ?? [];
    final variance = values.isEmpty
        ? 0.0
        : (values.fold<double>(
                    0, (a, v) => a + math.pow(v - avg, 2).toDouble()) +
                (historyDays - values.length) * avg * avg) /
            historyDays;
    final spread = math.sqrt(variance * horizonDays);
    final estimate = avg * horizonDays;
    final low = math.max(0.0, estimate - 1.64 * spread);
    final high = estimate + 1.64 * spread;
    final reorder = math.max(0.0, (high - p.stock).ceilToDouble());
    final priorDays = math.max(1, historyDays - 7);
    final backtest =
        ((used[p.id] ?? 0) - (recentUsed[p.id] ?? 0)) / priorDays * 7;
    return StockDecision(p, avg, avg > 0 ? p.stock / avg : double.infinity,
        reorder, low, high, backtest, recentUsed[p.id] ?? 0);
  }).toList()
    ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
}
