import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/async_view.dart';

const _units = ['stem', 'bunch', 'kg', 'dozen', 'piece', 'sheet', 'garland'];

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);
  String _search = ''; int _reloadKey = 0;
  @override void dispose() { _tab.dispose(); super.dispose(); }
  void _reload() => setState(() => _reloadKey++);

  @override Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(children: [
        PageHeader(title: 'Inventory', subtitle: 'Flowers, bouquets, margins.', actions: [GradientButton(
          onPressed: () async {
            final cat = _tab.index == 1 ? 'bouquet' : 'flower';
            final ok = await _editProduct(context, category: cat);
            if (ok == true) _reload();
          },
          child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 16), SizedBox(width: 6), Text('Add')]),
        )]),
        Material(color: Colors.white, child: TabBar(controller: _tab, tabs: const [
          Tab(icon: Icon(Icons.local_florist, size: 18), text: 'Stock'),
          Tab(icon: Icon(Icons.card_giftcard, size: 18), text: 'Bouquets'),
          Tab(icon: Icon(Icons.trending_up, size: 18), text: 'Margins'),
        ])),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search'),
          ),
        ),
        Expanded(child: TabBarView(controller: _tab, children: [
          _StockTab(key: ValueKey('stock$_reloadKey'), search: _search, onChange: _reload),
          _BouquetsTab(key: ValueKey('b$_reloadKey'), search: _search, onChange: _reload),
          _MarginsTab(key: ValueKey('m$_reloadKey'), search: _search),
        ])),
      ]),
    );
  }
}

class _StockTab extends StatelessWidget {
  final String search; final VoidCallback onChange;
  const _StockTab({super.key, required this.search, required this.onChange});
  @override Widget build(BuildContext context) {
    return AsyncView<List<Product>>(
      load: () => repo.products(),
      builder: (ctx, all, refresh) {
        final items = all.where((p) => p.category != Category.bouquet && (search.isEmpty || displayName(p).toLowerCase().contains(search))).toList();
        if (items.isEmpty) return const EmptyState(icon: Icons.inventory_2, message: 'No items', hint: 'Tap Add to register one.');
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 28),
          itemCount: items.length,
          itemBuilder: (c, i) {
            final p = items[i]; final low = p.stock <= 20;
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border),
                boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x0A000000), offset: Offset(0, 4))],
              ),
              child: Row(children: [
                Container(
                  width: 6, height: 48,
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(displayName(p), style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('${p.category.name} · per ${p.unit}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('${formatCurrency(p.purchasePrice)}  →  ${formatCurrency(p.sellingPrice)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: low ? AppColors.primaryGradient : null,
                      color: low ? null : AppColors.secondarySoft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: low ? Colors.transparent : AppColors.border),
                    ),
                    child: Text(p.stock.toStringAsFixed(0), style: TextStyle(fontWeight: FontWeight.w800, color: low ? Colors.white : AppColors.foreground, fontSize: 13)),
                  ),
                  PopupMenuButton<String>(
                    itemBuilder: (c) => const [
                      PopupMenuItem(value: 'stock', child: Row(children: [Icon(Icons.inventory_2_outlined, size: 18), SizedBox(width: 8), Text('Stock movement')])),
                      PopupMenuItem(value: 'history', child: Row(children: [Icon(Icons.history, size: 18), SizedBox(width: 8), Text('Stock history')])),
                      PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                      PopupMenuItem(value: 'archive', child: Row(children: [Icon(Icons.archive_outlined, size: 18), SizedBox(width: 8), Text('Archive')])),
                    ],
                    onSelected: (v) async {
                      if (v == 'stock') {
                        final changed = await _recordStock(context, p);
                        if (changed && context.mounted) { refresh(); onChange(); }
                      } else if (v == 'history') {
                        if (context.mounted) await _showStockHistory(context, p);
                      } else if (v == 'edit') {
                        final ok = await _editProduct(context, product: p);
                        if (ok == true) { refresh(); onChange(); }
                      } else if (v == 'archive') {
                        final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(
                          title: Text('Archive ${displayName(p)}?'),
                          content: const Text('Past bills keep it. It disappears from billing & inventory.'),
                          actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () => Navigator.pop(d, true), child: const Text('Archive'))],
                        ));
                        if (ok == true) {
                          try { await repo.archiveProduct(p.id); refresh(); onChange(); if (context.mounted) toast(context, 'Archived'); }
                          catch (e) { if (context.mounted) toast(context, '$e', error: true); }
                        }
                      }
                    },
                  ),
                ]),
              ]),
            ).animate(delay: (i.clamp(0, 10) * 20).ms).fadeIn(duration: 200.ms).slideY(begin: 0.08, end: 0);
          },
        );
      },
    );
  }
}

