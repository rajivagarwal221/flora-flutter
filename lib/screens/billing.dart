import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/async_view.dart';
import '../widgets/product_image.dart';
import '../widgets/receipt.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});
  @override State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);
  @override void dispose() { _tab.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return SafeArea(child: Column(children: [
      const PageHeader(title: 'Billing', subtitle: 'Pick items, generate bills, print or share.'),
      Material(color: Colors.white, child: TabBar(controller: _tab, tabs: const [
        Tab(icon: Icon(Icons.point_of_sale, size: 18), text: 'POS'),
        Tab(icon: Icon(Icons.flash_on, size: 18), text: 'Quick bill'),
        Tab(icon: Icon(Icons.history, size: 18), text: 'Today'),
      ])),
      Expanded(child: TabBarView(controller: _tab, children: const [
        _PosTab(), _QuickBillTab(), _TodayTab(),
      ])),
    ]));
  }
}

/* -------------------------  POS TAB  ------------------------- */

class _PosTab extends StatefulWidget {
  const _PosTab();
  @override State<_PosTab> createState() => _PosTabState();
}
class _PosTabState extends State<_PosTab> with AutomaticKeepAliveClientMixin {
  List<Product>? _products; List<Customer>? _customers;
  Map<int, BouquetAvailability> _avail = {};
  bool _loading = true; Object? _error;
  final List<_CartLine> _cart = []; Category? _filter; String _search = '';
  int? _customerId; double? _customTotal; double? _customPaid; bool _submitting = false;

  @override bool get wantKeepAlive => true;
  @override void initState() { super.initState(); _reload(); }

  Future<void> _reload() async {
    setState(() { _loading = true; _error = null; });
    try {
      final p = await repo.products(); final c = await repo.customers(); final a = await repo.bouquetAvailability();
      if (!mounted) return;
      setState(() { _products = p; _customers = c; _avail = {for (final x in a) x.bouquetId: x}; _loading = false; });
    } catch (e) { if (mounted) setState(() { _error = e; _loading = false; }); }
  }

  double _maxFor(Product p) => p.category == Category.bouquet ? (_avail[p.id]?.canMake ?? 0) : p.stock;
  double get _subtotal => _cart.fold(0, (a, l) => a + l.price * l.quantity);
  double get _total => _customTotal ?? _subtotal;
  double get _paid => _customPaid ?? _total;
  double get _due { final d = _total - _paid; return d > 0 ? d : 0; }
  int get _count => _cart.fold(0, (a, l) => a + l.quantity.toInt());

