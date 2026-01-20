import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/clients_provider.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import 'providers/add_client_provider.dart';

enum SortOption { recent, nameAZ, nameZA }

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SortOption _currentSort = SortOption.recent;

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.recent:
        return 'Reciente';
      case SortOption.nameAZ:
        return 'Nombre A-Z';
      case SortOption.nameZA:
        return 'Nombre Z-A';
    }
  }

  void _showSortOptions(BuildContext context, ColorScheme colors) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor:
          colors.surfaceContainer, // Matches the light grey in image
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  height: 4,
                  width: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Ordenar por',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              //const Divider(height: 1),
              _buildSortOption(context, 'Reciente', SortOption.recent, colors),
              _buildSortOption(
                context,
                'Nombre A-Z',
                SortOption.nameAZ,
                colors,
              ),
              _buildSortOption(
                context,
                'Nombre Z-A',
                SortOption.nameZA,
                colors,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String label,
    SortOption option,
    ColorScheme colors,
  ) {
    final isSelected = _currentSort == option;
    return InkWell(
      onTap: () {
        setState(() {
          _currentSort = option;
        });
        context.pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? (option == SortOption.recent
                        ? Icons.arrow_downward
                        : (option == SortOption.nameAZ
                              ? Icons.arrow_upward
                              : Icons.arrow_downward))
                  : (option == SortOption.recent
                        ? Icons.arrow_downward
                        : (option == SortOption.nameAZ
                              ? Icons.arrow_upward
                              : Icons
                                    .arrow_downward)), // Reuse icons or just use appropriate ones
              // Actually the image shows generic arrows or just the text with check?
              // Image 2 shows:
              // X Ordenar por
              // down arrow Reciente
              // up arrow Nombre A-Z
              // down arrow Nombre Z-A
              // And no obvious checkmark, maybe the icon color indicates selection?
              // Wait, the icons are explicitly next to the text always.
              // Let's match the image icons.
              color: colors.onSurface,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    readOnly: true,
                    onTap: () {
                      context.push('/clients/search');
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 16.0, right: 8.0),
                        child: Icon(Icons.search),
                      ),
                      suffixIcon: const Padding(
                        padding: EdgeInsets.only(right: 16.0, left: 8.0),
                        child: Icon(Icons.filter_list),
                      ),
                      filled: true,
                      fillColor: colors.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 0,
                      ),
                    ),
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
                  GestureDetector(
                    onTap: () => _showSortOptions(context, colors),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getSortLabel(_currentSort),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: colors.onSurface,
                        ),
                      ],
                    ),
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
                    final name = client.name.toLowerCase();
                    final id = client.taxId?.toLowerCase() ?? '';
                    final email = client.email?.toLowerCase() ?? '';
                    return name.contains(_searchQuery) ||
                        id.contains(_searchQuery) ||
                        email.contains(_searchQuery);
                  }).toList();

                  // Sort Clients
                  filteredClients.sort((a, b) {
                    switch (_currentSort) {
                      case SortOption.recent:
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
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
                    itemCount: filteredClients.length,
                    separatorBuilder: (context, index) => const Divider(),
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
