import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';
import 'widgets/backup.dart';
import 'widgets/calculator.dart';
import 'services/seeder.dart';
import 'utils.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.dashboard_outlined, selected: Icons.dashboard, label: 'Home', path: '/'),
    (icon: Icons.point_of_sale_outlined, selected: Icons.point_of_sale, label: 'Billing', path: '/billing'),
    (icon: Icons.receipt_long_outlined, selected: Icons.receipt_long, label: 'Sales', path: '/sales'),
    (icon: Icons.inventory_2_outlined, selected: Icons.inventory_2, label: 'Stock', path: '/inventory'),
    (icon: Icons.more_horiz, selected: Icons.more_horiz, label: 'More', path: '/more'),
  ];

  @override Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int idx = _tabs.indexWhere((t) => t.path == location);
    if (idx < 0) idx = const ['/customers', '/credits', '/reports', '/insights'].contains(location) ? 4 : 0;

    return Scaffold(
      body: child,
      floatingActionButton: _CalculatorFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) async {
          if (i == 4) {
            final choice = await showModalBottomSheet<String>(
              context: context, showDragHandle: true,
              builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                _moreTile(ctx, Icons.auto_awesome, 'AI Insights', '/insights'),
                _moreTile(ctx, Icons.people_outline, 'Customers', '/customers'),
                _moreTile(ctx, Icons.payments_outlined, 'Credits & dues', '/credits'),
                _moreTile(ctx, Icons.insights_outlined, 'Reports & charts', '/reports'),
                const Divider(),
                ListTile(leading: const Icon(Icons.local_florist, color: AppColors.primary), title: const Text('Seed demo catalog'), subtitle: const Text('Replace stock with curated flowers + accessories'),
                  onTap: () async { Navigator.pop(ctx); await _seedCatalog(context); }),
                ListTile(leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary), title: const Text('Backup data'), subtitle: const Text('Export everything to a JSON file'),
                  onTap: () async { Navigator.pop(ctx); await runBackup(context); }),
                ListTile(leading: const Icon(Icons.file_open_outlined, color: AppColors.primary), title: const Text('Inspect backup'), subtitle: const Text('Open a previously exported file'),
                  onTap: () async { Navigator.pop(ctx); await importBackup(context); }),
                ListTile(leading: const Icon(Icons.calculate_outlined, color: AppColors.primary), title: const Text('Calculator'),
                  onTap: () async { Navigator.pop(ctx); await showCalculator(context); }),
                const SizedBox(height: 10),
              ])),
            );
            if (choice != null && context.mounted) context.go(choice);
            return;
          }
          context.go(_tabs[i].path);
        },
        destinations: [
          for (final t in _tabs) NavigationDestination(icon: Icon(t.icon), selectedIcon: Icon(t.selected, color: AppColors.primary), label: t.label),
        ],
      ),
    );
  }

  Widget _moreTile(BuildContext ctx, IconData icon, String label, String path) =>
    ListTile(leading: Icon(icon, color: AppColors.primary), title: Text(label), onTap: () => Navigator.pop(ctx, path));
}

Future<void> _seedCatalog(BuildContext context) async {
  final confirmed = await showDialog<bool>(context: context, builder: (d) => AlertDialog(
    title: const Text('Seed demo catalog?'),
    content: const Text('This archives every active product in inventory and replaces it with '
      'a curated set of flowers, bouquets, and florist accessories (with images). '
      'Past bills keep referring to archived items — this is reversible by un-archiving.'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
      ElevatedButton(onPressed: () => Navigator.pop(d, true), child: const Text('Replace catalog')),
    ],
  ));
  if (confirmed != true || !context.mounted) return;

  final progress = ValueNotifier<SeedProgress>(const SeedProgress(done: 0, total: 1, current: 'Starting…'));
  showDialog(context: context, barrierDismissible: false, builder: (d) => AlertDialog(
    title: const Text('Seeding catalog'),
    content: ValueListenableBuilder<SeedProgress>(
      valueListenable: progress,
      builder: (c, v, _) => Column(mainAxisSize: MainAxisSize.min, children: [
        LinearProgressIndicator(value: v.total == 0 ? null : v.done / v.total, color: AppColors.primary),
        const SizedBox(height: 12),
        Text(v.current, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ]),
    ),
  ));
  try {
    final result = await seedShowroomCatalog(onProgress: (p) => progress.value = p);
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (context.mounted) {
      toast(context, 'Added ${result.inserted} items${result.failures.isNotEmpty ? " · ${result.failures.length} failed" : ""}',
        error: result.failures.isNotEmpty && result.inserted == 0);
    }
  } catch (e) {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (context.mounted) toast(context, 'Seed failed: $e', error: true);
  }
}

class _CalculatorFab extends StatelessWidget {
  @override Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FloatingActionButton.small(
        onPressed: () => showCalculator(context),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 4,
        tooltip: 'Calculator',
        child: const Icon(Icons.calculate),
      ),
    );
  }
}
