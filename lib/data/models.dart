// Models mirror src/api/types.ts in the web app.

double _n(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
int _i(dynamic v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);
String _s(dynamic v) => v?.toString() ?? '';

enum Category { flower, bouquet, accessory;
  static Category parse(String? v) => Category.values.firstWhere((c) => c.name == v, orElse: () => Category.flower);
}

class Product {
  final int id;
  final String name, variety, unit, supplier, createdAt;
  final Category category;
  final double purchasePrice, sellingPrice, stock;
  final String? archivedAt;
  Product({required this.id, required this.name, required this.variety, required this.unit, required this.category,
    required this.purchasePrice, required this.sellingPrice, required this.stock, required this.supplier,
    required this.createdAt, this.archivedAt});
  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: _i(j['id']), name: _s(j['name']), variety: _s(j['variety']), unit: _s(j['unit']),
    category: Category.parse(j['category'] as String?),
    purchasePrice: _n(j['purchase_price']), sellingPrice: _n(j['selling_price']), stock: _n(j['stock']),
    supplier: _s(j['supplier']), createdAt: _s(j['created_at']), archivedAt: j['archived_at'] as String?,
  );
  Map<String, dynamic> toInput() => {
    'name': name, 'variety': variety, 'unit': unit, 'category': category.name,
    'purchase_price': purchasePrice, 'selling_price': sellingPrice, 'stock': stock, 'supplier': supplier,
  };
}

class Customer {
  final int id;
  final String name, phone, business, address, notes, createdAt;
  final String? archivedAt;
  Customer({required this.id, required this.name, required this.phone, required this.business,
    required this.address, required this.notes, required this.createdAt, this.archivedAt});
  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
    id: _i(j['id']), name: _s(j['name']), phone: _s(j['phone']), business: _s(j['business']),
    address: _s(j['address']), notes: _s(j['notes']), createdAt: _s(j['created_at']),
    archivedAt: j['archived_at'] as String?,
  );
  Map<String, dynamic> toInput() => {
    'name': name, 'phone': phone, 'business': business, 'address': address, 'notes': notes,
  };
}

class RecipeRow {
  final int id, bouquetId, componentId;
  final double quantity;
  RecipeRow({required this.id, required this.bouquetId, required this.componentId, required this.quantity});
  factory RecipeRow.fromJson(Map<String, dynamic> j) => RecipeRow(
    id: _i(j['id']), bouquetId: _i(j['bouquet_id']), componentId: _i(j['component_id']), quantity: _n(j['quantity']),
  );
}

class Shortage {
  final int productId; final String name; final double need, have;
  Shortage({required this.productId, required this.name, required this.need, required this.have});
  factory Shortage.fromJson(Map<String, dynamic> j) => Shortage(
    productId: _i(j['product_id']), name: _s(j['name']), need: _n(j['need']), have: _n(j['have']),
  );
}

class BouquetAvailability {
  final int bouquetId; final double canMake; final List<Shortage> shortages;
  BouquetAvailability({required this.bouquetId, required this.canMake, required this.shortages});
  factory BouquetAvailability.fromJson(Map<String, dynamic> j) => BouquetAvailability(
    bouquetId: _i(j['bouquet_id']), canMake: _n(j['can_make']),
    shortages: ((j['shortages'] as List?) ?? []).map((e) => Shortage.fromJson(Map<String, dynamic>.from(e))).toList(),
  );
}

class SaleComponent {
  final int id; final int? productId; final String name; final double quantity, unitCost;
  SaleComponent({required this.id, this.productId, required this.name, required this.quantity, required this.unitCost});
  factory SaleComponent.fromJson(Map<String, dynamic> j) => SaleComponent(
    id: _i(j['id']), productId: j['product_id'] == null ? null : _i(j['product_id']),
    name: _s(j['name']), quantity: _n(j['quantity']), unitCost: _n(j['unit_cost']),
  );
}

enum ItemKind { product, customBouquet;
  static ItemKind parse(String? v) => v == 'custom_bouquet' ? ItemKind.customBouquet : ItemKind.product;
}

