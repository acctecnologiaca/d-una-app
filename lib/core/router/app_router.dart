import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
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
import '../../features/collaborators/presentation/screens/collaborators_screen.dart';
import '../../features/collaborators/presentation/screens/add_collaborator_screen.dart';
import '../../features/collaborators/domain/models/collaborator.dart';
import '../../features/quotes/domain/models/quote_aggregated_product.dart';
import '../../features/quotes/data/models/quote_item_product.dart';
import '../../features/quotes/data/models/quote_item_service.dart';
import 'package:d_una_app/features/reports/presentation/reports_screen.dart';
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
import '../../features/settings/presentation/screens/financial_parameters_screen.dart';
import '../../features/purchases/presentation/screens/purchases_list_screen.dart';
import '../../features/purchases/presentation/screens/add_purchase_screen.dart';
import '../../features/purchases/presentation/screens/add_purchase_select_product_screen.dart';
import '../../features/purchases/presentation/screens/add_purchase_product_search_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../router/router_notifier.dart';

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

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/login',
  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentUser;
    final isLoggingIn =
        state.uri.toString() == '/login' ||
        state.uri.toString() == '/register' ||
        state.uri.toString().startsWith('/register/');

    // If not logged in and not on login/register pages, redirect to login
    if (session == null && !isLoggingIn) {
      return '/login';
    }

    // If logged in and on login/register pages, redirect to home (clients)
    if (session != null && isLoggingIn) {
      return '/clients';
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
        // Branch Clients
        StatefulShellBranch(
          navigatorKey: _shellNavigatorClientsKey,
          routes: clientRoutes,
        ),
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
                  builder: (context, state) => const QuotesSearchScreen(),
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
                          builder: (context, state) =>
                              const QuoteProductSearchScreen(),
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
          routes: [
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsScreen(),
            ),
          ],
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
      ],
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
          path: 'add',
          builder: (context, state) => const AddPurchaseScreen(),
          routes: [
            GoRoute(
              path: 'select-product',
              builder: (context, state) => const AddPurchaseSelectProductScreen(),
              routes: [
                GoRoute(
                  path: 'search',
                  builder: (context, state) => const AddPurchaseProductSearchScreen(),
                ),
              ],
            ),
          ],
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
          path: 'financial-parameters',
          builder: (context, state) => const FinancialParametersScreen(),
        ),
      ],
    ),
  ],
);
