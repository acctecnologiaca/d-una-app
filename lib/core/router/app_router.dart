import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:d_una_app/features/auth/presentation/auth_routes.dart';
import 'package:d_una_app/features/clients/presentation/client_routes.dart';

import 'package:d_una_app/features/home/presentation/home_screen.dart';
import 'package:d_una_app/features/portfolio/presentation/portfolio_screen.dart';
import '../../features/portfolio/presentation/screens/own_inventory_screen.dart';
import '../../features/portfolio/presentation/screens/add_product/add_product_screen.dart';
import '../../features/portfolio/presentation/screens/edit_product/edit_product_screen.dart';
import '../../features/portfolio/presentation/screens/product_details/product_details_screen.dart';
import '../../features/portfolio/presentation/screens/product_search_screen.dart';
import '../../features/portfolio/presentation/screens/own_services_screen.dart';
import '../../features/portfolio/presentation/screens/service_search_screen.dart';
import '../../features/portfolio/presentation/screens/add_service/add_service_screen.dart';
import '../../features/portfolio/presentation/screens/service_details_screen.dart';
import '../../features/portfolio/presentation/screens/edit_service/edit_service_screen.dart';
import '../../features/portfolio/data/models/product_model.dart';
import '../../features/portfolio/data/models/service_model.dart';
import 'package:d_una_app/features/quotes/presentation/quotes_screen.dart';
import 'package:d_una_app/features/reports/presentation/reports_screen.dart';
import 'package:d_una_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:d_una_app/features/profile/presentation/screens/basic_data_screen.dart';
import 'package:d_una_app/features/profile/presentation/screens/contact_data_screen.dart';
import 'package:d_una_app/features/profile/presentation/screens/main_address_screen.dart';
import 'package:d_una_app/features/profile/presentation/screens/shipping_methods_screen.dart';
import 'package:d_una_app/features/profile/presentation/screens/add_shipping_method_screen.dart';
import 'package:d_una_app/features/profile/domain/models/shipping_method.dart';
import 'package:d_una_app/features/profile/presentation/screens/occupation_screen.dart';
import 'package:d_una_app/features/profile/presentation/screens/security_screen.dart';
import 'package:d_una_app/features/profile/presentation/screens/verification_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../router/router_notifier.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
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
  navigatorKey: _rootNavigatorKey,
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
                          _rootNavigatorKey, // Full screen, cover shell? Or standard?
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
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('Supplier Inventory')),
                  ),
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
              builder: (context, state) => const QuotesScreen(),
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
  ],
);
