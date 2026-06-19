import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/profile_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/medicines/presentation/medicine_list_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/sales/presentation/pos_screen.dart';
import '../../features/sales/presentation/sales_history_screen.dart';

/// Top-level navigation: a [NavigationBar] on phones and a [NavigationRail] on
/// wider tablet/desktop layouts.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _destinations = <_Dest>[
    _Dest('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
    _Dest('Inventory', Icons.medication_outlined, Icons.medication),
    _Dest('Sell', Icons.point_of_sale_outlined, Icons.point_of_sale),
    _Dest('Reports', Icons.bar_chart_outlined, Icons.bar_chart),
    _Dest('Profile', Icons.person_outline, Icons.person),
  ];

  void _goTo(int i) => setState(() => _index = i);

  List<Widget> get _pages => [
        DashboardScreen(
          onSeeAllSales: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
          ),
        ),
        const MedicineListScreen(),
        const PosScreen(),
        const ReportsScreen(),
        const ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    final body = IndexedStack(index: _index, children: _pages);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _goTo,
              labelType: NavigationRailLabelType.all,
              destinations: _destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: _destinations
            .map((d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }
}

class _Dest {
  const _Dest(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
