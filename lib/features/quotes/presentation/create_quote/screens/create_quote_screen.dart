import 'package:d_una_app/features/quotes/presentation/create_quote/providers/create_quote_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../tabs/quote_products_tab.dart';
import '../tabs/quote_services_tab.dart';
import '../tabs/quote_client_tab.dart';
import '../tabs/quote_details_tab.dart';
import '../tabs/quote_conditions_tab.dart';
import '../tabs/quote_summary_tab.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_dialog.dart';

class CreateQuoteScreen extends ConsumerStatefulWidget {
  final String? quoteId;
  const CreateQuoteScreen({super.key, this.quoteId});

  @override
  ConsumerState<CreateQuoteScreen> createState() => _CreateQuoteScreenState();
}

class _CreateQuoteScreenState extends ConsumerState<CreateQuoteScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _hasInitializedTab = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });

    // Initialize state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.quoteId != null) {
        ref.read(createQuoteProvider.notifier).loadQuote(widget.quoteId!);
      } else {
        ref.read(createQuoteProvider.notifier).reset();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedTab && _tabController.index == 0) {
      final tabStr = GoRouterState.of(context).uri.queryParameters['tab'];
      if (tabStr != null) {
        final initialTab = int.tryParse(tabStr);
        if (initialTab != null && initialTab >= 0 && initialTab < 6) {
          _tabController.index = initialTab;
        }
      }
      _hasInitializedTab = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(createQuoteProvider);
    final notifier = ref.read(createQuoteProvider.notifier);

    return PopScope(
      canPop: !state.hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showDiscardDialog(context);
        if (shouldPop && context.mounted) {
          notifier.reset();
          context.pop();
        }
      },
      child: Scaffold(
        appBar: StandardAppBar(
          title: widget.quoteId != null ? 'Editar cotización' : 'Nueva cotización',
          subtitle: state.currentQuoteNumber != null
              ? '#${state.currentQuoteNumber}'
              : 'Cargando...',
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert, color: colors.onSurface),
              onPressed: () => _showActionsMenu(context, ref),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurfaceVariant,
            indicatorColor: colors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Productos'),
              Tab(text: 'Servicios'),
              Tab(text: 'Cliente'),
              Tab(text: 'Detalles'),
              Tab(text: 'Condiciones'),
              Tab(text: 'Resúmen'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            const QuoteProductsTab(),
            const QuoteServicesTab(),
            const QuoteClientTab(),
            const QuoteDetailsTab(),
            const QuoteConditionsTab(),
            QuoteSummaryTab(
              onNavigateToTab: (index) {
                _tabController.animateTo(index);
              },
            ),
          ],
        ),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  Widget? _buildFab() {
    // Only show FAB on Products (0), Services (1), and Conditions (4) tabs
    if (_tabController.index != 0 &&
        _tabController.index != 1 &&
        _tabController.index != 4) {
      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: CustomExtendedFab(
        onPressed: () {
          if (_tabController.index == 0) {
            context.push('/quotes/create/select-product');
          } else if (_tabController.index == 1) {
            context.push('/quotes/create/select-service');
          } else if (_tabController.index == 4) {
            final currentUri = GoRouterState.of(
              context,
            ).uri.replace(queryParameters: {'tab': '4'});
            final encodedUri = Uri.encodeComponent(currentUri.toString());
            context.push('/quotes/create/conditions?returnTo=$encodedUri');
          }
        },
        icon: Icons.add,
        label: 'Agregar',
      ),
    );
  }

  void _showActionsMenu(BuildContext context, WidgetRef ref) {
    final state = ref.read(createQuoteProvider);
    final notifier = ref.read(createQuoteProvider.notifier);

    CustomActionSheet.show(
      context: context,
      title: 'Opciones de cotización',
      actions: [
        BottomSheetActionItem(
          icon: Icons.save_outlined,
          label: 'Guardar como borrador',
          enabled: state.isReadyToSaveDraft,
          onTap: () async {
            context.pop(); // Close sheet
            final success = await notifier.saveAsDraft();
            if (success && context.mounted) {
              context.pop(); // Go back to list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cotización guardada como borrador'),
                ),
              );
            }
          },
        ),
        BottomSheetActionItem(
          icon: Icons.delete_outline,
          label: 'Descartar cambios',
          onTap: () async {
            context.pop(); // Close sheet
            final shouldDiscard = await _showDiscardDialog(context);
            if (shouldDiscard && context.mounted) {
              notifier.reset();
              context.pop(); // Go back to list
            }
          },
        ),
      ],
    );
  }

  Future<bool> _showDiscardDialog(BuildContext context) async {
    final colors = Theme.of(context).colorScheme;
    return await CustomDialog.show<bool>(
          context: context,
          dialog: CustomDialog.destructive(
            title: '¿Descartar cambios?',
            contentText:
                'Hay cambios sin guardar en esta cotización. ¿Estás seguro de que deseas salir y perder el progreso?',
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continuar editando'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                ),
                child: const Text('Descartar'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