  void _addProduct(Product p) {
    final max = _maxFor(p); final key = 'p${p.id}';
    final existing = _cart.indexWhere((l) => l.key == key);
    if (existing >= 0) {
      if (_cart[existing].quantity + 1 > max) { toast(context, 'Only ${max.toStringAsFixed(0)} available'); return; }
      setState(() => _cart[existing].quantity += 1);
    } else {
      setState(() => _cart.add(_CartLine(key: key, kind: ItemKind.product, productId: p.id, name: displayName(p), price: p.sellingPrice, quantity: 1, maxQuantity: max)));
    }
  }
  void _changeQty(int i, int delta) {
    final l = _cart[i]; final q = l.quantity + delta;
    if (q < 1) return;
    if (l.maxQuantity != null && q > l.maxQuantity!) { toast(context, 'Only ${l.maxQuantity!.toStringAsFixed(0)} available'); return; }
    setState(() => l.quantity = q);
  }
  void _remove(int i) => setState(() => _cart.removeAt(i));
  void _clear() => setState(() { _cart.clear(); _customTotal = null; _customPaid = null; _customerId = null; });

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    if (_total <= 0) { toast(context, 'Total is zero', error: true); return; }
    if (_paid > _total + 0.005) { toast(context, 'Paid more than total', error: true); return; }
    if (_paid < _total - 0.005 && _customerId == null) { toast(context, 'Pick a customer for credit sales', error: true); return; }
    final items = _cart.map((l) => l.kind == ItemKind.product
      ? CreateSaleItem(kind: ItemKind.product, productId: l.productId, quantity: l.quantity.toDouble(), price: l.price)
      : CreateSaleItem(kind: ItemKind.customBouquet, name: l.name, quantity: l.quantity.toDouble(), price: l.price,
          components: l.components.map((c) => {'product_id': c.productId, 'quantity': c.quantity}).toList())).toList();
    setState(() => _submitting = true);
    try {
      final sale = await repo.createSale(customerId: _customerId, items: items, total: _total, amountPaid: _paid);
      if (!mounted) return;
      _clear(); toast(context, 'Bill #${sale.id} generated');
      await _reload();
      if (mounted) await showReceipt(context, sale);
    } catch (e) { if (mounted) toast(context, '$e', error: true); }
    finally { if (mounted) setState(() => _submitting = false); }
  }

  @override Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('$_error', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 12), ElevatedButton(onPressed: _reload, child: const Text('Retry')),
      ])));
    }
    final products = _products ?? [];
    final filtered = products.where((p) {
      if (_filter != null && p.category != _filter) return false;
      if (_search.isEmpty) return true;
      return displayName(p).toLowerCase().contains(_search);
    }).toList();
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 8), child: Row(children: [
        Expanded(child: TextField(onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search'))),
        const SizedBox(width: 8),
        OutlinedButton.icon(onPressed: _addCustom, icon: const Icon(Icons.auto_awesome, color: AppColors.primary), label: const Text('Custom')),
      ])),
      SizedBox(height: 40, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [_fchip('All', null), _fchip('Flowers', Category.flower), _fchip('Bouquets', Category.bouquet), _fchip('Accessories', Category.accessory)])),
      Expanded(child: filtered.isEmpty
        ? const EmptyState(icon: Icons.local_florist, message: 'No products found')
        : GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.3, mainAxisSpacing: 10, crossAxisSpacing: 10),
            itemCount: filtered.length,
            itemBuilder: (c, i) {
              final p = filtered[i]; final max = _maxFor(p); final disabled = max <= 0;
              final isBouquet = p.category == Category.bouquet;
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: disabled ? null : () => _addProduct(p),
                child: Opacity(opacity: disabled ? 0.5 : 1, child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x0A000000), offset: Offset(0, 4))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AspectRatio(aspectRatio: 1.3, child: ProductImage(product: p, size: 100, radius: 10)),
                    const SizedBox(height: 8),
                    Text(displayName(p), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Text(formatCurrency(p.sellingPrice), style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text(isBouquet ? (max > 0 ? 'Can make ${max.toStringAsFixed(0)}' : 'Short') : '${p.stock.toStringAsFixed(0)} ${p.unit} left',
                      style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                )),
              ).animate(delay: (i.clamp(0, 10) * 25).ms).fadeIn(duration: 220.ms).slideY(begin: 0.1, end: 0);
            },
          )),
      _buildCartBar(),
    ]);
  }

  Widget _fchip(String label, Category? cat) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(label: Text(label), selected: _filter == cat, onSelected: (_) => setState(() => _filter = cat),
      labelStyle: TextStyle(color: _filter == cat ? Colors.white : AppColors.foreground, fontWeight: FontWeight.w700)),
  );

  Widget _buildCartBar() => Material(elevation: 10, color: Colors.white, child: Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
    child: Row(children: [
      Expanded(child: InkWell(onTap: _cart.isEmpty ? null : _openCart, child: Row(children: [
        const Icon(Icons.shopping_bag, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('$_count items', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Text(formatCurrency(_total), style: GoogleFonts.fraunces(color: AppColors.foreground, fontWeight: FontWeight.w800, fontSize: 18)),
      ]))),
      GradientButton(
        onPressed: _cart.isEmpty || _submitting ? null : _openCart,
        loading: _submitting,
        child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Review'), SizedBox(width: 6), Icon(Icons.arrow_forward, size: 16)]),
      ),
    ]),
  ));

  void _openCart() {
    showModalBottomSheet(context: context, isScrollControlled: true, showDragHandle: true, useSafeArea: true, builder: (bc) => StatefulBuilder(builder: (sctx, setLocal) => DraggableScrollableSheet(
      expand: false, initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.96,
      builder: (c, scroll) {
        void redraw() { setLocal(() {}); setState(() {}); }
        return ListView(controller: scroll, padding: EdgeInsets.only(left: 20, right: 20, top: 4, bottom: MediaQuery.of(c).viewInsets.bottom + 16), children: [
          Row(children: [
            const Icon(Icons.shopping_bag, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Active bill', style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w800)),
            const Spacer(),
            TextButton(onPressed: () { _clear(); Navigator.pop(c); }, child: const Text('Clear')),
          ]),
          const SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            initialValue: _customerId,
            decoration: const InputDecoration(labelText: 'Customer', prefixIcon: Icon(Icons.person_outline)),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Walk-in customer')),
              for (final cu in (_customers ?? [])) DropdownMenuItem<int?>(value: cu.id, child: Text('${cu.name}${cu.phone.isNotEmpty ? ' · ${cu.phone}' : ''}')),
            ],
            onChanged: (v) { _customerId = v; redraw(); },
          ),
          const SizedBox(height: 12),
          if (_cart.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Cart is empty', style: TextStyle(color: AppColors.muted)))),
          for (int i = 0; i < _cart.length; i++) Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.secondarySoft, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_cart[i].name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Row(children: [
                  const Text('₹', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(width: 76, child: TextField(
                    controller: TextEditingController(text: _cart[i].price.toString())..selection = TextSelection.collapsed(offset: _cart[i].price.toString().length),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onSubmitted: (v) { _cart[i].price = double.tryParse(v) ?? _cart[i].price; redraw(); },
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6)),
                  )),
                ]),
              ])),
              Row(children: [
                IconButton(onPressed: () { _changeQty(i, -1); redraw(); }, icon: const Icon(Icons.remove_circle_outline)),
                Text('${_cart[i].quantity}', style: const TextStyle(fontWeight: FontWeight.w800)),
                IconButton(onPressed: () { _changeQty(i, 1); redraw(); }, icon: const Icon(Icons.add_circle_outline, color: AppColors.primary)),
              ]),
              IconButton(onPressed: () { _remove(i); redraw(); }, icon: const Icon(Icons.delete_outline)),
            ]),
          ),
          const SizedBox(height: 8),
          _amountRow('Total (₹)', _total, _subtotal, (v) { _customTotal = v; redraw(); }, bold: true),
          _amountRow('Paid (₹)', _paid, _total, (v) { _customPaid = v; redraw(); }),
          if (_due > 0.005) Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primarySoft, Colors.white]), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primaryBorder)),
            child: Row(children: [
              const Text('Credit due', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(formatCurrency(_due), style: GoogleFonts.fraunces(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 18)),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(c), child: const Text('Keep editing'))),
            const SizedBox(width: 10),
            Expanded(child: GradientButton(
              onPressed: _submitting || _cart.isEmpty ? null : () async { Navigator.pop(c); await _checkout(); },
              loading: _submitting,
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check, size: 18), SizedBox(width: 6), Text('Generate')]),
            )),
          ]),
        ]);
      },
    )));
  }

  Widget _amountRow(String label, double current, double placeholder, ValueChanged<double?> onChanged, {bool bold = false}) {
    final c = TextEditingController(text: current.toString());
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: AppColors.muted, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
      SizedBox(width: 140, child: TextField(
        controller: c..selection = TextSelection.collapsed(offset: c.text.length),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        style: GoogleFonts.fraunces(fontSize: bold ? 22 : 18, fontWeight: FontWeight.w800, color: AppColors.foreground),
        decoration: InputDecoration(hintText: placeholder.toStringAsFixed(0), isDense: true),
        onSubmitted: (v) => onChanged(double.tryParse(v.trim())),
      )),
    ]));
  }

  Future<void> _addCustom() async {
    final products = (_products ?? []).where((p) => p.category != Category.bouquet && p.archivedAt == null).toList();
    final selected = <int, double>{};
    final nameCtrl = TextEditingController(text: 'Custom bouquet');
    final priceCtrl = TextEditingController();
    await showModalBottomSheet(context: context, isScrollControlled: true, showDragHandle: true, useSafeArea: true,
      builder: (bc) => StatefulBuilder(builder: (sctx, setLocal) {
        double cost() => selected.entries.fold(0, (a, e) {
          final p = products.firstWhere((x) => x.id == e.key, orElse: () => products.first);
          return a + e.value * p.purchasePrice;
        });
        double suggested() => selected.entries.fold(0, (a, e) {
          final p = products.firstWhere((x) => x.id == e.key, orElse: () => products.first);
          return a + e.value * p.sellingPrice;
        });
        return DraggableScrollableSheet(expand: false, initialChildSize: 0.9, maxChildSize: 0.96,
          builder: (c, scroll) => ListView(controller: scroll, padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(c).viewInsets.bottom + 20, top: 4), children: [
            Text('Custom bouquet', style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 10),
            for (final p in products) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(displayName(p), style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Stock ${p.stock.toStringAsFixed(0)} · ${formatCurrency(p.sellingPrice)}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
              ])),
              IconButton(onPressed: () { final cur = selected[p.id] ?? 0; if (cur > 0) setLocal(() => (cur - 1) <= 0 ? selected.remove(p.id) : selected[p.id] = cur - 1); }, icon: const Icon(Icons.remove_circle_outline)),
              Text((selected[p.id] ?? 0).toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w800)),
              IconButton(onPressed: () {
                final cur = selected[p.id] ?? 0;
                if (cur + 1 <= p.stock) {
                  setLocal(() => selected[p.id] = cur + 1);
                } else {
                  toast(c, 'Max stock reached');
                }
              }, icon: const Icon(Icons.add_circle_outline, color: AppColors.primary)),
            ])),
            const SizedBox(height: 10),
            Text('Cost: ${formatCurrency(cost())} · Suggested: ${formatCurrency(suggested())}', style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 8),
            TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Price (₹)', hintText: suggested().toStringAsFixed(0))),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel'))),
              const SizedBox(width: 10),
              Expanded(child: GradientButton(
                onPressed: selected.isEmpty ? null : () {
                  final price = double.tryParse(priceCtrl.text.trim()) ?? suggested();
                  final comps = <_CartComponent>[];
                  for (final e in selected.entries) {
                    final p = products.firstWhere((x) => x.id == e.key);
                    comps.add(_CartComponent(productId: p.id, name: displayName(p), quantity: e.value, unitCost: p.purchasePrice));
                  }
                  final maxQty = comps.map((cc) {
                    final p = products.firstWhere((x) => x.id == cc.productId);
                    return (p.stock / cc.quantity).floor().toDouble();
                  }).reduce((a, b) => a < b ? a : b);
                  setState(() => _cart.add(_CartLine(
                    key: 'c${DateTime.now().microsecondsSinceEpoch}',
                    kind: ItemKind.customBouquet, productId: null,
                    name: nameCtrl.text.trim().isEmpty ? 'Custom bouquet' : nameCtrl.text.trim(),
                    price: price, quantity: 1, maxQuantity: maxQty, components: comps,
                  )));
                  Navigator.pop(c);
                },
                child: const Text('Add to bill'),
              )),
            ]),
          ]));
      }));
  }
}

