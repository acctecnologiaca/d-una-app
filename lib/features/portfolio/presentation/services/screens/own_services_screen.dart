import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/widgets/custom_search_bar.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../../../data/models/service_model.dart';
import '../../providers/services_provider.dart';
import '../../../../../shared/widgets/service_list_item.dart';
import '../widgets/service_action_sheet.dart';
import '../../../../../shared/widgets/empty_list_state.dart';

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

    final isError = servicesAsync.maybeWhen(
      error: (error, stack) => true,
      orElse: () => false,
    );

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
          if (!isError) ...[
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
                showFilterIcon: true,
                onTap: () {
                  context.push('/portfolio/own-services/search');
                },
              ),
            ),

            // Disclaimer
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

            // Sort Header
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
                    options: const [
                      SortOption.recent,
                      SortOption.nameAZ,
                      SortOption.nameZA,
                    ],
                  ),
                ],
              ),
            ),
          ],

          Expanded(
            child: servicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => FriendlyErrorWidget(
                error: err,
                onRetry: () => ref.invalidate(
                  servicesAsync.asData == null
                      ? servicesProvider
                      : servicesProvider,
                ), // Force refresh
              ),
              data: (services) {
                if (services.isEmpty) {
                  return EmptyListState(
                    icon: Icons.handyman_outlined,
                    message: 'No tienes servicios registrados',
                    searchQuery: _searchController.text,
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
                    default:
                      return 0;
                  }
                });

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  itemCount: finalServices.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Colors.transparent),
                  itemBuilder: (context, index) {
                    final service = finalServices[index];
                    return ServiceListItem(
                      service: service,
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
      floatingActionButton: isError
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: CustomExtendedFab(
                onPressed: () {
                  // Navigate to Add Service Wizard
                  context.push('/portfolio/own-services/add');
                },
                label: 'Agregar',
                icon: Icons.add,
              ),
            ),
    );
  }

  void _showServiceActionSheet(BuildContext context, ServiceModel service) {
    ServiceActionSheet.show(context, service);
  }
}
