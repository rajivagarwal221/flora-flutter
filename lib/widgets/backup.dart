import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/api.dart';
import '../theme.dart';
import '../utils.dart';

/// Reads every table through the public API and bundles them into one JSON file
/// that the user can share, email or copy to another device.
Future<void> runBackup(BuildContext ctx) async {
  showDialog(context: ctx, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)));
  try {
    final products = await repo.products();
    final customers = await repo.customers();
    final recipes = await repo.recipes();
    final sales = await repo.sales(limit: 10000);
    final payload = {
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'app': 'Flora - Flower Shop Management App',
      'version': 1,
      'products': products.map((p) => {
        'id': p.id, 'name': p.name, 'variety': p.variety, 'unit': p.unit, 'category': p.category.name,
        'purchase_price': p.purchasePrice, 'selling_price': p.sellingPrice, 'stock': p.stock, 'supplier': p.supplier,
      }).toList(),
      'customers': customers.map((c) => {
        'id': c.id, 'name': c.name, 'phone': c.phone, 'business': c.business, 'address': c.address, 'notes': c.notes,
      }).toList(),
      'bouquet_recipes': recipes.map((r) => {'bouquet_id': r.bouquetId, 'component_id': r.componentId, 'quantity': r.quantity}).toList(),
      'sales': sales.map((s) => {
        'id': s.id, 'customer_id': s.customerId, 'total': s.total, 'amount_paid': s.amountPaid,
        'notes': s.notes, 'date': s.date, 'voided_at': s.voidedAt, 'void_reason': s.voidReason,
        'items': s.items.map((i) => {
          'name': i.name, 'kind': i.kind.name, 'quantity': i.quantity, 'price': i.price, 'total': i.total, 'unit_cost': i.unitCost,
          'components': i.components.map((c) => {'name': c.name, 'quantity': c.quantity, 'unit_cost': c.unitCost}).toList(),
        }).toList(),
      }).toList(),
    };
    final tmp = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${tmp.path}/flora_backup_$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    if (ctx.mounted) Navigator.pop(ctx);
    await Share.shareXFiles([XFile(file.path, mimeType: 'application/json')], text: 'Flora backup $stamp');
  } catch (e) {
    if (ctx.mounted) Navigator.pop(ctx);
    if (ctx.mounted) toast(ctx, '$e', error: true);
  }
}

/// Backup inspection is disabled on this build (file_picker removed).
Future<void> importBackup(BuildContext ctx) async {
  toast(ctx, 'Open the backup JSON on your computer or a text editor.');
}
