import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';

import 'package:d_una_app/features/auth/presentation/auth_routes.dart';
import 'package:d_una_app/features/clients/presentation/client_routes.dart';
import 'package:d_una_app/features/home/presentation/home_screen.dart';
import 'package:d_una_app/features/portfolio/presentation/portfolio_screen.dart';
import '../../features/portfolio/presentation/inventory/screens/own_inventory_screen.dart';
import '../../features/portfolio/presentation/inventory/screens/add_product/add_product_screen.dart';
import '../../features/portfolio/presentation/inventory/screens/edit_product/edit_product_screen.dart';
import '../../features/portfolio/presentation/inventory/screens/product_details/product_details_screen.dart';
import '../../features/portfolio/presentation/inventory/screens/product_search_screen.dart';
import '../../features/portfolio/presentation/services/screens/own_services_screen.dart';
import '../../features/portfolio/presentation/services/screens/service_search_screen.dart';
import '../../features/portfolio/presentation/services/screens/add_service/add_service_screen.dart';
import '../../features/portfolio/presentation/services/screens/service_details/service_details_screen.dart';
import '../../features/portfolio/presentation/services/screens/edit_service/edit_service_screen.dart';
import '../../features/portfolio/data/models/product_model.dart';
import '../../features/portfolio/data/models/service_model.dart';
import 'package:d_una_app/features/quotes/presentation/quotes_list/screens/quotes_list_screen.dart';
import 'package:d_una_app/features/quotes/presentation/quotes_list/screens/quotes_search_screen.dart';
import 'package:d_una_app/features/quotes/presentation/create_quote/screens/create_quote_screen.dart';
import '../../features/quotes/presentation/create_quote/screens/select_product_screen.dart';
import '../../features/quotes/presentation/create_quote/screens/quote_product_search_screen.dart';
import '../../features/quotes/presentation/create_quote/screens/quote_product_sources_screen.dart';
import '../../features/quotes/presentation/create_quote/screens/select_condition_screen.dart';
import '../../features/quotes/presentation/create_quote/screens/quote_condition_search_screen.dart';
import '../../features/quotes/presentation/create_quote/screens/select_service_screen.dart';
import '../../features/quotes/presentation/create_quote/screens/quote_service_search_screen.dart';
import '../../features/quotes/presentation/create_quote/screens/add_temporal_product_screen.dart';
import '../../features/quotes/presentation/create_quote/screens/add_temporal_service_screen.dart';
import '../../features/quotes/presentation/view_quote/screens/view_quote_screen.dart';
import '../../features/collaborators/presentation/screens/collaborators_screen.dart';
import '../../features/collaborators/presentation/screens/add_collaborator_screen.dart';
import '../../features/collaborators/domain/models/collaborator.dart';
import '../../features/quotes/domain/models/quote_aggregated_product.dart';
import '../../features/quotes/data/models/quote_item_product.dart';
import '../../features/quotes/data/models/quote_item_service.dart';
import 'package:d_una_app/features/reports/presentation/report_routes.dart';
import 'package:d_una_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:d_una_app/features/profile/presentation/screens/basic_data_screen.dart';
import 'package:d_una_app/features/profile/presentation/screens/contact_data_screen.dart';
import 'package:d_una_app/features/profile/presentation/screens/main_address_screen.dart';
import 'package:d_una_app/features/settings/presentation/screens/shipping_methods_screen.dart';
import 'package:d_una_app/features/settings/presentation/screens/add_shipping_method_screen.dart';
import 'package:d_una_app/features/settings/data/models/shipping_method.dart';
import 'package:d_una_app/features/profile/presentation/screens/occupation_screen.dart';
import 'package:d_una_app/features/profile/presentation/screens/security_screen.dart';
import 'package:d_una_app/features/profile/presentation/screens/verification_screen.dart';
import 'package:d_una_app/features/profile/presentation/screens/credit_history_screen.dart';
import '../../features/portfolio/presentation/suppliers_directory/screens/suppliers_directory_screen.dart';
import 'package:d_una_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:d_una_app/features/settings/presentation/screens/brands_list_screen.dart';
import 'package:d_una_app/features/settings/presentation/screens/categories_list_screen.dart';
import 'package:d_una_app/features/settings/presentation/screens/uoms_list_screen.dart';
import 'package:d_una_app/features/settings/presentation/screens/service_rates_list_screen.dart';
import 'package:d_una_app/features/settings/presentation/screens/unaffiliated_suppliers_list_screen.dart';
import 'package:d_una_app/features/settings/presentation/screens/shipping_companies_list_screen.dart';
import '../../features/settings/presentation/screens/delivery_times_list_screen.dart';
import '../../features/settings/presentation/screens/commercial_conditions_list_screen.dart';
import '../../features/settings/presentation/screens/observations_list_screen.dart';
import '../../features/settings/presentation/screens/quick_phrases_list_screen.dart';
import '../../features/settings/presentation/screens/financial_parameters_screen.dart';
import '../../features/purchases/presentation/screens/purchases_list_screen.dart';
import '../../features/purchases/presentation/screens/purchase_details_screen.dart';
import '../../features/purchases/presentation/screens/add_purchase_screen.dart';
import '../../features/purchases/presentation/screens/add_purchase_select_product_screen.dart';
import '../../features/purchases/presentation/screens/add_purchase_product_search_screen.dart';
import '../../features/purchases/presentation/screens/manage_product_serials_screen.dart';
import '../../features/purchases/presentation/screens/purchases_search_screen.dart';
import '../../features/settings/presentation/screens/email_templates_list_screen.dart';
import '../../features/settings/presentation/screens/edit_email_template_screen.dart';
import '../../features/settings/data/models/email_template.dart';
import '../../features/supplier_orders/presentation/supplier_orders_list/screens/supplier_orders_list_screen.dart';
import '../../features/supplier_orders/presentation/view_supplier_order/screens/supplier_order_details_screen.dart';
import '../../features/supplier_orders/presentation/create_supplier_order/screens/create_supplier_order_screen.dart';
import '../../features/supplier_orders/presentation/supplier_orders_list/screens/supplier_orders_search_screen.dart';
import '../../features/supplier_orders/presentation/create_supplier_order/screens/select_supplier_order_product_screen.dart';
import '../../features/supplier_orders/presentation/create_supplier_order/screens/supplier_order_product_search_screen.dart';
import '../../features/supplier_orders/presentation/create_supplier_order/screens/supplier_order_product_branches_screen.dart';
import '../../features/supplier_orders/domain/models/supplier_order_status.dart';
import '../../features/portfolio/domain/models/aggregated_product.dart';

