import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:d_una_app/features/clients/presentation/providers/clients_provider.dart';
import 'package:d_una_app/features/clients/presentation/widgets/contact_list_tile.dart';
import 'package:d_una_app/features/auth/presentation/providers/register_provider.dart';
import 'package:d_una_app/core/utils/contact_utils.dart';
import 'package:d_una_app/core/utils/string_extensions.dart';

class ContactSearchScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String companyName;

  const ContactSearchScreen({
    super.key,
    required this.clientId,
    required this.companyName,
  });

  @override
  ConsumerState<ContactSearchScreen> createState() =>
      _ContactSearchScreenState();
}

class _ContactSearchScreenState extends ConsumerState<ContactSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _history = [];
  String _searchQuery = '';
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
    return 'contact_search_history_${user?.id ?? "guest"}';
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
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Buscar contacto...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 16),
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: colors.surfaceContainerHigh,
          ),
          style: TextStyle(color: colors.onSurface, fontSize: 16),
          textInputAction: TextInputAction.search,
          onSubmitted: _onSearchSubmitted,
        ),
        elevation: 0,
      ),
      body: _searchQuery.isEmpty
          ? _buildHistoryList(colors)
          : _buildSearchResults(clientsAsync, colors),
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
        final client = clients.firstWhere(
          (c) => c.id == widget.clientId,
          orElse: () => throw Exception('Client not found'),
        );

        if (client == null) {
          return const Center(child: Text('Cliente no encontrado'));
        }

        final contacts = client.contacts;
        final filteredContacts = contacts.where((contact) {
          final normalizedQuery = _searchQuery.normalized;
          return contact.name.normalized.contains(normalizedQuery) ||
              (contact.email?.normalized ?? '').contains(normalizedQuery) ||
              (contact.phone ?? '').contains(
                normalizedQuery,
              ) || // Phone usually numeric but kept as is
              (contact.role?.normalized ?? '').contains(normalizedQuery);
        }).toList();

        if (filteredContacts.isEmpty) {
          return Center(
            child: Text(
              'No se encontraron resultados',
              style: TextStyle(color: colors.outline),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          itemCount: filteredContacts.length,
          separatorBuilder: (context, index) => const Divider(height: 0),
          itemBuilder: (context, index) {
            final contact = filteredContacts[index];
            return ContactListTile(
              name: contact.name,
              role: contact.role ?? 'Sin cargo',
              initial: contact.name.isNotEmpty
                  ? contact.name[0].toUpperCase()
                  : '?',
              isPrimary: contact.isPrimary,
              onPhoneTap: () => ContactUtils.makePhoneCall(contact.phone),
              onWhatsAppTap: () => ContactUtils.launchWhatsApp(contact.phone),
              onTap: () {
                _addToHistory(contact.name);
                // Navigate to details using context.push to preserve stack
                context.push(
                  '/clients/${widget.clientId}/contacts/details',
                  extra: {
                    'companyName': widget.companyName,
                    'contact': contact,
                    'contactCount': contacts.length,
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
