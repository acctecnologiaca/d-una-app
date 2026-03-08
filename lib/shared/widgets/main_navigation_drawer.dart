import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

class MainNavigationDrawer extends StatelessWidget {
  const MainNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final String currentRoute = GoRouterState.of(context).uri.path;

    return Drawer(
      backgroundColor: colors.surfaceContainerLow,
      elevation: 0,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Logo
            Padding(
              padding: const EdgeInsets.only(
                top: 24.0,
                left: 24.0,
                bottom: 24.0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/images/logo_d_una.png',
                  height: 48,
                  // Adjust fit or size if needed based on the actual asset
                ),
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: Symbols.shopping_cart,
                    label: 'Pedidos a proveedores',
                    route: '/supplier-orders', // Placeholder route
                    currentRoute: currentRoute,
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Symbols.receipt_long,
                    label: 'Mis compras',
                    route: '/my-purchases', // Placeholder route
                    currentRoute: currentRoute,
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Symbols.list_alt,
                    label: 'Notas de entrega',
                    route: '/delivery-notes', // Placeholder route
                    currentRoute: currentRoute,
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Symbols.receipt,
                    label: 'Recibos',
                    route: '/receipts', // Placeholder route
                    currentRoute: currentRoute,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Symbols.diversity_3,
                    label: 'Colaboradores',
                    route: '/collaborators', // Placeholder route
                    currentRoute: currentRoute,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Symbols.settings,
                    label: 'Configuración',
                    route: '/settings', // Placeholder route
                    currentRoute: currentRoute,
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Symbols.help,
                    label: 'Ayuda',
                    route: '/help', // Placeholder route
                    currentRoute: currentRoute,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required String currentRoute,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // In real app, match currentRoute.
    final isSelected =
        currentRoute == route || currentRoute.startsWith('$route/');

    return ListTile(
      leading: Icon(
        icon,
        fill: isSelected ? 1 : 0, // Filled icon if selected
        color: colors.onSurfaceVariant, // Fixed: Always onSurfaceVariant
        weight: isSelected ? 600 : 400,
      ),
      title: Text(
        label,
        style: textTheme.titleMedium?.copyWith(
          color: isSelected
              ? colors.onSecondaryContainer
              : colors.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedTileColor: colors.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      onTap: () {
        // Close drawer
        Navigator.pop(context);

        if (route == '/settings') {
          context.push(route);
        } else {
          // Disable navigation if route is placeholder and doesn't exist yet,
          // to prevent GoRouter exceptions.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navegando a $label (Próximamente)')),
          );
        }
      },
    );
  }
}
