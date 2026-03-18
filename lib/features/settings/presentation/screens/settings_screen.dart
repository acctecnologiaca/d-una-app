import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: const StandardAppBar(title: 'Configuración'),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          // Group 1: Productos y finanzas
          _buildSectionHeader('Productos y finanzas', textTheme, colors),
          _buildSettingsItem(
            'Marcas de productos',
            context,
            onTap: () {
              context.push('/settings/brands');
            },
          ),
          _buildSettingsItem(
            'Categorías',
            context,
            onTap: () => context.push('/settings/categories'),
          ),
          _buildSettingsItem(
            'Unidades de medidas',
            context,
            onTap: () => context.push('/settings/uoms'),
          ),
          _buildSettingsItem(
            'Tarifas de servicios',
            context,
            onTap: () => context.push('/settings/service-rates'),
          ),
          _buildSettingsItem(
            'Parámetros financieros',
            context,
            onTap: () => context.push('/settings/financial-parameters'),
          ),
          const Divider(height: 32),

          // Group 2: Logística
          _buildSectionHeader('Logística', textTheme, colors),
          _buildSettingsItem(
            'Proveedores no afiliados',
            context,
            onTap: () => context.push('/settings/unaffiliated-suppliers'),
          ),
          _buildSettingsItem(
            'Empresas de encomienda',
            context,
            onTap: () => context.push('/settings/shipping-companies'),
          ),
          _buildSettingsItem(
            'Tiempos de entrega y ejecución',
            context,
            onTap: () => context.push('/settings/delivery-times'),
          ),
          _buildSettingsItem(
            'Métodos de envío',
            context,
            onTap: () => context.push('/settings/shipping-methods'),
          ),
          const Divider(height: 32),

          // Group 3: Términos y condiciones
          _buildSectionHeader('Términos y condiciones', textTheme, colors),
          _buildSettingsItem(
            'Condiciones comerciales',
            context,
            onTap: () => context.push('/settings/commercial-conditions'),
          ),
          _buildSettingsItem(
            'Observaciones',
            context,
            onTap: () => context.push('/settings/observations'),
          ),
          const Divider(height: 32),

          // Group 4: General (No header)
          _buildSettingsItem('Notificaciones', context, onTap: () {}),
          _buildSettingsItem('Acerca de...', context, onTap: () {}),

          // Bottom padding
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    TextTheme textTheme,
    ColorScheme colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
        top: 8.0,
      ),
      child: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colors.onSurface,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    String label,
    BuildContext context, {
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {
        // Since we pass empty closures `() {}` for upcoming items or actual navigation for finished ones,
        // we can check if it's an empty closure or just let them tap. For now we just call onTap.
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32.0, 16.0, 16.0, 16.0),
        child: Text(
          label,
          style: textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}