class SaleItem {
  final int id; final int? productId; final String name; final ItemKind kind;
  final double quantity, price, total, unitCost;
  final List<SaleComponent> components;
  SaleItem({required this.id, this.productId, required this.name, required this.kind,
    required this.quantity, required this.price, required this.total, required this.unitCost,
    required this.components});
  factory SaleItem.fromJson(Map<String, dynamic> j) => SaleItem(
    id: _i(j['id']), productId: j['product_id'] == null ? null : _i(j['product_id']),
    name: _s(j['name']), kind: ItemKind.parse(j['kind'] as String?),
    quantity: _n(j['quantity']), price: _n(j['price']), total: _n(j['total']), unitCost: _n(j['unit_cost']),
    components: ((j['sale_item_components'] as List?) ?? [])
        .map((e) => SaleComponent.fromJson(Map<String, dynamic>.from(e))).toList(),
  );
}

class SaleCustomer { final String name, phone; SaleCustomer(this.name, this.phone); }

class Sale {
  final int id; final int? customerId;
  final double total, amountPaid;
  final String? notes; final String date;
  final String? voidedAt, voidReason;
  final SaleCustomer? customer;
  final List<SaleItem> items;
  Sale({required this.id, this.customerId, required this.total, required this.amountPaid,
    this.notes, required this.date, this.voidedAt, this.voidReason, this.customer, required this.items});
  double get balanceDue => total - amountPaid;
  bool get isVoided => voidedAt != null;
  factory Sale.fromJson(Map<String, dynamic> j) {
    final c = j['customers'];
    return Sale(
      id: _i(j['id']),
      customerId: j['customer_id'] == null ? null : _i(j['customer_id']),
      total: _n(j['total']), amountPaid: _n(j['amount_paid']),
      notes: j['notes'] as String?, date: _s(j['date']),
      voidedAt: j['voided_at'] as String?, voidReason: j['void_reason'] as String?,
      customer: c == null ? null : SaleCustomer(_s(c['name']), _s(c['phone'])),
      items: (((j['sale_items'] as List?) ?? []).map((e) => SaleItem.fromJson(Map<String, dynamic>.from(e))).toList()
        ..sort((a, b) => a.id.compareTo(b.id))),
    );
  }
}

/// Postgres `create_sale` wants quantity as an integer; serialize as int when whole.
num _wholeOrDouble(num v) => v is int || v == v.toInt() ? v.toInt() : v;

class CreateSaleItem {
  final ItemKind kind; final int? productId; final String? name;
  final num quantity, price;
  final List<Map<String, dynamic>>? components;
  CreateSaleItem({required this.kind, this.productId, this.name, required this.quantity, required this.price, this.components});
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    if (productId != null) 'product_id': productId,
    if (name != null) 'name': name,
    'quantity': _wholeOrDouble(quantity), 'price': price,
    if (components != null) 'components': components!.map((c) => {
      ...c,
      if (c['quantity'] is num) 'quantity': _wholeOrDouble(c['quantity'] as num),
    }).toList(),
  };
}

class DashboardLowStock { final int id; final String name, variety, unit; final double stock;
  DashboardLowStock({required this.id, required this.name, required this.variety, required this.unit, required this.stock});
  factory DashboardLowStock.fromJson(Map<String, dynamic> j) => DashboardLowStock(
    id: _i(j['id']), name: _s(j['name']), variety: _s(j['variety']), unit: _s(j['unit']), stock: _n(j['stock']),
  );
}

class DashboardStar { final int id; final String name, variety; final Category category; final double quantitySold, revenue;
  DashboardStar({required this.id, required this.name, required this.variety, required this.category, required this.quantitySold, required this.revenue});
  factory DashboardStar.fromJson(Map<String, dynamic> j) => DashboardStar(
    id: _i(j['id']), name: _s(j['name']), variety: _s(j['variety']),
    category: Category.parse(j['category'] as String?),
    quantitySold: _n(j['quantity_sold']), revenue: _n(j['revenue']),
  );
}

