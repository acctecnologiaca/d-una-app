import 'package:d_una_app/features/profile/domain/models/user_profile.dart';
import 'package:d_una_app/features/quotes/presentation/quotes_list/widgets/quote_card.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/widgets/custom_search_bar.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../features/profile/presentation/providers/profile_provider.dart';
import '../providers/quotes_provider.dart';
import '../../../../../shared/widgets/friendly_error_widget.dart';
import '../../../domain/models/quote_model.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../create_quote/providers/create_quote_provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/core/pdf/templates/quote_pdf_template.dart';
import '../../../../../shared/utils/string_utils.dart';
import '../../../../../shared/widgets/user_profile_avatar.dart';
import '../../../../../shared/widgets/empty_list_state.dart';
import '../../../domain/repositories/quotes_repository.dart';
class QuotesListScreen extends ConsumerStatefulWidget {
  const QuotesListScreen({super.key});

  @override
  ConsumerState<QuotesListScreen> createState() => _QuotesListScreenState();
}

class _QuotesListScreenState extends ConsumerState<QuotesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  SortOption _currentSort = SortOption.recent;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final userProfileAsync = ref.watch(userProfileProvider);
    final selection = ref.watch(quoteSelectionProvider);
    final quotesState = ref.watch(quotesListProvider);

    final isError = quotesState.hasError || userProfileAsync.hasError;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            selection.isSelectionMode
                ? _buildSelectionHeader(context, ref, selection)
                : _buildNormalHeader(context, ref, userProfileAsync, isError),
            const SizedBox(height: 16),

            if (!isError) ...[
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
                  onFilterTap: () {},
                  onTap: () {
                    context.push('/quotes/search');
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Sort Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    SortSelector(
                      currentSort: _currentSort,
                      onSortChanged: (val) =>
                          setState(() => _currentSort = val),
                      options: const [
                        SortOption.recent,
                        SortOption.dateIssued,
                        SortOption.nameAZ,
                        SortOption.nameZA,
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // List
            Expanded(
              child: userProfileAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => FriendlyErrorWidget(
                  error: err,
                  onRetry: () {
                    ref.invalidate(userProfileProvider);
                    ref.read(quotesListProvider.notifier).refresh();
                  },
                ),
                data: (_) => ref
                    .watch(quotesListProvider)
                    .when(
                      data: (items) {
                        // Exclude archived quotes from main list
                        final activeItems = items
                            .where((q) => !q.isArchived)
                            .toList();

                        // Filter Logic (Search)
                        var filteredItems = activeItems.where((quote) {
                          final query = _searchController.text.toLowerCase();
                          if (query.isEmpty) return true;
                          return quote.clientName.toLowerCase().contains(
                                query,
                              ) ||
                              quote.quoteNumber.toLowerCase().contains(query);
                        }).toList();

                        // Sort Logic
                        filteredItems.sort((a, b) {
                          switch (_currentSort) {
                            case SortOption.recent:
                            case SortOption.frequency:
                              return b.createdAt.compareTo(a.createdAt);
                            case SortOption.dateIssued:
                              return b.date.compareTo(a.date);
                            case SortOption.nameAZ:
                              return a.clientName.compareTo(b.clientName);
                            case SortOption.nameZA:
                              return b.clientName.compareTo(a.clientName);
                            default:
                              return 0;
                          }
                        });

                        if (filteredItems.isEmpty) {
                          return EmptyListState(
                            icon: Icons.description_outlined,
                            message: 'No hay cotizaciones registradas.',
                            searchQuery: _searchController.text,
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () =>
                              ref.read(quotesListProvider.notifier).refresh(),
                          child: ListView.separated(
                            //padding: const EdgeInsets.symmetric(horizontal: 0),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: filteredItems.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 0,
                              indent: 16,
                              endIndent: 16,
                              color: Colors.transparent,
                            ),
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return QuoteCard(
                                quote: item,
                                isSelectionMode: selection.isSelectionMode,
                                isSelected: selection.isSelected(item.id),
                                onLongPress: () => ref
                                    .read(quoteSelectionProvider.notifier)
                                    .toggle(item.id),
                                onTap: selection.isSelectionMode
                                    ? () => ref
                                          .read(quoteSelectionProvider.notifier)
                                          .toggle(item.id)
                                    : () => context.push(
                                        '/quotes/view/${item.id}',
                                      ),
                              );
                            },
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => FriendlyErrorWidget(
                        error: err,
                        onRetry: () =>
                            ref.read(quotesListProvider.notifier).refresh(),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: selection.isSelectionMode || isError
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 0.0),
              child: CustomExtendedFab(
                onPressed: () {
                  ref.invalidate(createQuoteProvider);
                  context.push('/quotes/create');
                },
                icon: Icons.add,
                label: 'Nueva',
              ),
            ),
    );
  }

  Widget _buildNormalHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<UserProfile?> userProfileAsync,
    bool isError,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: isError
                ? null
                : () {
                    Scaffold.of(context).openDrawer();
                  },
          ),
          Text(
            'Cotizaciones',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          UserProfileAvatar(enabled: !isError),
        ],
      ),
    );
  }

  Widget _buildSelectionHeader(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () =>
                ref.read(quoteSelectionProvider.notifier).clearSelection(),
          ),
          Text(
            '${selection.count} Ítem${selection.count > 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Archivar',
            onPressed: () => _handleBatchArchive(context, ref, selection),
          ),
          IconButton(
            icon: const Icon(Symbols.conversion_path),
            tooltip: 'Cambiar estatus',
            onPressed: () => _showStatusDialog(context, ref, selection),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showActionsSheet(context, ref, selection),
          ),
        ],
      ),
    );
  }

  void _showActionsSheet(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection,
  ) {
    if (selection.isSingle) {
      final allQuotes = ref.read(quotesListProvider).value ?? [];
      final quote = allQuotes.firstWhere(
        (q) => q.id == selection.selectedIds.first,
      );
      _showSingleActionsSheet(context, ref, selection, quote);
    } else {
      _showMultiActionsSheet(context, ref, selection);
    }
  }

  void _showSingleActionsSheet(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection,
    Quote quote,
  ) {
    CustomActionSheet.show(
      context: context,
      title: '${quote.clientName}\n#${quote.quoteNumber}',
      actions: [
        BottomSheetActionItem(
          icon: Icons.send,
          label: 'Enviar',
          onTap: () {
            context.pop();
            _showComingSoon(context, 'Enviar');
          },
        ),
        BottomSheetActionItem(
          icon: Symbols.conversion_path,
          label: 'Cambiar estatus',
          onTap: () {
            context.pop();
            _showStatusDialog(context, ref, selection);
          },
        ),
        BottomSheetActionItem(
          icon: Icons.picture_as_pdf_outlined,
          label: 'Descargar PDF',
          onTap: () async {
            context.pop();

            final userProfile = ref.read(userProfileProvider).value;
            final userEmail = Supabase.instance.client.auth.currentUser?.email;

            if (userProfile == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Cargando perfil de usuario... Por favor espere.',
                  ),
                ),
              );
              return;
            }

            // Mostramos feedback de carga
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Preparando documento...'),
                duration: Duration(seconds: 1),
              ),
            );

            try {
              // Cargamos la cotización completa con sus detalles
              final fullQuote = await ref
                  .read(quotesRepositoryProvider)
                  .getQuoteWithDetails(quote.id);

              if (context.mounted) {
                context.push(
                  '/pdf-preview',
                  extra: {
                    'title': 'Previsualizar Cotización',
                    'subtitle':
                        ' ${fullQuote.quoteNumber} (${fullQuote.clientName})',
                    'fileName': StringUtils.sanitizeForFileName(
                      '${fullQuote.dateIssued.toIso8601String().substring(0, 10)}_${fullQuote.clientName ?? ''}_${fullQuote.quoteNumber ?? fullQuote.id}_${fullQuote.quoteTag ?? ''}.pdf',
                    ),
                    'buildPdf': (PdfPageFormat format) => QuotePdfTemplate(
                      quote: fullQuote,
                      products: fullQuote.products ?? [],
                      services: fullQuote.services ?? [],
                      conditions: fullQuote.conditions ?? [],
                      userProfile: userProfile,
                      userEmail: userEmail,
                    ).generate(format),
                  },
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al cargar detalles de cotización: $e'),
                  ),
                );
              }
            }
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: Icons.shopping_cart_outlined,
          label: 'Realizar pedido',
          onTap: () {
            context.pop();
            _showComingSoon(context, 'Realizar pedido');
          },
        ),
        BottomSheetActionItem(
          icon: Icons.receipt_outlined,
          label: 'Generar nota de entrega',
          onTap: () {
            context.pop();
            _showComingSoon(context, 'Generar nota de entrega');
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: Icons.content_copy_outlined,
          label: 'Crear una copia',
          onTap: () async {
            context.pop();
            await ref
                .read(createQuoteProvider.notifier)
                .loadQuoteAsCopy(quote.id);
            if (context.mounted) {
              ref.read(quoteSelectionProvider.notifier).clearSelection();
              context.push('/quotes/create');
            }
          },
        ),
        BottomSheetActionItem(
          icon: Icons.edit_outlined,
          label: 'Modificar',
          onTap: () {
            context.pop();
            ref.read(quoteSelectionProvider.notifier).clearSelection();
            context.push('/quotes/edit/${quote.id}');
          },
        ),
        BottomSheetActionItem(
          icon: quote.isArchived
              ? Icons.unarchive_outlined
              : Icons.archive_outlined,
          label: quote.isArchived ? 'Desarchivar' : 'Archivar',
          onTap: () async {
            context.pop();
            await ref
                .read(quotesListProvider.notifier)
                .archiveQuote(quote.id, archive: !quote.isArchived);
            ref.read(quoteSelectionProvider.notifier).clearSelection();
          },
        ),
      ],
    );
  }

  void _showMultiActionsSheet(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection,
  ) {
    CustomActionSheet.show(
      context: context,
      title: '${selection.count} seleccionados',
      actions: [
        BottomSheetActionItem(
          icon: Symbols.conversion_path,
          label: 'Cambiar estatus',
          onTap: () {
            context.pop();
            _showStatusDialog(context, ref, selection);
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        BottomSheetActionItem(
          icon: Icons.archive_outlined,
          label: 'Archivar',
          onTap: () async {
            context.pop();
            _handleBatchArchive(context, ref, selection);
          },
        ),
      ],
    );
  }

  Future<void> _showStatusDialog(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection,
  ) async {
    final selectedStatus = await CustomDialog.show<QuoteStatus>(
      context: context,
      dialog: CustomDialog.vertical(
        icon: Symbols.conversion_path,
        title: 'Cambiar estatus',
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: QuoteStatus.values
              .where((status) => status != QuoteStatus.expired)
              .map((status) {
                return ListTile(
                  leading: Image.asset(status.iconPath, width: 24, height: 24),
                  title: Text(status.label),
                  onTap: () =>
                      Navigator.of(context, rootNavigator: true).pop(status),
                );
              })
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selectedStatus != null) {
      try {
        await ref
            .read(quotesListProvider.notifier)
            .batchUpdateStatus(
              selection.selectedIds.toList(),
              selectedStatus.dbValue,
            );
        ref.read(quoteSelectionProvider.notifier).clearSelection();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Estatus cambiado a "${selectedStatus.label}"'),
            ),
          );
        }
      } on InsufficientStockException catch (e) {
        if (!context.mounted) return;
        CustomDialog.show(
          context: context,
          dialog: CustomDialog.confirmation(
            icon: Symbols.warning,
            iconColor: Colors.amber.shade800,
            title: 'Stock Insuficiente',
            contentText: 'No se puede aprobar la cotización porque no hay suficiente stock disponible en el inventario propio de los siguientes productos:\n\n${e.productNames.map((name) => '• $name').join('\n')}\n\nPor favor, agregue más stock para poder aprobarla.',
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estatus: $e'),
          ),
        );
      }
    }
  }

  void _showComingSoon(BuildContext context, String action) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$action — Próximamente')));
  }

  Future<void> _handleBatchArchive(
    BuildContext context,
    WidgetRef ref,
    QuoteSelectionState selection,
  ) async {
    await ref
        .read(quotesListProvider.notifier)
        .batchArchive(selection.selectedIds.toList(), archive: true);
    ref.read(quoteSelectionProvider.notifier).clearSelection();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${selection.count} cotización${selection.count > 1 ? 'es' : ''} archivada${selection.count > 1 ? 's' : ''}',
          ),
        ),
      );
    }
  }
}
