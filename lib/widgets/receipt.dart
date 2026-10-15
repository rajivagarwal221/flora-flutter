import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models.dart';
import '../theme.dart';
import '../utils.dart';

Future<void> showReceipt(BuildContext ctx, Sale sale) => showModalBottomSheet(
  context: ctx, isScrollControlled: true, showDragHandle: true, useSafeArea: true,
  builder: (c) => ReceiptSheet(sale: sale),
);

class ReceiptSheet extends StatelessWidget {
  final Sale sale;
  const ReceiptSheet({super.key, required this.sale});
  @override Widget build(BuildContext context) {
    final due = sale.balanceDue;
    return DraggableScrollableSheet(
      initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.96, expand: false,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(blurRadius: 24, color: AppColors.roseShadow, offset: Offset(0, 10))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.receipt_long, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Bill #${padId(sale.id)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (sale.isVoided) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                    child: const Text('VOIDED', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(formatDate(sale.date), style: const TextStyle(color: Colors.white70)),
                if (sale.customer != null) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(children: [
                    const Icon(Icons.person, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(sale.customer!.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    if (sale.customer!.phone.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 8), child: Text(sale.customer!.phone, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final it in sale.items) Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      SizedBox(width: 32, child: Text('${_qty(it.quantity)}×', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800))),
                      Expanded(child: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text(formatCurrency(it.total), style: const TextStyle(fontWeight: FontWeight.w800)),
                    ]),
                    for (final c in it.components) Padding(
                      padding: const EdgeInsets.only(left: 32, top: 2),
                      child: Text('— ${_qty(c.quantity)} ${c.name}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ),
                  ]),
                ),
                const Divider(height: 24),
                _row('Total', formatCurrency(sale.total), bold: true, large: true),
                _row('Paid', formatCurrency(sale.amountPaid)),
                if (due > 0.005) _row('Balance due', formatCurrency(due), danger: true, bold: true),
                if (sale.notes != null && sale.notes!.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(sale.notes!, style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.muted)),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), label: const Text('Close'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: () => _printPdf(sale), icon: const Icon(Icons.print), label: const Text('Print'))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _shareText(sale), icon: const Icon(Icons.share), label: const Text('Share'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(
                onPressed: sale.customer == null && sale.customer?.phone == null ? null : () => _shareWhatsApp(context, sale),
                icon: const Icon(Icons.chat_bubble), label: const Text('WhatsApp'),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, bool large = false, bool danger = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: danger ? AppColors.primary : AppColors.muted, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: large ? 16 : 14)),
      Text(value, style: TextStyle(color: danger ? AppColors.primary : AppColors.foreground, fontWeight: FontWeight.w800, fontSize: large ? 22 : 14)),
    ]),
  );
}

String _qty(num n) => (n.toInt() == n ? n.toInt() : n).toString();

String _plainTextReceipt(Sale sale) {
  final b = StringBuffer();
  b.writeln('Flora — Bill #${padId(sale.id)}');
  b.writeln(formatDate(sale.date));
  if (sale.customer != null) b.writeln('Customer: ${sale.customer!.name}');
  b.writeln('');
  for (final it in sale.items) {
    b.writeln('${_qty(it.quantity)}× ${it.name} — ${formatCurrency(it.total)}');
  }
  b.writeln('');
  b.writeln('Total: ${formatCurrency(sale.total)}');
  b.writeln('Paid:  ${formatCurrency(sale.amountPaid)}');
  if (sale.balanceDue > 0.005) b.writeln('Balance due: ${formatCurrency(sale.balanceDue)}');
  b.writeln('');
  b.writeln('Thank you for your order!');
  return b.toString();
}

Future<void> _shareText(Sale sale) async {
  await Share.share(_plainTextReceipt(sale), subject: 'Bill #${padId(sale.id)}');
}

Future<void> _shareWhatsApp(BuildContext ctx, Sale sale) async {
  final phoneRaw = sale.customer?.phone ?? '';
  final digits = phoneRaw.replaceAll(RegExp(r'\D'), '');
  final phone = digits.length == 10 ? '91$digits' : digits;
  final text = Uri.encodeComponent(_plainTextReceipt(sale));
  final uri = Uri.parse(phone.isEmpty ? 'https://wa.me/?text=$text' : 'https://wa.me/$phone?text=$text');
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && ctx.mounted) toast(ctx, 'Could not open WhatsApp', error: true);
}

Future<void> _printPdf(Sale sale) async {
  final doc = pw.Document();
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a5,
    build: (c) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Flora — Flower Shop Management App', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFD93B68))),
      pw.SizedBox(height: 2),
      pw.Text('Bill #${padId(sale.id)}  ·  ${formatDate(sale.date)}', style: const pw.TextStyle(color: PdfColors.grey700)),
      if (sale.customer != null) ...[
        pw.SizedBox(height: 10),
        pw.Text(sale.customer!.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        if (sale.customer!.phone.isNotEmpty) pw.Text(sale.customer!.phone, style: const pw.TextStyle(color: PdfColors.grey700)),
      ],
      pw.SizedBox(height: 14),
      pw.Divider(),
      pw.Table(
        columnWidths: const {0: pw.FlexColumnWidth(0.6), 1: pw.FlexColumnWidth(3), 2: pw.FlexColumnWidth(1.2)},
        children: [
          for (final it in sale.items) pw.TableRow(children: [
            pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 3), child: pw.Text('${_qty(it.quantity)}x')),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 3), child: pw.Text(it.name)),
            pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 3), child: pw.Text(formatCurrency(it.total), textAlign: pw.TextAlign.right)),
          ]),
        ],
      ),
      pw.Divider(),
      pw.Align(alignment: pw.Alignment.centerRight, child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        pw.Text('Total: ${formatCurrency(sale.total)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.Text('Paid: ${formatCurrency(sale.amountPaid)}'),
        if (sale.balanceDue > 0.005) pw.Text('Balance due: ${formatCurrency(sale.balanceDue)}', style: pw.TextStyle(color: PdfColors.red, fontWeight: pw.FontWeight.bold)),
      ])),
      pw.SizedBox(height: 16),
      pw.Text('Thank you for your order!', style: const pw.TextStyle(color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
    ]),
  ));
  await Printing.layoutPdf(onLayout: (fmt) async => doc.save());
}
