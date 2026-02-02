import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../shared/widgets/info_block.dart';
import '../../../../data/models/service_model.dart';
import '../../../providers/services_provider.dart';

class ServiceDetailsScreen extends ConsumerWidget {
  final ServiceModel service;

  const ServiceDetailsScreen({super.key, required this.service});

  String _getSymbol(String unit) {
    final match = RegExp(r'\((.*?)\)').firstMatch(unit);
    return match?.group(1) ?? unit;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Watch the list of services to react to updates
    final servicesAsync = ref.watch(servicesProvider);

    // Find the latest version of this service in the list, or fallback to the one passed in
    final latestService =
        servicesAsync.valueOrNull?.firstWhere(
          (s) => s.id == service.id,
          orElse: () => service,
        ) ??
        service;

    final symbol =
        latestService.serviceRate?.symbol ??
        _getSymbol(latestService.serviceRateId);
    final isPriceFixed = latestService.price > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del servicio'),
        centerTitle: false,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        titleSpacing:
            0, // Match default or adjust if needed to align with back button
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 20,
          color: colors.onSurface,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Eliminar servicio'),
                  content: const Text(
                    '¿Estás seguro de que deseas eliminar este servicio?',
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancelar'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: const Text(
                        'Eliminar',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref
                    .read(servicesProvider.notifier)
                    .deleteService(latestService.id);
                if (context.mounted) {
                  context.pop(); // Close details
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Servicio eliminado')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Text(
              latestService.name,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Category
            InfoBlock.text(
              icon: Icons.category_outlined,
              label: 'Categoría',
              value: (latestService.category == null)
                  ? 'Sin categoría'
                  : latestService.category!.name,
            ),
            const SizedBox(height: 24),

            // Warranty
            InfoBlock.text(
              icon: Icons.verified_outlined,
              label: 'Tiempo de garantía',
              value: latestService.hasWarranty == true
                  ? '${latestService.warrantyTime} ${latestService.warrantyUnit}'
                  : 'No ofrezco garantía',
            ),
            const SizedBox(height: 24),

            // Description
            InfoBlock(
              icon: Icons.description_outlined,
              label: 'Descripción',
              content:
                  (latestService.description == null ||
                      latestService.description!.isEmpty)
                  ? const Text('Sin descripción')
                  : _ExpandableDescription(text: latestService.description!),
            ),

            const SizedBox(height: 24),

            // Price
            InfoBlock(
              icon: Icons.attach_money,
              label: 'Precio de venta',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPriceFixed
                        ? '\$${latestService.price.toStringAsFixed(2)}/$symbol'
                        : '??/$symbol',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.onSurface,
                    ),
                  ),
                  if (!isPriceFixed)
                    Text(
                      'Precio variable',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: FloatingActionButton(
          onPressed: () {
            context.push(
              '/portfolio/own-services/edit/${latestService.id}',
              extra: latestService,
            );
          },
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  final String text;

  const _ExpandableDescription({required this.text});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Simple logic: if short, just show. If long, truncate.
    // Length threshold could be adjusted.
    final isLong = widget.text.length > 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _isExpanded ? null : 3,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            color: colors.onSurface,
            fontWeight: FontWeight.w400,
          ),
        ),
        if (isLong)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                _isExpanded ? 'Ver menos' : 'Ver más',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