class _BouquetsTab extends StatelessWidget {
  final String search; final VoidCallback onChange;
  const _BouquetsTab({super.key, required this.search, required this.onChange});
  @override Widget build(BuildContext context) {
    return AsyncView<(List<Product>, List<RecipeRow>, List<BouquetAvailability>)>(
      load: () async => (await repo.products(), await repo.recipes(), await repo.bouquetAvailability()),
      builder: (ctx, data, refresh) {
        final bouquets = data.$1.where((p) => p.category == Category.bouquet && (search.isEmpty || p.name.toLowerCase().contains(search))).toList();
        final availMap = {for (final a in data.$3) a.bouquetId: a};
        final productMap = {for (final p in data.$1) p.id: p};
        if (bouquets.isEmpty) return const EmptyState(icon: Icons.card_giftcard, message: 'No bouquets', hint: 'Tap Add to create one.');
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 28),
          itemCount: bouquets.length,
          itemBuilder: (c, i) {
            final b = bouquets[i]; final a = availMap[b.id]; final can = a?.canMake ?? 0;
            final recipes = data.$2.where((r) => r.bouquetId == b.id).toList();
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border),
                boxShadow: const [BoxShadow(blurRadius: 14, color: Color(0x0C000000), offset: Offset(0, 5))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primarySoft, Colors.white]),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.name, style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(formatCurrency(b.sellingPrice), style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ])),
                    StatusChip(
                      label: can > 0 ? 'Can make ${can.toStringAsFixed(0)}' : 'Short',
                      bg: can > 0 ? AppColors.primarySoft : AppColors.secondarySoft,
                      fg: can > 0 ? AppColors.primary : AppColors.muted,
                      icon: can > 0 ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (recipes.isEmpty) const Text('No recipe yet.', style: TextStyle(color: AppColors.muted, fontSize: 12, fontStyle: FontStyle.italic))
                    else for (final r in recipes) Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(productMap[r.componentId] != null ? displayName(productMap[r.componentId]) : '#${r.componentId}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        Text('${r.quantity.toStringAsFixed(0)} ${productMap[r.componentId]?.unit ?? ''}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      ]),
                    ),
                    if (a != null && a.shortages.isNotEmpty) Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primaryBorder)),
                        child: Text(shortageText(a.shortages), style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700))),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      OutlinedButton.icon(onPressed: () => _editRecipe(context, b, data.$1, recipes, () { refresh(); onChange(); }),
                        icon: const Icon(Icons.edit_note, size: 18), label: const Text('Recipe')),
                      const Spacer(),
                      IconButton(onPressed: () async { final ok = await _editProduct(context, product: b); if (ok == true) { refresh(); onChange(); } }, icon: const Icon(Icons.edit)),
                      IconButton(onPressed: () async {
                        final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(title: Text('Archive ${b.name}?'), actions: [
                          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                          ElevatedButton(onPressed: () => Navigator.pop(d, true), child: const Text('Archive'))]));
                        if (ok == true) { try { await repo.archiveProduct(b.id); refresh(); onChange(); if (context.mounted) toast(context, 'Archived'); } catch (e) { if (context.mounted) toast(context, '$e', error: true); } }
                      }, icon: const Icon(Icons.archive_outlined)),
                    ]),
                  ]),
                ),
              ]),
            ).animate(delay: (i.clamp(0, 10) * 30).ms).fadeIn(duration: 230.ms).slideY(begin: 0.08, end: 0);
          },
        );
      },
    );
  }
}

