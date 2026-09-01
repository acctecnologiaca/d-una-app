import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
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
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(suppliersProvider);
                ref.invalidate(userProfileProvider);
                await ref.read(suppliersProvider.future);
              },
              child: suppliersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => FriendlyErrorWidget(
                  error: err,
                  onRetry: () => ref.invalidate(suppliersProvider),
                ),
                data: (suppliers) {
                  if (suppliers.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: const Center(
                          child: Text(
                            'No hay proveedores disponibles para tu rubro.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                            AppToast.warning(
                              context,
                              message: lockMessage,
                              actionLabel: 'Verificar',
                              onAction: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const VerificationScreen(),
                                  ),
                                );
                              },
                              duration: const Duration(seconds: 5),
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
          ),
        ],
      ),
    );
  }
}
