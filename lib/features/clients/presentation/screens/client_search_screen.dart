import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/clients_provider.dart';
import '../../../../shared/widgets/custom_search_bar.dart';

import '../../../auth/presentation/providers/register_provider.dart';

class ClientSearchScreen extends ConsumerStatefulWidget {
  const ClientSearchScreen({super.key});

  @override
  ConsumerState<ClientSearchScreen> createState() => _ClientSearchScreenState();
}

class _ClientSearchScreenState extends ConsumerState<ClientSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _history = [];
  String _searchQuery = '';
  String? _selectedFilterType; // null = All, 'company', 'person'
  final Set<String> _selectedFilterCities = {};
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    // Request focus after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  String _getHistoryKey() {
    final user = ref.read(authRepositoryProvider).currentUser;
    return 'client_search_history_${user?.id ?? "guest"}';
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList(_getHistoryKey()) ?? [];
    });
  }

  Future<void> _addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> newHistory = List.from(_history);

    // Remove if exists to move to top
    newHistory.remove(query);
    // Add to top
    newHistory.insert(0, query);
    // Limit to 10
    if (newHistory.length > 10) {
      newHistory = newHistory.sublist(0, 10);
    }

    await prefs.setStringList(_getHistoryKey(), newHistory);
    setState(() {
      _history = newHistory;
    });
  }

  void _onSearchSubmitted(String query) {
    _addToHistory(query);
  }

  void _showTypeFilter(BuildContext context) {
    // ... Type filter implementation (unchanged) ...
    // Note: Re-using existing implementation to save space in replacement block if possible,
    // but since I'm replacing the whole class usually, I should include it.
    // However, to keep it clean, I will just include the logic I see above.
    // Actually, since I'm targeting the whole file structure effectively, I need to be careful.
    // Let's implement _showCityFilter and update _buildSearchResults and the chip.
    // I will replace the class content completely to avoid partial match issues, referencing existing code.
    final colors = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: colors.surfaceContainer,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tipo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildFilterOption(
                context: context,
                icon: Icons.grid_view,
                label: 'Todos',
                isSelected: _selectedFilterType == null,
                onTap: () {
                  setState(() => _selectedFilterType = null);
                  context.pop();
                },
              ),
              _buildFilterOption(
                context: context,
                icon: Icons.domain,
                label: 'Empresas',
                isSelected: _selectedFilterType == 'company',
                onTap: () {
                  setState(() => _selectedFilterType = 'company');
                  context.pop();
                },
              ),
              _buildFilterOption(
                context: context,
                icon: Icons.person_outline,
                label: 'Personas',
                isSelected: _selectedFilterType == 'person',
                onTap: () {
                  setState(() => _selectedFilterType = 'person');
                  context.pop();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCityFilter(BuildContext context, List<dynamic> clients) {
    final colors = Theme.of(context).colorScheme;
    // Extract unique cities
    final Set<String> availableCities = {};
    for (var client in clients) {
      if (client.city != null && client.city!.isNotEmpty) {
        availableCities.add(client.city!);
      }
    }
    final sortedCities = availableCities.toList()..sort();

    // Local state for the bottom sheet
    Set<String> tempSelectedCities = Set.from(_selectedFilterCities);
    String citySearchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: colors.surfaceContainer,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredCities = sortedCities
                .where(
                  (city) => city.toLowerCase().contains(
                    citySearchQuery.toLowerCase(),
                  ),
                )
                .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Stack(
                  children: [
                    Column(
                      children: [
                        // Handle
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
                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => context.pop(),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ciudad',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        // Search Box
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            onChanged: (value) {
                              setSheetState(() {
                                citySearchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Introduce el nombre de una ciudad',
                              prefixIcon:
                                  null, // Image doesn't show icon inside? Or maybe yes. Standard is no icon if plain.
                              filled: true,
                              fillColor: colors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: colors.outline),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            children: [
                              // "Todas" Option
                              CheckboxListTile(
                                title: const Text('Todas'),
                                value: tempSelectedCities.isEmpty,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                secondary: CircleAvatar(
                                  backgroundColor: colors.primaryContainer,
                                  child: Text(
                                    'T',
                                    style: TextStyle(
                                      color: colors.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                                onChanged: (bool? value) {
                                  setSheetState(() {
                                    if (value == true) {
                                      tempSelectedCities.clear();
                                    }
                                  });
                                },
                              ),
                              //const Divider(),

                              // Cities List
                              ...filteredCities.map((city) {
                                final isSelected = tempSelectedCities.contains(
                                  city,
                                );
                                return CheckboxListTile(
                                  title: Text(city),
                                  value: isSelected,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  secondary: CircleAvatar(
                                    backgroundColor: colors.secondaryContainer,
                                    child: Text(
                                      city.isNotEmpty
                                          ? city[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: colors.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                  controlAffinity:
                                      ListTileControlAffinity.trailing,
                                  onChanged: (bool? value) {
                                    setSheetState(() {
                                      if (value == true) {
                                        tempSelectedCities.add(city);
                                      } else {
                                        tempSelectedCities.remove(city);
                                      }
                                    });
                                  },
                                );
                              }),
                              const SizedBox(height: 80), // Space for FAB
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Floating "Aplicar" Button
                    Positioned(
                      bottom: 40,
                      right: 16,
                      child: FloatingActionButton.extended(
                        onPressed: () {
                          setState(() {
                            _selectedFilterCities.clear();
                            _selectedFilterCities.addAll(tempSelectedCities);
                          });
                          context.pop();
                        },
                        label: Text(
                          'Aplicar (${tempSelectedCities.isEmpty ? "Todas" : tempSelectedCities.length})',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        icon: const Icon(Icons.check),
                        backgroundColor: colors.primaryContainer,
                        foregroundColor: colors.onPrimaryContainer,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ... _buildFilterOption implementation (unchanged) ...

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surfaceContainerHigh,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: CustomSearchBar(
          controller: _searchController,
          focusNode: _focusNode,
          hintText: 'Buscar cliente...',
          onSubmitted: _onSearchSubmitted,
        ),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                ActionChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedFilterType != null) ...[
                        Icon(
                          Icons.check,
                          size: 18,
                          color: colors.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _selectedFilterType == null
                            ? 'Tipo'
                            : (_selectedFilterType == 'company'
                                  ? 'Empresas'
                                  : 'Personas'),
                        style: TextStyle(
                          color: _selectedFilterType == null
                              ? colors.onSurface
                              : colors.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: _selectedFilterType == null
                            ? colors.onSurface
                            : colors.onSecondaryContainer,
                      ),
                    ],
                  ),
                  backgroundColor: _selectedFilterType == null
                      ? colors.surface
                      : colors.secondaryContainer,
                  side: _selectedFilterType == null
                      ? BorderSide(color: colors.outline.withValues(alpha: 0.3))
                      : const BorderSide(color: Colors.transparent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  onPressed: () => _showTypeFilter(context),
                ),
                const SizedBox(width: 12),
                ActionChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedFilterCities.isNotEmpty) ...[
                        Icon(
                          Icons.check,
                          size: 18,
                          color: colors.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _selectedFilterCities.isEmpty
                            ? 'Ciudad'
                            : (_selectedFilterCities.length == 1
                                  ? _selectedFilterCities.first
                                  : '${_selectedFilterCities.first}+${_selectedFilterCities.length - 1}'),
                        style: TextStyle(
                          color: _selectedFilterCities.isEmpty
                              ? colors.onSurface
                              : colors.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: _selectedFilterCities.isEmpty
                            ? colors.onSurface
                            : colors.onSecondaryContainer,
                      ),
                    ],
                  ),
                  backgroundColor: _selectedFilterCities.isEmpty
                      ? colors.surface
                      : colors.secondaryContainer,
                  side: _selectedFilterCities.isEmpty
                      ? BorderSide(color: colors.outline.withValues(alpha: 0.3))
                      : const BorderSide(color: Colors.transparent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  onPressed: () {
                    clientsAsync.whenData((clients) {
                      _showCityFilter(context, clients);
                    });
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child:
                (_searchQuery.isEmpty &&
                    _selectedFilterType == null &&
                    _selectedFilterCities.isEmpty)
                ? _buildHistoryList(colors)
                : _buildSearchResults(clientsAsync, colors),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: colors.onSurfaceVariant, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(ColorScheme colors) {
    if (_history.isEmpty) {
      return Container();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'Historial de busqueda',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            itemCount: _history.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final term = _history[index];
              return Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -1),
                  leading: Icon(
                    Icons.history,
                    color: colors.onSurfaceVariant,
                    size: 20,
                  ),
                  title: Text(
                    term,
                    style: TextStyle(color: colors.onSurface, fontSize: 15),
                  ),
                  onTap: () {
                    _searchController.text = term;
                    _addToHistory(term);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(
    AsyncValue<List<dynamic>> clientsAsync,
    ColorScheme colors,
  ) {
    return clientsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (clients) {
        final filteredClients = clients.where((client) {
          // 1. Text Search Filter
          final matchesQuery =
              _searchQuery.isEmpty ||
              client.name.toLowerCase().contains(_searchQuery) ||
              (client.taxId?.toLowerCase() ?? '').contains(_searchQuery) ||
              (client.alias?.toLowerCase() ?? '').contains(_searchQuery) ||
              (client.email?.toLowerCase() ?? '').contains(_searchQuery);

          // 2. Type Filter
          final matchesType =
              _selectedFilterType == null || client.type == _selectedFilterType;

          // 3. City Filter
          final matchesCity =
              _selectedFilterCities.isEmpty ||
              (client.city != null &&
                  _selectedFilterCities.contains(client.city));

          return matchesQuery && matchesType && matchesCity;
        }).toList();

        if (filteredClients.isEmpty) {
          return Center(
            child: Text(
              'No se encontraron resultados',
              style: TextStyle(color: colors.outline),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          itemCount: filteredClients.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
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
                if (_searchQuery.isNotEmpty) {
                  _addToHistory(client.name);
                }
                context.push('/clients/${client.id}', extra: client);
              },
            );
          },
        );
      },
    );
  }
}
