import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_search_bar.dart';
import '../../providers/suppliers_provider.dart';
import '../widgets/supplier_card.dart';
import 'supplier_search_screen.dart';

class SuppliersDirectoryScreen extends ConsumerWidget {
  const SuppliersDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('Inventario proveedores'),
        centerTitle: false,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomSearchBar(
              hintText: 'Busca productos, marcas, proveedores...',
              readOnly: true,
              showFilterIcon: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SupplierSearchScreen(),
                  ),
                );
              },
              onFilterTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SupplierSearchScreen(),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: suppliersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
              data: (suppliers) {
                if (suppliers.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay proveedores disponibles para tu rubro.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: suppliers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    return SupplierCard(
                      supplier: supplier,
                      onTap: () {
                        // TODO: Navigate to Supplier Product Catalog
                        // context.go('/portfolio/suppliers/${supplier.id}');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
