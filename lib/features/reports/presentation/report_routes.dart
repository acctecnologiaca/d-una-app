import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'reports_list/screens/reports_list_screen.dart';
import 'reports_list/screens/report_search_screen.dart';
import 'create_report/screens/create_report_screen.dart';
import 'create_report/screens/select_report_product_screen.dart';
import 'create_report/screens/report_product_search_screen.dart';
import 'create_report/screens/add_report_temporal_product_screen.dart';
import 'create_report/screens/select_report_service_screen.dart';
import 'create_report/screens/add_report_temporal_service_screen.dart';
import 'create_report/screens/report_service_search_screen.dart';
import 'create_report/screens/select_report_condition_screen.dart';
import 'view_report/screens/view_report_screen.dart';
import '../data/models/service_report_item_product.dart';
import '../data/models/service_report_item_service.dart';

List<RouteBase> serviceReportsRoutes(GlobalKey<NavigatorState> rootNavigatorKey) {
  return [
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsListScreen(),
      routes: [
        GoRoute(
          path: 'search',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ReportSearchScreen(
              selectionMode: extra?['selectionMode'] as bool? ?? false,
              excludeStatuses: extra?['excludeStatuses'] as Set<String>?,
              productId: extra?['productId'] as String?,
              clientId: extra?['clientId'] as String?,
              initialQuery: extra?['initialQuery'] as String?,
              isSearchQueryReadOnly:
                  extra?['isSearchQueryReadOnly'] as bool? ?? false,
            );
          },
        ),
        GoRoute(
          path: 'create',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const CreateReportScreen(),
          routes: [
            GoRoute(
              path: 'select-product',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const SelectReportProductScreen(),
              routes: [
                GoRoute(
                  path: 'search',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) =>
                      const ReportProductSearchScreen(),
                ),
                GoRoute(
                  path: 'temporal',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) =>
                      AddReportTemporalProductScreen(
                    existingItem: state.extra as ServiceReportItemProduct?,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'select-service',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const SelectReportServiceScreen(),
              routes: [
                GoRoute(
                  path: 'search',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) =>
                      const ReportServiceSearchScreen(),
                ),
                GoRoute(
                  path: 'temporal',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) =>
                      AddReportTemporalServiceScreen(
                    existingItem: state.extra as ServiceReportItemService?,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'select-condition',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) =>
                  const SelectReportConditionScreen(),
            ),
          ],
        ),
        GoRoute(
          path: ':id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final reportId = state.pathParameters['id']!;
            return ViewReportScreen(reportId: reportId);
          },
          routes: [
            GoRoute(
              path: 'edit',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                final reportId = state.pathParameters['id']!;
                return CreateReportScreen(reportId: reportId);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'view/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final reportId = state.pathParameters['id']!;
            return ViewReportScreen(reportId: reportId);
          },
        ),
      ],
    ),
  ];
}
