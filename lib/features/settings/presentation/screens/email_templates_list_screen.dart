import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/email_templates_provider.dart';

class EmailTemplatesListScreen extends ConsumerWidget {
  const EmailTemplatesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final templatesAsync = ref.watch(emailTemplatesListProvider);

    const documentTypes = [
      {'id': 'quote', 'label': 'Cotizaciones', 'icon': Icons.description_outlined},
      {'id': 'order', 'label': 'Pedidos', 'icon': Icons.shopping_cart_outlined},
      {'id': 'receipt', 'label': 'Recibos', 'icon': Icons.receipt_long_outlined},
      {'id': 'report', 'label': 'Reportes', 'icon': Icons.analytics_outlined},
    ];

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Configuración de Correos'),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: templatesAsync.when(
        data: (templates) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: documentTypes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final type = documentTypes[index];
              final template = templates.where((t) => t.documentType == type['id']).firstOrNull;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colors.outlineVariant),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    child: Icon(type['icon'] as IconData, color: colors.onPrimaryContainer),
                  ),
                  title: Text(
                    type['label'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    template != null 
                        ? 'Configurado' 
                        : 'Usando valores por defecto',
                    style: TextStyle(
                      color: template != null ? colors.primary : colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
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
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
