import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/permissions.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/medicines/presentation/medicine_list_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/sales/presentation/pos_screen.dart';
import '../../features/sales/presentation/sales_history_screen.dart';

/// Top-level navigation: a [NavigationBar] on phones and a [NavigationRail] on
/// wider tablet/desktop layouts. The set of tabs is filtered by the signed-in
/// user's permissions; Profile is always available.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  void _goTo(int i) => setState(() => _index = i);

  /// Builds the tabs the current user is allowed to see.
  List<_Tab> _tabsFor(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    bool can(AppPermission p) => user?.can(p) ?? false;

    return [
      if (can(AppPermission.dashboard))
        _Tab(
          'Dashboard',
          Icons.dashboard_outlined,
          Icons.dashboard,
          DashboardScreen(
            onSeeAllSales: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
            ),
          ),
        ),
      if (can(AppPermission.inventoryView))
        _Tab(
          'Inventory',
          Icons.medication_outlined,
          Icons.medication,
          const MedicineListScreen(),
        ),
      if (can(AppPermission.sell))
        _Tab(
          'Sell',
          Icons.point_of_sale_outlined,
          Icons.point_of_sale,
          const PosScreen(),
        ),
      if (can(AppPermission.reports))
        _Tab(
          'Reports',
          Icons.bar_chart_outlined,
          Icons.bar_chart,
          const ReportsScreen(),
        ),
      // Profile is always available so every user can edit their profile / sign
      // out, even if no other area is permitted.
      _Tab(
        'Profile',
        Icons.person_outline,
        Icons.person,
        const ProfileScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabsFor(context);
    final index = _index.clamp(0, tabs.length - 1);
    final body = IndexedStack(
      index: index,
      children: tabs.map((t) => t.page).toList(),
    );

    // A NavigationBar/Rail needs at least two destinations; if a role can only
    // reach Profile, show it on its own without a navigation chrome.
    if (tabs.length < 2) {
      return Scaffold(body: body);
    }

    final isWide = MediaQuery.of(context).size.width >= 720;
    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: _goTo,
              labelType: NavigationRailLabelType.all,
              destinations: tabs
                  .map(
                    (t) => NavigationRailDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(t.selectedIcon),
                      label: Text(t.label),
                    ),
                  )
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
        selectedIndex: index,
        onDestinationSelected: _goTo,
        destinations: tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.selectedIcon),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon, this.page);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}