class _MarginsTab extends StatelessWidget {
  final String search;
  const _MarginsTab({super.key, required this.search});
  @override Widget build(BuildContext context) {
    return AsyncView<List<MarginRow>>(
      load: () => repo.profitMargins(),
      builder: (ctx, rows, refresh) {
        final list = rows.where((r) => search.isEmpty || displayName(r).toLowerCase().contains(search)).toList();
        if (list.isEmpty) return const EmptyState(icon: Icons.trending_up, message: 'No margin data yet');
        final totalProfit = list.fold<double>(0, (a, r) => a + r.totalProfit);
        final totalRevenue = list.fold<double>(0, (a, r) => a + r.totalRevenue);
        return ListView(padding: const EdgeInsets.only(bottom: 28), children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(blurRadius: 16, color: AppColors.roseShadow, offset: Offset(0, 6))]),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('TOTAL NET PROFIT', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(formatCurrency(totalProfit), style: GoogleFonts.fraunces(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('REVENUE', style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(formatCurrency(totalRevenue), style: GoogleFonts.fraunces(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              ]),
            ]),
          ),
          for (int i = 0; i < list.length; i++) _marginTile(list[i]).animate(delay: (i.clamp(0, 10) * 20).ms).fadeIn(duration: 200.ms).slideY(begin: 0.08, end: 0),
        ]);
      },
    );
  }

  Widget _marginTile(MarginRow r) {
    final hi = r.profitMarginPercent >= 40;
    final mid = r.profitMarginPercent >= 20 && !hi;
    final icon = hi ? Icons.trending_up : mid ? Icons.horizontal_rule : Icons.trending_down;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x0A000000), offset: Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(displayName(r), style: const TextStyle(fontWeight: FontWeight.w800))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(
            gradient: hi ? AppColors.primaryGradient : null,
            color: hi ? null : AppColors.secondarySoft, borderRadius: BorderRadius.circular(999),
            border: Border.all(color: hi ? Colors.transparent : AppColors.border)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 13, color: hi ? Colors.white : AppColors.muted),
              const SizedBox(width: 4),
              Text('${r.profitMarginPercent.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: hi ? Colors.white : AppColors.foreground)),
            ])),
        ]),
        const SizedBox(height: 4),
        Text('${r.category.name} · ${r.unit}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _mini('Cost', formatCurrency(r.purchasePrice))),
          Expanded(child: _mini('Sell', formatCurrency(r.sellingPrice))),
          Expanded(child: _mini('Profit/unit', formatCurrency(r.profitPerUnit))),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _mini('Units sold', r.totalUnitsSold.toStringAsFixed(0))),
          Expanded(child: _mini('Revenue', formatCurrency(r.totalRevenue))),
          Expanded(child: _mini('Net profit', formatCurrency(r.totalProfit), highlight: true)),
        ]),
      ]),
    );
  }
  Widget _mini(String label, String value, {bool highlight = false}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label.toUpperCase(), style: const TextStyle(color: AppColors.muted, fontSize: 9, fontWeight: FontWeight.w800)),
    Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: highlight ? AppColors.primary : AppColors.foreground, fontSize: 13)),
  ]);
}

