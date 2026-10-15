import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';
import 'shell.dart';
import 'screens/dashboard.dart';
import 'screens/billing.dart';
import 'screens/sales.dart';
import 'screens/inventory.dart';
import 'screens/customers.dart';
import 'screens/credits.dart';
import 'screens/reports.dart';

void main() => runApp(const SidhiApp());

class SidhiApp extends StatelessWidget {
  const SidhiApp({super.key});
  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (ctx, state, child) => AppShell(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
            GoRoute(path: '/billing', builder: (_, __) => const BillingScreen()),
            GoRoute(path: '/sales', builder: (_, __) => const SalesScreen()),
            GoRoute(path: '/inventory', builder: (_, __) => const InventoryScreen()),
            GoRoute(path: '/customers', builder: (_, __) => const CustomersScreen()),
            GoRoute(path: '/credits', builder: (_, __) => const CreditsScreen()),
            GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
          ],
        ),
      ],
    );
    return MaterialApp.router(
      title: 'Flora - Flower Shop Management App',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: router,
    );
  }
}