class _CartLine {
  final String key; final ItemKind kind; final int? productId;
  String name; double price; int quantity; double? maxQuantity; List<_CartComponent> components;
  _CartLine({required this.key, required this.kind, this.productId, required this.name, required this.price, required this.quantity, this.maxQuantity, this.components = const []});
}
class _CartComponent { final int productId; final String name; final double quantity, unitCost;
  _CartComponent({required this.productId, required this.name, required this.quantity, required this.unitCost}); }

/* -------------------------  QUICK BILL  ------------------------- */

class _QuickBillTab extends StatefulWidget {
  const _QuickBillTab();
  @override State<_QuickBillTab> createState() => _QuickBillTabState();
}
class _QuickBillTabState extends State<_QuickBillTab> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;
  List<Customer>? _customers;
  int? _customerId;
  final _descCtrl = TextEditingController(text: 'Flowers & bouquets');
  final _totalCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  bool _submitting = false;

  @override void initState() { super.initState(); repo.customers().then((v) { if (mounted) setState(() => _customers = v); }); }
  @override void dispose() { _descCtrl.dispose(); _totalCtrl.dispose(); _paidCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final total = double.tryParse(_totalCtrl.text.trim());
    if (total == null || total <= 0) { toast(context, 'Enter total', error: true); return; }
    final paid = double.tryParse(_paidCtrl.text.trim()) ?? total;
    if (paid < total - 0.005 && _customerId == null) { toast(context, 'Pick a customer for credit sales', error: true); return; }
    setState(() => _submitting = true);
    try {
      final item = CreateSaleItem(
        kind: ItemKind.customBouquet,
        name: _descCtrl.text.trim().isEmpty ? 'Quick bill' : _descCtrl.text.trim(),
        quantity: 1, price: total, components: const [],
      );
      final sale = await repo.createSale(customerId: _customerId, items: [item], total: total, amountPaid: paid);
      if (!mounted) return;
      _totalCtrl.clear(); _paidCtrl.clear();
      toast(context, 'Bill #${sale.id} generated');
      if (mounted) await showReceipt(context, sale);
    } catch (e) { if (mounted) toast(context, '$e', error: true); }
    finally { if (mounted) setState(() => _submitting = false); }
  }

  @override Widget build(BuildContext context) {
    super.build(context);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: AppColors.headerGradient, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.primaryBorder)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
            child: const Icon(Icons.flash_on, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Quick bill', style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w800)),
            const Text('Fastest way to generate a bill — just type the total.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ])),
        ]),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<int?>(
        initialValue: _customerId,
        decoration: const InputDecoration(labelText: 'Customer', prefixIcon: Icon(Icons.person_outline)),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('Walk-in customer')),
          for (final cu in (_customers ?? [])) DropdownMenuItem<int?>(value: cu.id, child: Text('${cu.name}${cu.phone.isNotEmpty ? ' · ${cu.phone}' : ''}')),
        ],
        onChanged: (v) => setState(() => _customerId = v),
      ),
      const SizedBox(height: 12),
      TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined))),
      const SizedBox(height: 12),
      TextField(controller: _totalCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.fraunces(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary),
        decoration: const InputDecoration(labelText: 'Total (₹)', prefixText: '₹  ')),
      const SizedBox(height: 12),
      TextField(controller: _paidCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Amount paid (₹) — blank = full', prefixText: '₹  ')),
      const SizedBox(height: 20),
      GradientButton(
        onPressed: _submitting ? null : _submit,
        loading: _submitting,
        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check, size: 18), SizedBox(width: 6), Text('Generate bill')]),
      ),
      const SizedBox(height: 20),
      const Text(
        'Quick bills do not deduct per-item stock. Use the POS tab when you need recipes and inventory tracking.',
        style: TextStyle(color: AppColors.muted, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    ]);
  }
}

