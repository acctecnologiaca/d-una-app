// plain file, no material import needed unless used.
// keeping go_router import.
import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/clients/data/models/client_model.dart';
import 'package:d_una_app/features/clients/presentation/client_list_screen.dart';
import 'package:d_una_app/features/clients/presentation/screens/client_search_screen.dart';
import 'package:d_una_app/features/clients/presentation/screens/add_client/add_client_type_screen.dart';
import 'package:d_una_app/features/clients/presentation/screens/add_client/add_client_company_info_screen.dart';
import 'package:d_una_app/features/clients/presentation/screens/add_client/add_client_person_info_screen.dart';
import 'package:d_una_app/features/clients/presentation/screens/add_client/add_client_address_screen.dart';
import 'package:d_una_app/features/clients/presentation/screens/add_client/add_client_contact_screen.dart';
import 'package:d_una_app/features/clients/presentation/client_details_screen.dart';
import 'package:d_una_app/features/clients/presentation/screens/edit_client/edit_client_company_screen.dart';
import 'package:d_una_app/features/clients/presentation/screens/edit_client/edit_client_person_screen.dart';
import 'package:d_una_app/features/clients/presentation/screens/manage_contacts/manage_contacts_screen.dart';
import 'package:d_una_app/features/clients/presentation/screens/manage_contacts/add_edit_contact_screen.dart';
import 'package:d_una_app/features/clients/presentation/screens/manage_contacts/contact_details_screen.dart';
import 'package:d_una_app/features/clients/presentation/screens/manage_contacts/contact_search_screen.dart';

final clientRoutes = <RouteBase>[
  GoRoute(
    path: '/clients',
    builder: (context, state) => const ClientListScreen(),
    routes: [
      GoRoute(
        path: 'search', // /clients/search
        builder: (context, state) => const ClientSearchScreen(),
      ),
      GoRoute(
        path: 'add', // /clients/add
        builder: (context, state) => const AddClientTypeScreen(),
        routes: [
          GoRoute(
            path: 'company-info', // /clients/add/company-info
            builder: (context, state) => const AddClientCompanyInfoScreen(),
          ),
          GoRoute(
            path: 'person-info', // /clients/add/person-info
            builder: (context, state) => const AddClientPersonInfoScreen(),
          ),
          GoRoute(
            path: 'address', // /clients/add/address
            builder: (context, state) => const AddClientAddressScreen(),
          ),
          GoRoute(
            path: 'contact', // /clients/add/contact
            builder: (context, state) => const AddClientContactScreen(),
          ),
        ],
      ),
      GoRoute(
        path: ':id', // /clients/:id
        builder: (context, state) =>
            ClientDetailsScreen(clientId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit-company', // /clients/:id/edit-company
            builder: (context, state) => EditClientCompanyScreen(
              clientId: state.pathParameters['id']!,
              client: state.extra as Client?,
            ),
          ),
          GoRoute(
            path: 'edit-person', // /clients/:id/edit-person
            builder: (context, state) => EditClientPersonScreen(
              clientId: state.pathParameters['id']!,
              client: state.extra as Client?,
            ),
          ),
          GoRoute(
            path: 'contacts', // /clients/:id/contacts
            builder: (context, state) => ManageContactsScreen(
              clientId: state.pathParameters['id']!,
              initialData: state.extra is Map<String, dynamic>
                  ? state.extra as Map<String, dynamic>
                  : null,
            ),
            routes: [
              GoRoute(
                path: 'add', // /clients/:id/contacts/add
                builder: (context, state) => AddEditContactScreen(
                  clientId: state.pathParameters['id']!,
                  companyName: state.extra is String
                      ? state.extra as String
                      : null,
                ),
              ),
              GoRoute(
                path: 'details', // /clients/:id/contacts/details
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  return ContactDetailsScreen(
                    clientId: state.pathParameters['id']!,
                    companyName: extra['companyName'] as String?,
                    contact: extra['contact'] as Contact,
                    contactCount: extra['contactCount'] as int?,
                  );
                },
              ),
              GoRoute(
                path: 'edit', // /clients/:id/contacts/edit
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  return AddEditContactScreen(
                    clientId: state.pathParameters['id']!,
                    companyName: extra['companyName'] as String?,
                    contact: extra['contact'] as Contact,
                    contactCount: extra['contactCount'] as int?,
                  );
                },
              ),
              GoRoute(
                path: 'search', // /clients/:id/contacts/search
                builder: (context, state) => ContactSearchScreen(
                  clientId: state.pathParameters['id']!,
                  companyName: state.extra as String,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
