import 'dart:math' as math;
import '../data/models.dart';

enum InsightTone { positive, negative, neutral, warning, action }

class Insight {
  final String title;
  final String body;
  final InsightTone tone;
  final String? icon;
  const Insight({required this.title, required this.body, required this.tone, this.icon});
}

/// Customer-segmentation output (RFM — Recency, Frequency, Monetary).
enum RfmSegment { champion, loyal, potential, newCustomer, atRisk, lost, oneTime }

extension RfmSegmentX on RfmSegment {
  String get label => switch (this) {
    RfmSegment.champion => 'Champion',
    RfmSegment.loyal => 'Loyal',
    RfmSegment.potential => 'Potential',
    RfmSegment.newCustomer => 'New',
    RfmSegment.atRisk => 'At risk',
    RfmSegment.lost => 'Lost',
    RfmSegment.oneTime => 'One-time',
  };
}

class RfmScore {
  final int customerId;
  final String name;
  final int recencyDays;
  final int frequency;
  final double monetary;
  final RfmSegment segment;
  const RfmScore({required this.customerId, required this.name, required this.recencyDays,
    required this.frequency, required this.monetary, required this.segment});
}

class ReorderRec {
  final int productId;
  final String name;
  final String variety;
  final String unit;
  final double stock;
  final double perDay;
  final double daysLeft;
  final double suggestOrder;
  const ReorderRec({required this.productId, required this.name, required this.variety, required this.unit,
    required this.stock, required this.perDay, required this.daysLeft, required this.suggestOrder});
}

class ForecastPoint {
  final DateTime date;
  final double value;
  final bool isForecast;
  const ForecastPoint({required this.date, required this.value, required this.isForecast});
}

class AnalyticsResult {
  final List<Insight> insights;
  final List<RfmScore> customerSegments;
  final List<ReorderRec> reorders;
  final List<ForecastPoint> forecast;
  final Map<RfmSegment, int> segmentCounts;
  final double projected7dRevenue;
  final double trailing7dRevenue;
  final double revenueWowDelta; // -1..+inf
  final Map<int, double> peakHourShare; // hour (0..23) -> share of today
  const AnalyticsResult({
    required this.insights,
    required this.customerSegments,
    required this.reorders,
    required this.forecast,
    required this.segmentCounts,
    required this.projected7dRevenue,
    required this.trailing7dRevenue,
    required this.revenueWowDelta,
    required this.peakHourShare,
  });
}

class InsightsEngine {
  final List<Sale> sales;
  final List<Product> products;
  final List<Customer> customers;
  final List<DailyRow> daily;
  final List<MarginRow> margins;
  final DateTime now;
  InsightsEngine({required this.sales, required this.products, required this.customers,
    required this.daily, required this.margins, DateTime? now}) : now = now ?? DateTime.now();

  AnalyticsResult run() {
    final rfm = _rfm();
    final reorders = _reorders();
    final forecast = _forecast(14);
    final segCounts = <RfmSegment, int>{for (final s in RfmSegment.values) s: 0};
    for (final r in rfm) {
      segCounts[r.segment] = (segCounts[r.segment] ?? 0) + 1;
    }

    final trailing7 = _sumLastDays(7);
    final prior7 = _sumRange(14, 7);
    final wow = prior7 == 0 ? 0.0 : (trailing7 - prior7) / prior7;
    final projected = forecast.where((f) => f.isForecast).fold<double>(0, (a, b) => a + b.value);
    final hours = _peakHours();
    final insights = _buildInsights(rfm: rfm, reorders: reorders, trailing7: trailing7,
      wow: wow, projected: projected, forecast: forecast, hours: hours);

    return AnalyticsResult(
      insights: insights,
      customerSegments: rfm,
      reorders: reorders,
      forecast: forecast,
      segmentCounts: segCounts,
      projected7dRevenue: projected,
      trailing7dRevenue: trailing7,
      revenueWowDelta: wow,
      peakHourShare: hours,
    );
  }

  // ---------------- RFM ----------------
  List<RfmScore> _rfm() {
    final byCust = <int, List<Sale>>{};
    for (final s in sales) {
      if (s.isVoided || s.customerId == null) continue;
      byCust.putIfAbsent(s.customerId!, () => []).add(s);
    }
    final rows = <RfmScore>[];
    for (final c in customers) {
      final list = byCust[c.id] ?? const [];
      if (list.isEmpty) {
        rows.add(RfmScore(customerId: c.id, name: c.name, recencyDays: 9999,
          frequency: 0, monetary: 0, segment: RfmSegment.lost));
        continue;
      }
      final latest = list.map((s) => _parseDate(s.date)).reduce((a, b) => a.isAfter(b) ? a : b);
      final recency = now.difference(latest).inDays;
      final freq = list.length;
      final mon = list.fold<double>(0, (a, s) => a + s.total);
      rows.add(RfmScore(customerId: c.id, name: c.name, recencyDays: recency,
        frequency: freq, monetary: mon, segment: _segment(recency, freq, mon)));
    }
    rows.sort((a, b) => b.monetary.compareTo(a.monetary));
    return rows;
  }