import '../router/router_notifier.dart';
import '../../shared/screens/pdf_preview_screen.dart';
import '../../shared/providers/pdf_preview_provider.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorClientsKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellClients',
);
final _shellNavigatorPortfolioKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellPortfolio',
);
final _shellNavigatorQuotesKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellQuotes',
);
final _shellNavigatorReportsKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellReports',
);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentUser;
      final isLoggingIn = state.uri.toString() == '/login' ||
          state.uri.toString() == '/register' ||
          state.uri.toString().startsWith('/register/');

      // If not logged in and not on login/register pages, redirect to login
      if (session == null && !isLoggingIn) {
        return '/login';
      }

      // If logged in and on login/register pages, redirect to home (portfolio)
      if (session != null && isLoggingIn) {
        return '/portfolio';
      }

      return null;
    },
    routes: [
      ...authRoutes,

    // Authenticated Routes (Shell)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return HomeScreen(navigationShell: navigationShell);
      },
      branches: [
        // Branch Portfolio
        StatefulShellBranch(
          navigatorKey: _shellNavigatorPortfolioKey,
          routes: [
            GoRoute(
              path: '/portfolio',
              builder: (context, state) => const PortfolioScreen(),
              routes: [
                GoRoute(
                  path: 'own-inventory',
                  routes: [
                    GoRoute(
                      path: 'search',
                      builder: (context, state) => const ProductSearchScreen(),
                    ),
                    GoRoute(
                      path: 'add',
                      parentNavigatorKey:
                          rootNavigatorKey, // Full screen, cover shell? Or standard?
                      // Design shows back arrow, likely full screen or standard nested.
                      // Let's use nested for now, but design implies it might be a full flow.
                      // Usually "Add" flows are better as root or full screen.
                      // Let's keep it simple first.
                      builder: (context, state) => const AddProductScreen(),
                    ),
                    GoRoute(
                      path: 'details/:id',
                      builder: (context, state) {
                        final extra = state.extra;
                        final Product product;
                        if (extra is Product) {
                          product = extra;
                        } else if (extra is Map<String, dynamic>) {
                          product = Product.fromJson(extra);
                        } else {
                          // Fallback or error if neither
                          throw Exception(
                            'Invalid navigation state for ProductDetails: Expected Product or JSON Map',
                          );
                        }
                        return ProductDetailsScreen(product: product);
                      },
                      routes: [
                        GoRoute(
                          path: 'edit',
                          builder: (context, state) {
                            final extra = state.extra;
                            final Product product;
                            if (extra is Product) {
                              product = extra;
                            } else if (extra is Map<String, dynamic>) {
                              product = Product.fromJson(extra);
                            } else {
                              throw Exception(
                                'Invalid navigation state for EditProduct: Expected Product or JSON Map',
                              );
                            }
                            return EditProductScreen(product: product);
                          },
                        ),
                      ],
                    ),
                  ],
                  builder: (context, state) => const OwnInventoryScreen(),
                ),
                GoRoute(
                  path: 'supplier-inventory',
                  builder: (context, state) => const SuppliersDirectoryScreen(),
                ),
                GoRoute(
                  path: 'own-services',
                  builder: (context, state) => const OwnServicesScreen(),
                  routes: [
                    GoRoute(
                      path: 'search',
                      builder: (context, state) => const ServiceSearchScreen(),
                    ),
                    GoRoute(
                      path: 'add',
                      builder: (context, state) => const AddServiceScreen(),
                    ),
                    GoRoute(
                      path: 'details/:id',
                      builder: (context, state) {
                        final service = state.extra as ServiceModel;
                        return ServiceDetailsScreen(service: service);
                      },
                    ),
                    // cleaned up
                    GoRoute(
                      path: 'edit/:id',
                      builder: (context, state) {
                        final service = state.extra as ServiceModel;
                        return EditServiceScreen(service: service);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        // Branch Quotes
        StatefulShellBranch(
          navigatorKey: _shellNavigatorQuotesKey,
          routes: [
            GoRoute(
              path: '/quotes',
              builder: (context, state) => const QuotesListScreen(),
              routes: [
                GoRoute(
                  path: 'search',
                  builder: (context, state) {
                    final productId = state.uri.queryParameters['productId'];
                    final clientId = state.uri.queryParameters['clientId'];
                    final clientName = state.uri.queryParameters['clientName'];
                    final productModel =
                        state.uri.queryParameters['productModel'];
                    final isReadOnly =
                        state.uri.queryParameters['readOnly'] == 'true';
                    final initialQuery = productModel ?? clientName;
                    return QuotesSearchScreen(
                      productId: productId,
                      clientId: clientId,
                      initialQuery: initialQuery,
                      isSearchQueryReadOnly: isReadOnly,
                    );
                  },
                ),
                GoRoute(
                  path: 'select',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final excludeStatuses = (state.extra as Set?)?.cast<String>();
                    return QuotesSearchScreen(
                      selectionMode: true,
                      excludeStatuses: excludeStatuses,
                    );
                  },
                ),
                GoRoute(
                  path: 'view/:id',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    final extra = state.extra as Map<String, dynamic>?;
                    final triggerSend = extra?['triggerSend'] as bool? ?? false;
                    return ViewQuoteScreen(
                      quoteId: id,
                      triggerSend: triggerSend,
                    );
                  },
                ),
                GoRoute(
                  path: 'edit/:id',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return CreateQuoteScreen(quoteId: id);
                  },
                ),
                GoRoute(
                  path: 'create',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const CreateQuoteScreen(),
                  routes: [
                    GoRoute(
                      path: 'select-product',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => const SelectProductScreen(),
                      routes: [
                        GoRoute(
                          path: 'search',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) {
                            final initialQuery = state.extra as String?;
                            return QuoteProductSearchScreen(
                              initialQuery: initialQuery,
                            );
                          },
                        ),
                        GoRoute(
                          path: 'product-sources',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) {
                            if (state.extra is QuoteAggregatedProduct) {
                              return QuoteProductSourcesScreen(
                                product: state.extra as QuoteAggregatedProduct,
                              );
                            } else if (state.extra is Map<String, dynamic>) {
                              final map = state.extra as Map<String, dynamic>;
                              return QuoteProductSourcesScreen(
                                product:
                                    map['product'] as QuoteAggregatedProduct,
                                initialSelections:
                                    map['initialSelections']
                                        as Map<String, double>?,
                                initialCostPrices:
                                    map['initialCostPrices']
                                        as Map<String, double>?,
                                externalCostPrice:
                                    map['externalCostPrice'] as double?,
                                externalProviderName:
                                    map['externalProviderName'] as String?,
                                groupIndex: map['groupIndex'] as int?,
                              );
                            }
                            // Fallback
                            return const SizedBox.shrink();
                          },
                        ),
                        GoRoute(
                          path: 'temporal-product',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) {
                            final existingItem = state.extra is QuoteItemProduct
                                ? state.extra as QuoteItemProduct
                                : null;
                            return AddTemporalProductScreen(
                              existingItem: existingItem,
                            );
                          },
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'select-service',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) => const SelectServiceScreen(),
                      routes: [
                        GoRoute(
                          path: 'search',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) =>
                              const QuoteServiceSearchScreen(),
                        ),
                        GoRoute(
                          path: 'temporal-service',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) {
                            final existingItem = state.extra is QuoteItemService
                                ? state.extra as QuoteItemService
                                : null;
                            return AddTemporalServiceScreen(
                              existingItem: existingItem,
                            );
                          },
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'conditions',
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) =>
                          const SelectConditionScreen(),
                      routes: [
                        GoRoute(
                          path: 'search',
                          parentNavigatorKey: rootNavigatorKey,
                          builder: (context, state) =>
                              const QuoteConditionSearchScreen(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        // Branch Reports
        StatefulShellBranch(
          navigatorKey: _shellNavigatorReportsKey,
          routes: serviceReportsRoutes(rootNavigatorKey),
        ),
        // Branch Clients
        StatefulShellBranch(
          navigatorKey: _shellNavigatorClientsKey,
          routes: clientRoutes,
        ),
      ],
    ),

    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
      routes: [
        GoRoute(
          path: 'basic-data',
          builder: (context, state) => const BasicDataScreen(),
        ),
        GoRoute(
          path: 'contact-data',
          builder: (context, state) => const ContactDataScreen(),
        ),
        GoRoute(
          path: 'main-address',
          builder: (context, state) => const MainAddressScreen(),
        ),

        GoRoute(
          path: 'occupation',
          builder: (context, state) => const OccupationScreen(),
        ),
        GoRoute(
          path: 'security',
          builder: (context, state) => const SecurityScreen(),
        ),
        GoRoute(
          path: 'verification',
          builder: (context, state) => const VerificationScreen(),
        ),
        GoRoute(
          path: 'credits-history',
          builder: (context, state) => const CreditHistoryScreen(),
        ),
      ],
    ),

    GoRoute(
      path: '/pdf-preview',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra;
        
        if (extra is Map<String, dynamic>) {
          // Guardar en el respaldo global
          PdfPreviewData.lastData = PdfPreviewData(
            title: extra['title'] as String,
            subtitle: extra['subtitle'] as String?,
            fileName: extra['fileName'] as String,
            buildPdf: extra['buildPdf'] as Future<Uint8List> Function(PdfPageFormat),
          );
        }

        final data = PdfPreviewData.lastData;

        if (data == null) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Error: Datos del PDF no encontrados.\nPor favor, intente de nuevo.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return PdfPreviewScreen(
          title: data.title,
          subtitle: data.subtitle,
          fileName: data.fileName,
          buildPdf: data.buildPdf,
        );
      },
    ),

    GoRoute(
      path: '/collaborators',
      builder: (context, state) => const CollaboratorsScreen(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) {
            final collaborator = state.extra is Collaborator
                ? state.extra as Collaborator
                : null;
            return AddCollaboratorScreen(collaborator: collaborator);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/my-purchases',
      builder: (context, state) => const PurchasesListScreen(),
      routes: [
        GoRoute(
          path: 'search',
          builder: (context, state) {
            final productId = state.uri.queryParameters['productId'];
            final productModel = state.uri.queryParameters['productModel'];
            final isReadOnly =
                state.uri.queryParameters['readOnly'] == 'true';
            return PurchasesSearchScreen(
              productId: productId,
              initialQuery: productModel,
              isSearchQueryReadOnly: isReadOnly,
            );
          },
        ),
        GoRoute(
          path: 'select',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const PurchasesSearchScreen(
            selectionMode: true,
          ),
        ),
        GoRoute(
          path: 'view/:id',
          name: 'view_purchase',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final extra = state.extra;
            bool editMode = false;
            String? highlightProductId;
            if (extra is Map<String, dynamic>) {
              if (extra.containsKey('editMode')) {
                editMode = extra['editMode'] as bool;
              }
              if (extra.containsKey('highlightProductId')) {
                highlightProductId = extra['highlightProductId'] as String;
              }
            }
            return PurchaseDetailsScreen(
              purchaseId: id,
              startInEditMode: editMode,
              highlightProductId: highlightProductId,
            );
          },
        ),
        GoRoute(
          path: 'add',
          builder: (context, state) {
            final extra = state.extra;
            int tabIndex = 0;
            String? purchaseId;
            if (extra is Map<String, dynamic>) {
              if (extra.containsKey('initialTabIndex')) {
                tabIndex = extra['initialTabIndex'] as int;
              }
              if (extra.containsKey('purchaseId')) {
                purchaseId = extra['purchaseId'] as String?;
              }
            }
            return AddPurchaseScreen(
              purchaseId: purchaseId,
              initialTabIndex: tabIndex,
            );
          },
          routes: [
            GoRoute(
              path: 'select-product',
              builder: (context, state) =>
                  const AddPurchaseSelectProductScreen(),
              routes: [
                GoRoute(
                  path: 'search',
                  builder: (context, state) =>
                      const AddPurchaseProductSearchScreen(),
                ),
                GoRoute(
                  path: 'manage-serials',
                  builder: (context, state) {
                    final extra = state.extra;
                    if (extra is! Map<String, dynamic>) {
                      return const Scaffold(
                        body: Center(
                          child: Text(
                            'Error: Datos del producto no encontrados.',
                          ),
                        ),
                      );
                    }
                    return ManageProductSerialsScreen(
                      product: extra['product'] as Product,
                      quantity: extra['quantity'] as int,
                      purchaseItemId: extra['purchaseItemId'] as String,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/supplier-orders',
      builder: (context, state) => const SupplierOrdersListScreen(),
      routes: [
        GoRoute(
          path: 'search',
          builder: (context, state) {
            String? initialQuery;
            bool readOnly = false;
            if (state.extra is String) {
              initialQuery = state.extra as String;
            } else if (state.extra is Map<String, dynamic>) {
              final map = state.extra as Map<String, dynamic>;
              initialQuery = map['initialQuery'] as String?;
              readOnly = map['readOnly'] as bool? ?? (initialQuery != null && initialQuery.isNotEmpty);
            }
            return SupplierOrdersSearchScreen(
              initialQuery: initialQuery,
              isSearchQueryReadOnly: readOnly,
            );
          },
        ),
        GoRoute(
          path: 'select',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final allowedStatuses =
                extra?['statuses'] as Set<SupplierOrderStatus>?;
            final supplierName = extra?['supplierName'] as String?;
            return SupplierOrdersSearchScreen(
              selectionMode: true,
              allowedStatuses: allowedStatuses,
              initialQuery: supplierName,
              isSearchQueryReadOnly:
                  supplierName != null && supplierName.isNotEmpty,
            );
          },
        ),
        GoRoute(
          path: 'create',
          builder: (context, state) => const CreateSupplierOrderScreen(),
          routes: [
            GoRoute(
              path: 'select-product',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const SelectSupplierOrderProductScreen(),
              routes: [
                GoRoute(
                  path: 'search',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final initialQuery = state.extra as String?;
                    return SupplierOrderProductSearchScreen(
                      initialQuery: initialQuery,
                    );
                  },
                ),
                GoRoute(
                  path: 'branches',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    if (state.extra is AggregatedProduct) {
                      return SupplierOrderProductBranchesScreen(
                        product: state.extra as AggregatedProduct,
                      );
                    } else if (state.extra is Map<String, dynamic>) {
                      final map = state.extra as Map<String, dynamic>;
                      return SupplierOrderProductBranchesScreen(
                        product: map['product'] as AggregatedProduct,
                        initialSelections: map['initialSelections'] as Map<String, double>?,
                        isEditing: map['isEditing'] as bool? ?? false,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: 'edit/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            final tabParam = state.uri.queryParameters['tab'];
            final initialTab =
                tabParam != null ? int.tryParse(tabParam) : null;
            return CreateSupplierOrderScreen(
              orderId: id,
              editMode: true,
              initialTab: initialTab,
            );
          },
        ),
        GoRoute(
          path: 'view/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final triggerSend = state.uri.queryParameters['triggerSend'] == 'true';
            return SupplierOrderDetailsScreen(orderId: id, triggerSend: triggerSend);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'brands',
          builder: (context, state) => const BrandsListScreen(),
        ),
        GoRoute(
          path: 'categories',
          builder: (context, state) => const CategoriesListScreen(),
        ),
        GoRoute(
          path: 'uoms',
          builder: (context, state) => const UomsListScreen(),
        ),
        GoRoute(
          path: 'service-rates',
          builder: (context, state) => const ServiceRatesListScreen(),
        ),
        GoRoute(
          path: 'unaffiliated-suppliers',
          builder: (context, state) => const UnaffiliatedSuppliersListScreen(),
        ),
        GoRoute(
          path: 'shipping-companies',
          builder: (context, state) => const ShippingCompaniesListScreen(),
        ),
        GoRoute(
          path: 'delivery-times',
          builder: (context, state) => const DeliveryTimesListScreen(),
        ),
        GoRoute(
          path: 'commercial-conditions',
          builder: (context, state) => const CommercialConditionsListScreen(),
        ),
        GoRoute(
          path: 'shipping-methods',
          builder: (context, state) => const ShippingMethodsScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) =>
                  AddShippingMethodScreen(key: state.pageKey),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final shippingMethod = state.extra as ShippingMethod?;
                return AddShippingMethodScreen(
                  key: state.pageKey,
                  shippingMethod: shippingMethod,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'observations',
          builder: (context, state) => const ObservationsListScreen(),
        ),
        GoRoute(
          path: 'quick-phrases',
          builder: (context, state) => const QuickPhrasesListScreen(),
        ),
        GoRoute(
          path: 'financial-parameters',
          builder: (context, state) => const FinancialParametersScreen(),
        ),
        GoRoute(
          path: 'email-templates',
          builder: (context, state) => const EmailTemplatesListScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>;
                final templateExtra = extra['template'];
                
                EmailTemplate? template;
                if (templateExtra is EmailTemplate) {
                  template = templateExtra;
                } else if (templateExtra is Map<String, dynamic>) {
                  template = EmailTemplate.fromJson(templateExtra);
                }

                return EditEmailTemplateScreen(
                  typeId: extra['typeId'] as String,
                  label: extra['label'] as String,
                  template: template,
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
});
