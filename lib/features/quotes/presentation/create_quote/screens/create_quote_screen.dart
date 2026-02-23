import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/create_quote_provider.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/utils/currency_formatter.dart';

class CreateQuoteScreen extends ConsumerStatefulWidget {
  const CreateQuoteScreen({super.key});

  @override
  ConsumerState<CreateQuoteScreen> createState() => _CreateQuoteScreenState();
}

class _CreateQuoteScreenState extends ConsumerState<CreateQuoteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final quoteState = ref.watch(createQuoteProvider);

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Nueva cotización',
        subtitle: '#C-00000011', // Placeholder or fetched ID
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: colors.onSurface),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurfaceVariant,
          indicatorColor: colors.primary,
          tabs: const [
            Tab(text: 'Productos'),
            Tab(text: 'Servicios'),
            Tab(text: 'Cliente'),
            Tab(text: 'Detalles'),
            Tab(text: 'Condiciones'),
            Tab(text: 'Resumen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Products Tab
          _buildProductsTab(quoteState),
          // 2. Services Tab (Placeholder)
          const Center(child: Text('Servicios')),
          // 3. Client Tab (Placeholder)
          const Center(child: Text('Cliente')),
          // 4. Details Tab (Placeholder)
          const Center(child: Text('Detalles')),
          // 5. Conditions Tab (Placeholder)
          const Center(child: Text('Condiciones')),
          // 6. Summary Tab (Placeholder)
          const Center(child: Text('Resumen')),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildProductsTab(QuoteState state) {
    if (state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Potentially an illustration here if available in assets
            Text(
              'No hay productos agregados',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.products.length,
      itemBuilder: (context, index) {
        final product = state.products[index];
        final colors = Theme.of(context).colorScheme;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: colors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.brand != null && product.brand!.isNotEmpty)
                        Text(
                          product.brand!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (product.model != null &&
                          product.model!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          product.model!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${product.quantity.toStringAsFixed(product.quantity.truncateToDouble() == product.quantity ? 0 : 2)} ${product.uom}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colors.onSecondaryContainer,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            CurrencyFormatter.format(product.totalPrice),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: colors.error,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    ref
                        .read(createQuoteProvider.notifier)
                        .removeProduct(product.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget? _buildFab() {
    final colors = Theme.of(context).colorScheme;
    // Show FAB only on specific tabs if desired, e.g., Products/Services
    // For now, consistent "Agregar" as shown in screenshot
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: FloatingActionButton.extended(
        onPressed: () {
          // Handle Add Action based on tab index
          if (_tabController.index == 0) {
            context.push('/quotes/create/select-product');
          }
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Agregar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
