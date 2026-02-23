import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/widgets/custom_search_bar.dart';
import '../../../data/models/service_model.dart';
import '../../providers/services_provider.dart';
import '../widgets/service_item_card.dart';
import '../widgets/service_action_sheet.dart';
import '../../../../../shared/widgets/sort_selector.dart';

class OwnServicesScreen extends ConsumerStatefulWidget {
  const OwnServicesScreen({super.key});

  @override
  ConsumerState<OwnServicesScreen> createState() => _OwnServicesScreenState();
}

class _OwnServicesScreenState extends ConsumerState<OwnServicesScreen> {
  final TextEditingController _searchController = TextEditingController();

  SortOption _currentSort = SortOption.recent;

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
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Precios no incluyen impuesto',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
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
                SortSelector(
                  currentSort: _currentSort,
                  onSortChanged: (val) => setState(() => _currentSort = val),
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
                finalServices.sort((a, b) {
                  switch (_currentSort) {
                    case SortOption.recent:
                    case SortOption.frequency:
                      return b.createdAt.compareTo(a.createdAt);
                    case SortOption.nameAZ:
                      return a.name.toLowerCase().compareTo(
                        b.name.toLowerCase(),
                      );
                    case SortOption.nameZA:
                      return b.name.toLowerCase().compareTo(
                        a.name.toLowerCase(),
                      );
                  }
                });

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: finalServices.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Colors.transparent),
                  itemBuilder: (context, index) {
                    final service = finalServices[index];
                    return ServiceItemCard(
                      name: service.name,
                      category: service.category?.name,
                      price: service.price,
                      priceUnit: service.serviceRate != null
                          ? '${service.serviceRate!.name} (${service.serviceRate!.symbol})'
                          : '',
                      onTap: () {
                        _showServiceActionSheet(context, service);
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

  void _showServiceActionSheet(BuildContext context, ServiceModel service) {
    ServiceActionSheet.show(context, service);
  }
}