  RfmSegment _segment(int rec, int freq, double mon) {
    if (freq == 1 && rec > 90) return RfmSegment.oneTime;
    if (freq >= 5 && rec <= 30 && mon >= 2000) return RfmSegment.champion;
    if (freq >= 3 && rec <= 60) return RfmSegment.loyal;
    if (freq >= 2 && rec <= 90) return RfmSegment.potential;
    if (freq >= 1 && rec <= 30) return RfmSegment.newCustomer;
    if (rec > 90 && rec <= 180) return RfmSegment.atRisk;
    if (rec > 180) return RfmSegment.lost;
    return RfmSegment.potential;
  }

  // ---------------- Reorder ----------------
  List<ReorderRec> _reorders() {
    final windowDays = 30;
    final cutoff = now.subtract(Duration(days: windowDays));
    final sold = <int, double>{};
    for (final s in sales) {
      if (s.isVoided) continue;
      final d = _parseDate(s.date);
      if (d.isBefore(cutoff)) continue;
      for (final it in s.items) {
        if (it.kind == ItemKind.product && it.productId != null) {
          sold.update(it.productId!, (v) => v + it.quantity, ifAbsent: () => it.quantity);
        }
        for (final comp in it.components) {
          if (comp.productId != null) {
            sold.update(comp.productId!, (v) => v + comp.quantity, ifAbsent: () => comp.quantity);
          }
        }
      }
    }
    final recs = <ReorderRec>[];
    for (final p in products) {
      if (p.category == Category.bouquet) continue;
      final consumed = sold[p.id] ?? 0;
      final perDay = consumed / windowDays;
      if (perDay <= 0 && p.stock > 20) continue;
      final daysLeft = perDay > 0 ? p.stock / perDay : double.infinity;
      if (daysLeft > 14 && p.stock > 10) continue;
      final target = math.max(perDay * 21, 20); // 3-week buffer, min 20
      final order = (target - p.stock).clamp(0, 10000).toDouble();
      if (order <= 0) continue;
      recs.add(ReorderRec(
        productId: p.id, name: p.name, variety: p.variety, unit: p.unit,
        stock: p.stock, perDay: perDay, daysLeft: daysLeft, suggestOrder: order,
      ));
    }
    recs.sort((a, b) {
      final al = a.daysLeft.isInfinite ? 1e9 : a.daysLeft;
      final bl = b.daysLeft.isInfinite ? 1e9 : b.daysLeft;
      return al.compareTo(bl);
    });
    return recs;
  }

  // ---------------- Forecast (EMA + weekday profile) ----------------
  List<ForecastPoint> _forecast(int days) {
    final series = <ForecastPoint>[];
    final sorted = [...daily]..sort((a, b) => a.date.compareTo(b.date));
    final take = sorted.length > 60 ? sorted.sublist(sorted.length - 60) : sorted;
    for (final r in take) {
      series.add(ForecastPoint(date: _parseDate(r.date), value: r.revenue, isForecast: false));
    }
    if (series.isEmpty) return series;

    // Weekday seasonality: average revenue per weekday / overall average.
    final byWd = List<List<double>>.generate(7, (_) => []);
    for (final s in series) {
      byWd[s.date.weekday % 7].add(s.value);
    }
    final allAvg = series.map((e) => e.value).fold<double>(0, (a, b) => a + b) / series.length;
    final wdFactor = List<double>.generate(7, (i) {
      if (byWd[i].isEmpty) return 1.0;
      final avg = byWd[i].reduce((a, b) => a + b) / byWd[i].length;
      return allAvg == 0 ? 1.0 : (avg / allAvg);
    });

    // Exponential moving average (alpha ~ 0.3).
    double ema = series.first.value;
    const alpha = 0.3;
    for (final s in series.skip(1)) {
      ema = alpha * s.value + (1 - alpha) * ema;
    }

    final lastDate = series.last.date;
    for (int i = 1; i <= days; i++) {
      final d = DateTime(lastDate.year, lastDate.month, lastDate.day).add(Duration(days: i));
      final factor = wdFactor[d.weekday % 7];
      final v = (ema * factor).clamp(0, double.infinity).toDouble();
      series.add(ForecastPoint(date: d, value: v, isForecast: true));
    }
    return series;
  }

