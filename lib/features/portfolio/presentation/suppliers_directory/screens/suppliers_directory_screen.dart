import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_search_bar.dart';
import '../../providers/suppliers_provider.dart';
import '../widgets/supplier_card.dart';
import 'supplier_search_screen.dart';

import '../../../../profile/presentation/providers/profile_provider.dart';

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
                    final allowedTypes = supplier.allowedVerificationTypes;
                    final isRestricted = allowedTypes.isNotEmpty;

                    final userType =
                        userProfileAsync.asData?.value?.verificationType;
                    final isBusiness = userType == 'business';
                    final isRetail =
                        supplier.tradeType == 'RETAIL' ||
                        supplier.tradeType == 'BOTH';

                    bool isLocked = true;

                    if (isBusiness) {
                      // Rule 3: Business overrides all
                      isLocked = false;
                    } else if (isRetail) {
                      // Rule 1: Retail/Both is accessible to unverified/individuals explicitly
                      // (Unless we want to respect isRestricted for Retail too? User implies Retail is public)
                      isLocked = false;
                    } else {
                      // It is WHOLESALE (or null)

                      // Rule: Unverified cannot access ANY Wholesaler
                      if (!isVerified) {
                        isLocked = true;
                      } else {
                        // User is Verified Individual accessing Wholesaler
                        if (isRestricted) {
                          // Check list matches
                          if (userType == null ||
                              !allowedTypes.contains(userType)) {
                            isLocked = true;
                          } else {
                            isLocked = false;
                          }
                        } else {
                          // Wholesaler with no explicit list -> Accessible to Verified Individual
                          isLocked = false;
                        }
                      }
                    }

                    return SupplierCard(
                      supplier: supplier,
                      isLocked: isLocked, // Pass lock status
                      onTap: () {
                        if (isLocked) {
                          // Show "Access Denied" dialog or snackbar
                          final requiredTypes = allowedTypes.join(' o ');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                !isVerified
                                    ? 'Este proveedor es exclusivo para usuarios verificados ($requiredTypes).'
                                    : 'Tu tipo de verificación no permite acceder a este proveedor (Requiere: $requiredTypes).',
                              ),
                              action: SnackBarAction(
                                label: 'Verificarme',
                                onPressed: () {
                                  // TODO: Navigate to Verification Screen
                                },
                              ),
                            ),
                          );
                          return;
                        }
                        // Navigate to Supplier Product Catalog with Filter
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
