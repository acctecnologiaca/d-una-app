import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_search_bar.dart';
import '../../providers/suppliers_provider.dart';
import '../widgets/supplier_card.dart';
import 'supplier_search_screen.dart';

import '../../../../profile/presentation/providers/profile_provider.dart';
import '../../../../profile/presentation/screens/verification_screen.dart';

class SuppliersDirectoryScreen extends ConsumerWidget {
  const SuppliersDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final suppliersAsync = ref.watch(suppliersProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    // Determine verification status safely
    final isVerified =
        userProfileAsync.asData?.value?.verificationStatus == 'verified';

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
              hintText: 'Buscar proveedores, productos, marcas,...',
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
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];

                    // Logic: Is this supplier locked for this user?
                    // Logic: Is this supplier locked for this user?

                    final isRetail =
                        supplier.tradeType == 'RETAIL' ||
                        supplier.tradeType == 'BOTH';

                    bool isLocked = false;
                    String lockMessage = '';

                    if (isRetail) {
                      // Retail is always open
                      isLocked = false;
                    } else {
                      // WHOLESALE
                      // Logic:
                      // 1. Unverified -> Locked (Restricted).
                      //    Note: "Denied" suppliers (Wholesale Business) are filtered out by Backend.
                      //    So any Wholesale supplier appearing here for Unverified is "Restricted".
                      if (!isVerified) {
                        isLocked = true;
                        // Generic message for restricted access
                        lockMessage =
                              "Para acceder a los productos de este proveedor debes estar verificado.";
                      } else {
                        // Verified User (Individual or Business)
                        // 2. Verified Individual ->
                        //    - Wholesale (Individual) -> Full -> Open
                        //    - Wholesale (Business) -> Partial -> Open (Blur inside)
                        // 3. Verified Business -> Full -> Open
                        
                        // Therefore, for Verified users, the Card is ALWAYS Open in the directory.
                        // The restriction (Partial) is handled inside the details screen.
                        isLocked = false;
                      }
                    }

                    return SupplierCard(
                      supplier: supplier,
                      isLocked: isLocked, // Pass lock status
                      onTap: () {
                        if (isLocked) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 5),
                              content: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      lockMessage,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).hideCurrentSnackBar();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const VerificationScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Verificar',
                                      style: TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).hideCurrentSnackBar();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SupplierSearchScreen(
                              initialSupplierId: supplier.id,
                            ),
                          ),
                        );
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
