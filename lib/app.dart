import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
// FIX: Hide Flutter's own LockState (in src/widgets) so ours is unambiguous
import 'core/providers/app_state_provider.dart';
import 'features/lock/lock_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/settings/settings_screen.dart';

class ArthaApp extends StatelessWidget {
  const ArthaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AppGate(),
    );
  }
}

// Decides what to show based on lock state
class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    return switch (state) {
      // FIX: Use AppLockState prefix to avoid Flutter's LockState clash
      AppLockState.checking => const _Splash(),
      AppLockState.locked => LockScreen(
          onUnlocked: () =>
              ref.read(appStateProvider.notifier).unlock()),
      AppLockState.unlocked ||
      AppLockState.noAuth =>
        const MainNav(),
    };
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('₹',
                style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: AppColors.purple)),
            SizedBox(height: 20),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.purple),
            ),
          ],
        ),
      ),
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> with WidgetsBindingObserver {
  int _idx = 0;
  DateTime? _bgAt;

  static const _screens = [
    DashboardScreen(),
    TransactionsScreen(),
    ChatScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused) {
      _bgAt = DateTime.now();
    } else if (s == AppLifecycleState.resumed && _bgAt != null) {
      final elapsed = DateTime.now().difference(_bgAt!).inSeconds;
      if (elapsed > 30) {
        ProviderScope.containerOf(context)
            .read(appStateProvider.notifier)
            .lock();
      }
      _bgAt = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Transactions'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Chat'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}