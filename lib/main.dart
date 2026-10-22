import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'screens/sign_in.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: FloraFirebaseOptions.current);
  runApp(const SidhiApp());
}

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
            GoRoute(
                path: '/billing', builder: (_, __) => const BillingScreen()),
            GoRoute(path: '/sales', builder: (_, __) => const SalesScreen()),
            GoRoute(
                path: '/inventory',
                builder: (_, __) => const InventoryScreen()),
            GoRoute(
                path: '/customers',
                builder: (_, __) => const CustomersScreen()),
            GoRoute(
                path: '/credits', builder: (_, __) => const CreditsScreen()),
            GoRoute(
                path: '/reports', builder: (_, __) => const ReportsScreen()),
          ],
        ),
      ],
    );
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            title: 'Flora',
            theme: buildTheme(),
            home: const SignInScreen(),
          );
        }
        final user = snapshot.data!;
        if (user.email != 'arajiv221@gmail.com' || !user.emailVerified) {
          return MaterialApp(
            title: 'Flora',
            theme: buildTheme(),
            home: Scaffold(
                body: Center(
                    child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('This account does not have access to Flora.'),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text('Sign out')),
              ],
            ))),
          );
        }
        return MaterialApp.router(
          title: 'Flora - Flower Shop Management App',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          routerConfig: router,
        );
      },
    );
  }
}