  // ---------------- Peak hours ----------------
  Map<int, double> _peakHours() {
    final today = DateTime(now.year, now.month, now.day);
    final byHour = <int, double>{};
    double total = 0;
    for (final s in sales) {
      if (s.isVoided) continue;
      final d = _parseDate(s.date);
      if (DateTime(d.year, d.month, d.day) != today) continue;
      byHour.update(d.hour, (v) => v + s.total, ifAbsent: () => s.total);
      total += s.total;
    }
    if (total == 0) return {};
    return {for (final e in byHour.entries) e.key: e.value / total};
  }

  // ---------------- Insight NLG ----------------
  List<Insight> _buildInsights({required List<RfmScore> rfm, required List<ReorderRec> reorders,
      required double trailing7, required double wow, required double projected,
      required List<ForecastPoint> forecast, required Map<int, double> hours}) {
    final out = <Insight>[];

    if (wow.abs() > 0.03) {
      final up = wow > 0;
      final pct = (wow * 100).abs().toStringAsFixed(0);
      out.add(Insight(
        title: up ? 'Revenue trending up' : 'Revenue trending down',
        body: 'Last 7 days ${up ? "grew" : "fell"} $pct% vs the previous 7. '
            'Trailing 7-day revenue: ₹${trailing7.toStringAsFixed(0)}.',
        tone: up ? InsightTone.positive : InsightTone.negative,
      ));
    } else if (trailing7 > 0) {
      out.add(Insight(
        title: 'Revenue steady',
        body: 'Trailing 7-day revenue is ₹${trailing7.toStringAsFixed(0)}, flat vs the prior week.',
        tone: InsightTone.neutral,
      ));
    }

    if (projected > 0) {
      out.add(Insight(
        title: 'Next 7 days outlook',
        body: 'Projecting ₹${projected.toStringAsFixed(0)} in sales over the next 7 days '
            'based on 60-day trend + weekday seasonality.',
        tone: InsightTone.action,
      ));
    }

    // Top mover (from margins).
    if (margins.isNotEmpty) {
      final sorted = [...margins]..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
      final top = sorted.first;
      if (top.totalRevenue > 0) {
        out.add(Insight(
          title: 'Top earner',
          body: '${top.name}${top.variety.isEmpty ? "" : " · ${top.variety}"} drove '
              '₹${top.totalRevenue.toStringAsFixed(0)} in revenue '
              '(${top.profitMarginPercent.toStringAsFixed(0)}% margin).',
          tone: InsightTone.positive,
        ));
      }
      // Highest-margin pick.
      final byMargin = [...margins.where((m) => m.totalUnitsSold > 0)]
        ..sort((a, b) => b.profitMarginPercent.compareTo(a.profitMarginPercent));
      if (byMargin.isNotEmpty) {
        final m = byMargin.first;
        out.add(Insight(
          title: 'Push the high-margin item',
          body: '${m.name}${m.variety.isEmpty ? "" : " · ${m.variety}"} returns '
              '${m.profitMarginPercent.toStringAsFixed(0)}% margin — lead with it in the next bouquet.',
          tone: InsightTone.action,
        ));
      }
    }

    // Urgent reorders.
    final urgent = reorders.where((r) => r.daysLeft <= 5).take(3).toList();
    if (urgent.isNotEmpty) {
      final list = urgent.map((r) =>
        '${r.name}${r.variety.isEmpty ? "" : " ${r.variety}"} (${r.daysLeft.isFinite ? "~${r.daysLeft.toStringAsFixed(0)} days" : "slow"})'
      ).join(', ');
      out.add(Insight(
        title: 'Stock running low',
        body: 'Reorder soon: $list.',
        tone: InsightTone.warning,
      ));
    }

    // Champions.
    final champs = rfm.where((r) => r.segment == RfmSegment.champion).toList();
    if (champs.isNotEmpty) {
      out.add(Insight(
        title: '${champs.length} Champion customer${champs.length == 1 ? "" : "s"}',
        body: 'Your top-value regulars have ordered ${champs.first.frequency}× '
            '(₹${champs.first.monetary.toStringAsFixed(0)}+) within the last 30 days. '
            'A thank-you call wins repeat orders.',
        tone: InsightTone.action,
      ));
    }

    final atRisk = rfm.where((r) => r.segment == RfmSegment.atRisk).toList();
    if (atRisk.length >= 3) {
      out.add(Insight(
        title: '${atRisk.length} customers at risk',
        body: 'Haven\'t ordered in 90+ days. A small discount or seasonal nudge recovers most of them.',
        tone: InsightTone.warning,
      ));
    }

    // Peak hour today.
    if (hours.isNotEmpty) {
      final peak = hours.entries.reduce((a, b) => a.value > b.value ? a : b);
      final share = (peak.value * 100).toStringAsFixed(0);
      out.add(Insight(
        title: 'Today\'s peak hour',
        body: '${peak.key.toString().padLeft(2, "0")}:00 pulled $share% of today\'s revenue. '
            'Keep best stems ready at that slot tomorrow.',
        tone: InsightTone.neutral,
      ));
    }

    return out;
  }