Future<bool?> _editProduct(BuildContext ctx, {Product? product, String? category}) async {
  final cat = ValueNotifier<String>(product?.category.name ?? category ?? 'flower');
  final name = TextEditingController(text: product?.name ?? '');
  final variety = TextEditingController(text: product?.variety ?? '');
  final unit = ValueNotifier<String>(product?.unit ?? (cat.value == 'bouquet' ? 'piece' : 'stem'));
  final purchase = TextEditingController(text: product == null ? '' : product.purchasePrice.toString());
  final selling = TextEditingController(text: product == null ? '' : product.sellingPrice.toString());
  final stock = TextEditingController(text: product == null ? '' : product.stock.toString());
  final supplier = TextEditingController(text: product?.supplier ?? '');
  final form = GlobalKey<FormState>();
  bool saving = false;
  return showModalBottomSheet<bool>(context: ctx, isScrollControlled: true, showDragHandle: true, builder: (bc) => StatefulBuilder(builder: (sctx, setLocal) => Padding(
    padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(sctx).viewInsets.bottom + 20, top: 4),
    child: Form(key: form, child: ListView(shrinkWrap: true, children: [
      Text(product == null ? 'New ${cat.value}' : 'Edit ${product.name}', style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      ValueListenableBuilder(valueListenable: cat, builder: (c, v, _) => DropdownButtonFormField<String>(
        initialValue: v,
        decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
        onChanged: product != null ? null : (nv) { if (nv != null) cat.value = nv; },
        items: const [DropdownMenuItem(value: 'flower', child: Text('Flower')), DropdownMenuItem(value: 'accessory', child: Text('Accessory')), DropdownMenuItem(value: 'bouquet', child: Text('Bouquet'))],
      )),
      const SizedBox(height: 10),
      TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.local_florist)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
      const SizedBox(height: 10),
      TextFormField(controller: variety, decoration: const InputDecoration(labelText: 'Variety / colour (optional)')),
      ValueListenableBuilder(valueListenable: cat, builder: (c, catVal, _) {
        if (catVal == 'bouquet') return const SizedBox.shrink();
        return Column(children: [
          const SizedBox(height: 10),
          ValueListenableBuilder(valueListenable: unit, builder: (c2, u, _) => DropdownButtonFormField<String>(
            initialValue: u, decoration: const InputDecoration(labelText: 'Unit', prefixIcon: Icon(Icons.straighten)),
            items: _units.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
            onChanged: (nv) { if (nv != null) unit.value = nv; },
          )),
          const SizedBox(height: 10),
          TextFormField(controller: purchase, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Purchase price (₹)'),
            validator: (v) => double.tryParse((v ?? '').trim()) == null ? 'Enter a number' : null),
        ]);
      }),
      const SizedBox(height: 10),
      TextFormField(controller: selling, keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Selling price (₹)'),
        validator: (v) => double.tryParse((v ?? '').trim()) == null ? 'Enter a number' : null),
      ValueListenableBuilder(valueListenable: cat, builder: (c, catVal, _) {
        if (catVal == 'bouquet') return const SizedBox.shrink();
        return Column(children: [
          const SizedBox(height: 10),
          TextFormField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock'),
            validator: (v) => double.tryParse((v ?? '').trim()) == null ? 'Enter a number' : null),
          const SizedBox(height: 10),
          TextFormField(controller: supplier, decoration: const InputDecoration(labelText: 'Supplier (optional)')),
        ]);
      }),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(bc), child: const Text('Cancel'))),
        const SizedBox(width: 10),
        Expanded(child: GradientButton(
          onPressed: saving ? null : () async {
            if (!form.currentState!.validate()) return;
            setLocal(() => saving = true);
            final isBouquet = cat.value == 'bouquet';
            final input = {
              'name': name.text.trim(), 'variety': variety.text.trim(),
              'unit': isBouquet ? 'piece' : unit.value, 'category': cat.value,
              'purchase_price': isBouquet ? 0 : (double.tryParse(purchase.text.trim()) ?? 0),
              'selling_price': double.tryParse(selling.text.trim()) ?? 0,
              'stock': isBouquet ? 0 : (double.tryParse(stock.text.trim()) ?? 0),
              'supplier': supplier.text.trim(),
            };
            try {
              if (product == null) {
                await repo.createProduct(input);
              } else {
                await repo.updateProduct(product.id, input);
              }
              if (bc.mounted) Navigator.pop(bc, true);
            } catch (e) { setLocal(() => saving = false); if (bc.mounted) toast(bc, '$e', error: true); }
          },
          loading: saving,
          child: const Text('Save'),
        )),
      ]),
      const SizedBox(height: 8),
    ])),
  )));
}

