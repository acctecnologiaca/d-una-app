import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/clients_provider.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'providers/add_client_provider.dart';
import 'package:d_una_app/core/utils/string_extensions.dart';
import '../../../../shared/widgets/custom_search_bar.dart';
import '../../../../shared/widgets/sort_selector.dart';

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SortOption _currentSort = SortOption.recent;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Search Bar
            Column(
              children: [
                // App Bar Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          // Open drawer
                        },
                      ),
                      Text(
                        'Clientes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      InkWell(
                        onTap: () => context.push('/profile'),
                        child: userProfileAsync.when(
                          data: (profile) {
                            final avatarUrl = profile?.avatarUrl;
                            return CircleAvatar(
                              radius: 18,
                              backgroundImage: avatarUrl != null
                                  ? NetworkImage(avatarUrl)
                                  : const NetworkImage(
                                      'https://i.pravatar.cc/150?img=11',
                                    ),
                            );
                          },
                          loading: () => const CircleAvatar(
                            radius: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (err, stack) => const CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/150?img=11',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: CustomSearchBar(
                    controller: _searchController,
                    hintText: 'Buscar...',
                    readOnly: true,
                    showFilterIcon: true,
                    onTap: () {
                      context.push('/clients/search');
                    },
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),

            // Sort Options Row
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

            // Content
            Expanded(
              child: clientsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (clients) {
                  // Filter Clients
                  var filteredClients = clients.where((client) {
                    final normalizedQuery = _searchQuery.normalized;
                    final name = client.name.normalized;
                    final id = (client.taxId ?? '').normalized;
                    final email = (client.email ?? '').normalized;
                    return name.contains(normalizedQuery) ||
                        id.contains(normalizedQuery) ||
                        email.contains(normalizedQuery);
                  }).toList();

                  // Sort Clients
                  filteredClients.sort((a, b) {
                    switch (_currentSort) {
                      case SortOption.recent:
                      case SortOption.frequency:
                        // Assuming createdAt exists and is DateTime.
                        // If not, we might need another field or fallback.
                        // Checked model: DateTime createdAt exists.
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

                  if (filteredClients.isEmpty) {
                    if (_searchQuery.isNotEmpty) {
                      return Center(
                        child: Text(
                          'No se encontraron resultados',
                          style: TextStyle(color: colors.outline, fontSize: 16),
                        ),
                      );
                    }
                    return Center(
                      child: Text(
                        'No hay clientes agregados',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                    itemCount: filteredClients.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Colors.transparent,
                    ),
                    itemBuilder: (context, index) {
                      final client = filteredClients[index];

                      return ListTile(
                        leading: Icon(
                          client.type == 'company'
                              ? Icons.domain_outlined
                              : Icons.person_outlined,
                          size: 32,
                          color: colors.onSurfaceVariant,
                        ),
                        visualDensity: VisualDensity.standard,
                        title: Text(client.name),
                        subtitle: Text(client.taxId ?? 'Sin ID'),
                        onTap: () {
                          // Navigate to details using ID
                          context.push('/clients/${client.id}', extra: client);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            // Reset provider state before starting new wizard
            ref.read(addClientProvider.notifier).reset();
            context.push('/clients/add');
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'Agregar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