/* -------------------------  TODAY TAB  ------------------------- */

class _TodayTab extends StatelessWidget {
  const _TodayTab();
  @override Widget build(BuildContext context) {
    return AsyncView<List<Sale>>(
      load: () async {
        final all = await repo.sales(limit: 200);
        final today = DateTime.now().toLocal();
        return all.where((s) {
          try { final d = DateTime.parse(s.date).toLocal();
            return d.year == today.year && d.month == today.month && d.day == today.day;
          } catch (_) { return false; }
        }).toList();
      },
      builder: (ctx, sales, refresh) {
        if (sales.isEmpty) return const EmptyState(icon: Icons.calendar_today, message: "No bills yet today", hint: 'Create one from the POS or Quick bill tab.');
        final total = sales.where((s) => !s.isVoided).fold<double>(0, (a, s) => a + s.total);
        return ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(blurRadius: 18, offset: Offset(0, 6), color: AppColors.roseShadow)]),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("TODAY'S TAKE", style: TextStyle(color: Colors.white70, letterSpacing: 1, fontWeight: FontWeight.w800, fontSize: 10)),
                const SizedBox(height: 4),
                Text(formatCurrency(total), style: GoogleFonts.fraunces(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              ]),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${sales.length}', style: GoogleFonts.fraunces(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const Text('bills', style: TextStyle(color: Colors.white70)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          for (final s in sales) InkWell(
            onTap: () => showReceipt(context, s),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.customer?.name ?? 'Walk-in', style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text('#${padId(s.id)} · ${formatTime(s.date)}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ])),
                Text(formatCurrency(s.total), style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w800, color: s.isVoided ? AppColors.muted : AppColors.foreground, decoration: s.isVoided ? TextDecoration.lineThrough : null)),
              ]),
            ),
          ),
        ]);
      },
    );
  }
}
