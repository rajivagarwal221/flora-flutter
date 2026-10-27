import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/async_view.dart';
import '../widgets/charts.dart';
import '../widgets/count_up.dart';
import '../widgets/petal_field.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AsyncView<(DashboardData, List<DailyRow>)>(
        load: () async => (await repo.dashboard(), await repo.dailySales()),
        builder: (ctx, data, refresh) {
          final d = data.$1;
          final daily = data.$2;
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _Hero(data: d),
              const SizedBox(height: 12),
              _StatGrid(d: d),
              const SizedBox(height: 16),
              const _AiInsightBanner(),
              const SizedBox(height: 14),
              _RevenueChartCard(daily: daily),
              const SizedBox(height: 16),
              if (d.starProduct != null) _StarCard(star: d.starProduct!),
              if (d.lowStock.isNotEmpty) _LowStockCard(items: d.lowStock),
              if (d.unavailableBouquets.isNotEmpty) _UnavailableCard(items: d.unavailableBouquets),
            ],
          );
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final DashboardData data;
  const _Hero({required this.data});
  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: 160,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(blurRadius: 24, offset: Offset(0, 10), color: AppColors.roseShadow)],
      ),
      child: Stack(children: [
        Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(24), child: const PetalField(count: 14, height: 160))),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ]),
              ),
              const Spacer(),
              const Icon(Icons.local_florist, color: Colors.white70, size: 20),
            ]),
            const Spacer(),
            Text('Good day,', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('Flora Studio', style: GoogleFonts.fraunces(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            Row(children: [
              CountUp(
                value: data.todayRevenue,
                format: formatCurrency,
                style: GoogleFonts.fraunces(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              const Text('today', style: TextStyle(color: Colors.white70)),
            ]),
          ]),
        ),
      ]),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }
}

class _StatGrid extends StatelessWidget {
  final DashboardData d;
  const _StatGrid({required this.d});
  @override Widget build(BuildContext context) {
    final cards = [
      (Icons.payments, "Today's Revenue", d.todayRevenue, true, true),
      (Icons.local_florist, 'Stems Today', d.todayStems, false, false),
      (Icons.trending_up, 'Monthly Revenue', d.monthlyRevenue, true, true),
      (Icons.card_giftcard, 'Bouquets / mo', d.monthlyBouquets, false, false),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          for (int i = 0; i < cards.length; i++)
            StatCard(
              icon: cards[i].$1, label: cards[i].$2, primary: cards[i].$4,
              value: CountUp(
                value: cards[i].$3,
                format: cards[i].$5 ? formatCurrency : (v) => formatNumber(v.round()),
                style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.foreground),
              ),
            ).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms).slideY(begin: 0.15, end: 0),
        ],
      ),
    );
  }
}

class _AiInsightBanner extends StatelessWidget {
  const _AiInsightBanner();
  @override Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.go('/insights'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primaryBorder),
              boxShadow: const [BoxShadow(blurRadius: 14, color: AppColors.roseShadow, offset: Offset(0, 6))],
            ),
            child: Row(children: [
              Container(width: 42, height: 42, decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI Insights', style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                const Text('Forecast · reorder suggestions · customer segments · bouquet designer',
                  style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
              ])),
              const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 16),
            ]),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 120.ms, duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

class _RevenueChartCard extends StatelessWidget {
  final List<DailyRow> daily;
  const _RevenueChartCard({required this.daily});
  @override Widget build(BuildContext context) {
    final rows = daily.take(30).toList();
    return StudioChartPanel(
      title: 'Revenue Overview',
      subtitle: '30-day continuous sales trajectory',
      accentColor: AppColors.primary,
      delay: 150,
      trailing: const StatusChip(
        label: 'Live',
        bg: AppColors.primarySoft,
        fg: AppColors.primary,
        icon: Icons.auto_awesome,
      ),
      child: StudioAreaChart(
        rows: rows,
        metric: (r) => r.revenue,
        metricName: 'Revenue',
        isCurrency: true,
      ),
    );
  }
}

class _StarCard extends StatelessWidget {
  final DashboardStar star;
  const _StarCard({required this.star});
  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primarySoft, Colors.white]),
        borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle,
            boxShadow: [BoxShadow(blurRadius: 14, color: AppColors.roseShadow, offset: Offset(0, 4))]),
          child: const Icon(Icons.star, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('BLOOM OF THE MONTH', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted, fontSize: 10, letterSpacing: 0.6)),
          const SizedBox(height: 2),
          Text(displayName(star), style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 2),
          Text('${formatNumber(star.quantitySold)} sold · ${formatCurrency(star.revenue)}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ])),
      ]),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }
}

class _LowStockCard extends StatelessWidget {
  final List<DashboardLowStock> items;
  const _LowStockCard({required this.items});
  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.warning_amber, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Low stock', style: GoogleFonts.fraunces(fontWeight: FontWeight.w800, fontSize: 16)),
          const Spacer(),
          TextButton(onPressed: () => context.go('/inventory'), child: const Text('Open stock')),
        ]),
        for (final it in items) Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(child: Text(displayName(it), style: const TextStyle(fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.all(Radius.circular(999))),
              child: Text('${it.stock.toStringAsFixed(0)} ${it.unit}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  final List<UnavailableBouquet> items;
  const _UnavailableCard({required this.items});
  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.card_giftcard, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Bouquets short on flowers', style: GoogleFonts.fraunces(fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        const SizedBox(height: 8),
        for (final b in items) Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(shortageText(b.shortages), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}
