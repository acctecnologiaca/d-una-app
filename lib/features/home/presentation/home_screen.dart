import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class HomeScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    // Determine the current path
    final String location = GoRouterState.of(context).uri.path;

    // Define main paths where the bottom bar should be visible
    final bool showBottomBar = [
      '/clients',
      '/portfolio',
      '/quotes',
      '/reports',
    ].contains(location);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: showBottomBar
          ? NavigationBar(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Symbols.people, weight: 600),
                  label: 'Clientes',
                ),
                NavigationDestination(
                  icon: Icon(Symbols.widgets, weight: 600),
                  label: 'Portafolio',
                ),
                NavigationDestination(
                  icon: Icon(Symbols.request_quote, weight: 600),
                  label: 'Cotizaciones',
                ),
                NavigationDestination(
                  icon: Icon(Symbols.contract, weight: 600),
                  label: 'Reportes',
                ),
              ],
            )
          : null,
    );
  }
}
