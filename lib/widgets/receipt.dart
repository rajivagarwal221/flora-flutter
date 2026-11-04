import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              Expanded(child: OutlinedButton.icon(onPressed: () => _shareText(context, sale), icon: const Icon(Icons.share), label: const Text('Share'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton.icon(
                onPressed: (sale.customer?.phone ?? '').isEmpty ? null : () => _shareWhatsApp(context, sale),
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

Future<void> _shareText(BuildContext ctx, Sale sale) async {
  final text = _plainTextReceipt(sale);
  final subject = 'Bill #${padId(sale.id)}';
  if (kIsWeb) {
    // The web Share API no-ops on desktop Chrome with no share target;
    // copying to clipboard is the reliable fallback.
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (ctx.mounted) toast(ctx, 'Receipt copied to clipboard');
      return;
    } catch (_) { /* fall through to native share */ }
  }
  try {
    final result = await Share.share(text, subject: subject);
    if (result.status == ShareResultStatus.unavailable && ctx.mounted) {
      await Clipboard.setData(ClipboardData(text: text));
      if (ctx.mounted) toast(ctx, 'Receipt copied to clipboard');
    }
  } catch (e) {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (ctx.mounted) toast(ctx, 'Receipt copied to clipboard');
    } catch (_) {
      if (ctx.mounted) toast(ctx, 'Could not share: $e', error: true);
    }
  }
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

const _shopPhone = '9136018065';
const _shopTagline = 'Fresh Flowers, Bouquets & Gifting';

String _rupee(num n) {
  // Use "Rs." prefix instead of ₹ so the PDF renders correctly with the
  // bundled font set (no Unicode glyph gaps). The in-app UI still shows ₹.
  final hasPaise = (n.toDouble() * 100 - (n.toDouble() * 100).round()).abs() > 0.5
      || ((n.toDouble() * 100).round() % 100) != 0;
  final s = hasPaise ? n.toStringAsFixed(2) : n.toStringAsFixed(0);
  // Indian thousands grouping: 3,66,000
  final parts = s.split('.');
  final intPart = parts[0];
  final neg = intPart.startsWith('-');
  final digits = neg ? intPart.substring(1) : intPart;
  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final last3 = digits.substring(digits.length - 3);
    final rest = digits.substring(0, digits.length - 3);
    final buf = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      final fromEnd = rest.length - i;
      buf.write(rest[i]);
      if (fromEnd > 1 && fromEnd.isOdd) buf.write(',');
    }
    grouped = '$buf,$last3';
  }
  final body = parts.length == 2 ? '$grouped.${parts[1]}' : grouped;
  return 'Rs. ${neg ? "-" : ""}$body';
}

String _receiptDateTime(String iso) {
  try {
    final d = DateTime.parse(iso).toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    int h = d.hour;
    final suffix = h >= 12 ? 'pm' : 'am';
    h = h % 12 == 0 ? 12 : h % 12;
    final mm = d.minute.toString().padLeft(2, '0');
    final ss = d.second.toString().padLeft(2, '0');
    return '$day/$month/$year, $h:$mm:$ss $suffix';
  } catch (_) { return iso; }
}

pw.Widget _dashedDivider() => pw.Container(
  height: 1,
  child: pw.CustomPaint(
    size: const PdfPoint(double.infinity, 1),
    painter: (canvas, size) {
      const dash = 3.0, gap = 2.5;
      canvas.setStrokeColor(PdfColors.grey600);
      canvas.setLineWidth(0.5);
      double x = 0;
      while (x < size.x) {
        canvas.drawLine(x, 0.5, (x + dash).clamp(0, size.x).toDouble(), 0.5);
        x += dash + gap;
      }
      canvas.strokePath();
    },
  ),
);

Future<void> _printPdf(Sale sale) async {
  final doc = pw.Document();
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 32),
    build: (c) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
      // ---------- Header (centered) ----------
      pw.Center(child: pw.Text('FLORA', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 4),
      pw.Center(child: pw.Text(_shopTagline, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))),
      pw.Center(child: pw.Text('Phone: $_shopPhone', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))),
      pw.SizedBox(height: 10),
      _dashedDivider(),
      pw.SizedBox(height: 10),
      // ---------- Receipt metadata ----------
      pw.Center(child: pw.Text('RECEIPT #${padId(sale.id)}', style: const pw.TextStyle(fontSize: 11))),
      pw.SizedBox(height: 2),
      pw.Center(child: pw.Text(_receiptDateTime(sale.date), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))),
      pw.SizedBox(height: 10),
      _dashedDivider(),
      pw.SizedBox(height: 12),
      // ---------- Customer block ----------
      pw.Text('CUSTOMER', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700, letterSpacing: 1)),
      pw.SizedBox(height: 4),
      pw.Text(
        sale.customer?.name ?? 'Walk-in Customer',
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
      if ((sale.customer?.phone ?? '').isNotEmpty)
        pw.Text(sale.customer!.phone, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      pw.SizedBox(height: 16),
      // ---------- Items table ----------
      pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(3.5),
          1: pw.FlexColumnWidth(0.8),
          2: pw.FlexColumnWidth(1.5),
          3: pw.FlexColumnWidth(1.5),
        },
        border: pw.TableBorder(
          top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
          horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            children: [
              _cell('Item', bold: true, align: pw.TextAlign.left),
              _cell('Qty', bold: true, align: pw.TextAlign.center),
              _cell('Price', bold: true, align: pw.TextAlign.right),
              _cell('Total', bold: true, align: pw.TextAlign.right),
            ],
          ),
          for (final it in sale.items) pw.TableRow(children: [
            _cell(it.name, align: pw.TextAlign.left),
            _cell(_qty(it.quantity), align: pw.TextAlign.center),
            _cell(_rupee(it.price), align: pw.TextAlign.right),
            _cell(_rupee(it.total), align: pw.TextAlign.right, bold: true),
          ]),
        ],
      ),
      pw.SizedBox(height: 14),
      // ---------- Grand total ----------
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('GRAND TOTAL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.Text(_rupee(sale.total), style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      ]),
      if (sale.amountPaid < sale.total - 0.005 || sale.amountPaid > sale.total + 0.005) ...[
        pw.SizedBox(height: 6),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Paid', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(_rupee(sale.amountPaid), style: const pw.TextStyle(fontSize: 10)),
        ]),
      ],
      if (sale.balanceDue > 0.005) ...[
        pw.SizedBox(height: 4),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Balance Due', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
          pw.Text(_rupee(sale.balanceDue), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
        ]),
      ],
      pw.SizedBox(height: 28),
      // ---------- Footer ----------
      pw.Center(child: pw.Text('Thank you for your order!',
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, fontStyle: pw.FontStyle.italic))),
      pw.SizedBox(height: 2),
      pw.Center(child: pw.Text('Please visit again',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic))),
    ]),
  ));
  await Printing.layoutPdf(
    onLayout: (fmt) async => doc.save(),
    name: 'Flora - Bill #${padId(sale.id)}',
  );
}

pw.Widget _cell(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
  child: pw.Text(text,
    textAlign: align,
    style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
);
