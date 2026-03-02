import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/create_quote_provider.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../../../../../shared/widgets/custom_dropdown.dart';
import '../widgets/quote_added_product_card.dart';
import '../widgets/quote_added_service_card.dart';
import '../widgets/quote_product_sale_details_sheet.dart';
import '../widgets/quote_service_sale_details_sheet.dart';
import '../providers/quote_service_selection_provider.dart';
import '../../../domain/models/quote_aggregated_product.dart';
import '../../../data/models/quote_item_product.dart';
import '../../../../clients/presentation/providers/clients_provider.dart';
import '../../../../clients/data/models/client_model.dart';

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
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
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
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
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
          // 2. Services Tab
          _buildServicesTab(quoteState),
          // 3. Client Tab
          _buildClientTab(quoteState),
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

    final groupedProducts = <String, List<QuoteItemProduct>>{};
    for (var product in state.products) {
      if (!groupedProducts.containsKey(product.name)) {
        groupedProducts[product.name] = [];
      }
      groupedProducts[product.name]!.add(product);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: groupedProducts.length,
      itemBuilder: (context, index) {
        final groupName = groupedProducts.keys.elementAt(index);
        final items = groupedProducts[groupName]!;
        final firstItem = items.first;

        double totalQuantity = 0;
        double totalAvailableStock = 0;
        double totalCost = 0;
        double subtotal = 0;

        for (var item in items) {
          totalQuantity += item.quantity;
          totalAvailableStock += item.availableStock ?? double.infinity;
          totalCost += item.costPrice * item.quantity;
          subtotal += item.unitPrice * item.quantity;
        }

        double averageCost = totalQuantity > 0
            ? totalCost / totalQuantity
            : firstItem.costPrice;

        final bool isTemporal = firstItem.isTemporal;

        return QuoteAddedProductCard(
          name: groupName,
          brand: firstItem.brand,
          model: firstItem.model,
          uom: firstItem.uom,
          subtotal: subtotal,
          totalQuantity: totalQuantity,
          totalAvailableStock: isTemporal ? 99999 : totalAvailableStock,
          isTemporal: isTemporal,
          onDelete: () {
            ref
                .read(createQuoteProvider.notifier)
                .removeProductGroup(groupName);
          },
          onEditPrice: () async {
            final result = await QuoteProductSaleDetailsSheet.show(
              context,
              averageCost: averageCost,
              productName: groupName,
              brand: firstItem.brand,
              model: firstItem.model,
            );
            if (result != null) {
              final newPrice = result['sellingPrice'] as double;
              final newMargin = result['profitMargin'] as double;
              ref
                  .read(createQuoteProvider.notifier)
                  .updateGroupPrice(groupName, newPrice, newMargin);
            }
          },
          onEditSources: () {
            // Build the initial selections map
            final Map<String, double> initialSelections = {};
            for (var item in items) {
              final sourceId = item.supplierProductId ?? item.productId;
              if (sourceId != null) {
                initialSelections[sourceId] = item.quantity;
              }
            }

            // Construct a QuoteAggregatedProduct to pass to sources screen
            final productObj = QuoteAggregatedProduct(
              name: groupName,
              brand: firstItem.brand ?? '',
              model: firstItem.model ?? '',
              uom: firstItem.uom,
              minPrice: firstItem.costPrice,
              totalQuantity: totalAvailableStock,
              supplierCount: items.length,
              hasOwnInventory: items.any((i) => i.productId != null),
              frequencyScore: 0,
              lastAddedAt: DateTime.now(),
              category: '',
              sources: [],
            );
            context.push(
              '/quotes/create/select-product/product-sources',
              extra: {
                'product': productObj,
                'initialSelections': initialSelections,
              },
            );
          },
          onEditTemporal: isTemporal
              ? () async {
                  final result = await context.push<bool>(
                    '/quotes/create/select-product/temporal-product',
                    extra: firstItem,
                  );
                  if (result == true && mounted) {
                    setState(() {});
                  }
                }
              : null,
          onQuantityChanged: (newQty) {
            ref
                .read(createQuoteProvider.notifier)
                .updateGroupQuantity(groupName, newQty);
          },
        );
      },
    );
  }

  Widget _buildServicesTab(QuoteState state) {
    if (state.services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No hay servicios agregados',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final suggestionsAsync = ref.watch(quoteServiceSuggestionsProvider);
    final serviceModels = suggestionsAsync.value ?? [];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.services.length,
      itemBuilder: (context, index) {
        final serviceItem = state.services[index];
        final serviceModel = serviceModels
            .where((s) => s.id == serviceItem.serviceId)
            .firstOrNull;

        // Try to get category and rate from the model, or fallback
        final categoryName = serviceModel?.category?.name;

        String rateSuffix;
        if (serviceModel == null) {
          // Temporal service: use stored symbol directly
          rateSuffix = '/${serviceItem.rateSymbol}';
        } else {
          final rateName =
              serviceModel.serviceRate?.name.toLowerCase() ?? 'ud.';
          rateSuffix = '/ud.';
          if (rateName.contains('hora') || rateName.contains('h')) {
            rateSuffix = '/h';
          } else if (rateName.contains('día') || rateName.contains('dia')) {
            rateSuffix = '/dia';
          } else if (rateName.contains('mes')) {
            rateSuffix = '/mes';
          } else if (rateName.contains('serv')) {
            rateSuffix = '/serv.';
          }
        }

        return QuoteAddedServiceCard(
          name: serviceItem.name,
          category: categoryName,
          subtotal: serviceItem.unitPrice,
          quantity: serviceItem.quantity,
          rateSuffix: rateSuffix,
          executionTime: serviceItem.executionTimeId,
          isTemporal: serviceItem.serviceId == null,
          onDelete: () {
            ref
                .read(createQuoteProvider.notifier)
                .removeService(serviceItem.id);
          },
          onEditSaleDetails: () async {
            final isTemporal = serviceItem.serviceId == null;
            if (isTemporal) {
              final result = await context.push<bool>(
                '/quotes/create/select-service/temporal-service',
                extra: serviceItem,
              );
              if (result == true && mounted) {
                setState(() {});
              }
              return;
            }
            if (serviceModel == null) {
              return; // Cannot edit without full model yet
            }
            final result = await QuoteServiceSaleDetailsSheet.show(
              context,
              service: serviceModel,
              existingItem: serviceItem,
            );
            if (result != null) {
              ref
                  .read(createQuoteProvider.notifier)
                  .updateServiceDetails(result);
            }
          },
          onQuantityChanged: (newQty) {
            ref
                .read(createQuoteProvider.notifier)
                .updateServiceQuantity(serviceItem.id, newQty);
          },
        );
      },
    );
  }

  Widget _buildClientTab(QuoteState state) {
    final clientsAsync = ref.watch(clientsProvider);
    final clients = clientsAsync.value ?? [];

    // Find the currently selected client object
    final selectedClient = clients
        .where((c) => c.id == state.clientId)
        .firstOrNull;

    final contacts = selectedClient?.contacts ?? [];
    final selectedContact = contacts
        .where((c) => c.id == state.contactId)
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Client Dropdown ───────────────────────────────────────────
          CustomDropdown<Client>(
            value: selectedClient,
            items: clients,
            label: 'Nombre o razón social',
            searchable: true,
            itemLabelBuilder: (c) => c.alias != null && c.alias!.isNotEmpty
                ? '${c.name} (${c.alias})'
                : c.name,
            showAddOption: true,
            addOptionLabel: 'Agregar cliente',
            onAddPressed: () async {
              final previousClients = clientsAsync.value ?? [];
              await context.push('/clients/add');

              // Refresh and wait for result
              final newClientsResult = await ref.refresh(
                clientsProvider.future,
              );

              if (mounted && newClientsResult.length > previousClients.length) {
                // Auto-select the newly added one (find the ID not in previous list)
                final oldIds = previousClients.map((c) => c.id).toSet();
                final newClient = newClientsResult.firstWhere(
                  (c) => !oldIds.contains(c.id),
                  orElse: () => newClientsResult.last,
                );
                ref
                    .read(createQuoteProvider.notifier)
                    .setClient(newClient.id, newClient.name);
              }
            },
            onChanged: (client) {
              if (client != null) {
                ref
                    .read(createQuoteProvider.notifier)
                    .setClient(client.id, client.name);

                // If it's a person, they don't have separate contacts, clear contact selection
                if (client.type == 'person') {
                  ref.read(createQuoteProvider.notifier).setContact('', '');
                }
              }
            },
          ),
          const SizedBox(height: 24),

          // ── Contact Dropdown ───────────────────────────────────────────
          CustomDropdown<Contact>(
            value: selectedContact,
            items: contacts,
            label: 'Persona de contacto',
            searchable: true,
            itemLabelBuilder: (c) => c.role != null && c.role!.isNotEmpty
                ? '${c.name} — ${c.role}'
                : c.name,
            // Disabled until a company client is selected
            onChanged:
                (selectedClient == null || selectedClient.type == 'person')
                ? null
                : (contact) {
                    if (contact != null) {
                      ref
                          .read(createQuoteProvider.notifier)
                          .setContact(contact.id, contact.name);
                    }
                  },
            showAddOption:
                selectedClient != null && selectedClient.type != 'person',
            addOptionLabel: 'Agregar contacto',
            onAddPressed:
                (selectedClient == null || selectedClient.type == 'person')
                ? null
                : () async {
                    final previousContacts = selectedClient.contacts;
                    await context.push(
                      '/clients/${selectedClient.id}/contacts/add',
                      extra: selectedClient.name,
                    );

                    // Refresh to get the new contact
                    final newClientsResult = await ref.refresh(
                      clientsProvider.future,
                    );

                    if (mounted) {
                      // Find the updated client object
                      final updatedClient = newClientsResult.firstWhere(
                        (c) => c.id == selectedClient.id,
                        orElse: () => selectedClient,
                      );
                      if (updatedClient.contacts.length >
                          previousContacts.length) {
                        final oldIds = previousContacts
                            .map((c) => c.id)
                            .toSet();
                        final newContact = updatedClient.contacts.firstWhere(
                          (c) => !oldIds.contains(c.id),
                          orElse: () => updatedClient.contacts.last,
                        );
                        ref
                            .read(createQuoteProvider.notifier)
                            .setContact(newContact.id, newContact.name);
                      }
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget? _buildFab() {
    // Only show FAB on Products (0) and Services (1) tabs
    if (_tabController.index != 0 && _tabController.index != 1) return null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: CustomExtendedFab(
        onPressed: () {
          if (_tabController.index == 0) {
            context.push('/quotes/create/select-product');
          } else if (_tabController.index == 1) {
            context.push('/quotes/create/select-service');
          }
        },
        icon: Icons.add,
        label: 'Agregar',
      ),
    );
  }
}