class UnavailableBouquet { final int id; final String name; final List<Shortage> shortages;
  UnavailableBouquet({required this.id, required this.name, required this.shortages});
  factory UnavailableBouquet.fromJson(Map<String, dynamic> j) => UnavailableBouquet(
    id: _i(j['id']), name: _s(j['name']),
    shortages: ((j['shortages'] as List?) ?? []).map((e) => Shortage.fromJson(Map<String, dynamic>.from(e))).toList(),
  );
}

class DashboardData {
  final double todayRevenue, todayStems, monthlyRevenue, monthlyBouquets;
  final List<DashboardLowStock> lowStock;
  final DashboardStar? starProduct;
  final List<UnavailableBouquet> unavailableBouquets;
  DashboardData({required this.todayRevenue, required this.todayStems, required this.monthlyRevenue, required this.monthlyBouquets,
    required this.lowStock, this.starProduct, required this.unavailableBouquets});
  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
    todayRevenue: _n(j['today_revenue']), todayStems: _n(j['today_stems']),
    monthlyRevenue: _n(j['monthly_revenue']), monthlyBouquets: _n(j['monthly_bouquets']),
    lowStock: ((j['low_stock'] as List?) ?? []).map((e) => DashboardLowStock.fromJson(Map<String, dynamic>.from(e))).toList(),
    starProduct: j['star_product'] == null ? null : DashboardStar.fromJson(Map<String, dynamic>.from(j['star_product'])),
    unavailableBouquets: ((j['unavailable_bouquets'] as List?) ?? []).map((e) => UnavailableBouquet.fromJson(Map<String, dynamic>.from(e))).toList(),
  );
}

class DailyRow { final String date; final double revenue, quantitySold, profit;
  DailyRow({required this.date, required this.revenue, required this.quantitySold, required this.profit});
  factory DailyRow.fromJson(Map<String, dynamic> j) => DailyRow(
    date: _s(j['date']), revenue: _n(j['revenue']), quantitySold: _n(j['quantity_sold']), profit: _n(j['profit']),
  );
}
class MonthlyRow { final String month; final double revenue, quantitySold, profit;
  MonthlyRow({required this.month, required this.revenue, required this.quantitySold, required this.profit});
  factory MonthlyRow.fromJson(Map<String, dynamic> j) => MonthlyRow(
    month: _s(j['month']), revenue: _n(j['revenue']), quantitySold: _n(j['quantity_sold']), profit: _n(j['profit']),
  );
}
class TopProduct { final int id; final String name, variety; final Category category; final double quantitySold, revenue;
  TopProduct({required this.id, required this.name, required this.variety, required this.category, required this.quantitySold, required this.revenue});
  factory TopProduct.fromJson(Map<String, dynamic> j) => TopProduct(
    id: _i(j['id']), name: _s(j['name']), variety: _s(j['variety']),
    category: Category.parse(j['category'] as String?),
    quantitySold: _n(j['quantity_sold']), revenue: _n(j['revenue']),
  );
}
class MarginRow {
  final int id; final String name, variety, unit; final Category category;
  final double purchasePrice, sellingPrice, profitPerUnit, profitMarginPercent, totalUnitsSold, totalRevenue, totalProfit, stock;
  MarginRow({required this.id, required this.name, required this.variety, required this.unit, required this.category,
    required this.purchasePrice, required this.sellingPrice, required this.profitPerUnit, required this.profitMarginPercent,
    required this.totalUnitsSold, required this.totalRevenue, required this.totalProfit, required this.stock});
  factory MarginRow.fromJson(Map<String, dynamic> j) => MarginRow(
    id: _i(j['id']), name: _s(j['name']), variety: _s(j['variety']), unit: _s(j['unit']),
    category: Category.parse(j['category'] as String?),
    purchasePrice: _n(j['purchase_price']), sellingPrice: _n(j['selling_price']),
    profitPerUnit: _n(j['profit_per_unit']), profitMarginPercent: _n(j['profit_margin_percent']),
    totalUnitsSold: _n(j['total_units_sold']), totalRevenue: _n(j['total_revenue']),
    totalProfit: _n(j['total_profit']), stock: _n(j['stock']),
  );
}
