import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/async_view.dart';
import '../widgets/count_up.dart';
import '../widgets/receipt.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});
  @override Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AsyncView<List<Sale>>(
        load: () => repo.sales(),
        builder: (ctx, sales, refresh) {
          final active = sales.where((s) => !s.isVoided);
          final total = active.fold<double>(0, (a, s) => a + s.total);
          final collected = active.fold<double>(0, (a, s) => a + s.amountPaid);
          final dues = active.fold<double>(0, (a, s) => a + s.balanceDue);
          return ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              const PageHeader(title: 'Sales ledger', subtitle: 'Every invoice, latest first.'),
              _SummaryHero(bills: active.length, total: total, collected: collected, dues: dues),
              const SizedBox(height: 10),
              if (sales.isEmpty) const EmptyState(icon: Icons.receipt_long, message: 'No sales yet.', hint: 'Create one from the Billing tab.'),
              for (int i = 0; i < sales.length; i++)
                _SaleTile(sale: sales[i], refresh: refresh)
                  .animate(delay: (i.clamp(0, 10) * 25).ms).fadeIn(duration: 220.ms).slideY(begin: 0.08, end: 0),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  final int bills; final double total, collected, dues;
  const _SummaryHero({required this.bills, required this.total, required this.collected, required this.dues});
  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(blurRadius: 20, color: AppColors.roseShadow, offset: Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.receipt_long, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text('$bills active bills', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 10),
        CountUp(
          value: total,
          format: formatCurrency,
          style: GoogleFonts.fraunces(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const Text('Gross revenue', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _mini('Collected', collected)),
          const SizedBox(width: 8),
          Expanded(child: _mini('Dues', dues)),
        ]),
      ]),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }
  Widget _mini(String label, double value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
      const SizedBox(height: 2),
      CountUp(value: value, format: formatCurrency, style: GoogleFonts.fraunces(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
    ]),
  );
}

class _SaleTile extends StatefulWidget {
  final Sale sale; final VoidCallback refresh;
  const _SaleTile({required this.sale, required this.refresh});
  @override State<_SaleTile> createState() => _SaleTileState();
}
class _SaleTileState extends State<_SaleTile> {
  bool open = false;
  @override Widget build(BuildContext context) {
    final s = widget.sale; final due = s.balanceDue;
    final itemsCount = s.items.fold<double>(0, (a, i) => a + i.quantity);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(blurRadius: 12, color: Color(0x0A000000), offset: Offset(0, 4))],
      ),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => open = !open),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: s.isVoided ? null : AppColors.primaryGradient,
                  color: s.isVoided ? AppColors.secondarySoft : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: s.isVoided ? null : const [BoxShadow(blurRadius: 10, color: AppColors.roseShadow, offset: Offset(0, 4))],
                ),
                child: Icon(s.isVoided ? Icons.block : Icons.receipt, color: s.isVoided ? AppColors.muted : Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(formatDate(s.date), style: TextStyle(fontWeight: FontWeight.w800, color: s.isVoided ? AppColors.muted : AppColors.foreground)),
                  const SizedBox(width: 6),
                  Text(formatTime(s.date), style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                ]),
                const SizedBox(height: 2),
                Text(s.customer?.name ?? 'Walk-in', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text('${itemsCount.toStringAsFixed(itemsCount.truncateToDouble() == itemsCount ? 0 : 1)} items · #${padId(s.id)}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formatCurrency(s.total), style: GoogleFonts.fraunces(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: s.isVoided ? AppColors.muted : AppColors.foreground,
                  decoration: s.isVoided ? TextDecoration.lineThrough : null,
                )),
                const SizedBox(height: 4),
                _statusBadge(s, due),
              ]),
            ]),
          ),
        ),
        if (open) Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Divider(height: 1),
            const SizedBox(height: 8),
            for (final it in s.items) Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(width: 30, child: Text('${it.quantity.toStringAsFixed(it.quantity.truncateToDouble() == it.quantity ? 0 : 1)}×', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800))),
                Expanded(child: Text(it.name)),
                Text(formatCurrency(it.total), style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
            ),
            if (s.notes != null && s.notes!.isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(s.notes!, style: const TextStyle(color: AppColors.muted, fontStyle: FontStyle.italic, fontSize: 12)),
            ),
            const SizedBox(height: 10),
            Row(children: [
              OutlinedButton.icon(onPressed: () => showReceipt(context, s), icon: const Icon(Icons.receipt, size: 18), label: const Text('Receipt')),
              const Spacer(),
              if (!s.isVoided) TextButton.icon(
                onPressed: () => _voidSale(context, s),
                icon: const Icon(Icons.block, color: AppColors.primary, size: 18),
                label: const Text('Void', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
              ),
            ]),
          ]),
        ).animate().fadeIn(duration: 180.ms).slideY(begin: -0.03, end: 0),
      ]),
    );
  }

  Widget _statusBadge(Sale s, double due) {
    if (s.isVoided) return const StatusChip(label: 'Voided', bg: AppColors.secondarySoft, fg: AppColors.muted, icon: Icons.block);
    if (due > 0.01) return StatusChip(label: 'Due ${formatCurrency(due)}', bg: AppColors.primarySoft, fg: AppColors.primary, icon: Icons.hourglass_bottom);
    return const StatusChip(label: 'Paid', bg: AppColors.secondarySoft, fg: AppColors.foreground, icon: Icons.check_circle_outline);
  }

  Future<void> _voidSale(BuildContext ctx, Sale s) async {
    final ctrl = TextEditingController();
    final go = await showDialog<bool>(context: ctx, builder: (c) => AlertDialog(
      title: Text('Void bill #${s.id}?'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Stock returns and the bill stops counting toward revenue. The bill itself is kept.'),
        const SizedBox(height: 12),
        TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Reason (optional)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Void')),
      ],
    ));
    if (go != true) return;
    try {
      await repo.voidSale(s.id, reason: ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
      if (!ctx.mounted) return;
      toast(ctx, 'Bill voided — stock returned');
      widget.refresh();
    } catch (e) { if (ctx.mounted) toast(ctx, '$e', error: true); }
  }
}
