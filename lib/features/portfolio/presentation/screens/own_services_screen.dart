import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/custom_search_bar.dart';
import '../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../data/models/service_model.dart';
import '../providers/services_provider.dart';
import 'widgets/service_item_card.dart';

class OwnServicesScreen extends ConsumerStatefulWidget {
  const OwnServicesScreen({super.key});

  @override
  ConsumerState<OwnServicesScreen> createState() => _OwnServicesScreenState();
}

class _OwnServicesScreenState extends ConsumerState<OwnServicesScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Sort state could be expanded later, currently matching image "Frecuente"
  final String _currentSortLabel = 'Frecuente';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final servicesAsync = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios propios'),
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colors.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: CustomSearchBar(
              controller: _searchController,
              hintText: 'Buscar servicio...',
              readOnly: true,
              onTap: () {
                context.push('/portfolio/own-services/search');
              },
              showFilterIcon: true,
            ),
          ),

          // Sort/Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // TODO: Show sort options bottom sheet
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ordenar: Pendiente de implementación'),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        _currentSortLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_downward,
                        size: 16,
                        color: colors.onSurface,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: servicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (services) {
                if (services.isEmpty) {
                  return Center(
                    child: Text(
                      'No tienes servicios registrados',
                      style: TextStyle(color: colors.outline),
                    ),
                  );
                }

                // Sorting
                List<ServiceModel> finalServices = List.from(services);
                // Default sort: already sorted by repo (created_at desc)
                // If we implement client side sort, we would do it here.

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: finalServices.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final service = finalServices[index];
                    return ServiceItemCard(
                      name: service.name,
                      description: service.description,
                      price: service.price,
                      priceUnit: service.serviceRate != null
                          ? '${service.serviceRate!.name} (${service.serviceRate!.symbol})'
                          : '',
                      onTap: () {
                        _showServiceActionSheet(context, service, colors);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            // Navigate to Add Service Wizard
            context.push('/portfolio/own-services/add');
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'Agregar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
        ),
      ),
    );
  }

  void _showServiceActionSheet(
    BuildContext context,
    ServiceModel service,
    ColorScheme colors,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: colors.surfaceContainer,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  height: 4,
                  width: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Servicio seleccionado',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Service Info Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ServiceItemCard(
                  name: service.name,
                  description: service.category?.name ?? service.description,
                  price: service.price,
                  priceUnit: service.serviceRate != null
                      ? '${service.serviceRate!.name} (${service.serviceRate!.symbol})'
                      : '',
                  onTap: () {}, // No action in sheet
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Actions
              BottomSheetActionItem(
                icon: Icons.request_quote_outlined,
                label: 'Cotizar a cliente',
                onTap: () {
                  context.pop();
                  // No-op for now
                },
              ),
              BottomSheetActionItem(
                icon: 'assets/icons/add_request_quote.png',
                label: 'Agregar a cotización existente',
                onTap: () {
                  context.pop();
                  // No-op for now
                },
              ),
              BottomSheetActionItem(
                icon: Icons.info_outline,
                label: 'Detalles del servicio',
                onTap: () {
                  context.pop();
                  context.push(
                    '/portfolio/own-services/details/${service.id}',
                    extra: service,
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
