import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// Simple shop-floor calculator presented as a bottom sheet.
Future<void> showCalculator(BuildContext ctx) => showModalBottomSheet(
  context: ctx, showDragHandle: true, isScrollControlled: true,
  builder: (_) => const _Calculator(),
);

class _Calculator extends StatefulWidget {
  const _Calculator();
  @override State<_Calculator> createState() => _CalculatorState();
}
class _CalculatorState extends State<_Calculator> {
  String _expr = '';
  String _result = '0';

  void _tap(String v) {
    HapticFeedback.selectionClick();
    setState(() {
      if (v == 'C') { _expr = ''; _result = '0'; return; }
      if (v == '⌫') { if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1); _eval(); return; }
      if (v == '=') { _eval(); return; }
      _expr += v; _eval();
    });
  }

  void _eval() {
    if (_expr.trim().isEmpty) { _result = '0'; return; }
    try { _result = _compute(_expr).toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), ''); }
    catch (_) { _result = '…'; }
  }

  double _compute(String src) {
    final tokens = <String>[]; int i = 0;
    while (i < src.length) {
      final c = src[i];
      if ('+-×÷*/'.contains(c)) { tokens.add(c == '×' ? '*' : c == '÷' ? '/' : c); i++; continue; }
      final start = i;
      while (i < src.length && !'+-×÷*/'.contains(src[i])) { i++; }
      tokens.add(src.substring(start, i));
    }
    if (tokens.isEmpty) return 0;
    // Pass 1: * /
    final p1 = <String>[tokens.first];
    for (int k = 1; k < tokens.length; k += 2) {
      final op = tokens[k]; final b = tokens[k + 1];
      if (op == '*' || op == '/') {
        final a = double.parse(p1.removeLast());
        final bn = double.parse(b);
        p1.add((op == '*' ? a * bn : a / bn).toString());
      } else { p1.add(op); p1.add(b); }
    }
    // Pass 2: + -
    double acc = double.parse(p1.first);
    for (int k = 1; k < p1.length; k += 2) {
      final op = p1[k]; final b = double.parse(p1[k + 1]);
      acc = op == '+' ? acc + b : acc - b;
    }
    return acc;
  }

  @override Widget build(BuildContext context) {
    const btns = [
      ['C', '⌫', '÷', '×'],
      ['7', '8', '9', '-'],
      ['4', '5', '6', '+'],
      ['1', '2', '3', '='],
      ['0', '00', '.', '='],
    ];
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 4, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.secondarySoft, borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.centerRight,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_expr.isEmpty ? ' ' : _expr, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
            const SizedBox(height: 4),
            Text('₹$_result', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ]),
        ),
        const SizedBox(height: 10),
        for (final row in btns) Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            for (final key in row) Expanded(child: Padding(
              padding: const EdgeInsets.all(3),
              child: Material(
                color: _isOp(key) ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _tap(key),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14)),
                    child: Text(key, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: _isOp(key) ? Colors.white : AppColors.foreground)),
                  ),
                ),
              ),
            )),
          ]),
        ),
      ]),
    );
  }
  bool _isOp(String k) => '+-×÷='.contains(k);
}
