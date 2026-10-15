import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'models.dart';

/// Thin PostgREST client. Mirrors how the web app's @supabase/postgrest-js
/// talks to the same REST endpoint.
class ApiException implements Exception {
  final String message; final int? status;
  ApiException(this.message, [this.status]);
  @override String toString() => message;
}

String _friendly(dynamic err) {
  if (err == null) return 'Something went wrong.';
  final raw = err.toString();
  if (raw.contains('Failed to fetch') || raw.contains('SocketException') || raw.contains('Network')) {
    return 'Could not reach the server. Check your internet.';
  }
  return raw.replaceFirst(RegExp(r'^[A-Z0-9]{5}:\s*'), '');
}

class SupabaseRest {
  SupabaseRest._();
  static final instance = SupabaseRest._();

  Map<String, String> get _headers => {
    'apikey': AppConfig.supabaseAnonKey,
    'Authorization': 'Bearer ${AppConfig.supabaseAnonKey}',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _uri(String path, [Map<String, String>? q]) =>
      Uri.parse('${AppConfig.restUrl}/$path').replace(queryParameters: q);

  Future<List<Map<String, dynamic>>> select(String table, {Map<String, String>? query}) async {
    final q = {'select': '*', ...?query};
    final r = await http.get(_uri(table, q), headers: _headers);
    _check(r);
    return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> insert(String table, Map<String, dynamic> row, {bool returning = true}) async {
    final r = await http.post(_uri(table, {'select': '*'}),
      headers: {..._headers, if (returning) 'Prefer': 'return=representation'},
      body: jsonEncode(row));
    _check(r);
    final list = (jsonDecode(r.body) as List);
    return (list.first as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>?> update(String table, Map<String, dynamic> row, {required String match}) async {
    final parts = match.split('=');
    final r = await http.patch(_uri(table, {parts[0]: 'eq.${parts[1]}', 'select': '*'}),
      headers: {..._headers, 'Prefer': 'return=representation'}, body: jsonEncode(row));
    _check(r);
    final list = (jsonDecode(r.body) as List);
    if (list.isEmpty) return null;
    return (list.first as Map).cast<String, dynamic>();
  }

  Future<void> delete(String table, {required String match}) async {
    final parts = match.split('=');
    final r = await http.delete(_uri(table, {parts[0]: 'eq.${parts[1]}'}), headers: _headers);
    _check(r);
  }

  Future<dynamic> rpc(String name, Map<String, dynamic> args) async {
    final r = await http.post(_uri('rpc/$name'), headers: _headers, body: jsonEncode(args));
    _check(r);
    if (r.body.isEmpty) return null;
    return jsonDecode(r.body);
  }

  void _check(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    String msg = r.body;
    try {
      final j = jsonDecode(r.body);
      if (j is Map && j['message'] != null) msg = j['message'].toString();
    } catch (_) {}
    throw ApiException(_friendly(msg), r.statusCode);
  }
}

/// High-level repository matching src/api in the web app.
class Repo {
  final _api = SupabaseRest.instance;

  // ---- Products ----
  Future<List<Product>> products() async {
    final rows = await _api.select('products', query: {'archived_at': 'is.null', 'order': 'name,variety'});
    return rows.map(Product.fromJson).toList();
  }
  Future<Product> createProduct(Map<String, dynamic> input) async {
    final r = await _api.insert('products', input);
    return Product.fromJson(r);
  }
  Future<Product> updateProduct(int id, Map<String, dynamic> input) async {
    final r = await _api.update('products', input, match: 'id=$id');
    return Product.fromJson(r!);
  }
  Future<void> archiveProduct(int id) async {
    await _api.update('products', {'archived_at': DateTime.now().toUtc().toIso8601String()}, match: 'id=$id');
  }
  Future<List<RecipeRow>> recipes() async {
    final rows = await _api.select('bouquet_recipes');
    return rows.map(RecipeRow.fromJson).toList();
  }
  Future<void> saveRecipe(int bouquetId, List<Map<String, dynamic>> rows) async {
    await _api.delete('bouquet_recipes', match: 'bouquet_id=$bouquetId');
    for (final r in rows) {
      await _api.insert('bouquet_recipes', {...r, 'bouquet_id': bouquetId}, returning: false);
    }
  }
  Future<List<BouquetAvailability>> bouquetAvailability() async {
    final rows = await _api.select('v_bouquet_availability');
    return rows.map(BouquetAvailability.fromJson).toList();
  }

  // ---- Customers ----
  Future<List<Customer>> customers() async {
    final rows = await _api.select('customers', query: {'archived_at': 'is.null', 'order': 'name'});
    return rows.map(Customer.fromJson).toList();
  }
  Future<Customer> createCustomer(Map<String, dynamic> input) async {
    return Customer.fromJson(await _api.insert('customers', input));
  }
  Future<Customer> updateCustomer(int id, Map<String, dynamic> input) async {
    return Customer.fromJson((await _api.update('customers', input, match: 'id=$id'))!);
  }
  Future<void> archiveCustomer(int id) async {
    await _api.update('customers', {'archived_at': DateTime.now().toUtc().toIso8601String()}, match: 'id=$id');
  }

  // ---- Sales ----
  static const _saleSelect = '*,customers(name,phone),sale_items(*,sale_item_components(*))';
  Future<List<Sale>> sales({int limit = 500}) async {
    final rows = await _api.select('sales',
      query: {'select': _saleSelect, 'order': 'date.desc', 'limit': '$limit'});
    return rows.map(Sale.fromJson).toList();
  }
  Future<List<Sale>> outstandingSales() async {
    final rows = await _api.select('sales',
      query: {'select': _saleSelect, 'balance_due': 'gt.0.005', 'voided_at': 'is.null', 'order': 'date.desc'});
    return rows.map(Sale.fromJson).toList();
  }
  Future<List<Sale>> customerSales(int customerId) async {
    final rows = await _api.select('sales',
      query: {'select': _saleSelect, 'customer_id': 'eq.$customerId', 'order': 'date.desc'});
    return rows.map(Sale.fromJson).toList();
  }
  Future<Sale> createSale({required int? customerId, required List<CreateSaleItem> items,
      required double total, required double amountPaid, String? notes}) async {
    final r = await _api.rpc('create_sale', {
      'p_customer_id': customerId, 'p_items': items.map((i) => i.toJson()).toList(),
      'p_total': total, 'p_amount_paid': amountPaid, 'p_notes': notes,
    });
    return Sale.fromJson(Map<String, dynamic>.from(r as Map));
  }
  Future<Sale> recordPayment(int saleId, double amount) async {
    final r = await _api.rpc('record_payment', {'p_sale_id': saleId, 'p_amount': amount});
    return Sale.fromJson(Map<String, dynamic>.from(r as Map));
  }
  Future<Sale> voidSale(int saleId, {String? reason}) async {
    final r = await _api.rpc('void_sale', {'p_sale_id': saleId, 'p_reason': reason});
    return Sale.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // ---- Analytics ----
  Future<DashboardData> dashboard() async {
    final r = await _api.rpc('get_dashboard', {});
    return DashboardData.fromJson(Map<String, dynamic>.from(r as Map));
  }
  Future<List<DailyRow>> dailySales() async =>
      (await _api.select('v_daily_sales')).map(DailyRow.fromJson).toList();
  Future<List<MonthlyRow>> monthlySales() async =>
      (await _api.select('v_monthly_sales')).map(MonthlyRow.fromJson).toList();
  Future<List<TopProduct>> topProducts() async =>
      (await _api.select('v_top_products')).map(TopProduct.fromJson).toList();
  Future<List<MarginRow>> profitMargins() async =>
      (await _api.select('v_profit_margins')).map(MarginRow.fromJson).toList();
}

final repo = Repo();

/// Lightweight listenable cache so screens can share results without a heavy
/// state-management lib.
class Loader<T> extends ChangeNotifier {
  T? data; Object? error; bool loading = false;
  final Future<T> Function() _fetch;
  Loader(this._fetch);
  Future<void> load({bool force = false}) async {
    if (loading) return;
    if (data != null && !force) return;
    loading = true; error = null; notifyListeners();
    try { data = await _fetch(); }
    catch (e) { error = e; }
    finally { loading = false; notifyListeners(); }
  }
  Future<void> refresh() => load(force: true);
}
