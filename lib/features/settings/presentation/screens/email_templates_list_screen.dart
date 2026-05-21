import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/custom_menu_tile.dart';
import '../providers/email_templates_provider.dart';

class EmailTemplatesListScreen extends ConsumerWidget {
  const EmailTemplatesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final templatesAsync = ref.watch(emailTemplatesListProvider);

    const documentTypes = [
      {'id': 'quote', 'label': 'Cotizaciones', 'icon': Symbols.request_quote},
      {'id': 'order', 'label': 'Pedidos', 'icon': Icons.shopping_cart_outlined},
      {
        'id': 'receipt',
        'label': 'Recibos',
        'icon': Icons.receipt_long_outlined,
      },
      {'id': 'report', 'label': 'Reportes', 'icon': Symbols.contract},
    ];

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: const StandardAppBar(title: 'Plantillas de correos electrónicos'),
      body: templatesAsync.when(
        data: (templates) {
          return ListView(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 16.0,
            ),
            children: documentTypes.map((type) {
              final template = templates
                  .where((t) => t.documentType == type['id'])
                  .firstOrNull;
              return CustomMenuTile(
                icon: type['icon'] as IconData,
                title: type['label'] as String,
                subtitle: template != null
                    ? 'Plantilla personalizada'
                    : 'Plantilla por defecto',
                subtitleStyle: textTheme.bodyMedium?.copyWith(
                  color: template != null
                      ? colors.onSurfaceVariant
                      : colors.onSurfaceVariant,
                  fontWeight: template != null
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                onTap: () {
                  context.push(
                    '/settings/email-templates/edit',
                    extra: {
                      'typeId': type['id'],
                      'label': type['label'],
                      'template': template,
                    },
                  );
                },
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
