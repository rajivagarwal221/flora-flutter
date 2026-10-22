import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'analytics.dart';
import 'models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class Repo {
  FirebaseFirestore get db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');
  CollectionReference<Map<String, dynamic>> col(String name) =>
      db.collection(name);
  String get now => DateTime.now().toUtc().toIso8601String();
  double number(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
  Map<String, dynamic> row(DocumentSnapshot<Map<String, dynamic>> doc) =>
      {'id': int.tryParse(doc.id) ?? 0, ...?doc.data()};
  Future<List<Map<String, dynamic>>> rows(String name) async =>
      (await col(name).get()).docs.map(row).toList();
  Future<int> nextId(Transaction tx, String name) async {
    final ref = col('counters').doc(name);
    final next =
        (((await tx.get(ref)).data()?['value'] as num?)?.toInt() ?? 0) + 1;
    tx.set(ref, {'value': next});
    return next;
  }

  Future<List<Product>> allProducts() async =>
      (await rows('products')).map(Product.fromJson).toList();
  Future<List<Product>> products() async =>
      (await allProducts()).where((p) => p.archivedAt == null).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
  Future<Product> createProduct(Map<String, dynamic> input) async {
    final id = await db.runTransaction((tx) async {
      final id = await nextId(tx, 'products');
      tx.set(col('products').doc('$id'), {...input, 'created_at': now});
      final openingStock = number(input['stock']);
      if (openingStock > 0) {
        tx.set(col('stock_movements').doc(), {
          'product_id': id,
          'kind': 'received',
          'quantity': openingStock,
          'before': 0,
          'after': openingStock,
          'reason': 'Opening stock',
          'date': now,
        });
      }
      return id;
    });
    return Product.fromJson({'id': id, ...input, 'created_at': now});
  }

  Future<Product> updateProduct(int id, Map<String, dynamic> input) async {
    final ref = col('products').doc('$id');
    await db.runTransaction((tx) async {
      final old = (await tx.get(ref)).data();
      if (old == null) throw ApiException('Product not found.');
      final before = number(old['stock']);
      final after =
          input.containsKey('stock') ? number(input['stock']) : before;
      if (after < 0) throw ApiException('Stock cannot be negative.');
      tx.update(ref, input);
      if ((after - before).abs() > 0.0001) {
        tx.set(col('stock_movements').doc(), {
          'product_id': id,
          'kind': after > before ? 'received' : 'adjustment',
          'quantity': after - before,
          'before': before,
          'after': after,
          'reason': 'Product edit',
          'date': now
        });
      }
    });
    return Product.fromJson({'id': id, ...?(await ref.get()).data()});
  }

  Future<void> recordStockMovement(
      int productId, String kind, double quantity, String reason) async {
    if (!{'received', 'waste', 'adjustment'}.contains(kind) ||
        quantity == 0 ||
        (kind != 'adjustment' && quantity < 0)) {
      throw ApiException('Invalid stock movement.');
    }
    final delta = kind == 'waste' ? -quantity : quantity;
    await db.runTransaction((tx) async {
      final ref = col('products').doc('$productId');
      final product = (await tx.get(ref)).data();
      if (product == null || product['archived_at'] != null) {
        throw ApiException('Product unavailable.');
      }
      final before = number(product['stock']);
      final after = before + delta;
      if (after < -0.0001) throw ApiException('Not enough stock.');
      tx.update(ref, {'stock': after});
      tx.set(col('stock_movements').doc(), {
        'product_id': productId,
        'kind': kind,
        'quantity': delta,
        'before': before,
        'after': after,
        'reason': reason,
        'date': now,
      });
    });
  }

  Future<List<Map<String, dynamic>>> stockMovements(int productId) async {
    final result = (await col('stock_movements')
            .where('product_id', isEqualTo: productId)
            .get())
        .docs
        .map((d) => d.data())
        .toList();
    result.sort((a, b) => '${b['date']}'.compareTo('${a['date']}'));
    return result;
  }

  Future<List<Map<String, dynamic>>> allStockMovements() async =>
      rows('stock_movements');

  Future<void> archiveProduct(int id) =>
      col('products').doc('$id').update({'archived_at': now});

  Future<List<RecipeRow>> recipes() async =>
      (await rows('bouquet_recipes')).map(RecipeRow.fromJson).toList();
  Future<void> saveRecipe(
      int bouquetId, List<Map<String, dynamic>> entries) async {
    final old = (await col('bouquet_recipes')
            .where('bouquet_id', isEqualTo: bouquetId)
            .get())
        .docs;
    final batch = db.batch();
    for (final doc in old) {
      batch.delete(doc.reference);
    }
    for (var i = 0; i < entries.length; i++) {
      batch.set(
          col('bouquet_recipes')
              .doc('${bouquetId}_${entries[i]['component_id']}'),
          {...entries[i], 'bouquet_id': bouquetId, 'id': i + 1});
    }
    await batch.commit();
  }

  Future<List<BouquetAvailability>> bouquetAvailability() async {
    final all = await products(), recipe = await recipes();
    final byId = {for (final p in all) p.id: p};
    return all.where((p) => p.category == Category.bouquet).map((bouquet) {
      var count = double.infinity;
      final shortages = <Shortage>[];
      for (final part in recipe.where((r) => r.bouquetId == bouquet.id)) {
        if (part.quantity <= 0) continue;
        final p = byId[part.componentId], have = p?.stock ?? 0;
        if (have < part.quantity) {
          shortages.add(Shortage(
              productId: part.componentId,
              name: p?.name ?? 'Missing product',
              need: part.quantity,
              have: have));
        }
        final possible = (have / part.quantity).floorToDouble();
        if (possible < count) count = possible;
      }
      return BouquetAvailability(
          bouquetId: bouquet.id,
          canMake: count.isFinite ? count : 0,
          shortages: shortages);
    }).toList();
  }

  Future<List<Customer>> customers() async => (await rows('customers'))
      .map(Customer.fromJson)
      .where((c) => c.archivedAt == null)
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  Future<Customer> createCustomer(Map<String, dynamic> input) async {
    final id = await db.runTransaction((tx) async {
      final id = await nextId(tx, 'customers');
      tx.set(col('customers').doc('$id'), {...input, 'created_at': now});
      return id;
    });
    return Customer.fromJson({'id': id, ...input, 'created_at': now});
  }

  Future<Customer> updateCustomer(int id, Map<String, dynamic> input) async {
    final ref = col('customers').doc('$id');
    await ref.update(input);
    return Customer.fromJson({'id': id, ...?(await ref.get()).data()});
  }

  Future<void> archiveCustomer(int id) =>
      col('customers').doc('$id').update({'archived_at': now});

  Future<List<Sale>> sales({int limit = 500}) async {
    final all = (await rows('sales')).map(Sale.fromJson).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return all.take(limit).toList();
  }

  Future<List<Sale>> reportSales(DateTime start, DateTime end) async =>
      (await sales(limit: 100000)).where((s) {
        final d = DateTime.tryParse(s.date)?.toLocal();
        return !s.isVoided &&
            d != null &&
            !d.isBefore(DateTime(start.year, start.month, start.day)) &&
            d.isBefore(DateTime(end.year, end.month, end.day + 1));
      }).toList();
  Future<List<Sale>> outstandingSales() async => (await sales(limit: 100000))
      .where((s) => !s.isVoided && s.balanceDue > 0.005)
      .toList();
  Future<List<Sale>> customerSales(int id) async =>
      (await sales(limit: 100000)).where((s) => s.customerId == id).toList();
  Future<double> overdueAmount(DateTime before) async =>
      (await outstandingSales())
          .where((s) => DateTime.tryParse(s.date)?.isBefore(before) ?? false)
          .fold<double>(0.0, (total, s) => total + s.balanceDue);

  Future<Sale> createSale(
      {required int? customerId,
      required List<CreateSaleItem> items,
      required double total,
      required double amountPaid,
      String? notes}) async {
    if (items.isEmpty ||
        total <= 0 ||
        amountPaid < 0 ||
        amountPaid > total + 0.005 ||
        (amountPaid < total - 0.005 && customerId == null)) {
      throw ApiException('Invalid bill or payment.');
    }
    // Resolve recipe components before the transaction; transaction reads stay before writes.
    final recipesByBouquet = <int, List<RecipeRow>>{};
    for (final r in await recipes()) {
      recipesByBouquet.putIfAbsent(r.bouquetId, () => []).add(r);
    }
    return db.runTransaction((tx) async {
      Map<String, dynamic>? customer;
      if (customerId != null) {
        customer = (await tx.get(col('customers').doc('$customerId'))).data();
        if (customer == null || customer['archived_at'] != null) {
          throw ApiException('Customer unavailable.');
        }
      }
      final needed = <int>{};
      for (final item in items) {
        if (item.productId != null) {
          needed.add(item.productId!);
          for (final part in recipesByBouquet[item.productId] ?? []) {
            needed.add(part.componentId);
          }
        }
        for (final c in item.components ?? []) {
          needed.add((c['product_id'] as num).toInt());
        }
      }
      final refs = {for (final id in needed) id: col('products').doc('$id')};
      final products = <int, Map<String, dynamic>>{};
      for (final e in refs.entries) {
        final value = (await tx.get(e.value)).data();
        if (value == null || value['archived_at'] != null) {
          throw ApiException('Product unavailable.');
        }
        products[e.key] = value;
      }
      final used = <int, double>{}, lines = <Map<String, dynamic>>[];
      for (var i = 0; i < items.length; i++) {
        final item = items[i],
            qty = number(items[i].quantity),
            price = number(items[i].price);
        if (qty <= 0 || price < 0) {
          throw ApiException('Invalid item quantity or price.');
        }
        final parts = <Map<String, dynamic>>[];
        var unitCost = 0.0;
        void consume(int componentId, double per) {
          if (per <= 0 || products[componentId] == null) {
            throw ApiException('Invalid component.');
          }
          used.update(componentId, (v) => v + per * qty,
              ifAbsent: () => per * qty);
          final p = products[componentId]!;
          unitCost += per * number(p['purchase_price']);
          parts.add({
            'id': parts.length + 1,
            'product_id': componentId,
            'name': p['name'],
            'quantity': per,
            'unit_cost': number(p['purchase_price'])
          });
        }

        if (item.kind == ItemKind.customBouquet) {
          for (final c in item.components ?? []) {
            consume((c['product_id'] as num).toInt(), number(c['quantity']));
          }
        } else {
          final product = products[item.productId];
          if (product == null) throw ApiException('Product unavailable.');
          final recipe = recipesByBouquet[item.productId] ?? [];
          if (recipe.isEmpty) {
            used.update(item.productId!, (v) => v + qty, ifAbsent: () => qty);
            unitCost = number(product['purchase_price']);
          } else {
            for (final r in recipe) {
              consume(r.componentId, r.quantity);
            }
          }
        }
        lines.add({
          'id': i + 1,
          'product_id': item.productId,
          'kind': item.kind == ItemKind.customBouquet
              ? 'custom_bouquet'
              : 'product',
          'name': item.name ?? products[item.productId]?['name'] ?? 'Item',
          'quantity': qty,
          'price': price,
          'total': qty * price,
          'unit_cost': unitCost,
          'sale_item_components': parts
        });
      }
      for (final e in used.entries) {
        final before = number(products[e.key]?['stock']);
        if (before + 0.0001 < e.value) {
          throw ApiException(
              'Insufficient stock for ${products[e.key]?['name']}.');
        }
      }
      final id = await nextId(tx, 'sales');
      for (final e in used.entries) {
        final before = number(products[e.key]?['stock']);
        tx.update(refs[e.key]!, {'stock': before - e.value});
        tx.set(col('stock_movements').doc(), {
          'product_id': e.key,
          'kind': 'sale',
          'quantity': -e.value,
          'before': before,
          'after': before - e.value,
          'sale_id': id,
          'date': now
        });
      }
      final invoice = {
        'id': id,
        'customer_id': customerId,
        'customers': customer == null
            ? null
            : {'name': customer['name'], 'phone': customer['phone']},
        'date': now,
        'notes': notes,
        'total': total,
        'amount_paid': amountPaid,
        'sale_items': lines,
        'voided_at': null,
        'void_reason': null
      };
      tx.set(col('sales').doc('$id'), invoice);
      return Sale.fromJson(invoice);
    });
  }

  Future<Sale> recordPayment(int saleId, double amount) async {
    if (amount <= 0) throw ApiException('Payment must be positive.');
    return db.runTransaction((tx) async {
      final ref = col('sales').doc('$saleId'),
          old = (await tx.get(col('sales').doc('$saleId'))).data();
      if (old == null || old['voided_at'] != null) {
        throw ApiException('Bill unavailable.');
      }
      final paid = number(old['amount_paid']) + amount;
      if (paid > number(old['total']) + 0.005) {
        throw ApiException('Payment exceeds balance.');
      }
      tx.update(ref, {'amount_paid': paid});
      tx.set(col('payments').doc(),
          {'sale_id': saleId, 'amount': amount, 'date': now});
      return Sale.fromJson({'id': saleId, ...old, 'amount_paid': paid});
    });
  }

  Future<Sale> voidSale(int saleId, {String? reason}) async =>
      db.runTransaction((tx) async {
        final ref = col('sales').doc('$saleId');
        final old = (await tx.get(ref)).data();
        if (old == null || old['voided_at'] != null) {
          throw ApiException('Bill unavailable.');
        }
        final restore = <int, double>{};
        for (final raw in old['sale_items'] as List? ?? []) {
          final item = Map<String, dynamic>.from(raw as Map),
              qty = number(raw['quantity']);
          final parts = item['sale_item_components'] as List? ?? [];
          if (parts.isNotEmpty) {
            for (final rawPart in parts) {
              final part = Map<String, dynamic>.from(rawPart as Map);
              final id = (part['product_id'] as num?)?.toInt();
              if (id != null) {
                restore.update(id, (v) => v + qty * number(part['quantity']),
                    ifAbsent: () => qty * number(part['quantity']));
              }
            }
          } else if (item['kind'] != 'custom_bouquet' &&
              item['product_id'] is num) {
            final id = (item['product_id'] as num).toInt();
            restore.update(id, (v) => v + qty, ifAbsent: () => qty);
          }
        }
        final refs = {
          for (final id in restore.keys) id: col('products').doc('$id')
        };
        final before = <int, double>{};
        for (final e in refs.entries) {
          before[e.key] = number((await tx.get(e.value)).data()?['stock']);
        }
        for (final e in restore.entries) {
          tx.update(refs[e.key]!, {'stock': before[e.key]! + e.value});
          tx.set(col('stock_movements').doc(), {
            'product_id': e.key,
            'kind': 'void',
            'quantity': e.value,
            'before': before[e.key],
            'after': before[e.key]! + e.value,
            'sale_id': saleId,
            'date': now
          });
        }
        final stamp = now;
        tx.update(ref, {'voided_at': stamp, 'void_reason': reason});
        return Sale.fromJson(
            {'id': saleId, ...old, 'voided_at': stamp, 'void_reason': reason});
      });

  Future<DashboardData> dashboard() async {
    final all = await products(),
        invoices =
            (await sales(limit: 100000)).where((s) => !s.isVoided).toList();
    final today = DateTime.now();
    bool sameDay(Sale s) {
      final d = DateTime.tryParse(s.date)?.toLocal();
      return d != null &&
          d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }

    bool sameMonth(Sale s) {
      final d = DateTime.tryParse(s.date)?.toLocal();
      return d != null && d.year == today.year && d.month == today.month;
    }

    final daily = invoices.where(sameDay), monthly = invoices.where(sameMonth);
    final report = ReportData.build(
        invoices, all, DateTime(today.year, today.month), today);
    return DashboardData(
        todayRevenue: daily.fold(0, (v, s) => v + s.total),
        todayStems:
            daily.expand((s) => s.items).fold(0, (v, i) => v + i.quantity),
        monthlyRevenue: monthly.fold(0, (v, s) => v + s.total),
        monthlyBouquets: monthly
            .expand((s) => s.items)
            .where((i) =>
                i.kind == ItemKind.customBouquet ||
                all.any((p) =>
                    p.id == i.productId && p.category == Category.bouquet))
            .fold(0, (v, i) => v + i.quantity),
        lowStock: all
            .where((p) => p.category != Category.bouquet && p.stock <= 20)
            .map((p) => DashboardLowStock(
                id: p.id,
                name: p.name,
                variety: p.variety,
                unit: p.unit,
                stock: p.stock))
            .toList(),
        starProduct: report.top.isEmpty
            ? null
            : DashboardStar(
                id: report.top.first.id,
                name: report.top.first.name,
                variety: report.top.first.variety,
                category: report.top.first.category,
                quantitySold: report.top.first.quantitySold,
                revenue: report.top.first.revenue),
        unavailableBouquets: const []);
  }

  Future<List<DailyRow>> dailySales() async {
    final end = DateTime.now(), start = end.subtract(const Duration(days: 30));
    return ReportData.build(
            await reportSales(start, end), await allProducts(), start, end)
        .daily;
  }

  Future<List<MonthlyRow>> monthlySales() async {
    final end = DateTime.now(), start = DateTime(end.year, end.month - 11);
    return ReportData.build(
            await reportSales(start, end), await allProducts(), start, end)
        .monthly;
  }

  Future<List<TopProduct>> topProducts() async {
    final end = DateTime.now(), start = DateTime(end.year, end.month);
    return ReportData.build(
            await reportSales(start, end), await allProducts(), start, end)
        .top;
  }

  Future<List<MarginRow>> profitMargins() async {
    final all = await products(),
        invoices = (await sales(limit: 100000)).where((s) => !s.isVoided);
    final totals = <int, List<double>>{};
    for (final item in invoices.expand((s) => s.items)) {
      if (item.productId == null) continue;
      final bucket = totals.putIfAbsent(item.productId!, () => [0, 0, 0]);
      bucket[0] += item.quantity;
      bucket[1] += item.total;
      bucket[2] += item.total - item.unitCost * item.quantity;
    }
    return all.map((p) {
      final values = totals[p.id] ?? [0, 0, 0],
          margin = p.sellingPrice - p.purchasePrice;
      return MarginRow(
          id: p.id,
          name: p.name,
          variety: p.variety,
          unit: p.unit,
          category: p.category,
          purchasePrice: p.purchasePrice,
          sellingPrice: p.sellingPrice,
          profitPerUnit: margin,
          profitMarginPercent:
              p.sellingPrice > 0 ? margin / p.sellingPrice * 100 : 0,
          totalUnitsSold: values[0],
          totalRevenue: values[1],
          totalProfit: values[2],
          stock: p.stock);
    }).toList();
  }
}

final repo = Repo();

class Loader<T> extends ChangeNotifier {
  T? data;
  Object? error;
  bool loading = false;
  final Future<T> Function() _fetch;
  Loader(this._fetch);
  Future<void> load({bool force = false}) async {
    if (loading || (data != null && !force)) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      data = await _fetch();
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(force: true);
}
