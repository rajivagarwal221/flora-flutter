import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'data/models.dart';

final _rupee = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
final _rupeeNoDec = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _int = NumberFormat.decimalPattern('en_IN');

String formatCurrency(num amount) {
  final n = amount.toDouble();
  final hasPaise = (n * 100 - (n * 100).round()).abs() > 0.5 || ((n * 100).round() % 100) != 0;
  return hasPaise ? _rupee.format(n) : _rupeeNoDec.format(n);
}

String formatCompactCurrency(num amount) {
  final n = amount.toDouble();
  final absN = n.abs();
  if (absN >= 10000000) {
    final cr = n / 10000000;
    return '₹${cr.toStringAsFixed(cr % 1 == 0 ? 0 : 1)}Cr';
  }
  if (absN >= 100000) {
    final lk = n / 100000;
    return '₹${lk.toStringAsFixed(lk % 1 == 0 ? 0 : 1)}L';
  }
  if (absN >= 1000) {
    final k = n / 1000;
    return '₹${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k';
  }
  return '₹${n.round()}';
}

String formatChartDate(String iso) {
  if (iso.length >= 10) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('d MMM').format(dt);
    } catch (_) {}
  }
  if (iso.length > 5) return iso.substring(5);
  return iso;
}

String formatChartMonth(String iso) {
  if (iso.length >= 7) {
    try {
      final parts = iso.split('-');
      if (parts.length >= 2) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        if (year != null && month != null) {
          final dt = DateTime(year, month);
          return DateFormat('MMM').format(dt);
        }
      }
    } catch (_) {}
  }
  if (iso.length > 2) return iso.substring(2);
  return iso;
}

String formatNumber(num n) => _int.format(n);

String formatDate(String iso) {
  if (iso.isEmpty) return '';
  try {
    final d = DateTime.parse(iso).toLocal();
    return DateFormat('d MMM y').format(d);
  } catch (_) { return iso; }
}

String formatTime(String iso) {
  try {
    final d = DateTime.parse(iso).toLocal();
    return DateFormat('HH:mm').format(d);
  } catch (_) { return ''; }
}

String displayName(dynamic p) {
  final name = p.name as String? ?? '';
  final variety = p.variety as String? ?? '';
  return variety.isEmpty ? name : '$name · $variety';
}

String padId(int id) => id.toString().padLeft(6, '0');

String shortageText(List<Shortage> shortages) {
  if (shortages.isEmpty) return '';
  return 'Short: ${shortages.map((s) => '${s.name} (need ${s.need.toStringAsFixed(0)}, have ${s.have.toStringAsFixed(0)})').join(', ')}';
}

void toast(BuildContext ctx, String msg, {bool error = false}) {
  ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: error ? const Color(0xFFD93B68) : null,
    duration: const Duration(seconds: 3),
  ));
}
