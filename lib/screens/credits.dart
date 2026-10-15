import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/async_view.dart';
import '../widgets/count_up.dart';
import '../widgets/petal_field.dart';
import '../widgets/receipt.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});
  @override Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AsyncView<List<Sale>>(
        load: () => repo.outstandingSales(),
        builder: (ctx, sales, refresh) {
          final total = sales.fold<double>(0, (a, s) => a + s.balanceDue);
          final debtors = sales.map((s) => s.customerId).whereType<int>().toSet().length;
          return ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              const PageHeader(title: 'Credits & dues', subtitle: 'Outstanding balances, record settlements.'),
              _CreditsHero(total: total, debtors: debtors, bills: sales.length),
              const SizedBox(height: 14),
              if (sales.isEmpty) const EmptyState(icon: Icons.verified, message: 'All settled', hint: 'No outstanding dues right now.'),
              for (int i = 0; i < sales.length; i++)
                _CreditTile(sale: sales[i], refresh: refresh)
                  .animate(delay: (i.clamp(0, 10) * 25).ms).fadeIn(duration: 220.ms).slideY(begin: 0.08, end: 0),
            ],
          );
        },
      ),
    );
  }
}

class _CreditsHero extends StatelessWidget {
  final double total; final int debtors; final int bills;
  const _CreditsHero({required this.total, required this.debtors, required this.bills});
  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      height: 160,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(blurRadius: 22, color: AppColors.roseShadow, offset: Offset(0, 10))],
      ),
      child: Stack(children: [
        Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(22), child: const PetalField(count: 12, height: 160))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('TOTAL OUTSTANDING', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            CountUp(
              value: total,
              format: formatCurrency,
              style: GoogleFonts.fraunces(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Row(children: [
              _mini(Icons.people, 'Debtors', '$debtors'),
              const SizedBox(width: 8),
              _mini(Icons.receipt_long, 'Bills', '$bills'),
            ]),
          ]),
        ),
      ]),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }
  Widget _mini(IconData icon, String label, String value) => Expanded(child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Icon(icon, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
        Text(value, style: GoogleFonts.fraunces(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ]),
  ));
}

class _CreditTile extends StatelessWidget {
  final Sale sale; final VoidCallback refresh;
  const _CreditTile({required this.sale, required this.refresh});
  @override Widget build(BuildContext context) {
    final due = sale.balanceDue;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(blurRadius: 12, color: Color(0x0A000000), offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primaryBorder)),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sale.customer?.name ?? 'Walk-in', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Text('${formatDate(sale.date)} · #${padId(sale.id)}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(formatCurrency(due), style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
            Text('of ${formatCurrency(sale.total)}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ]),
        ]),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: sale.total == 0 ? 0 : (sale.amountPaid / sale.total).clamp(0, 1),
          backgroundColor: AppColors.primarySoft,
          color: AppColors.primary,
          minHeight: 6, borderRadius: BorderRadius.circular(999),
        ),
        const SizedBox(height: 10),
        Row(children: [
          OutlinedButton.icon(onPressed: () => showReceipt(context, sale), icon: const Icon(Icons.receipt, size: 16), label: const Text('Receipt')),
          const Spacer(),
          GradientButton(
            onPressed: () => _pay(context, sale, due, refresh),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.payments, size: 16), SizedBox(width: 6), Text('Pay now')]),
          ),
        ]),
      ]),
    );
  }

  Future<void> _pay(BuildContext ctx, Sale s, double due, VoidCallback refresh) async {
    final amount = TextEditingController(text: due.toStringAsFixed(due.truncateToDouble() == due ? 0 : 2));
    final go = await showDialog<bool>(context: ctx, builder: (c) => AlertDialog(
      title: const Text('Record payment'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${s.customer?.name ?? 'Walk-in'} · #${padId(s.id)}'),
        const SizedBox(height: 4),
        Text('Outstanding: ${formatCurrency(due)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 12),
        TextField(controller: amount, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount received (₹)')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Record'))],
    ));
    if (go != true) return;
    final amt = double.tryParse(amount.text.trim());
    if (amt == null || amt <= 0) { if (ctx.mounted) toast(ctx, 'Enter a positive amount', error: true); return; }
    if (amt > due + 0.005) { if (ctx.mounted) toast(ctx, 'Max is ${formatCurrency(due)}', error: true); return; }
    try { await repo.recordPayment(s.id, amt); if (ctx.mounted) toast(ctx, 'Payment recorded'); refresh(); }
    catch (e) { if (ctx.mounted) toast(ctx, '$e', error: true); }
  }
}
