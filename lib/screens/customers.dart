import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/async_view.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String search = '';
  final _key = GlobalKey<_CustListState>();

  @override Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(children: [
        PageHeader(
          title: 'Customers',
          subtitle: 'Decorators, planners, temples, regulars.',
          actions: [GradientButton(
            onPressed: () async { final ok = await _editCustomer(context); if (ok == true) _key.currentState?.reload(); },
            child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.person_add, size: 16), SizedBox(width: 6), Text('Add')]),
          )],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: TextField(
            onChanged: (v) => setState(() => search = v.trim().toLowerCase()),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search name, phone, business'),
          ),
        ),
        Expanded(child: _CustList(key: _key, search: search)),
      ]),
    );
  }
}

class _CustList extends StatefulWidget {
  final String search;
  const _CustList({super.key, required this.search});
  @override State<_CustList> createState() => _CustListState();
}
class _CustListState extends State<_CustList> {
  late Future<List<Customer>> _f;
  @override void initState() { super.initState(); _f = repo.customers(); }
  void reload() => setState(() => _f = repo.customers());

  Color _avatarColor(String name) {
    const palette = [
      Color(0xFFE94A7A), Color(0xFFBE2B57), Color(0xFF28242E), Color(0xFF6E6475),
      Color(0xFFEE91AC), Color(0xFFD93B68),
    ];
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override Widget build(BuildContext context) {
    return AsyncView<List<Customer>>(
      key: ValueKey(_f),
      load: () => _f,
      builder: (ctx, all, refresh) {
        final list = all.where((c) {
          if (widget.search.isEmpty) return true;
          final q = widget.search;
          return c.name.toLowerCase().contains(q) || c.phone.contains(q) || c.business.toLowerCase().contains(q);
        }).toList();
        if (list.isEmpty) return const EmptyState(icon: Icons.people_outline, message: 'No customers', hint: 'Tap Add to register one.');
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 28),
          itemCount: list.length,
          itemBuilder: (c, i) {
            final cu = list[i];
            final color = _avatarColor(cu.name);
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border),
                boxShadow: const [BoxShadow(blurRadius: 12, color: Color(0x0A000000), offset: Offset(0, 4))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withValues(alpha: 0.85), color]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(blurRadius: 10, color: color.withValues(alpha: 0.3), offset: const Offset(0, 4))],
                    ),
                    child: Center(child: Text(_initials(cu.name), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(cu.name, style: GoogleFonts.fraunces(fontSize: 17, fontWeight: FontWeight.w800)),
                    if (cu.business.isNotEmpty) Text(cu.business, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                  ])),
                  IconButton(onPressed: () => _history(context, cu), icon: const Icon(Icons.history), tooltip: 'History'),
                  PopupMenuButton<String>(
                    itemBuilder: (c) => const [
                      PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                      PopupMenuItem(value: 'archive', child: Row(children: [Icon(Icons.archive_outlined, size: 18), SizedBox(width: 8), Text('Archive')])),
                    ],
                    onSelected: (v) async {
                      if (v == 'edit') {
                        final ok = await _editCustomer(context, cu);
                        if (ok == true) reload();
                      } else if (v == 'archive') {
                        await _archive(context, cu);
                      }
                    },
                  ),
                ]),
                if (cu.phone.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(children: [const Icon(Icons.phone, size: 14, color: AppColors.primary), const SizedBox(width: 6), Text(cu.phone, style: const TextStyle(fontWeight: FontWeight.w700))]),
                ),
                if (cu.address.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.place, size: 14, color: AppColors.muted), const SizedBox(width: 6), Expanded(child: Text(cu.address, style: const TextStyle(color: AppColors.muted, fontSize: 12)))]),
                ),
                if (cu.notes.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.secondarySoft, borderRadius: BorderRadius.circular(10)),
                    child: Text(cu.notes, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontStyle: FontStyle.italic))),
                ),
              ]),
            ).animate(delay: (i.clamp(0, 10) * 25).ms).fadeIn(duration: 220.ms).slideY(begin: 0.08, end: 0);
          },
        );
      },
    );
  }

  Future<void> _archive(BuildContext ctx, Customer c) async {
    final ok = await showDialog<bool>(context: ctx, builder: (c2) => AlertDialog(
      title: Text('Archive ${c.name}?'),
      content: const Text('Past bills and dues are kept. Nothing is deleted.'),
      actions: [TextButton(onPressed: () => Navigator.pop(c2, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(c2, true), child: const Text('Archive'))],
    ));
    if (ok != true) return;
    try { await repo.archiveCustomer(c.id); if (ctx.mounted) toast(ctx, 'Archived'); reload(); }
    catch (e) { if (ctx.mounted) toast(ctx, '$e', error: true); }
  }

  Future<void> _history(BuildContext ctx, Customer c) async {
    showModalBottomSheet(context: ctx, isScrollControlled: true, showDragHandle: true, useSafeArea: true, builder: (b) => DraggableScrollableSheet(
      expand: false, initialChildSize: 0.85, maxChildSize: 0.95,
      builder: (c2, scroll) => FutureBuilder<List<Sale>>(
        future: repo.customerSales(c.id),
        builder: (c3, s) {
          if (!s.hasData) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.primary)));
          final sales = s.data!;
          final total = sales.where((x) => !x.isVoided).fold<double>(0, (a, x) => a + x.total);
          final due = sales.where((x) => !x.isVoided).fold<double>(0, (a, x) => a + x.balanceDue);
          return ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(blurRadius: 16, color: AppColors.roseShadow, offset: Offset(0, 6))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: GoogleFonts.fraunces(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                const Text('PURCHASE HISTORY', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _histTile('Lifetime', formatCurrency(total))),
                  const SizedBox(width: 8),
                  Expanded(child: _histTile('Due', formatCurrency(due))),
                  const SizedBox(width: 8),
                  Expanded(child: _histTile('Bills', '${sales.length}')),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            if (sales.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No bills yet.', style: TextStyle(color: AppColors.muted)))),
            for (final sa in sales) Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(formatDate(sa.date), style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(formatCurrency(sa.total), style: GoogleFonts.fraunces(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16)),
                ]),
                if (sa.balanceDue > 0.01) Padding(padding: const EdgeInsets.only(top: 2), child: Text('Due: ${formatCurrency(sa.balanceDue)}', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700))),
                const SizedBox(height: 6),
                for (final it in sa.items) Text('${it.quantity.toStringAsFixed(0)} × ${it.name} — ${formatCurrency(it.total)}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
            ),
          ]);
        },
      ),
    ));
  }

  Widget _histTile(String label, String value) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
      const SizedBox(height: 2),
      Text(value, style: GoogleFonts.fraunces(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

Future<bool?> _editCustomer(BuildContext ctx, [Customer? c]) async {
  final name = TextEditingController(text: c?.name ?? '');
  final phone = TextEditingController(text: c?.phone ?? '');
  final biz = TextEditingController(text: c?.business ?? '');
  final addr = TextEditingController(text: c?.address ?? '');
  final notes = TextEditingController(text: c?.notes ?? '');
  final form = GlobalKey<FormState>();
  bool saving = false;
  return showModalBottomSheet<bool>(context: ctx, isScrollControlled: true, showDragHandle: true, builder: (bc) {
    return StatefulBuilder(builder: (sctx, setLocal) => Padding(
      padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(sctx).viewInsets.bottom + 20, top: 8),
      child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(c == null ? 'Add customer' : 'Edit customer', style: GoogleFonts.fraunces(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
        const SizedBox(height: 10),
        TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
        const SizedBox(height: 10),
        TextFormField(controller: biz, decoration: const InputDecoration(labelText: 'Business / event (optional)', prefixIcon: Icon(Icons.business))),
        const SizedBox(height: 10),
        TextFormField(controller: addr, maxLines: 2, decoration: const InputDecoration(labelText: 'Address (optional)', prefixIcon: Icon(Icons.place_outlined))),
        const SizedBox(height: 10),
        TextFormField(controller: notes, decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.sticky_note_2_outlined))),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(bc), child: const Text('Cancel'))),
          const SizedBox(width: 10),
          Expanded(child: GradientButton(
            onPressed: saving ? null : () async {
              if (!form.currentState!.validate()) return;
              setLocal(() => saving = true);
              final input = {'name': name.text.trim(), 'phone': phone.text.trim(), 'business': biz.text.trim(), 'address': addr.text.trim(), 'notes': notes.text.trim()};
              try {
                if (c == null) { await repo.createCustomer(input); } else { await repo.updateCustomer(c.id, input); }
                if (bc.mounted) Navigator.pop(bc, true);
              } catch (e) { setLocal(() => saving = false); if (bc.mounted) toast(bc, '$e', error: true); }
            },
            loading: saving,
            child: const Text('Save'),
          )),
        ]),
      ])),
    ));
  });
}