  // ---------------- Helpers ----------------
  DateTime _parseDate(String iso) {
    try { return DateTime.parse(iso).toLocal(); }
    catch (_) { return now; }
  }

  double _sumLastDays(int days) {
    final cutoff = now.subtract(Duration(days: days));
    double s = 0;
    for (final r in daily) {
      final d = _parseDate(r.date);
      if (d.isAfter(cutoff)) s += r.revenue;
    }
    return s;
  }

  double _sumRange(int fromDaysAgo, int toDaysAgo) {
    final from = now.subtract(Duration(days: fromDaysAgo));
    final to = now.subtract(Duration(days: toDaysAgo));
    double s = 0;
    for (final r in daily) {
      final d = _parseDate(r.date);
      if (d.isAfter(from) && d.isBefore(to)) s += r.revenue;
    }
    return s;
  }
}

/// Suggests a bouquet composition for a target budget, drawing from available stock.
class BouquetDesigner {
  final List<Product> products;
  final List<MarginRow> margins;
  BouquetDesigner({required this.products, required this.margins});

  List<BouquetSuggestion> suggest({required double budget, String? theme}) {
    final flowers = products
      .where((p) => p.category == Category.flower && p.stock > 0 && p.sellingPrice > 0)
      .toList();
    if (flowers.isEmpty) return [];

    // Theme filter — lightweight substring match on variety/name.
    bool matchesTheme(Product p) {
      if (theme == null || theme.isEmpty) return true;
      final q = theme.toLowerCase();
      return p.name.toLowerCase().contains(q) || p.variety.toLowerCase().contains(q);
    }
    final themed = flowers.where(matchesTheme).toList();
    final pool = themed.isNotEmpty ? themed : flowers;

    // Highest-margin first, bounded to 5 unique items.
    pool.sort((a, b) {
      final ma = margins.firstWhere((m) => m.id == a.id,
        orElse: () => MarginRow(id: a.id, name: a.name, variety: a.variety, unit: a.unit,
          category: a.category, purchasePrice: a.purchasePrice, sellingPrice: a.sellingPrice,
          profitPerUnit: a.sellingPrice - a.purchasePrice, profitMarginPercent: 0,
          totalUnitsSold: 0, totalRevenue: 0, totalProfit: 0, stock: a.stock));
      final mb = margins.firstWhere((m) => m.id == b.id,
        orElse: () => MarginRow(id: b.id, name: b.name, variety: b.variety, unit: b.unit,
          category: b.category, purchasePrice: b.purchasePrice, sellingPrice: b.sellingPrice,
          profitPerUnit: b.sellingPrice - b.purchasePrice, profitMarginPercent: 0,
          totalUnitsSold: 0, totalRevenue: 0, totalProfit: 0, stock: b.stock));
      return mb.profitMarginPercent.compareTo(ma.profitMarginPercent);
    });

    final suggestions = <BouquetSuggestion>[];
    for (final size in [3, 5]) {
      final picks = pool.take(size).toList();
      if (picks.isEmpty) continue;
      final lines = <BouquetLine>[];
      double running = 0;
      // Fill proportionally by budget, rounding down to whole units.
      final shareBudget = budget / picks.length;
      for (final p in picks) {
        final maxByBudget = (shareBudget / p.sellingPrice).floor();
        final maxByStock = p.stock.floor();
        final qty = math.max(1, math.min(maxByBudget, maxByStock));
        if (qty == 0) continue;
        lines.add(BouquetLine(product: p, quantity: qty));
        running += qty * p.sellingPrice;
      }
      if (lines.isEmpty) continue;
      final cost = lines.fold<double>(0, (a, l) => a + l.quantity * l.product.purchasePrice);
      suggestions.add(BouquetSuggestion(
        lines: lines,
        total: running,
        cost: cost,
        margin: running == 0 ? 0 : (running - cost) / running * 100,
      ));
    }
    return suggestions;
  }
}

class BouquetLine {
  final Product product;
  final int quantity;
  const BouquetLine({required this.product, required this.quantity});
}

class BouquetSuggestion {
  final List<BouquetLine> lines;
  final double total;
  final double cost;
  final double margin;
  const BouquetSuggestion({required this.lines, required this.total, required this.cost, required this.margin});
}
