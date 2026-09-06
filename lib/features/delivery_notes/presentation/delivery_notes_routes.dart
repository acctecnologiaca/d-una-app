import 'package:go_router/go_router.dart';
import 'package:d_una_app/core/router/app_router.dart';
import 'delivery_notes_list/screens/delivery_notes_list_screen.dart';
import 'delivery_notes_list/screens/delivery_notes_search_screen.dart';
import 'create_delivery_note/screens/create_delivery_note_screen.dart';
import 'view_delivery_note/screens/view_delivery_note_screen.dart';

final deliveryNotesRoutes = <RouteBase>[
  GoRoute(
    path: '/delivery-notes',
    builder: (context, state) => const DeliveryNotesListScreen(),
    routes: [
      GoRoute(
        path: 'search',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          String? initialQuery;
          if (state.extra is String) {
            initialQuery = state.extra as String;
          } else if (state.extra is Map<String, dynamic>) {
            initialQuery = (state.extra as Map<String, dynamic>)['initialQuery'] as String?;
          }
          return DeliveryNotesSearchScreen(initialQuery: initialQuery);
        },
      ),
      GoRoute(
        path: 'create',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final quoteId = state.uri.queryParameters['quoteId'];
          final supplierOrderId = state.uri.queryParameters['supplierOrderId'];
          return CreateDeliveryNoteScreen(
            quoteId: quoteId,
            supplierOrderId: supplierOrderId,
          );
        },
      ),
      GoRoute(
        path: 'edit/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final noteId = state.pathParameters['id'];
          return CreateDeliveryNoteScreen(noteId: noteId);
        },
      ),
      GoRoute(
        path: 'view/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final noteId = state.pathParameters['id']!;
          return ViewDeliveryNoteScreen(noteId: noteId);
        },
      ),
    ],
  ),
];