Future<void> _editRecipe(BuildContext ctx, Product bouquet, List<Product> allProducts, List<RecipeRow> current, VoidCallback onDone) async {
  final components = <_RecipeDraft>[
    for (final r in current) if (allProducts.any((p) => p.id == r.componentId))
      _RecipeDraft(productId: r.componentId, quantity: r.quantity),
  ];
  final pool = allProducts.where((p) => p.category != Category.bouquet && p.archivedAt == null).toList();
  bool saving = false;
  await showModalBottomSheet(context: ctx, isScrollControlled: true, showDragHandle: true, builder: (bc) => StatefulBuilder(builder: (sctx, setLocal) {
    Future<void> addComponent() async {
      final chosen = await showModalBottomSheet<Product>(context: sctx, isScrollControlled: true, showDragHandle: true,
        builder: (c) => ListView(shrinkWrap: true, children: [for (final p in pool) ListTile(
          title: Text(displayName(p)), subtitle: Text('Stock: ${p.stock.toStringAsFixed(0)}'),
          onTap: () => Navigator.pop(c, p),
        )]));
      if (chosen != null) setLocal(() => components.add(_RecipeDraft(productId: chosen.id, quantity: 1)));
    }
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(sctx).viewInsets.bottom + 20, top: 4),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Recipe · ${bouquet.name}', style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (int i = 0; i < components.length; i++) ...[
          Row(children: [
            Expanded(child: Text(displayName(allProducts.firstWhere((p) => p.id == components[i].productId)))),
            SizedBox(width: 80, child: TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Qty'),
              controller: TextEditingController(text: components[i].quantity.toString()),
              onChanged: (v) => components[i].quantity = double.tryParse(v) ?? components[i].quantity,
            )),
            IconButton(onPressed: () => setLocal(() => components.removeAt(i)), icon: const Icon(Icons.delete_outline)),
          ]),
          const SizedBox(height: 4),
        ],
        OutlinedButton.icon(onPressed: addComponent, icon: const Icon(Icons.add), label: const Text('Add component')),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(bc), child: const Text('Cancel'))),
          const SizedBox(width: 10),
          Expanded(child: GradientButton(
            onPressed: saving ? null : () async {
              setLocal(() => saving = true);
              try {
                await repo.saveRecipe(bouquet.id,
                    components.map((c) => {'component_id': c.productId, 'quantity': c.quantity}).toList());
                if (bc.mounted) Navigator.pop(bc);
                onDone();
                if (ctx.mounted) toast(ctx, 'Recipe saved');
              } catch (e) { setLocal(() => saving = false); if (bc.mounted) toast(bc, '$e', error: true); }
            },
            loading: saving,
            child: const Text('Save'),
          )),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }));
}

class _RecipeDraft { final int productId; double quantity; _RecipeDraft({required this.productId, required this.quantity}); }

Future<bool> _recordStock(BuildContext context, Product product) async {
  final quantity = TextEditingController();
  final reason = TextEditingController();
  var kind = 'received';
  final result = await showDialog<bool>(context: context, builder: (dialog) =>
    StatefulBuilder(builder: (context, setState) => AlertDialog(
      title: Text('Stock · ${product.name}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(initialValue: kind,
          decoration: const InputDecoration(labelText: 'Movement'),
          items: const [
            DropdownMenuItem(value: 'received', child: Text('Received')),
            DropdownMenuItem(value: 'waste', child: Text('Waste')),
            DropdownMenuItem(value: 'adjustment', child: Text('Adjustment (+ / −)')),
          ], onChanged: (v) => setState(() => kind = v ?? kind)),
        TextField(controller: quantity, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: const InputDecoration(labelText: 'Quantity')),
        TextField(controller: reason, decoration: const InputDecoration(labelText: 'Reason')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          final amount = double.tryParse(quantity.text.trim());
          if (amount == null || amount == 0 || (kind != 'adjustment' && amount < 0)) {
            toast(context, 'Enter a valid quantity', error: true); return;
          }
          try {
            await repo.recordStockMovement(product.id, kind, amount, reason.text.trim());
            if (dialog.mounted) Navigator.pop(dialog, true);
          } catch (e) { if (context.mounted) toast(context, '$e', error: true); }
        }, child: const Text('Record')),
      ],
    )));
  quantity.dispose(); reason.dispose();
  return result ?? false;
}

Future<void> _showStockHistory(BuildContext context, Product product) async {
  await showModalBottomSheet(context: context, isScrollControlled: true,
    builder: (sheet) => SafeArea(child: SizedBox(height: MediaQuery.of(sheet).size.height * 0.65,
      child: Column(children: [
        ListTile(title: Text('${product.name} · stock history'),
          trailing: IconButton(onPressed: () => Navigator.pop(sheet), icon: const Icon(Icons.close))),
        Expanded(child: FutureBuilder<List<Map<String,dynamic>>>(
          future: repo.stockMovements(product.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            if (snapshot.data!.isEmpty) return const Center(child: Text('No movements recorded yet.'));
            return ListView(children: [for (final movement in snapshot.data!) ListTile(
              title: Text('${movement['kind']} · ${movement['quantity']} ${product.unit}'),
              subtitle: Text('${movement['reason'] ?? ''}  ${movement['date'] ?? ''}'),
              trailing: Text('${movement['before']} → ${movement['after']}'),
            )]);
          },
        )),
      ]))));
}
